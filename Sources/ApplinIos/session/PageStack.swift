import Foundation
import OSLog
import UIKit

public class PageStack {
    static let logger = Logger(subsystem: "Applin", category: "PageStack")

    public class Token {
        fileprivate let instant: LamportInstant

        fileprivate init(_ instant: LamportInstant) {
            self.instant = instant
        }
    }

    class Entry {
        let pageKey: String
        var spec: PageSpec
        var updatedInstant: Instant
        var updatedLamportInstant: LamportInstant

        init(pageKey: String, _ spec: PageSpec, _ instant: Instant, _ lamportInstant: LamportInstant) {
            self.pageKey = pageKey
            self.spec = spec
            self.updatedInstant = instant
            self.updatedLamportInstant = lamportInstant
        }
    }

    class State {
        static let logger = Logger(subsystem: "Applin", category: "State")
        private let config: ApplinConfig
        private let lamportClock: LamportClock
        private let wallClock: WallClock
        private var stack: [Entry]
        private var dirty = true

        init(_ config: ApplinConfig, _ lamportClock: LamportClock, _ wallClock: WallClock, pageKeys: [String]) {
            self.config = config
            self.lamportClock = lamportClock
            self.wallClock = wallClock
            let instant = self.wallClock.now()
            let lamportInstant = self.lamportClock.now()
            self.stack = pageKeys.map({ key in
                let spec = config.staticPageSpec(pageKey: key) ?? config.applinPageNotLoadedPage(config, key)
                return Entry(pageKey: key, spec, instant, lamportInstant)
            })
        }

        private func getEntry(pageKey: String) -> Entry? {
            for entry in self.stack {
                if entry.pageKey == pageKey {
                    return entry
                }
            }
            return nil
        }

        func getSpec(pageKey: String) -> PageSpec? {
            self.getEntry(pageKey: pageKey)?.spec
        }

        func replaceAll(pageKey: String, _ spec: PageSpec) {
            let instant = self.wallClock.now()
            let lamportInstant = self.lamportClock.now()
            self.stack = [Entry(pageKey: pageKey, spec, instant, lamportInstant)]
            self.dirty = true
            Self.logger.info("stack is \(self.stack.map({ entry in String(describing: entry.pageKey) }))")
        }

        func pop() throws {
            if self.stack.count < 2 {
                throw ApplinError.appError("The app tried to pop the last page.")
            }
            self.stack.removeLast()
            self.dirty = true
            Self.logger.info("stack is \(self.stack.map({ entry in String(describing: entry.pageKey) }))")
        }

        func push(pageKey: String, _ spec: PageSpec) throws {
            if self.getEntry(pageKey: pageKey) != nil {
                throw ApplinError.appError("App tried to show a page that is already shown.  Navigate back to it.")
            }
            let instant = self.wallClock.now()
            let lamportInstant = self.lamportClock.now()
            self.stack.append(Entry(pageKey: pageKey, spec, instant, lamportInstant))
            self.dirty = true
            Self.logger.info("stack is \(self.stack.map({ entry in String(describing: entry.pageKey) }))")
        }

        func trySet(pageKey: String, _ token: Token, _ spec: PageSpec) -> Bool {
            assert(self.config.staticPages[pageKey] == nil)
            guard let entry = self.getEntry(pageKey: pageKey) else {
                return false
            }
            if token.instant < entry.updatedLamportInstant {
                return false
            }
            entry.spec = spec
            entry.updatedInstant = self.wallClock.now()
            entry.updatedLamportInstant = self.lamportClock.now()
            self.dirty = true
            return true
        }

        func set(pageKey: String, _ spec: PageSpec) {
            guard let entry = self.getEntry(pageKey: pageKey) else {
                Self.logger.warning("set called on missing page: '\(pageKey)'")
                return
            }
            entry.spec = spec
            entry.updatedInstant = self.wallClock.now()
            entry.updatedLamportInstant = self.lamportClock.now()
            self.dirty = true
        }

        func stackPageKeys() -> [String] {
            self.stack.map({ entry in entry.pageKey })
        }

        func stackPages() -> [(String, PageSpec, Instant)] {
            self.stack.map({ entry in (entry.pageKey, entry.spec, entry.updatedInstant) })
        }

        func stackSpecsForUpdate() -> [(String, PageSpec)]? {
            if self.dirty {
                self.dirty = false
                return self.stack.map({ entry -> (String, PageSpec) in (entry.pageKey, entry.spec) })
            } else {
                return nil
            }
        }

        func token() -> Token {
            Token(self.lamportClock.now())
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
            if let nav = self.weakNav,
               let pageStack = self.weakPageStack,
               let varSet = self.weakVarSet,
               let stackSpecs = self.state.stackSpecsForUpdate() {
                await nav.update(pageStack, varSet, newPages: stackSpecs)
            }
            return result
        }
    }

    private var lock = ApplinLock()
    private let config: ApplinConfig
    private let mutex: StateMutex
    weak var weakNav: NavigationController?
    weak var weakServerCaller: ServerCaller?
    weak var weakVarSet: VarSet?

