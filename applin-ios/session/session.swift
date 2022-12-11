import Foundation
import UIKit

struct Update: Codable {
    var pages: [String: JsonItem?]?
    var stack: [String]?
    var userError: String?
    var vars: [String: JSON]?
}

struct FetchError: Error {
}

enum Var {
    case boolean(Bool)
    case string(String)
    // case Int(Int64)
    // case Float(Double)
    // case EpochSeconds(UInt64)

    func toJson() -> JSON {
        switch self {
        case let .boolean(value):
            return .boolean(value)
        case let .string(value):
            return .string(value)
        }
    }
}

struct ApplinState {
    public static func loading() -> Self {
        ApplinState(
                connectionMode: .disconnect,
                error: nil,
                // TODO: Show a spinner.
                pages: ["/loading": .plainPage(PlainPageSpec(title: "Loading", Spec(.text(TextSpec("Loading")))))],
                pauseUpdateNav: false,
                stack: ["/loading"],
                vars: [:]
        )
    }

    public static func loadError(error: String) -> Self {
        ApplinState(
                connectionMode: .disconnect,
                error: nil,
                pages: [
                    "/error": .plainPage(PlainPageSpec(
                            title: "Error",
                            Spec(.text(TextSpec("ERROR: \(error)")))
                    ))
                ],
                pauseUpdateNav: false,
                stack: ["/error"],
                vars: [:]
        )
    }

    // TODO: Replace connectionMode with a method.
    var connectionMode: ConnectionMode = .disconnect
    var error: String?
    var pages: [String: PageSpec] = [:]
    var pauseUpdateNav: Bool = false
    var stack: [String] = ["/"]
    var vars: [String: Var] = [:]

    public mutating func merge(_ other: ApplinState) {
        self.connectionMode = other.connectionMode
        self.error = other.error
        for (key, spec) in other.pages {
            self.pages[key] = spec
        }
        self.pauseUpdateNav = other.pauseUpdateNav
        self.stack = other.stack
        for (name, value) in other.vars {
            self.vars[name] = value
        }
    }

    public mutating func setVar(_ name: String, _ optValue: Var?) -> [String] {
        guard let value = optValue else {
            self.vars.removeValue(forKey: name)
            return ["setVar \(name)=nil"]
        }
        let oldValue = self.vars.updateValue(value, forKey: name)
        switch (oldValue, value) {
        case let (.boolean, .boolean(value)):
            return ["setVar \(name)=\(value)"]
        case let (.string, .string(value)):
            return ["setVar \(name)=\(value)"]
        default:
            return [
                "setVar \(name)=\(value)",
                "WARN setVar changed var type: \(name): \(String(describing: oldValue)) -> \(String(describing: optValue))"
            ]
        }
    }
}

// TODO: Prevent racing between applyUpdate(), rpc(), and doActionsAsync().

class ApplinSession: ObservableObject {
    let config: ApplinConfig
    let stateStore: StateStore
    let connection: ApplinConnection?
    let nav: NavigationController?

    init(_ config: ApplinConfig,
         _ stateStore: StateStore,
         _ connection: ApplinConnection?,
         _ nav: NavigationController?
    ) {
        print("ApplinSession")
        self.config = config
        self.stateStore = stateStore
        self.connection = connection
        self.nav = nav
        self.updateDisplayedPages()
    }

    public func pause() {
        self.connection?.pause()
    }

    public func unpause() {
        let connectionMode = self.stateStore.read({ state in state.connectionMode })
        self.connection?.unpause(self, connectionMode)
    }

