import Foundation
import OSLog
import UIKit

class PageStack {
    static let logger = Logger(subsystem: "Applin", category: "PageStack")

    public class Token {
        fileprivate let instant: LamportInstant

        fileprivate init(_ instant: LamportInstant) {
            self.instant = instant
        }
    }

    class Entry {
        let pageKey: String
        var updated: LamportInstant

        init(pageKey: String, updated: LamportInstant) {
            self.pageKey = pageKey
            self.updated = updated
        }
    }

    class State {
        static let logger = Logger(subsystem: "Applin", category: "State")
        private let clock: LamportClock
        private let config: ApplinConfig
        private var specs: [String: PageSpec]
        private var stack: [Entry]
        private var dirty = true

        init(_ clock: LamportClock, _ config: ApplinConfig, pageKeys: [String]) {
            self.config = config
            self.clock = clock
            self.specs = pageKeys.map({ key in (key, config.applinPageNotLoadedPage(config, key)) }).toDictionary()
            self.stack = pageKeys.map({ key in Entry(pageKey: key, updated: clock.now()) })
        }

        func getEntry(pageKey: String) -> Entry? {
            for entry in self.stack {
                if entry.pageKey == pageKey {
                    return entry
                }
            }
            return nil
        }

        func hasSpec(pageKey: String) -> Bool {
            self.config.staticPages[pageKey] != nil || self.specs[pageKey] != nil
        }

        func getSpec(pageKey: String) -> PageSpec {
            self.config.staticPages[pageKey]?(self.config, pageKey) ??
                    self.specs[pageKey] ??
                    self.config.pageNotFoundPage(self.config, pageKey)
        }

        func tryReplaceAll(pageKey: String) -> Bool {
            if !self.hasSpec(pageKey: pageKey) {
                return false
            }
            var updated: LamportInstant?
            for entry in self.stack {
                if entry.pageKey == pageKey {
                    updated = entry.updated
                } else {
                    self.specs.removeValue(forKey: entry.pageKey)
                }
            }
            self.stack.removeAll()
            self.stack.append(Entry(pageKey: pageKey, updated: updated ?? self.clock.now()))
            self.dirty = true
            Self.logger.info("stack is \(self.stack.map({ entry in String(describing: entry.pageKey) }))")
            return true
        }

        func pop() throws {
            if self.stack.count < 2 {
                throw ApplinError.appError("The app tried to pop the last page.")
            }
            let entry = self.stack.popLast()!
            self.specs.removeValue(forKey: entry.pageKey)
            self.dirty = true
            Self.logger.info("stack is \(self.stack.map({ entry in String(describing: entry.pageKey) }))")
        }

        func tryPush(pageKey: String) throws -> Bool {
            if self.stack.contains(where: { entry in entry.pageKey == pageKey }) {
                throw ApplinError.appError("App tried to show a page that is already shown.  Navigate back to it.")
            }
            if !self.hasSpec(pageKey: pageKey) {
                return false
            }
            self.stack.append(Entry(pageKey: pageKey, updated: self.clock.now()))
            self.dirty = true
            Self.logger.info("stack is \(self.stack.map({ entry in String(describing: entry.pageKey) }))")
            return true
        }

        func trySet(pageKey: String, _ token: Token, _ spec: PageSpec) -> Bool {
            assert(self.config.staticPages[pageKey] == nil)
            if let entry = self.getEntry(pageKey: pageKey) {
                if token.instant < entry.updated {
                    return false
                }
                entry.updated = self.clock.now()
            }
            self.specs[pageKey] = spec
            self.dirty = true
            return true
        }

        func trySet(pageKey: String, _ spec: PageSpec) -> Bool {
            if self.getEntry(pageKey: pageKey) != nil {
                return false
            }
            self.specs[pageKey] = spec
            self.dirty = true
            return true
        }

        func stackPageKeys() -> [String] {
            self.stack.map({ entry in entry.pageKey })
        }

