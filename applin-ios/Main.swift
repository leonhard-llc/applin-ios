import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    let navigationController = NavigationController()
    let stateStore: StateStore
    let connection: ApplinConnection
    let session: ApplinSession
    var window: UIWindow?

    override init() {
        // Note: This code runs during app prewarming.
        let config = ApplinConfig(
                dataDirPath: getDataDirPath(),
                url: URL(string: "http://127.0.0.1:8000/")!
        )
        self.connection = ApplinConnection(config)
        self.stateStore = StateStore(config)
        self.session = ApplinSession(
                config,
                ApplinState(),
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
            let initialState: ApplinState
            do {
                initialState = try await self.stateStore.read()
            } catch {
                print(error)
                // TODO: Add a test that reads and checks default.json.
                initialState = ApplinState(error: "Error loading data")
            }
            self.session.state = initialState
            self.session.updateNav()
            self.session.unpause()
        }
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        print("active")
        self.session.unpause()
        self.stateStore.start()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        print("background")
        self.session.pause()
        self.stateStore.stop()
    }
}
