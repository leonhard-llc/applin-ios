import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    let config: ApplinConfig
    let navigationController = NavigationController()
    let poller: Poller
    let rpcCaller: RpcCaller
    let stateFileWriter: StateFileWriter
    let session: ApplinSession
    let streamer: Streamer
    var window: UIWindow?
    let initialized = AtomicBool(false)

    override init() {
        // Note: This code runs during app prewarming.
        do {
            self.config = try ApplinConfig(dataDirPath: getDataDirPath())
        } catch let e {
            fatalError("error starting app: \(e)")
        }
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
        URLCache.shared = URLCache(memoryCapacity: 10 * 1024 * 1024, diskCapacity: 500 * 1024 * 1024, diskPath: nil)
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
            defer {
                _ = self.initialized.store(true)
            }
            var optLoadedState: ApplinState? = nil
            do {
                optLoadedState = try await loadStateFile(self.config)
            } catch {
                print("ERROR: \(error)")
            }
            if let loadedState = optLoadedState {
                print("loaded state file")
                self.session.mutex.lock { state in
                    state = loadedState
                    state.paused = false
                    state.pauseUpdates = false
                }
                print("saved new state")
            } else {
                let hasSession = hasSessionCookie(self.config)
                //self.session.mutex.lockAndUpdate { state in
                self.session.mutex.lock { state in
                    state.pages = self.config.static_pages
                    if hasSession {
                        print("has session")
                        state.stack = [APPLIN_STATE_LOAD_ERROR_PAGE_KEY]
                    } else {
                        print("no session")
                        state.stack = ["/"]
                    }
                    state.paused = false
                    state.pauseUpdates = false
                }
            }
        }
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        print("active")
        if self.initialized.load() {
            self.session.mutex.lock({ state in state.paused = false })
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        print("background")
        self.session.mutex.lock({ state in state.paused = true })
    }
}