        func stackSpecs() -> [(String, PageSpec)] {
            self.stack.map({ entry -> (String, PageSpec) in (entry.pageKey, self.getSpec(pageKey: entry.pageKey)) })
        }

        func stackSpecsForUpdate() -> [(String, PageSpec)]? {
            if self.dirty {
                self.dirty = false
                return self.stackSpecs()
            } else {
                return nil
            }
        }

        func token() -> Token {
            Token(self.clock.now())
        }
    }

    class StateMutex {
        private let lock = ApplinLock()
        private let state: State
        weak var weakNav: NavigationController?
        weak var weakPageStack: PageStack?
        weak var weakVarSet: VarSet?

        init(state: State, _ nav: NavigationController?, _ varSet: VarSet?) {
            self.state = state
            self.weakNav = nav
            self.weakVarSet = varSet
        }

        func token() -> Token {
            self.state.token()
        }

        func lockReadOnly<R>(_ f: (State) -> R) -> R {
            self.lock.lock({ f(self.state) })
        }

        func lockAsyncAndUpdate<R>(_ f: (State) -> R) async -> R {
            try! await self.lockAsyncThrowsAndUpdate(f)
        }

        func lockAsyncThrowsAndUpdate<R>(_ f: (State) throws -> R) async throws -> R {
            let result = try await self.lock.lockAsyncThrows({ try f(self.state) })
            if let nav = self.weakNav, let pageStack = self.weakPageStack, let varSet = self.weakVarSet, let stackSpecs = self.state.stackSpecsForUpdate() {
                await nav.update(pageStack, varSet, newPages: stackSpecs)
            }
            return result
        }
    }

    private var lock = ApplinLock()
    private let config: ApplinConfig
    private let mutex: StateMutex
    weak var weakCache: ResponseCache?
    weak var weakNav: NavigationController?
    weak var weakServerCaller: ServerCaller?
    weak var weakVarSet: VarSet?

    init(_ cache: ResponseCache?,
         _ clock: LamportClock,
         _ config: ApplinConfig,
         _ nav: NavigationController?,
         _ varSet: VarSet?,
         pageKeys: [String]
    ) {
        self.config = config
        self.mutex = StateMutex(state: State(clock, config, pageKeys: pageKeys), nav, varSet)
        self.mutex.weakPageStack = self
        self.weakCache = cache
        self.weakNav = nav
        self.weakVarSet = varSet
    }

    func doChoosePhotoAction(path: String) async throws {
        guard let nav = self.weakNav else {
            return
        }
        switch await PhotoPicker.pick(nav) {
        case nil:
            break
        case let .failure(e):
            throw ApplinError.appError("choosePhoto(path=\(path)) error: \(e)")
        case let .success(data):
            Self.logger.info("choosePhoto uploading \(data.count) bytes")
            let uploadBody = UploadBody(data, contentType: "image/jpeg")
            return try await self.withWorking({
                try await self.weakServerCaller?.upload(path: path, uploadBody: uploadBody)
            })
        }
    }

    func doPollAction(pageKey: String) async throws {
        if self.config.staticPages[pageKey] != nil {
            // Show first page on startup.
            await self.mutex.lockAsyncAndUpdate({ state in })
            return
        }
        guard let cache = self.weakCache, let serverCaller = self.weakServerCaller else {
            return
        }
        let varNamesAndValues = self.varNamesAndValues(pageKey: pageKey)
        try await self.withWorking {
            let token = self.mutex.token()
            let optUpdate = try await serverCaller.call(path: pageKey, varNamesAndValues: varNamesAndValues)
            guard let update = optUpdate else {
                throw ApplinError.serverError("server returned empty result for page '\(pageKey)")
            }
            let updated = await self.mutex.lockAsyncAndUpdate({ state in
                state.trySet(pageKey: pageKey, token, update.spec)
            })
            if updated, let responseInfo = update.responseInfo {
                cache.add(responseInfo, update.data)
            }
        }
    }

