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
        self.session = ApplinSession(self.config, ApplinState.loading(), self.navigationController)
        self.rpcCaller = RpcCaller(config, self.session)
        self.poller = Poller(config, self.rpcCaller, self.session)
        self.stateFileWriter = StateFileWriter(config, self.session)
        self.streamer = Streamer(config, self.session)
        self.session.setDeps(
                self.poller,
                self.rpcCaller,
                self.stateFileWriter,
                self.streamer
        )
        super.init()
    }

    // impl UIApplicationDelegate

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
                print("loaded state file")
                let mutexGuard = self.session.mutex.lock()
                mutexGuard.state.pauseUpdates = false
                mutexGuard.state = state
                print("saved new state")
            } else {
                let hasSession = hasSessionCookie(self.config)
                let defaultPages = self.customConfig.defaultPages(self.config)
                let mutexGuard = self.session.mutex.lock()
                mutexGuard.state.pauseUpdates = false
                mutexGuard.state.pages = defaultPages
                if hasSession {
                    print("has session")
                    mutexGuard.state.stack = [APPLIN_STATE_LOAD_ERROR_PAGE_KEY]
                } else {
                    print("no session")
                    mutexGuard.state.stack = ["/"]
                }
            }
        }
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        print("active")
        self.session.mutex.lock().state.paused = false
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        print("background")
        self.session.mutex.lock().state.paused = true
    }
}
