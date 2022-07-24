import Foundation
import UIKit

struct Update: Codable {
    var pages: [String: JsonItem]?
    var stack: [String]?
    var userError: String?
}

struct FetchError: Error {
}

enum Var {
    case Bool(Bool)
    case String(String)
    // case Int(Int64)
    // case Float(Double)
    // case EpochSeconds(UInt64)
}

// TODO: Prevent racing between applyUpdate(), rpc(), and doActionsAsync().
class ApplinSession: ObservableObject {
    let cacheFileWriter: CacheFileWriter
    let connection: ApplinConnection
    weak var nav: NavigationController?
    let url: URL
    var error: String?
    var pages: [String: PageData] = [:]
    var stack: [String] = ["/"]
    var vars: [String: Var] = [:]
    var connectionMode: ConnectionMode = .disconnect
    var pauseUpdateNav: Bool = false

    init(_ cacheFileWriter: CacheFileWriter,
         _ connection: ApplinConnection,
         _ nav: NavigationController,
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
        self.connection.pause()
    }

    public func unpause() {
        self.connection.unpause(self, self.connectionMode)
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
        let entries = self.stack.map({ key -> (String, PageData) in
            let page =
                    self.pages[key]
                            ?? self.pages["/applin-page-not-found"]
                            ?? .navPage(NavPageData(
                            title: "Not Found",
                            // TODO: Center the text.
                            widget: .text(TextData("Page not found."))
                    ))
            return (key, page)
        })
        self.connectionMode = entries.map({ (_, data) in data.inner().connectionMode }).min() ?? .disconnect
        self.connection.setMode(self, self.connectionMode)
        Task {
            await self.nav?.setStackPages(self, entries)
            // TODO: Fix bug where poll gets updates but they aren't visible until user scrolls.
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

    func setBoolVar(_ name: String, value: Bool) {
        let newVar: Var = .Bool(value)
        switch self.vars[name] {
        case .none, .Bool:
            break
        case let .some(oldVar):
            print("WARN setVar changed var type: \(name): \(oldVar) -> \(newVar)")
        }
        print("setVar \(name)=\(newVar)")
        self.vars[name] = newVar
        self.cacheFileWriter.scheduleWrite(self)
    }

    func getBoolVar(_ name: String) -> Bool? {
        switch self.vars[name] {
        case .none:
            return nil
        case let .some(.Bool(value)):
            return value
        case let .some(other):
            print("WARNING tried to read variable \(name) as bool but it is: \(other)")
            return nil
        }
    }

    func applyUpdate(_ data: Data) throws {
        // TODO: Support null 'pages' entries.  Run Applin's dynamic_page example.
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
            for (key, item) in newPages {
                do {
                    let data = try PageData(item, self)
                    self.pages[key] = data
                    print("updated key \(key) \(data)")
                } catch {
                    err = "error processing updated key '\(key)': \(error)"
                    print(err!)
                }
            }
        }
        if let err = err {
            throw ApplinError.serverError(err)
        }
        // TODO: Handle user_error.
        self.cacheFileWriter.scheduleWrite(self)
        self.updateNav()
    }

    func rpc(path: String, method: String) async throws {
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
        // urlRequest.httpBody = try! encodeJson(jsonRequest)
        urlRequest.addValue("application/json", forHTTPHeaderField: "content-type")
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

    @MainActor func doActionsAsync(_ actions: [ActionData]) async -> Bool {
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
                    try await self.rpc(path: path, method: "POST")
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

    func doActions(_ actions: [ActionData]) {
        Task {
            await self.doActionsAsync(actions)
        }
    }
}