    func doPushAction(pageKey: String) async throws {
        let pushed = try await self.mutex.lockAsyncThrowsAndUpdate({ state in try state.tryPush(pageKey: pageKey) })
        if pushed {
            return
        }
        guard let cache = self.weakCache, let serverCaller = self.weakServerCaller else {
            return
        }
        let varNamesAndValues = self.varNamesAndValues(pageKey: pageKey)
        try await self.withWorking {
            if let spec = await cache.getSpec(pageKey: pageKey) {
                let _ = await self.mutex.lockAsyncAndUpdate({ state in state.trySet(pageKey: pageKey, spec) })
                let pushed = try await self.mutex.lockAsyncThrowsAndUpdate({ state in try state.tryPush(pageKey: pageKey) })
                if pushed {
                    return
                }
            }
            let token = self.mutex.token()
            let optUpdate = try await serverCaller.call(path: pageKey, varNamesAndValues: varNamesAndValues)
            guard let update = optUpdate else {
                throw ApplinError.serverError("server returned empty result for page '\(pageKey)")
            }
            try await self.mutex.lockAsyncThrowsAndUpdate({ state in
                let _ = state.trySet(pageKey: pageKey, token, update.spec)
                let _ = try state.tryPush(pageKey: pageKey)
            })
            if let responseInfo = update.responseInfo {
                cache.add(responseInfo, update.data)
            }
        }
    }

    func doReplaceAllAction(pageKey: String) async throws {
        let success = await self.mutex.lockAsyncAndUpdate({ state in state.tryReplaceAll(pageKey: pageKey) })
        if success {
            return
        }
        guard let cache = self.weakCache, let serverCaller = self.weakServerCaller else {
            return
        }
        let varNamesAndValues = self.varNamesAndValues(pageKey: pageKey)
        try await self.withWorking {
            if let spec = await cache.getSpec(pageKey: pageKey) {
                let _ = await self.mutex.lockAsyncAndUpdate({ state in state.trySet(pageKey: pageKey, spec) })
                let success = await self.mutex.lockAsyncAndUpdate({ state in state.tryReplaceAll(pageKey: pageKey) })
                if success {
                    return
                }
            }
            let token = self.mutex.token()
            let optUpdate = try await serverCaller.call(path: pageKey, varNamesAndValues: varNamesAndValues)
            guard let update = optUpdate else {
                throw ApplinError.serverError("server returned empty result for page '\(pageKey)")
            }
            let success = await self.mutex.lockAsyncAndUpdate({ state in
                let success = state.trySet(pageKey: pageKey, token, update.spec)
                if !success {
                    return false
                }
                return state.tryReplaceAll(pageKey: pageKey)
            })
            if success {
                if let responseInfo = update.responseInfo {
                    cache.add(responseInfo, update.data)
                }
            } else {
                throw ApplinError.appError("error replacing all pages with: \(String(describing: pageKey))")
            }
        }
    }

    func doRpcAction(pageKey: String, path: String) async throws {
        guard let serverCaller = self.weakServerCaller else {
            return
        }
        let varNamesAndValues = self.varNamesAndValues(pageKey: pageKey)
        try await self.withWorking {
            let _ = try await serverCaller.call(path: path, varNamesAndValues: varNamesAndValues)
        }
    }