    init(
            _ config: ApplinConfig,
            _ lamportClock: LamportClock,
            _ nav: NavigationController?,
            _ varSet: VarSet?,
            _ wallClock: WallClock,
            pageKeys: [String]
    ) {
        self.config = config
        self.mutex = StateMutex(state: State(config, lamportClock, wallClock, pageKeys: pageKeys), nav, varSet)
        self.mutex.weakPageStack = self
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
        guard let serverCaller = self.weakServerCaller else {
            return
        }
        let varNamesAndValues = self.varNamesAndValues(pageKey: pageKey)
        try await self.withWorking {
            let optUpdate =
                    try await serverCaller.poll(path: pageKey, varNamesAndValues: varNamesAndValues, interactive: true)
            guard let update = optUpdate else {
                throw ApplinError.serverError("server returned empty result for page '\(pageKey)")
            }
            await self.mutex.lockAsyncAndUpdate({ state in
                state.set(pageKey: pageKey, update.spec)
            })
        }
    }

    func doPushAction(pageKey: String) async throws {
        if let spec = self.config.staticPageSpec(pageKey: pageKey) {
            try await self.mutex.lockAsyncThrowsAndUpdate({ state in
                try state.push(pageKey: pageKey, spec)
            })
            return
        }
        guard let serverCaller = self.weakServerCaller else {
            return
        }
        let varNamesAndValues = self.varNamesAndValues(pageKey: pageKey)
        try await self.withWorking {
            let optUpdate =
                    try await serverCaller.poll(path: pageKey, varNamesAndValues: varNamesAndValues, interactive: true)
            guard let update = optUpdate else {
                throw ApplinError.serverError("server returned empty result for page '\(pageKey)")
            }
            try await self.mutex.lockAsyncThrowsAndUpdate({ state in
                try state.push(pageKey: pageKey, update.spec)
            })
        }
    }

    func doReplaceAllAction(pageKey: String) async throws {
        if let spec = self.config.staticPageSpec(pageKey: pageKey) {
            try await self.mutex.lockAsyncThrowsAndUpdate({ state in
                state.replaceAll(pageKey: pageKey, spec)
            })
            return
        }
        guard let serverCaller = self.weakServerCaller else {
            return
        }
        let varNamesAndValues = self.varNamesAndValues(pageKey: pageKey)
        try await self.withWorking {
            let optUpdate =
                    try await serverCaller.poll(path: pageKey, varNamesAndValues: varNamesAndValues, interactive: true)
            guard let update = optUpdate else {
                throw ApplinError.serverError("server returned empty result for page '\(pageKey)")
            }
            await self.mutex.lockAsyncAndUpdate({ state in
                state.replaceAll(pageKey: pageKey, update.spec)
            })
        }
    }

    func doRpcAction(pageKey: String, path: String) async throws {
        guard let serverCaller = self.weakServerCaller else {
            return
        }
        let varNamesAndValues = self.varNamesAndValues(pageKey: pageKey)
        try await self.withWorking {
            let _ = try await serverCaller.call(
                    .POST,
                    path: path,
                    varNamesAndValues: varNamesAndValues,
                    interactive: true
            )
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
                        Self.logger.info("action launchUrl(\(url)")
                        Task { @MainActor in
                            await UIApplication.shared.open(url)
                        }
                    case .logout:
                        // TODO: Delete session cookies.
                        // TODO: Delete state file.
                        // TODO: Stop state file writer.
                        // TODO: Erase session saved state.
                        // TODO: Disconnect streamer.
                        // TODO: Stop poller.
                        // TODO: Interrupt sequence of actions.
                        Self.logger.info("action not implemented")
                    case .nothing:
                        break
                    case .poll:
                        try await self.doPollAction(pageKey: pageKey)
                    case .pop:
                        try await self.mutex.lockAsyncThrowsAndUpdate({ state in
                            try state.pop()
                        })
                    case let .push(key):
                        try await self.doPushAction(pageKey: key)
                    case let .replaceAll(key):
                        try await self.doReplaceAllAction(pageKey: key)
                    case let .rpc(path):
                        try await self.doRpcAction(pageKey: pageKey, path: path)
                    case .takePhoto(_):
                        // TODO: Implement take_photo.
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
                try? await self.doPushAction(pageKey: errorPageKey)
                return false
            }
        })
    }

    func stackPageKeys() -> [String] {
        self.mutex.lockReadOnly({ state in
            state.stackPageKeys()
        })
    }

    func stackPages() -> [(String, PageSpec, Instant)] {
        self.mutex.lockReadOnly({ state in
            state.stackPages()
        })
    }

    func tryUpdate(pageKey: String, _ token: Token, _ spec: PageSpec) async -> Bool {
        await self.lock.lockAsync({
            await self.mutex.lockAsyncAndUpdate({ state in
                state.trySet(pageKey: pageKey, token, spec)
            })
        })
    }

    func token() -> Token {
        self.mutex.token()
    }

    func varNamesAndValues(pageKey: String) -> [(String, Var)] {
        guard let varSet = self.weakVarSet else {
            return []
        }
        guard let namesAndDefaultValues: [(String, Var)] = self.mutex.lockReadOnly({ state in
            state.getSpec(pageKey: pageKey)?.vars()
        })
        else {
            return []
        }
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
