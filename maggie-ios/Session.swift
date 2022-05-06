import Foundation
import SwiftUI

enum SessionState {
    case startup, connectError, serverError, connected
}

struct CacheFileContents: Codable {
    var pages: [String: JsonItem]?
    var stack: [String]?
}

struct Update: Codable {
    var pages: [String: JsonItem]?
    var stack: [String]?
    var user_error: String?
}

class MaggieSession: ObservableObject {
    static func cacheFilePath() -> String {
        return documentDirPath() + "/cache.json"
    }
    
    static func readCacheFile() async -> CacheFileContents? {
        print("readCacheFile")
        let path = cacheFilePath()
        let bytes: Data
        do {
            bytes = try await readFile(path: path)
        } catch {
            print("error reading file \(path): \(error)")
            return nil
        }
        do {
            return try decodeJson(bytes)
        } catch {
            print("error decoding file \(path): \(error)")
            return nil
        }
    }
    
    static func writeCacheFile(pages: [String: MaggiePage], stack: [String]) async throws {
        print("writeCacheFile")
        var contents = CacheFileContents()
        contents.pages = pages.mapValues({page in page.toJsonItem()})
        contents.stack = stack
        let bytes = try encodeJson(contents)
        let path = cacheFilePath()
        let tmpPath = path + ".tmp"
        if await fileExists(path: tmpPath) {
            try await deleteFile(path: tmpPath)
        }
        try await writeFile(data: bytes, path: tmpPath)
        // Swift has no atomic file replace function.
        if await fileExists(path: path) {
            try await deleteFile(path: path)
        }
        try await moveFile(atPath: tmpPath, toPath: path)
    }
    
    let url: URL
    let nav: NavigationController?
    @Published
    var state: SessionState = .startup
    @Published
    var error: String?
    private var pages: [String: MaggiePage] = [:]
    private var stack: [String] = []
    private var writeCacheAfter: Date = .distantPast
    
    init(
        url: URL,
        _ nav: NavigationController?,
        startTasks: Bool = true
    ) {
        precondition(url.scheme == "http" || url.scheme == "https")
        self.url = url
        self.nav = nav
        if startTasks {
            Task(priority: .high) {
                await self.startupTask()
            }
        }
    }
    
    private func updateNav() {
        print("updateNav \(self.stack)")
        if self.stack.isEmpty {
            self.stack = ["/"]
            print("updateNav \(self.stack)")
        }
        let entries = self.stack.map({key -> (String, MaggiePage) in
            let page =
            self.pages[key]
            // TODO: Show loading.
            ?? self.pages["/maggie-page-not-found"]
            ?? .NavPage(MaggieNavPage(
                title: "Not Found",
                widget: .Expand(MaggieExpand(
                    .Text(MaggieText("Page not found."))
                ))
            ))
            return (key, page)
        })
        self.nav?.setStackPages(self, entries)
    }
    
    func pop() {
        if self.stack.count > 1 {
            let key = self.stack.removeLast()
            print("pop '\(key)'")
            self.updateNav()
        } else {
            print("WARN: tried to pop root page")
        }
    }
    
    func push(pageKey: String) {
        print("push '\(pageKey)'")
        self.stack.append(pageKey)
        self.updateNav()
    }
    
    func scheduleWriteData() {
        let now = Date()
        if now < self.writeCacheAfter {
            return
        }
        self.writeCacheAfter = now + 10.0 /* seconds */
    }
    
    @MainActor
    func cacheWriterTask() async {
        print("cacheWriterTask \(MaggieSession.cacheFilePath())")
        while !Task.isCancelled {
            if self.writeCacheAfter != .distantPast && self.writeCacheAfter < Date() {
                do {
                    self.writeCacheAfter = .distantPast
                    try await MaggieSession.writeCacheFile(
                        pages: self.pages,
                        stack: self.stack
                    )
                } catch {
                    print("ERROR cacheWriterTask: \(error)")
                    self.writeCacheAfter = Date()
                    await sleep(ms: 60_000)
                }
            } else {
                await sleep(ms: 1_000)
            }
        }
        print("cacheWriterTask cancelled")
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
        self.updateNav()
        self.scheduleWriteData()
        return true
    }
    
