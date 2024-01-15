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
            let now = self.wallClock.now()
            let lamportInstant = self.lamportClock.now()
            self.stack = pageKeys.map({ key in
                let instant: Instant
                let spec: PageSpec
                if let staticPageSpec = config.staticPageSpec(pageKey: key) {
                    spec = staticPageSpec
                    instant = now
                } else {
                    spec = config.applinPageNotLoadedPage(config, key).toPageSpec()
                    instant = Instant.EARLIEST
                }
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

        func nonEphemeralStackPageKeys() -> [String] {
            self.stack
                    .prefix(while: { entry in !entry.spec.isEphemeral })
                    .map({ entry in entry.pageKey })
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

        func topPageKey() -> String? {
            self.stack.last?.pageKey
        }
    }

    class StateMutex {
        private let lock = ApplinLock()
        private let state: State
        weak var weakForegroundPoller: ForegroundPoller?
        weak var weakNav: NavigationController?
        weak var weakPageStack: PageStack?
        weak var weakVarSet: VarSet?

        init(
                state: State,
                _ foregroundPoller: ForegroundPoller?,
                _ nav: NavigationController?,
                _ varSet: VarSet?
        ) {
            self.state = state
            self.weakForegroundPoller = foregroundPoller
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
               let foregroundPoller = self.weakForegroundPoller,
               let pageStack = self.weakPageStack,
               let varSet = self.weakVarSet,
               let stackSpecs = self.state.stackSpecsForUpdate() {
                await nav.update(foregroundPoller, pageStack, varSet, newPages: stackSpecs)
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
            _ foregroundPoller: ForegroundPoller?,
            _ nav: NavigationController?,
            _ varSet: VarSet?,
            _ wallClock: WallClock,
            pageKeys: [String]
    ) {
        self.config = config
        let state = State(config, lamportClock, wallClock, pageKeys: pageKeys)
        self.mutex = StateMutex(state: state, foregroundPoller, nav, varSet)
        self.mutex.weakPageStack = self
        self.weakNav = nav
        self.weakVarSet = varSet
    }

    private func uploadImage(_ image: UIImage, _ spec: UploadPhotoActionSpec) async throws -> Bool {
        // TODO: Allow user to retry a failed upload.
        let data: Data
        if let aspectRatio = spec.aspect_ratio {
            guard let nav = self.weakNav,
                  let jpegData = try await PhotoEditor.edit(nav, image, aspectRatio: aspectRatio)
            else {
                return false
            }
            data = jpegData
        } else {
            data = try await image.jpegData(compressionQuality: 0.9)
        }
        Self.logger.info("choosePhoto uploading \(data.count) bytes")
        //let filePath = self.config.dataDirPath + "/upload.jpg"
        //Self.logger.info("writing \(filePath)")
        //try await writeFile(data: data, path: filePath)
        let uploadBody = UploadBody(data, contentType: "image/jpeg")
        return try await self.withWorking({
            try await self.weakServerCaller?.upload(url: spec.url, uploadBody: uploadBody)
            return true
        })
    }

    // TODO: Don't show error modal when poll-delay poll fails.  Show error bar.
    private func doChoosePhotoAction(_ spec: UploadPhotoActionSpec) async throws -> Bool {
        guard let nav = self.weakNav else {
            return false
        }
        guard let uiImage = try await PhotoPicker.pick(nav) else {
            return false
        }
        return try await self.uploadImage(uiImage, spec)
    }

    private func doTakePhotoAction(_ spec: UploadPhotoActionSpec) async throws -> Bool {
        guard let nav = self.weakNav else {
            return false
        }
        guard let uiImage = try await PhotoTaker.take(nav) else {
            return false
        }
        return try await self.uploadImage(uiImage, spec)
    }

    private func doModalAction(pageKey: String, _ spec: ModalActionSpec) async throws {
        let task = Task<(), Never> { @MainActor in
            guard let nav = self.weakNav else {
                return
            }
            let dialogCtl = UIAlertController(title: spec.title, message: spec.message, preferredStyle: .alert)
            for button in spec.buttons {
                let style: UIAlertAction.Style
                if button.text == "Cancel" {
                    style = .cancel
                } else if button.text.starts(with: "!") {
                    style = .destructive
                } else {
                    style = .default
                }
                dialogCtl.addAction(UIAlertAction(
                        title: button.text.removePrefix("!"),
                        style: style,
                        handler: { _ in
                            Task {
                                await self.doActions(pageKey: pageKey, button.actions)
                            }
                        }
                ))
            }
            nav.present(dialogCtl, animated: true);
        }
        let _ = await task.value
    }

    private func fetchPageSpec(_ serverCaller: ServerCaller, pageKey: String) async throws -> PageSpec {
        if let spec = self.config.staticPageSpec(pageKey: pageKey) {
            return spec
        }
        let varNamesAndValues = self.varNamesAndValues(pageKey: pageKey)
        let update = try await serverCaller.poll(
                pageKey: pageKey,
                varNamesAndValues: varNamesAndValues,
                interactive: true
        )
        return update.spec
    }

    private func doPollAction(pageKey: String) async throws {
        guard let serverCaller = self.weakServerCaller else {
            return
        }
        if self.config.staticPages[pageKey] != nil {
            // Show first page on startup.
            await self.mutex.lockAsyncAndUpdate({ state in })
            return
        }
        let spec = try await self.fetchPageSpec(serverCaller, pageKey: pageKey)
        await self.mutex.lockAsyncAndUpdate({ state in
            state.set(pageKey: pageKey, spec)
        })
    }

    private func doPushAction(pageKey: String) async throws {
        guard let serverCaller = self.weakServerCaller else {
            return
        }
        let spec = try await self.fetchPageSpec(serverCaller, pageKey: pageKey)
        try await self.mutex.lockAsyncThrowsAndUpdate({ state in
            try state.push(pageKey: pageKey, spec)
        })
        // TODO: Skip the extra poll when the validated input widgets' vars have no values.
        if spec.hasValidatedInput() {
            // Poll again, this time sending variable values so server can validate them.
            let spec = try await self.fetchPageSpec(serverCaller, pageKey: pageKey)
            await self.mutex.lockAsyncAndUpdate({ state in
                state.set(pageKey: pageKey, spec)
            })
        }
    }

    private func doReplaceAllAction(pageKey: String) async throws {
        guard let serverCaller = self.weakServerCaller else {
            return
        }
        let spec = try await self.fetchPageSpec(serverCaller, pageKey: pageKey)
        await self.mutex.lockAsyncAndUpdate({ state in
            state.replaceAll(pageKey: pageKey, spec)
        })
        // TODO: Skip the extra poll when the validated input widgets' vars have no values.
        if spec.hasValidatedInput() {
            // Poll again, this time sending variable values so server can validate them.
            let spec = try await self.fetchPageSpec(serverCaller, pageKey: pageKey)
            await self.mutex.lockAsyncAndUpdate({ state in
                state.set(pageKey: pageKey, spec)
            })
        }
    }

    private func doRpcAction(pageKey: String, _ url: URL) async throws {
        guard let serverCaller = self.weakServerCaller else {
            return
        }
        let varNamesAndValues = self.varNamesAndValues(pageKey: pageKey)
        let _ = try await serverCaller.call(
                .POST,
                url,
                varNamesAndValues: varNamesAndValues,
                interactive: true
        )
    }

    private func doAction(pageKey: String, _ action: ActionSpec) async throws -> Bool {
        Self.logger.info("action \(action.description)")
        switch action {
        case let .choosePhoto(spec):
            return try await self.doChoosePhotoAction(spec)
        case let .copyToClipboard(string):
            UIPasteboard.general.string = string
        case let .launchUrl(url):
            Task { @MainActor in
                await UIApplication.shared.open(url)
            }
        case .logout:
            // TODO: Display confirmation dialog.
            // TODO: Display "Logged Out" dialog.
            Cookies.deleteSessionCookie(self.config)
            self.weakVarSet?.removeAll()
            try await self.doReplaceAllAction(pageKey: config.showPageOnFirstStartup)
        case let .modal(spec):
            try await self.doModalAction(pageKey: pageKey, spec)
        case .poll:
            try await self.doPollAction(pageKey: pageKey)
        case .pop:
            try await self.mutex.lockAsyncThrowsAndUpdate({ state in
                try state.pop()
            })
        case let .push(pageKey):
            try await self.doPushAction(pageKey: pageKey)
        case let .replaceAll(pageKey):
            try await self.doReplaceAllAction(pageKey: pageKey)
        case let .rpc(spec):
            do {
                try await self.doRpcAction(pageKey: pageKey, spec.url)
            } catch let e as ApplinError {
                if case .userError = e, spec.on_user_error_poll ?? false {
                    let _ = try? await self.doPollAction(pageKey: pageKey)
                }
                throw e
            }

        case let .takePhoto(spec):
            return try await self.doTakePhotoAction(spec)
        }
        return true
    }

    func doActions(pageKey: String, _ actions: [ActionSpec], showWorking: Bool? = nil) async -> Bool {
        await self.lock.lockAsync({
            await self.handleInteractiveError({
                let showWorkingForActions = actions.contains(where: { action in action.showWorking })
                if showWorking ?? showWorkingForActions {
                    return try await self.withWorking({ () in
                        for action in actions {
                            let success = try await self.doAction(pageKey: pageKey, action)
                            if !success {
                                return false
                            }
                        }
                        return true
                    })
                } else {
                    for action in actions {
                        let success = try await self.doAction(pageKey: pageKey, action)
                        if !success {
                            return false
                        }
                    }
                    return true
                }
            })
        })
    }

    func handleInteractiveError(_ f: () async throws -> Bool) async -> Bool {
        do {
            return try await f()
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
    }

    func nonEphemeralStackPageKeys() -> [String] {
        self.mutex.lockReadOnly({ state in
            state.nonEphemeralStackPageKeys()
        })
    }

    func stackPages() -> [(String, PageSpec, Instant)] {
        self.mutex.lockReadOnly({ state in
            state.stackPages()
        })
    }

    func topPageKey() -> String? {
        self.mutex.lockReadOnly({ state in
            state.topPageKey()
        })
    }


    func token() -> Token {
        self.mutex.token()
    }

    func tryUpdate(pageKey: String, _ token: Token, _ spec: PageSpec) async -> Bool {
        await self.lock.lockAsync({
            await self.mutex.lockAsyncAndUpdate({ state in
                state.trySet(pageKey: pageKey, token, spec)
            })
        })
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

    private func withWorking(_ f: @escaping () async throws -> Bool) async throws -> Bool {
        //let promise: ApplinPromise<()> = ApplinPromise()
        let task = Task(priority: .userInitiated) { @MainActor in
            do {
                return try await f()
                //let _ = promise.tryComplete(value: <#T##()##()#>)
            } catch let e {
                if !Task.isCancelled {
                    throw e
                }
                return false
            }
        };
        await self.weakNav?.setWorking("Working", task)
        let stopwatch = Stopwatch()
        do {
            let result = try await task.value
            await stopwatch.waitUntil(seconds: 0.5)
            await self.weakNav?.setWorking(nil, nil)
            return result
        } catch let e {
            await stopwatch.waitUntil(seconds: 0.5)
            await self.weakNav?.setWorking(nil, nil)
            throw e
        }
    }
}