    func doActions(pageKey: String, _ actions: [ActionSpec]) async -> Bool {
        await self.lock.lockAsync({
            do {
                for action in actions {
                    Self.logger.info("action \(action.description)")
                    switch action {
                    case let .choosePhoto(path):
                        try await self.doChoosePhotoAction(path: path);
                    case let .copyToClipboard(string):
                        Self.logger.info("action copyToClipboard(\(string))")
                        UIPasteboard.general.string = string
                    case let .launchUrl(url):
                        // TODO: Implement launch-url action
                        Self.logger.info("action not implemented")
                    case .logout:
                        // TODO: Implement Logout
                        Self.logger.info("action not implemented")
                    case .nothing:
                        break
                    case .poll:
                        try await self.doPollAction(pageKey: pageKey)
                    case .pop:
                        try await self.mutex.lockAsyncThrowsAndUpdate({ state in try state.pop() })
                    case let .push(key), let .pushPreloaded(key):
                        try await self.doPushAction(pageKey: key)
                    case let .replaceAll(key):
                        try await self.doReplaceAllAction(pageKey: key)
                    case let .rpc(path):
                        try await self.doRpcAction(pageKey: pageKey, path: path)
                    case let .takePhoto(path):
                        // TODO: Implement take-photo.
                        Self.logger.info("action not implemented")
                    }
                }
                return true
            } catch let e {
                let errorPageKey: String;
                if let e = e as? ApplinError {
                    Self.logger.error("\(e)")
                    self.weakVarSet?.setInteractiveError(e)
                    switch e {
                    case .appError:
                        errorPageKey = StaticPageKeys.APPLIN_CLIENT_ERROR
                    case .networkError:
                        errorPageKey = StaticPageKeys.APPLIN_NETWORK_ERROR
                    case .serverError:
                        errorPageKey = StaticPageKeys.APPLIN_SERVER_ERROR
                    case .userError:
                        errorPageKey = StaticPageKeys.APPLIN_USER_ERROR
                    }
                } else {
                    Self.logger.error("unexpected error: \(e)")
                    self.weakVarSet?.setInteractiveError(.appError("\(e)"))
                    errorPageKey = StaticPageKeys.APPLIN_CLIENT_ERROR
                }
                // TODO: Use static error page specs and eliminate the try.
                try! await self.doPushAction(pageKey: errorPageKey)
                return false
            }
        })
    }

    func stackPageKeys() -> [String] {
        self.mutex.lockReadOnly({ state in state.stackPageKeys() })
    }

    func tryUpdate(pageKey: String, _ token: Token, spec: PageSpec) async -> Bool {
        await self.lock.lockAsync({
            await self.mutex.lockAsyncAndUpdate({ state in
                state.trySet(pageKey: pageKey, token, spec)
            })
        })
    }

    func preloadPageKeys() -> [String] {
        self.mutex.lockReadOnly({ state in
            var unvisited: [String] = state.stackPageKeys()
            var preload = Set<String>()
            while let key = unvisited.popLast() {
                let (inserted, _) = preload.insert(key)
                if inserted {
                    let spec = state.getSpec(pageKey: key)
                    spec.visitActions({ action in
                        if case let .pushPreloaded(newKey) = action {
                            unvisited.append(newKey)
                        }
                    })
                }
            }
            return Array(preload)
        })
    }

    func token() -> Token {
        self.mutex.token()
    }

    func varNamesAndValues(pageKey: String) -> [(String, Var)] {
        guard let varSet = self.weakVarSet else {
            return []
        }
        let namesAndDefaultValues: [(String, Var)] = self.mutex.lockReadOnly({ state in
            state.getSpec(pageKey: pageKey).vars()
        })
        let namesAndValues: [(String, Var)] = namesAndDefaultValues.compactMap({ (name, defaultValue) in
            guard let value = varSet.get(name) else {
                return (name, defaultValue)
            }
            switch (defaultValue, value) {
            case (.bool, .bool): break
            case (.string, .string): break
            default:
                Self.logger.error("expected page '\(pageKey)' var '\(name)' to be same type as \(String(describing: defaultValue)) but found \(String(describing: value)), ignoring var")
                return nil
            }
            return (name, value)
        })
        return namesAndValues
    }

    private func withWorking<T>(_ f: () async throws -> T) async throws -> T {
        await self.weakNav?.setWorking("Working")
        let stopwatch = Stopwatch()
        do {
            let result = try await f()
            await stopwatch.waitUntil(seconds: 0.5)
            await self.weakNav?.setWorking(nil)
            return result
        } catch let e {
            await stopwatch.waitUntil(seconds: 0.5)
            await self.weakNav?.setWorking(nil)
            throw e
        }
    }
}
