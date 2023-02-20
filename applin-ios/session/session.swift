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
    public static func loading() -> ApplinState {
        var state = ApplinState()
        // TODO: Show a spinner.
        state.pages = ["/": .plainPage(PlainPageSpec(title: "Loading", Spec(.text(TextSpec("Loading")))))]
        state.stack = ["/"]
        return state
    }

    // TODO: Clean up unused vars.
    var working: String?
    var paused: Bool = true
    var connectionError: ApplinError?
    var interactiveError: ApplinError?
    var pages: [String: PageSpec] = [:]
    var pauseUpdates: Bool = true
    var stack: [String] = ["/"]
    var vars: [String: Var] = [:]
    var navUpdateId: UInt64 = 0
    var serverUpdateId: UInt64 = 0
    var fileUpdateId: UInt64 = 0

    func getStack() -> [String] {
        self.stack.isEmpty ? ["/"] : self.stack
    }

    func getStackPages() -> [(String, PageSpec)] {
        self.getStack().map({ key -> (String, PageSpec) in
            let page = self.pages[key]
                    ?? self.pages[APPLIN_PAGE_NOT_FOUND_PAGE_KEY]
                    ?? NavPageSpec(pageKey: key, title: "Not Found", ColumnSpec([TextSpec("Page not found.")])).toSpec()
            return (key, page)
        })
    }

    func getConnectionMode() -> ConnectionMode {
        self.getStack().compactMap({ key -> ConnectionMode? in self.pages[key]?.connectionMode }).min() ?? .disconnect
    }

    func errorDetails() -> String {
        switch self.interactiveError ?? self.connectionError {
        case nil:
            return "Error details not found."
        case let .appError(e), let .networkError(e), let .serverError(e), let .userError(e):
            return e
        }
    }

    mutating func pop() {
        if self.stack.isEmpty {
            let pageKey = self.stack.removeLast()
            print("pop '\(pageKey)'")
        }
        if self.stack.isEmpty {
            self.stack = ["/"]
        }
        print("stack=\(self.stack)")
    }

    mutating func push(pageKey: String) {
        print("push '\(pageKey)'")
        self.stack.append(pageKey)
        print("stack=\(self.stack)")
    }

    func pageVars(pageKey: String) -> [String: Var]? {
        if let pageVars = self.pages[pageKey]?.vars() {
            return Dictionary(uniqueKeysWithValues: pageVars)
        } else {
            return nil
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

    mutating func setVar(_ name: String, _ optValue: Var?) {
        guard let value = optValue else {
            self.vars.removeValue(forKey: name)
            print("setVar \(name)=nil")
            return
        }
        let oldValue = self.vars.updateValue(value, forKey: name)
        switch (oldValue, value) {
        case let (.boolean, .boolean(value)):
            print("setVar \(name)=\(value)")
        case let (.string, .string(value)):
            print("setVar \(name)=\(value)")
        default:
            print("setVar \(name)=\(value)")
            print("WARN setVar changed var type: \(name): \(String(describing: oldValue)) -> \(String(describing: optValue))")
        }
    }

    mutating func setBoolVar(_ name: String, _ optValue: Bool?) {
        if let value = optValue {
            self.setVar(name, .boolean(value))
        } else {
            self.setVar(name, nil)
        }
    }

    mutating func setStringVar(_ name: String, _ optValue: String?) {
        if let value = optValue {
            self.setVar(name, .string(value))
        } else {
            self.setVar(name, nil)
        }
    }
}

// TODO: Prevent racing between applyUpdate(), rpc(), and doActionsAsync().

class ApplinSession: ObservableObject {
    class Mutex {
        class Guard {
            private let mutex: Mutex
            public var state: ApplinState

            init(_ mutex: Mutex) {
                self.mutex = mutex
                self.mutex.nsLock.lock()
                self.state = self.mutex.value
            }

            deinit {
                self.state.fileUpdateId += 1
                self.mutex.value = self.state
                self.mutex.session?.updateDeps(self.mutex.value)
                self.mutex.nsLock.unlock()
            }
        }

        class ReadOnlyGuard {
            private let mutex: Mutex
            public let readOnlyState: ApplinState

            init(_ mutex: Mutex) {
                self.mutex = mutex
                self.mutex.nsLock.lock()
                self.readOnlyState = self.mutex.value
            }

            deinit {
                self.mutex.nsLock.unlock()
            }
        }

        let nsLock = NSLock()
        weak var session: ApplinSession?
        var value: ApplinState

        init(value: ApplinState) {
            self.value = value
        }

        public func lock() -> Guard {
            Guard(self)
        }

        public func readOnlyLock() -> ReadOnlyGuard {
            ReadOnlyGuard(self)
        }
    }

    private class PauseUpdateGuard {
        weak var session: ApplinSession?

        init(_ session: ApplinSession?) {
            self.session = session
        }

        deinit {
            if let session = self.session {
                session.mutex.lock().state.pauseUpdates = false
                print("unpause updates")
            }
        }
    }

    let config: ApplinConfig
    let mutex: Mutex
    weak var nav: NavigationController?
    weak var poller: Poller?
    weak var rpcCaller: RpcCaller?
    weak var stateFileWriter: StateFileWriter?
    weak var streamer: Streamer?

    init(_ config: ApplinConfig, _ initialState: ApplinState, _ nav: NavigationController?) {
        self.config = config
        self.nav = nav
        self.mutex = Mutex(value: initialState)
        self.mutex.session = self
    }

    func setDeps(_ poller: Poller, _ rpcCaller: RpcCaller, _ stateFileWriter: StateFileWriter, _ streamer: Streamer) {
        self.poller = poller
        self.rpcCaller = rpcCaller
        self.stateFileWriter = stateFileWriter
        self.streamer = streamer
    }

    private func pauseUpdates() -> PauseUpdateGuard {
        let _ = {
            let mutexGuard = self.mutex.lock()
            mutexGuard.state.pauseUpdates = true
            print("pauseUpdates \(mutexGuard.state.pauseUpdates)")
        }
        print("pause updates")
        return PauseUpdateGuard(self)
    }

    func updateDeps(_ value: ApplinState) {
        if value.pauseUpdates {
            print("skipped update")
            return
        }
        print("update")
        self.nav?.update(self, value)
        self.poller?.update(value)
        self.stateFileWriter?.update(value)
        self.streamer?.update(value)
    }

    func applyUpdate(_ data: Data) throws {
        let update: Update
        do {
            update = try decodeJson(data)
            print("update \(update)")
        } catch {
            throw ApplinError.serverError("error decoding update: \(error)")
        }
        var optPageError: ApplinError?
        let mutexGuard = self.mutex.lock()
        // TODO: Set mutexGuard.state.serverUpdateId and don't go backwards.
        for (key, optItem) in update.pages ?? [:] {
            if let item = optItem {
                do {
                    let pageSpec = try PageSpec(self.config, pageKey: key, item)
                    mutexGuard.state.pages[key] = pageSpec
                    print("updated key \(key) \(pageSpec)")
                } catch {
                    mutexGuard.state.pages[key] = NavPageSpec(
                            pageKey: key,
                            title: "Error",
                            // TODO: Show a better error page.
                            TextSpec("Error loading page. Please update the app.")
                    ).toSpec()
                    optPageError = ApplinError.appError("error processing updated key '\(key)': \(error)")
                }
            } else {
                mutexGuard.state.pages.removeValue(forKey: key)
                print("removed key \(key)")
            }
        }
        if let newStack = update.stack {
            mutexGuard.state.stack = newStack
        }
        if let vars = update.vars {
            for (name, jsonValue) in vars {
                switch jsonValue {
                case .null:
                    mutexGuard.state.setVar(name, nil)
                case let .boolean(value):
                    mutexGuard.state.setVar(name, .boolean(value))
                case let .string(value):
                    mutexGuard.state.setVar(name, .string(value))
                default:
                    optPageError = ApplinError.appError("unknown var from server \(name)=\(jsonValue)")
                }
            }
        }
        if let pageError = optPageError {
            throw pageError
        }
    }

    func doActionsAsync(pageKey: String, _ actions: [ActionSpec]) async -> Bool {
        let _pauseUpdatesGuard = self.pauseUpdates()
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
            case .poll:
                print("poll")
                let success = await self.rpcCaller?.interactiveRpc(optPageKey: nil, path: "/", method: "GET")
                if success != true {
                    return false
                }
            case .pop:
                print("pop")
                self.mutex.lock().state.pop()
            case let .push(key):
                print("push(\(key))")
                self.mutex.lock().state.push(pageKey: key)
            case let .rpc(path):
                print("rpc(\(path))")
                let success = await self.rpcCaller?.interactiveRpc(optPageKey: pageKey, path: path, method: "POST")
                if success != true {
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
