import Foundation
import UIKit

struct Update: Codable {
    var pages: [String: JsonItem?]?
    var stack: [String]?
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
    var paused: Bool = false
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

    mutating func pop() {
        if !self.stack.isEmpty {
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
        guard let pageVars = self.pages[pageKey]?.vars() else {
            return nil
        }
        return Dictionary(uniqueKeysWithValues: pageVars.compactMap({ (name, defaultValue) -> (String, Var)? in
            guard let value = self.vars[name] else {
                return nil
            }
            switch (defaultValue, value) {
            case (.boolean, .boolean):
                return (name, value)
            case (.string, .string):
                return (name, value)
            default:
                print("WARN expected page '\(pageKey)' var '\(name)' to be same type as \(String(describing: defaultValue)) but found \(String(describing: value)), not sending var in RPC")
                return nil
            }
        }))
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
    class StateMutex {
        weak var session: ApplinSession?
        let applinMutex: ApplinMutex<ApplinState>

        init(state: ApplinState) {
            self.applinMutex = ApplinMutex(value: state)
        }

        private func update(_ state: inout ApplinState) {
            state.fileUpdateId += 1
            self.session?.updateDeps(state)
        }

        func lock<R>(_ f: (inout ApplinState) -> R) -> R {
            self.applinMutex.lock({ state in
                let result = f(&state)
                self.update(&state)
                return result
            })
        }

        func lockReadOnly<R>(_ f: (ApplinState) -> R) -> R {
            self.applinMutex.lock({ state in f(state) })
        }

        func lockThrows<R>(_ f: (inout ApplinState) throws -> R) throws -> R {
            try self.applinMutex.lockThrows({ state in
                let result = try f(&state)
                self.update(&state)
                return result
            })
        }

        func lockReadOnlyThrows<R>(_ f: (ApplinState) throws -> R) throws -> R {
            try self.applinMutex.lockThrows({ state in try f(state) })
        }

        func lockAsync<R>(_ f: (inout ApplinState) async -> R) async -> R {
            await self.applinMutex.lockAsync({ state in
                let result = await f(&state)
                self.update(&state)
                return result
            })
        }

        func lockAsyncReadOnly<R>(_ f: (ApplinState) async -> R) async -> R {
            await self.applinMutex.lockAsync({ state in await f(state) })
        }

        func lockAsyncThrows<R>(_ f: (inout ApplinState) async throws -> R) async throws -> R {
            try await self.applinMutex.lockAsyncThrows({ state in
                let result = try await f(&state)
                self.update(&state)
                return result
            })
        }

        func lockAsyncThrowsReadOnly<R>(_ f: (ApplinState) async throws -> R) async throws -> R {
            try await self.applinMutex.lockAsyncThrows({ state in try await f(state) })
        }
    }

    let config: ApplinConfig
    let mutex: StateMutex
    private let actionLock = ApplinLock()
    weak var nav: NavigationController?
    weak var poller: Poller?
    weak var rpcCaller: RpcCaller?
    weak var stateFileWriter: StateFileWriter?
    weak var streamer: Streamer?

    init(_ config: ApplinConfig, _ initialState: ApplinState, _ nav: NavigationController?) {
        self.config = config
        self.nav = nav
        self.mutex = StateMutex(state: initialState)
        self.mutex.session = self
    }

    func setDeps(_ poller: Poller, _ rpcCaller: RpcCaller, _ stateFileWriter: StateFileWriter, _ streamer: Streamer) {
        self.poller = poller
        self.rpcCaller = rpcCaller
        self.stateFileWriter = stateFileWriter
        self.streamer = streamer
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
        try self.mutex.lockThrows { state in
            // TODO: Set state.serverUpdateId and don't go backwards.
            for (key, optItem) in update.pages ?? [:] {
                if let item = optItem {
                    do {
                        let pageSpec = try PageSpec(self.config, pageKey: key, item)
                        state.pages[key] = pageSpec
                        print("updated key \(key) \(pageSpec)")
                    } catch {
                        state.pages[key] = NavPageSpec(
                                pageKey: key,
                                title: "Error",
                                connectionMode: .pollSeconds(5),
                                // TODO: Show a better error page.
                                TextSpec("Error loading page. Please update the app.")
                        ).toSpec()
                        optPageError = ApplinError.appError("error processing updated key '\(key)': \(error)")
                    }
                } else {
                    state.pages.removeValue(forKey: key)
                    print("removed key \(key)")
                }
            }
            if let newStack = update.stack {
                state.stack = newStack
            }
            if let vars = update.vars {
                for (name, jsonValue) in vars {
                    switch jsonValue {
                    case .null:
                        state.setVar(name, nil)
                    case let .boolean(value):
                        state.setVar(name, .boolean(value))
                    case let .string(value):
                        state.setVar(name, .string(value))
                    default:
                        optPageError = ApplinError.appError("unknown var from server \(name)=\(jsonValue)")
                    }
                }
            }
            if let pageError = optPageError {
                throw pageError
            }
        }
    }

    func withUpdatesPaused<R>(_ f: () async -> R) async -> R {
        await self.mutex.lockAsync { (state: inout ApplinState) in
            assert(!state.pauseUpdates)
            state.pauseUpdates = true
            print("pauseUpdates = true")
        }
        let result = await f()
        await self.mutex.lockAsync { (state: inout ApplinState) in
            assert(state.pauseUpdates)
            state.pauseUpdates = false
            print("pauseUpdates = false")
        }
        return result
    }

    func doActionsAsync(pageKey: String, _ actions: [ActionSpec]) async -> Bool {
        await self.actionLock.lockAsync {
            await self.withUpdatesPaused {
                for action in actions {
                    switch action {
                    case let .choosePhoto(path):
                        print("choosePhoto(\(path))")
                        if let nav = self.nav {
                            switch await PhotoPicker.pick(nav) {
                            case nil:
                                return false
                            case let .failure(e):
                                print("choosePhoto error: \(e)")
                                await self.mutex.lockAsync { state in
                                    state.interactiveError = .appError("\(e)")
                                    state.stack.append(APPLIN_CLIENT_ERROR_PAGE_KEY)
                                }
                                return false
                            case let .success(data):
                                print("choosePhoto uploading \(data.count) bytes")
                                let success = await self.rpcCaller?.interactiveRpc(
                                        optPageKey: nil,
                                        path: path,
                                        method: "POST",
                                        uploadBody: UploadBody(data, contentType: "image/jpeg")
                                )
                                if success != true {
                                    return false
                                }
                            }
                        }
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
                        self.mutex.lock { (state: inout ApplinState) in
                            state.pop()
                        }
                    case let .push(key):
                        print("push(\(key))")
                        self.mutex.lock { (state: inout ApplinState) in
                            state.push(pageKey: key)
                        }
                    case let .rpc(path):
                        print("rpc(\(path))")
                        let success = await self.rpcCaller?.interactiveRpc(optPageKey: pageKey, path: path, method: "POST")
                        if success != true {
                            return false
                        }
                    case let .takePhoto(path):
                        // TODO: Implement take-photo.
                        print("takePhoto(\(path))")
                    }
                }
                return true
            }
        }
    }

    func doActions(pageKey: String, _ actions: [ActionSpec]) {
        Task {
            await self.doActionsAsync(pageKey: pageKey, actions)
        }
    }
}