    public func updateDisplayedPages() {
        let (pauseUpdateNav, stack, entries, connectionMode) = self.stateStore.update({
            state -> (Bool, [String], [(String, PageSpec)], ConnectionMode) in
            if state.pauseUpdateNav {
                return (true, [], [], .disconnect)
            }
            if state.stack.isEmpty {
                state.stack = ["/"]
            }
            let entries: [(String, PageSpec)] = state.stack.map({ key -> (String, PageSpec) in
                let page = state.pages[key]
                        ?? state.pages["/applin-page-not-found"]
                        ?? .navPage(NavPageSpec(
                        pageKey: key,
                        title: "Not Found",
                        // TODO: Center the text.
                        widget: Spec(.text(TextSpec("Page not found.")))
                ))
                return (key, page)
            })
            state.connectionMode = entries.map({ (_, pageSpec) in pageSpec.connectionMode }).min() ?? .disconnect
            // Swift Array and String are value types.
            return (false, state.stack, entries, state.connectionMode)
        })
        print("updateNav \(stack)")
        if pauseUpdateNav {
            print("updateNav paused")
            return
        }
        self.connection?.setMode(self, connectionMode)
        Task {
            await self.nav?.setStackPages(self, entries)
        }
    }

    func pop() {
        let (stack, optPoppedKey) = self.stateStore.update({ state -> ([String], String?) in
            let optPoppedKey = state.stack.isEmpty ? nil : state.stack.removeLast()
            if state.stack.isEmpty {
                state.stack = ["/"]
            }
            return (state.stack, optPoppedKey)
        })
        if let poppedKey = optPoppedKey {
            print("pop '\(poppedKey)'")
        }
        print("stack=\(stack)")
        self.updateDisplayedPages()
    }

    func push(pageKey: String) {
        print("push '\(pageKey)'")
        let stack = self.stateStore.update({ state -> [String] in
            state.stack.append(pageKey)
            return state.stack
        })
        print("stack=\(stack)")
        self.updateDisplayedPages()
    }

    func setVar(_ name: String, _ optValue: Var?) {
        let messages = self.stateStore.update({ state -> [String] in state.setVar(name, optValue) })
        for message in messages {
            print(message)
        }
    }

    func setBoolVar(_ name: String, _ optValue: Bool?) {
        if let value = optValue {
            self.setVar(name, .boolean(value))
        } else {
            self.setVar(name, nil)
        }
    }

    func setStringVar(_ name: String, _ optValue: String?) {
        if let value = optValue {
            self.setVar(name, .string(value))
        } else {
            self.setVar(name, nil)
        }
    }

    func getBoolVar(_ name: String) -> Bool? {
        switch self.stateStore.read({ state in state.vars[name] }) {
        case .none:
            return nil
        case let .some(.boolean(value)):
            return value
        case let .some(other):
            print("WARNING tried to read variable \(name) as bool but it is: \(other)")
            return nil
        }
    }

    func getStringVar(_ name: String) -> String? {
        switch self.stateStore.read({ state in state.vars[name] }) {
        case .none:
            return nil
        case let .some(.string(value)):
            return value
        case let .some(other):
            print("WARNING tried to read variable \(name) as string but it is: \(other)")
            return nil
        }
    }

    func applyUpdate(_ data: Data) throws {
        let update: Update
        do {
            update = try decodeJson(data)
            print("update \(update)")
        } catch {
            throw ApplinError.serverError("error decoding update: \(error)")
        }
        let messages: [String] = self.stateStore.update({ state in
            var messages: [String] = []
            if let newPages = update.pages {
                for (key, optItem) in newPages {
                    if let item = optItem {
                        do {
                            let pageSpec = try PageSpec(self.config, pageKey: key, item)
                            state.pages[key] = pageSpec
                            messages.append("updated key \(key) \(pageSpec)")
                        } catch {
                            state.pages[key] = .navPage(NavPageSpec(
                                    pageKey: key,
                                    title: "Error",
                                    // TODO: Show a better error page.
                                    widget: Spec(.text(TextSpec("Error loading page. Please update the app.")))
                            ))
                            messages.append("WARN error processing updated key '\(key)': \(error)")
                        }
                    } else {
                        state.pages.removeValue(forKey: key)
                        messages.append("removed key \(key)")
                    }
                }
            }
            if let newStack = update.stack {
                state.stack = newStack
            }
            // TODO: Handle user_error.
            if let vars = update.vars {
                for (name, jsonValue) in vars {
                    switch jsonValue {
                    case .null:
                        let newMessages = state.setVar(name, nil)
                        messages.append(contentsOf: newMessages)
                    case let .boolean(value):
                        let newMessages = state.setVar(name, .boolean(value))
                        messages.append(contentsOf: newMessages)
                    case let .string(value):
                        let newMessages = state.setVar(name, .string(value))
                        messages.append(contentsOf: newMessages)
                    default:
                        messages.append("WARN ignoring unknown var from server \(name)=\(jsonValue)")
                    }
                }
            }
            return messages
        })
        for message in messages {
            print(message)
        }
        self.updateDisplayedPages()
    }

