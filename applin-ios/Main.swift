import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    let dataDirPath: String
    let cacheFileWriter: CacheFileWriter
    let connection: ApplinConnection = ApplinConnection()
    let session: ApplinSession
    let navigationController: NavigationController
    var window: UIWindow?

    override init() {
        // Note: This code runs during app prewarming.
        self.dataDirPath = getDataDirPath()
        self.cacheFileWriter = CacheFileWriter(dataDirPath: dataDirPath)
        self.navigationController = NavigationController()
        let url = URL(string: "http://127.0.0.1:8000/")!
        self.session = ApplinSession(self.cacheFileWriter, self.connection, self.navigationController, url)
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
                await readDefaultData(self.session)
                try createDir(dataDirPath)
                await readCacheFile(dataDirPath: self.dataDirPath, self.session)
                self.connection.start(self.session)
                self.session.updateNav()
            } catch {
                print("startup error: \(error)")
            }
        }
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        print("active")
        self.connection.start(self.session)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        print("background")
        self.connection.stop()
        self.cacheFileWriter.stop()
    }
}
