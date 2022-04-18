import Foundation
import SwiftUI

enum SessionState {
    case Connecting, ConnectError, ServerError(String), Connected
}

class MaggieSession: ObservableObject {
    let url: String
    let nav: NavigationController?
    @Published
    var connected = false
    @Published
    var error: String?
    @Published
    var pages: [String: MaggiePage] = [:]
    @Published
    var stack: [String] = []
    
    init(
        url: String,
        _ nav: NavigationController?,
        startTasks: Bool = true
    ) {
        self.url = url
        self.nav = nav
        if startTasks {
            Task(priority: .high) {
                await self.startupTask()
            }
        }
    }
    
    static func pageNotFound() -> MaggiePage {
        return .NavPage(MaggieNavPage(
            title: "Not Found",
            widget: .Center(MaggieCenter(
                .Text(MaggieText("Page not found."))
            )),
            start: .BackButton(MaggieBackButton())
        ))
    }
    
    func getPage(_ key: String) -> MaggiePage {
        let page = self.pages[key]
        ?? self.pages["/maggie-page-not-found"]
        ?? MaggieSession.pageNotFound()
        print("toView \(key)")
        return page
    }
    
    func updateNav() {
        print("updateNav")
        self.nav?.setViews(
            self.stack.map({ key in self.getPage(key)}),
            animated: false
        )
    }
    
    @MainActor
    func startupTask() async -> () {
        print("startupTask starting")
        do {
            let defaultJson: Dictionary<String,JsonItem> = try await decodeBundleJsonFile("default.json")
            for (key, jsonWidget) in defaultJson {
                do {
                    self.pages[key] = try MaggiePage(jsonWidget, self)
                } catch {
                    preconditionFailure("error loading default.json key '\(key)': \(error)")
                }
            }
        } catch {
            preconditionFailure("error loading default.json: \(error)")
        }
        do {
            let initialJson: Dictionary<String,JsonItem> = try await decodeBundleJsonFile("initial.json")
            for (key, jsonWidget) in initialJson {
                do {
                    self.pages[key] = try MaggiePage(jsonWidget, self)
                } catch {
                    preconditionFailure("error loading initial.json key '\(key)': \(error)")
                }
            }
        } catch {
            preconditionFailure("error loading initial.json: \(error)")
        }
        // TODO: Try to read cache file and restore previous stack.
        self.stack = ["/"]
        self.updateNav()
        //Task(priority: .medium) {
        //    await self.connectTask()
        //}
        print("startupTask done")
        //        let cookieFilePath = documentDirPath() + "/cookie"
        //        // The proper way is to open the file and catch file-not-found exception.
        //        // I searched for an hour and found no documentated way to catch such an error. :(
        //        if await fileExists(path: cookieFilePath) {
        //            print("startupTask: reading \(cookieFilePath)")
        //            let data: Data
        //            do {
        //                data = try await readFile(path: cookieFilePath)
        //            } catch {
        //                // TODO: Show a dialog.
        //                fatalError("error reading cookie file \(cookieFilePath): \(error)")
        //            }
        //            switch data.count {
        //            case 0:
        //                break
        //            case 1..512
        //            }
        //        }
        //
        //        let cacheJsonPath = documentDirPath() + "/cache.json"
        //        // The proper way is to open the file and catch file-not-found exception.
        //        // I searched for an hour and found no documentated way to catch such an error. :(
        //        if await fileExists(path: cacheJsonPath) {
        //            print("startupTask: reading \(cacheJsonPath)")
        //            do {
        //                let contents = try await readFile(path: cacheJsonPath)
        //            } catch {
        //                print("startupTask: error reading \(cacheJsonPath): \(error)")
        //                // TODO: Push "data-load-error" page
        //            }
        //        }
        //        print("startupTask: loading data file")
        //        print("startupTask: no data file found, loading initial_data.json from bundle")
        //
        //        while true {
        //            try await Task.sleep(nanoseconds:2_000_000_000)
        //            print("startupTask: connecting")
        //            self.state = .Connecting
        //            try await Task.sleep(nanoseconds:2_000_000_000)
        //            print("startupTask: error")
        //            self.state = .ServerError("err1")
        //            //            print("startupTask: state=\(self.state)")
        //            //            try Task.checkCancellation()
        //            //            let url = URL(string: "http://localhost:8000/health")!
        //            //            let task = URLSession.shared.dataTask(with: url) { data, response, error in
        //            //                if let error = error {
        //            //                    print("transport error: \(error)")
        //            //                    return
        //            //                }
        //            //                guard let httpResponse = response as? HTTPURLResponse,
        //            //                      (200...299).contains(httpResponse.statusCode) else {
        //            //                          print("server error: \(response!)")
        //            //                          return
        //            //                      }
        //            //                if let mimeType = httpResponse.mimeType, mimeType.starts(with: "text/plain"),
        //            //                   let data = data,
        //            //                   let string = String(data: data, encoding: .utf8) {
        //            //                    print("response: \(httpResponse) \"\(string)\"")
        //            //                }
        //            //            }
        //            //            task.resume()
        //            //            print("sleeping")
        //            //            /// The docs say this is function is async, but the compiler warns
        //            //            /// "no 'async' operations occur within 'await' expression".
        //            //            /// `static func sleep(_ duration: UInt64) async`
        //            //            /// https://developer.apple.com/documentation/swift/task/3814836-sleep
        //            //            try await Task.sleep(nanoseconds:2_000_000_000)
        //        }
        //
    }
    
