import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    let config: ApplinConfig
    let dataDirPath: String
    let navigationController = NavigationController()
    let cacheFileWriter: CacheFileWriter
    let connection: ApplinConnection
    let session: ApplinSession
    var window: UIWindow?

    override init() {
        // Note: This code runs during app prewarming.
        self.config = ApplinConfig(url: URL(string: "http://127.0.0.1:8000/")!)
        self.connection = ApplinConnection(self.config)
        self.dataDirPath = getDataDirPath()
        self.cacheFileWriter = CacheFileWriter(dataDirPath: dataDirPath)
        self.session = ApplinSession(
                self.config,
                ApplinState(),
                self.cacheFileWriter,
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
                initialState = try await readCacheFile(self.config, dataDirPath: self.dataDirPath)
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
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        print("background")
        self.session.pause()
        self.cacheFileWriter.stop()
    }
}
