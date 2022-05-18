import Foundation
import UIKit

struct Update: Codable {
    var pages: [String: JsonItem]?
    var stack: [String]?
    var userError: String?
}

class MaggieSession: ObservableObject {
    let cacheFileWriter: CacheFileWriter
    let connection: MaggieConnection
    let nav: NavigationController
    let url: URL
    var error: String?
    var pages: [String: MaggiePage] = [:]
    var stack: [String] = ["/"]

    init(_ cacheFileWriter: CacheFileWriter,
         _ connection: MaggieConnection,
         _ nav: NavigationController,
         _ url: URL
    ) {
        print("MaggieSession \(url)")
        precondition(url.scheme == "http" || url.scheme == "https")
        self.cacheFileWriter = cacheFileWriter
        self.connection = connection
        self.nav = nav
        self.url = url
    }

    private func updateNav() {
        print("updateNav \(self.stack)")
        if self.stack.isEmpty {
            self.stack = ["/"]
            print("updateNav \(self.stack)")
        }
        let entries = self.stack.map({ key -> (String, MaggiePage) in
            let page =
                    self.pages[key]
                            // TODO: Show loading.
                            ?? self.pages["/maggie-page-not-found"]
                            ?? .navPage(MaggieNavPage(
                            title: "Not Found",
                            widget: .expand(MaggieExpand(
                                    .text(MaggieText("Page not found."))
                            ))
                    ))
            return (key, page)
        })
        self.nav.setStackPages(self, entries)
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
        let update: Update
        do {
            update = try decodeJson(data)
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
                    self.pages[key] = try MaggiePage(item, self)
                    print("updated key \(key)")
                } catch {
                    print("ERROR: error processing updated key '\(key)': \(error)")
                }
            }
        }
        // TODO: Handle user_error.
        self.cacheFileWriter.scheduleWrite(self)
        return true
    }

    func rpc(path: String) async -> Bool {
        print("rpc \(path)")
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10.0 /* seconds */
        config.timeoutIntervalForResource = 60.0 /* seconds */
        config.urlCache = nil
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
        urlRequest.httpMethod = "POST"
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

    func doActionsAsync(_ actions: [MaggieAction]) async {
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
                let result = await self.rpc(path: path)
                if !result {
                    break loop
                }
            }
        }
    }

    func doActions(_ actions: [MaggieAction]) {
        Task {
            await self.doActionsAsync(actions)
        }
    }
}