    @MainActor
    func connectOnce() async throws {
        print("connectOnce")
        let config = URLSessionConfiguration.default
        config.urlCache = nil
        config.timeoutIntervalForRequest = 60.0 /* seconds to wait for next chunk */
        config.timeoutIntervalForResource = 60 * 60.0 /* seconds, max connection duration */
        // When config.waitsForConnectivity=true, it waits a long time between connect attempts.
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        let urlSession = URLSession(configuration: config)
        defer {
            urlSession.invalidateAndCancel()
        }
        // URLSession.bytes does not call the URLSessionTaskDelegate on error.
        // So we cannot use a delegate to suppress network error log spam.
        // Probably the only way to do it is to re-implement bytes() using AsyncStream:
        // https://developer.apple.com/documentation/swift/asyncstream
        // If we're going to spend that code, then let's make it good.
        // Let's make an URLSession extension with an asyncEventStream() method that returns
        // whole Server-Sent Events.
        let (asyncBytes, response) = try await urlSession.bytes(from: self.url)
        let httpResponse = response as! HTTPURLResponse
        if httpResponse.statusCode != 200 {
            self.state = .serverError
            if httpResponse.contentTypeBase() == "text/plain" {
               let string = try await asyncBytes.lines.reduce(into: "", {result, item in result += item})
                print("ERROR: connect \(self.url) server error: \(httpResponse.statusCode) \(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)) \"\(string)\"")
            } else {
                print("ERROR: connect \(self.url) server error: \(httpResponse.statusCode) \(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)), len=\(response.expectedContentLength) \(httpResponse.mimeType ?? "")")
            }
            return
        }
        if httpResponse.contentTypeBase() != "text/event-stream" {
            self.state = .serverError
            print("ERROR: connect \(self.url) server sent unexpected content-type: \" \(httpResponse.mimeType ?? "")\"")
            return
        }
        self.state = .connected
        defer { self.state = .connectError }
        print("reading lines")
        for try await line in asyncBytes.lines {
            // https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events
            print("line: '\(line)'")
            let parts = line.split(separator: ":", maxSplits: 1)
            if parts.count != 2 || parts[1].isEmpty {
                throw MaggieError.networkError("server sent line with unexpected format: \"\(line)\"")
            }
            if parts[0] != "data" {
                print("ignoring non-data line from server: \"\(line)\"")
                continue
            }
            let _ = self.applyUpdate(parts[1].data(using: .utf8)!)
        }
        print("disconnected")
    }

    @MainActor
    func connectTask() async {
        print("connectTask \(self.url)")
        while !Task.isCancelled {
            do {
                try await self.connectOnce()
            } catch let error as NSError
                        where error.code == -1004 /* Could not connect to the server */ {
                self.state = .connectError
            } catch {
                // TODO: Show error to user on startup.
                self.state = .connectError
                print("ERROR connectTask: \(error)")
            }
            await sleep(ms: 5_000)
        }
        print("connectTask cancelled")
    }

    @MainActor
    func startupTask() async -> () {
        print("startupTask starting")
        do {
            let itemMap: Dictionary<String,JsonItem> = try await decodeBundleJsonFile("default.json")
            for (key, item) in itemMap {
                do {
                    self.pages[key] = try MaggiePage(item, self)
                } catch {
                    preconditionFailure("error loading default.json key '\(key)': \(error)")
                }
            }
        } catch {
            preconditionFailure("error loading default.json: \(error)")
        }
        if let contents = await MaggieSession.readCacheFile() {
            for (key, item) in contents.pages ?? [:] {
                do {
                    self.pages[key] = try MaggiePage(item, self)
                } catch {
                    print("ERROR: error loading cached key '\(key)': \(error)")
                }
            }
            self.stack = contents.stack ?? ["/"]
        }
        self.updateNav()
        Task(priority: .medium) {
            await self.connectTask()
        }
        Task(priority: .medium) {
            await self.cacheWriterTask()
        }
        print("startupTask done")
    }
        
    @MainActor
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
        //urlRequest.httpBody = try! encodeJson(jsonRequest)
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
                print("rpc \(path) server error: \(httpResponse.statusCode) \(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)) \"\(string)\"")
            } else {
            print("rpc \(path) server error: \(httpResponse.statusCode) \(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)), len=\(data.count) \(httpResponse.mimeType ?? "")")
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
    
    @MainActor
    func doActionsAsync(_ actions: [MaggieAction]) async {
        loop: for action in actions {
            switch action {
            case let .CopyToClipboard(string):
                print("CopyToClipboard(\(string))")
                UIPasteboard.general.string = string
            case let .LaunchUrl(url):
                print("LaunchUrl(\(url))")
                // TODO
                print("unimplemented")
            case .Logout:
                print("Logout")
                // TODO
                print("unimplemented")
            case .Nothing:
                print("Nothing")
            case .Pop:
                print("Pop")
                self.pop()
            case let .Push(key):
                print("Push(\(key))")
                self.push(pageKey: key)
            case let .Rpc(path):
                print("Rpc(\(path))")
                let result = await self.rpc(path: path)
                if !result {
                    break loop
                }
            }
        }
    }
    
    func doActions(_ actions: [MaggieAction]) {
        Task() {
            await self.doActionsAsync(actions)
        }
    }

    static func preview() -> MaggieSession {
        let session = MaggieSession(url: URL(string: "http://localhost:8000")!, nil, startTasks: false)
        session.state = .connectError
        return session
    }
    
    static func preview_connected() -> MaggieSession {
        let session = MaggieSession(url: URL(string: "http://localhost:8000")!, nil, startTasks: false)
        session.state = .connected
        return session
    }
}
