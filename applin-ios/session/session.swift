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

// TODO: Prevent racing between applyUpdate(), rpc(), and doActionsAsync().

class ApplinSession: ObservableObject {
    let cacheFileWriter: CacheFileWriter?
    let connection: ApplinConnection?
    weak var nav: NavigationController?
    let url: URL
    var error: String?
    var pages: [String: PageSpec] = [:]
    var stack: [String] = ["/"]
    var vars: [String: Var] = [:]
    var connectionMode: ConnectionMode = .disconnect
    var pauseUpdateNav: Bool = false

    init(_ cacheFileWriter: CacheFileWriter?,
         _ connection: ApplinConnection?,
         _ nav: NavigationController?,
         _ url: URL
    ) {
        print("ApplinSession \(url)")
        precondition(url.scheme == "http" || url.scheme == "https")
        self.cacheFileWriter = cacheFileWriter
        self.connection = connection
        self.nav = nav
        self.url = url
    }

    public func pause() {
        self.connection?.pause()
    }

    public func unpause() {
        self.connection?.unpause(self, self.connectionMode)
    }

    public func updateNav() {
        print("updateNav \(self.stack)")
        if self.pauseUpdateNav {
            print("updateNav paused")
            return
        }
        if self.stack.isEmpty {
            self.stack = ["/"]
            print("updateNav \(self.stack)")
        }
        let entries = self.stack.map({ key -> (String, PageSpec) in
            let page =
                    self.pages[key]
                            ?? self.pages["/applin-page-not-found"]
                            ?? .navPage(NavPageSpec(
                            pageKey: key,
                            title: "Not Found",
                            // TODO: Center the text.
                            widget: Spec(.text(TextSpec("Page not found.")))
                    ))
            return (key, page)
        })
        self.connectionMode = entries.map({ (_, pageSpec) in pageSpec.connectionMode }).min() ?? .disconnect
        self.connection?.setMode(self, self.connectionMode)
        Task {
            await self.nav?.setStackPages(self, entries)
        }
    }

    func pop() {
        if self.stack.count > 1 {
            let key = self.stack.removeLast()
            print("pop '\(key)'")
        }
        if self.stack.isEmpty {
            self.stack = ["/"]
        }
        print("stack=\(self.stack)")
        self.updateNav()
    }

    func push(pageKey: String) {
        print("push '\(pageKey)'")
        self.stack.append(pageKey)
        print("stack=\(self.stack)")
        self.updateNav()
    }

    func setStack(_ stack: [String]) {
        self.stack = stack
        if self.stack.isEmpty {
            self.stack = ["/"]
        }
        print("stack=\(self.stack)")
        self.updateNav()
    }

    func setVar(_ name: String, _ optValue: Var?) {
        guard let value = optValue else {
            print("setVar \(name)=nil")
            self.vars.removeValue(forKey: name)
            return
        }
        switch (self.vars[name], value) {
        case (.none, _), (.boolean, .boolean), (.string, .string):
            break
        default:
            print("WARN setVar changed var type: \(name): \(String(describing: self.vars[name])) -> \(value)")
        }
        print("setVar \(name)=\(value)")
        self.vars[name] = value
        self.cacheFileWriter?.scheduleWrite(self)
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
        switch self.vars[name] {
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
        switch self.vars[name] {
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
        if let newStack = update.stack {
            self.stack = newStack
        }
        var err: String?
        if let newPages = update.pages {
            for (key, optItem) in newPages {
                if let item = optItem {
                    do {
                        let pageSpec = try PageSpec(self, pageKey: key, item)
                        self.pages[key] = pageSpec
                        print("updated key \(key) \(pageSpec)")
                    } catch {
                        err = "error processing updated key '\(key)': \(error)"
                        print(err!)
                    }
                } else {
                    self.pages.removeValue(forKey: key)
                    print("removed key \(key)")
                }
            }
        }
        // TODO: Handle user_error.
        self.cacheFileWriter?.scheduleWrite(self)
        if let vars = update.vars {
            for (name, jsonValue) in vars {
                switch jsonValue {
                case let .boolean(value):
                    self.setBoolVar(name, value)
                default:
                    print("WARN ignoring var from server \(name)=\(jsonValue)")
                }
            }
        }
        if let err = err {
            throw ApplinError.serverError(err)
        }
        self.updateNav()
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
        let url = self.url.appendingPathComponent(
                path.starts(with: "/") ? String(path.dropFirst()) : path)
        var urlRequest = URLRequest(
                url: url,
                cachePolicy: .reloadIgnoringLocalAndRemoteCacheData
        )
        urlRequest.httpMethod = method
        if let pageKey = optPageKey {
            urlRequest.addValue("application/json", forHTTPHeaderField: "content-type")
            var reqObj: [String: JSON] = [:]
            if let pageSpec = self.pages[pageKey] {
                for (name, initialValue) in pageSpec.vars() {
                    reqObj[name] = (self.vars[name] ?? initialValue).toJson()
                }
            } else {
                // TODO: Prevent this.
                print("WARN rpc for missing page '\(pageKey)', not including any variables")
            }
            urlRequest.httpBody = try! encodeJson(reqObj)
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

    @MainActor func doActionsAsync(pageKey: String, _ actions: [ActionSpec]) async -> Bool {
        self.pauseUpdateNav = true
        defer {
            self.pauseUpdateNav = false
            self.updateNav()
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
                self.nav?.setWorking("Working")
                defer {
                    self.nav?.setWorking(nil)
                }
                let stopwatch = Stopwatch()
                do {
                    try await self.rpc(pageKey: pageKey, path: path, method: "POST")
                    await stopwatch.waitUntil(seconds: 1.0)
                } catch {
                    print(error)
                    switch error as? ApplinError {
                    case nil:
                        self.error = "Unexpected exception: \(error)"
                        await stopwatch.waitUntil(seconds: 1.0)
                        self.push(pageKey: "/applin-error-details")
                    case let .deserializeError(msg), let .networkError(msg), let .serverError(msg):
                        self.error = msg
                        await stopwatch.waitUntil(seconds: 1.0)
                        self.push(pageKey: "/applin-error-details")
                    case let .userError(msg):
                        self.error = msg
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
