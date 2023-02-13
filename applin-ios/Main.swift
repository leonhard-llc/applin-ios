import UIKit

/// Applin pushes this page when the server returns a non-200 response.
let APPLIN_RPC_ERROR_PAGE_KEY = "/applin-rpc-error-modal"
/// Applin pushes this page when it fails to make an HTTP request to the server.
let APPLIN_NETWORK_ERROR_PAGE_KEY = "/applin-network-error"
/// Applin pushes this modal when it fails to load the state file.
/// Show the user a Connect button so they can retry and deal with auto errors.
let APPLIN_STATE_LOAD_ERROR_PAGE_KEY = "/applin-state-load-error"
/// Applin pushes this page the page key is not found in the page set.
let APPLIN_PAGE_NOT_FOUND_PAGE_KEY = "/applin-page-not-found"
/// Applin pushes this page when the server returns a user error message.
/// Include an ErrorDetails widget to display the message.
let APPLIN_USER_ERROR_PAGE_KEY = "/applin-user-error"
/// Applin pushes this page when the app has an error.
/// Include an ErrorDetails widget to display the message.
let APPLIN_APP_ERROR_PAGE_KEY = "/applin-app-error"

protocol CustomConfigProto {
    func serverUrl() -> URL
    func defaultPages(_ config: ApplinConfig) -> [String: PageSpec]
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    let customConfig: CustomConfigProto
    let config: ApplinConfig
    let navigationController = NavigationController()
    let poller: Poller
    let rpcCaller: RpcCaller
    let stateFileWriter: StateFileWriter
    let session: ApplinSession
    let streamer: Streamer
    var window: UIWindow?

    override init() {
        // Note: This code runs during app prewarming.
        self.customConfig = CustomConfig()
        self.config = ApplinConfig(dataDirPath: getDataDirPath(), url: self.customConfig.serverUrl())
        self.rpcCaller = RpcCaller(config)
        self.poller = Poller(config)
        self.stateFileWriter = StateFileWriter(config)
        self.streamer = Streamer(config)
        self.session = ApplinSession(
                self.config,
                ApplinState.loading(),
                self.navigationController,
                self.poller,
                self.rpcCaller,
                self.stateFileWriter,
                self.streamer
        )
        self.poller.setWeakRpcCaller(self.rpcCaller)
        self.poller.setWeakSession(self.session)
        self.rpcCaller.setWeakSession(self.session)
        self.stateFileWriter.setWeakSession(self.session)
        self.streamer.setWeakSession(self.session)
        super.init()
    }

    func application(
            _ application: UIApplication,
            didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        print("launch")
        // https://betterprogramming.pub/creating-ios-apps-without-storyboards-42a63c50756f
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window!.rootViewController = self.navigationController
        self.window!.makeKeyAndVisible()
        Task(priority: .high) {
            var optState: ApplinState? = nil
            do {
                optState = try await loadStateFile(self.config)
            } catch {
                print("ERROR: \(error)")
            }
            if let state = optState {
                print("Loaded state file.")
                self.session.state.lock().value = state
            } else {
                let cookies = HTTPCookieStorage.shared.cookies(for: self.config.url) ?? []
                let session_cookies = cookies.filter({ c in c.name == "session" })
                let defaultPages = self.customConfig.defaultPages(self.config)
                let state_guard = self.session.state.lock()
                if session_cookies.isEmpty {
                    // New app install.
                    state_guard.value.pages = defaultPages
                } else {
                    // App already has a session.
                    state_guard.value.stack = ["/applin-error-loading-state"]
                }
            }
            let pages = self.customConfig.defaultPages(self.config)
            let state_guard = self.session.state.lock()
            state_guard.value.pages = pages

            var initialState: ApplinState
            do {
                initialState = try await StateFileReader.loadDefaultJson(self.config)
            } catch {
                print("ERROR: startup error: \(error)")
                // TODO: Make app developers provide unique error codes.
                self.stateStore.update({ state in state = ApplinState.loadError(error: "\(error)") })
                self.session.updateDisplayedPages()
                return
            }
            if let savedState = await StateFileReader.loadSavedState(self.config) {
                initialState.merge(savedState)
            } else {
                // Don't let app start up with cookies (session) and no saved pages because the rpc:/ will not update
                // any of the pages.
                print("WARNING: Failed to load saved state.  Erasing cookies.")
                HTTPCookieStorage.shared.cookies?.forEach(HTTPCookieStorage.shared.deleteCookie)
            }
            self.stateStore.update({ state in state = initialState })
            self.stateStore.allowWrites()
            self.session.updateDisplayedPages()
            self.session.unpause()
            self.stateStore.startWriterTask()
        }
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        print("active")
        self.session.unpause()
        self.stateStore.startWriterTask()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        print("background")
        self.session.pause()
        self.stateStore.stopWriterTask()
    }
}