    func rpc(pageKey optPageKey: String?, path: String, method: String) async throws {
        print("rpc \(path)")
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10.0 /* seconds */
        config.timeoutIntervalForResource = 60.0 /* seconds */
        config.urlCache = nil
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        let urlSession = URLSession(configuration: config)
        defer {
            urlSession.invalidateAndCancel()
        }
        let url = self.config.url.appendingPathComponent(
                path.starts(with: "/") ? String(path.dropFirst()) : path)
        var urlRequest = URLRequest(
                url: url,
                cachePolicy: .reloadIgnoringLocalAndRemoteCacheData
        )
        urlRequest.httpMethod = method
        if let pageKey = optPageKey {
            urlRequest.addValue("application/json", forHTTPHeaderField: "content-type")
            let optVars: [String: Var]? = self.stateStore.read({ state -> [String: Var]? in
                if let pageSpec = state.pages[pageKey] {
                    var vars: [String: Var] = [:]
                    for (name, initialValue) in pageSpec.vars() {
                        let value = state.vars[name] ?? initialValue
                        vars[name] = value
                    }
                    return vars
                } else {
                    return nil
                }
            })
            let jsonBody: [String: JSON]
            if let vars = optVars {
                jsonBody = vars.mapValues({ v in v.toJson() })
            } else {
                // TODO: Prevent this.
                print("WARN rpc for missing page '\(pageKey)', not including any variables")
                jsonBody = [:]
            }
            urlRequest.httpBody = try! encodeJson(jsonBody)
            if let bodyString = String(data: urlRequest.httpBody!, encoding: .utf8) {
                print("DEBUG request body: \(bodyString)")
            }
        }
        let data: Data
        let httpResponse: HTTPURLResponse
        do {
            let (urlData, urlResponse) = try await urlSession.data(for: urlRequest)
            data = urlData
            httpResponse = urlResponse as! HTTPURLResponse
        } catch {
            throw ApplinError.networkError("rpc \(path) transport error: \(error)")
        }
        if !(200...299).contains(httpResponse.statusCode) {
            if httpResponse.contentTypeBase() == "text/plain", let string = String(data: data, encoding: .utf8) {
                throw ApplinError.serverError("rpc \(path) server error: \(httpResponse.statusCode) "
                        + "\(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)) \"\(string)\"")
            } else {
                throw ApplinError.serverError("rpc \(path) server error: \(httpResponse.statusCode) "
                        + "\(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)), "
                        + "len=\(data.count) \(httpResponse.mimeType ?? "")")
            }
        }
        let contentTypeBase = httpResponse.contentTypeBase()
        if let bodyString = String(data: data, encoding: .utf8) {
            print("DEBUG response body \(contentTypeBase ?? ""): \(bodyString)")
        }
        if contentTypeBase != "application/json" {
            throw ApplinError.serverError(
                    "rpc \(path) server response content-type is not 'application/json': '\(contentTypeBase ?? "")'")
        }
        try self.applyUpdate(data)
    }

