import Foundation
import UIKit

struct Update: Codable {
    var pages: [String: JsonItem]?
    var stack: [String]?
    var userError: String?
}

struct FetchError: Error {
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
    var connectionMode: ConnectionMode = .disconnect

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
        self.connectionMode = entries.map({ (_, data) in data.inner().connectionMode }).max() ?? .disconnect
        self.connection.setMode(self, self.connectionMode)
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

    func applyUpdate(_ data: Data) -> Bool {
        // TODO: Support null 'pages' entries.  Run Applin's dynamic_page example.
        let update: Update
        do {
            update = try decodeJson(data)
            print("update \(update)")
        } catch {
            print("error decoding update: \(error)")
            return false
        }
        if let newStack = update.stack {
            self.stack = newStack
        }
        if let newPages = update.pages {
            for (key, item) in newPages {
                do {
                    self.pages[key] = try PageData(item, self)
                    print("updated key \(key)")
                } catch {
                    print("ERROR: error processing updated key '\(key)': \(error)")
                }
            }
        }
        // TODO: Handle user_error.
        self.cacheFileWriter.scheduleWrite(self)
        self.updateNav()
        return true
    }

    func rpc(path: String, method: String) async -> Bool {
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
            print("rpc \(path) transport error: \(error)")
            // TODO: Push error modal
            return false
        }
        if !(200...299).contains(httpResponse.statusCode) {
            if httpResponse.contentTypeBase() == "text/plain",
               let string = String(data: data, encoding: .utf8) {
                print("rpc \(path) server error: \(httpResponse.statusCode) "
                        + "\(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)) \"\(string)\"")
            } else {
                print("rpc \(path) server error: \(httpResponse.statusCode) "
                        + "\(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)), "
                        + "len=\(data.count) \(httpResponse.mimeType ?? "")")
            }
            // TODO: Save error
            // TODO: Push error modal
            return false
        }
        let contentTypeBase = httpResponse.contentTypeBase()
        if contentTypeBase != "application/json" {
            print("rpc \(path) server response content-type is not 'application/json': '\(contentTypeBase ?? "")'")
            // TODO: Save error
            // TODO: Push error modal
            return false
        }
        return self.applyUpdate(data)
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

    func doActionsAsync(_ actions: [ActionData]) async {
        // TODO: Call updateNav once at the end, to reduce racing.
        loop: for action in actions {
            switch action {
            case let .copyToClipboard(string):
                print("CopyToClipboard(\(string))")
                UIPasteboard.general.string = string
            case let .launchUrl(url):
                print("LaunchUrl(\(url))")
                // TODO
                print("unimplemented")
            case .logout:
                print("Logout")
                // TODO
                print("unimplemented")
            case .nothing:
                print("Nothing")
            case .pop:
                print("Pop")
                self.pop()
            case let .push(key):
                print("Push(\(key))")
                self.push(pageKey: key)
            case let .rpc(path):
                print("Rpc(\(path))")
                let result = await self.rpc(path: path, method: "POST")
                if !result {
                    break loop
                }
            }
        }
    }

    func doActions(_ actions: [ActionData]) {
        Task {
            await self.doActionsAsync(actions)
        }
    }
}
