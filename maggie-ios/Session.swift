import Foundation
import SwiftUI

enum SessionState {
    case Connecting, ServerError(String), Connected, Sending
}

struct Err: Error {}

//struct Page: View {
//    var body: some View {
//        get {
//            return AnyView(Text("Connected"))
//        }
//    }
//}
//
//enum Page {
//    case Plain(PlainPage),
//}
//func toPage(any: Any) -> Page {
//
//}

class MaggieSession: ObservableObject {
    let url: String
    var cookie: String?
    @Published
    var state = SessionState.Connecting
    @Published
    var panes: [String: MaggiePane] = [:]
    @Published
    var stack: [String] = []
    
    init(url: String) {
        self.url = url
        Task(priority: .high) {
            await self.startupTask()
        }
    }
    
    @MainActor
    func startupTask() async -> () {
        print("startupTask: loading default panes")
        let defaultJson: Dictionary<String,JsonWidget> = await decodeBundleJsonFile("default.json")
        for (key, jsonWidget) in defaultJson {
            do {
                self.panes[key] = try jsonWidget.toStackItem()
            } catch {
                // TODO: Remove all `fatalError` calls because they don't
                //       actually stop the process like Apple's shit docs say. :(
                fatalError("error loading default key \(key): \(error)")
            }
        }
        print("startupTask: loading initial panes")
        let initialJson: Dictionary<String,JsonWidget> = await decodeBundleJsonFile("initial.json")
        for (key, jsonWidget) in initialJson {
            do {
                self.panes[key] = try jsonWidget.toStackItem()
            } catch {
                fatalError("error loading initial key \(key): \(error)")
            }
        }
        Task(priority: .medium) {
            await self.connectTask()
        }
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
    
    func connectTask() async {
        while !Task.isCancelled {
            do {
                try await self.connectOnce()
            } catch {
                print("ERROR: MaggieSession.connectTask: \(error)")
            }
            await sleep(ms:1000)
        }
    }
    
    @MainActor
    func connectOnce() async throws {
        print("connectTask: starting, url=\(self.url)")
        while true {
            try await Task.sleep(nanoseconds:2_000_000_000)
            print("connectTask: connecting")
            self.state = .Connecting
            try await Task.sleep(nanoseconds:2_000_000_000)
            print("connectTask: error")
            self.state = .ServerError("err1")
            //            print("connectTask: state=\(self.state)")
            //            try Task.checkCancellation()
            //            let url = URL(string: "http://localhost:8000/health")!
            //            let task = URLSession.shared.dataTask(with: url) { data, response, error in
            //                if let error = error {
            //                    print("transport error: \(error)")
            //                    return
            //                }
            //                guard let httpResponse = response as? HTTPURLResponse,
            //                      (200...299).contains(httpResponse.statusCode) else {
            //                          print("server error: \(response!)")
            //                          return
            //                      }
            //                if let mimeType = httpResponse.mimeType, mimeType.starts(with: "text/plain"),
            //                   let data = data,
            //                   let string = String(data: data, encoding: .utf8) {
            //                    print("response: \(httpResponse) \"\(string)\"")
            //                }
            //            }
            //            task.resume()
            //            print("sleeping")
            //            /// The docs say this is function is async, but the compiler warns
            //            /// "no 'async' operations occur within 'await' expression".
            //            /// `static func sleep(_ duration: UInt64) async`
            //            /// https://developer.apple.com/documentation/swift/task/3814836-sleep
            //            try await Task.sleep(nanoseconds:2_000_000_000)
        }
    }
    
    static func preview() -> MaggieSession {
        MaggieSession(url: "http://localhost:8000")
    }
}