    func fetch(_ url: URL) async throws -> Data {
        // TODO: Merge concurrent fetches of the same URL.
        //  https://developer.apple.com/documentation/uikit/views_and_controls/table_views/asynchronously_loading_images_into_table_and_collection_views#3637628
        // TODO: Retry on error.
        // TODO: When retrying multiple URLs at same server, round-robin the URLs.
        print("fetch \(url.absoluteString)")
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10.0 /* seconds */
        config.timeoutIntervalForResource = 60.0 /* seconds */
        // TODONT: Don't set the config.urlCache to nil.  We want to use the cache.
        config.httpShouldSetCookies = true
        let urlSession = URLSession(configuration: config)
        defer {
            urlSession.invalidateAndCancel()
        }
        var urlRequest = URLRequest(
                url: url,
                cachePolicy: .useProtocolCachePolicy
        )
        urlRequest.httpMethod = "GET"
        let data: Data
        let httpResponse: HTTPURLResponse
        do {
            let (urlData, urlResponse) = try await urlSession.data(for: urlRequest)
            data = urlData
            httpResponse = urlResponse as! HTTPURLResponse
        } catch {
            print("fetch \(url.absoluteString) transport error: \(error)")
            throw FetchError()
        }
        if !(200...299).contains(httpResponse.statusCode) {
            if httpResponse.contentTypeBase() == "text/plain",
               let string = String(data: data, encoding: .utf8) {
                print("fetch \(url.absoluteString) server error: \(httpResponse.statusCode) "
                        + "\(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)) \"\(string)\"")
            } else {
                print("fetch \(url.absoluteString) server error: \(httpResponse.statusCode) "
                        + "\(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)), "
                        + "len=\(data.count) \(httpResponse.mimeType ?? "")")
            }
            throw FetchError()
        }
        return data
    }

    func doActionsAsync(pageKey: String, _ actions: [ActionSpec]) async -> Bool {
        self.stateStore.update({ state in state.pauseUpdateNav = true })
        defer {
            self.stateStore.update({ state in state.pauseUpdateNav = false })
            self.updateDisplayedPages()
        }
        loop: for action in actions {
            switch action {
            case let .copyToClipboard(string):
                print("copyToClipboard(\(string))")
                UIPasteboard.general.string = string
            case let .launchUrl(url):
                // TODO: Implement launch-url action
                print("launchUrl(\(url)) unimplemented")
            case .logout:
                // TODO: Implement Logout
                print("logout unimplemented")
            case .nothing:
                print("nothing")
            case .pop:
                print("pop")
                self.pop()
            case let .push(key):
                print("push(\(key))")
                self.push(pageKey: key)
            case let .rpc(path):
                print("rpc(\(path))")
                await self.nav?.setWorking("Working")
                defer {
                    Task {
                        await self.nav?.setWorking(nil)
                    }
                }
                let stopwatch = Stopwatch()
                do {
                    try await self.rpc(pageKey: pageKey, path: path, method: "POST")
                    await stopwatch.waitUntil(seconds: 1.0)
                } catch {
                    print(error)
                    switch error as? ApplinError {
                    case nil:
                        self.stateStore.update({ state in state.error = "Unexpected exception: \(error)" })
                        await stopwatch.waitUntil(seconds: 1.0)
                        self.push(pageKey: "/applin-error-details")
                    case let .appError(msg), let .networkError(msg), let .serverError(msg):
                        self.stateStore.update({ state in state.error = msg })
                        await stopwatch.waitUntil(seconds: 1.0)
                        self.push(pageKey: "/applin-error-details")
                    case let .userError(msg):
                        self.stateStore.update({ state in state.error = msg })
                        await stopwatch.waitUntil(seconds: 1.0)
                        // TODO: Display a simple alert.
                        self.push(pageKey: "/applin-error-details")
                    }
                    return false
                }
            }
        }
        return true
    }

    func doActions(pageKey: String, _ actions: [ActionSpec]) {
        Task {
            await self.doActionsAsync(pageKey: pageKey, actions)
        }
    }
}
