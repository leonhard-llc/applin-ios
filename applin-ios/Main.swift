import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    let config: ApplinConfig
    let dataDirPath: String
    let cacheFileWriter: CacheFileWriter
    let connection: ApplinConnection
    let session: ApplinSession
    let navigationController: NavigationController
    var window: UIWindow?

    override init() {
        // Note: This code runs during app prewarming.
        self.config = ApplinConfig(url: URL(string: "http://127.0.0.1:8000/")!)
        self.connection = ApplinConnection(self.config)
        self.dataDirPath = getDataDirPath()
        self.cacheFileWriter = CacheFileWriter(dataDirPath: dataDirPath)
        self.navigationController = NavigationController()
        self.session = ApplinSession(self.config, self.cacheFileWriter, self.connection, self.navigationController)
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
            do {
                self.session.pauseUpdateNav = true
                defer {
                    self.session.pauseUpdateNav = false
                    self.session.updateNav()
                }
                await readDefaultData(self.config, self.session)
                try createDir(dataDirPath)
                await readCacheFile(dataDirPath: self.dataDirPath, self.config, self.session)
                self.session.unpause()
            } catch {
                print("startup error: \(error)")
            }
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