    @MainActor
    func connectTask() async {
        print("connectTask url=\(self.url)")
        while !Task.isCancelled {
            do {
                try await self.connectOnce()
            } catch {
                print("ERROR connectTask: \(error)")
            }
            await sleep(ms:1000)
        }
        print("connectTask cancelled")
    }
    
    @MainActor
    func connectOnce() async throws {
        print("connectOnce")
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60.0 /* seconds */
        config.timeoutIntervalForResource = 60 * 60.0 /* seconds */
        // TODO: Make a class that implements URLSessionDataDelegate to process
        // chunks of the HTTP response body and decode them as Server-Sent Events.
        // https://developer.apple.com/documentation/foundation/urlsessiondatadelegate
        // https://developer.apple.com/documentation/foundation/urlsession/1411597-init
        //        let urlSession = URLSession(configuration: config, delegate: TODO, delegateQueue: OperationQueue.main)
        //        self.state = .Connecting
        //        let task = urlSession.dataTask(with: self.url, completionHandler: {
        //            (data: Data?, response: URLResponse?, error: Error?) -> Void in
        //            if let error = error {
        //                print("transport error: \(error)")
        //                return
        //            }
        //            guard let httpResponse = response as? HTTPURLResponse,
        //                  (200...299).contains(httpResponse.statusCode) else {
        //                      print("server error: \(response!)")
        //                      return
        //                  }
        //            if let mimeType = httpResponse.mimeType, mimeType.starts(with: "text/plain"),
        //               let data = data,
        //               let string = String(data: data, encoding: .utf8) {
        //                print("response: \(httpResponse) \"\(string)\"")
        //            }
        //        })
        //            task.resume()
        //            print("sleeping")
        //            /// The docs say this is function is async, but the compiler warns
        //            /// "no 'async' operations occur within 'await' expression".
        //            /// `static func sleep(_ duration: UInt64) async`
        //            /// https://developer.apple.com/documentation/swift/task/3814836-sleep
        //            try await Task.sleep(nanoseconds:2_000_000_000)
        self.connected = true
        defer { self.connected = false }
        await sleep(ms: 2000)
        throw MaggieError.deserializeError("err1")
    }
    
    static func preview() -> MaggieSession {
        let session = MaggieSession(url: "http://localhost:8000", nil, startTasks: false)
        session.connected = false
        return session
    }
    
    static func preview_connected() -> MaggieSession {
        let session = MaggieSession(url: "http://localhost:8000", nil, startTasks: false)
        session.connected = true
        return session
    }
}
