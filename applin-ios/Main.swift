import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    let config: ApplinConfig
    let navigationController = NavigationController()
    let stateStore: StateStore
    let connection: ApplinConnection
    let session: ApplinSession
    var window: UIWindow?

    override init() {
        // Note: This code runs during app prewarming.
        self.config = ApplinConfig(
                dataDirPath: getDataDirPath(),
                url: URL(string: "http://127.0.0.1:8000/")!
        )
        self.connection = ApplinConnection(self.config)
        let initialState = ApplinState.loading()
        self.stateStore = StateStore(self.config, initialState)
        self.session = ApplinSession(
                self.config,
                self.stateStore,
                self.connection,
                self.navigationController
        )
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
            var initialState: ApplinState
            do {
                initialState = try await StateStore.loadDefaultJson(self.config)
            } catch {
                print("ERROR: startup error: \(error)")
                // TODO: Make app developers provide unique error codes.
                self.stateStore.update({ state in state = ApplinState.loadError(error: "\(error)") })
                self.session.updateNav()
                return
            }
            if let savedState = await StateStore.loadSavedState(self.config) {
                initialState.merge(savedState)
            }
            self.stateStore.update({ state in state = initialState })
            self.stateStore.allowWrites()
            self.session.updateNav()
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
