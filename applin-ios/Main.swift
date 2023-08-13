import OSLog
import UIKit

@main
class Main: UIResponder, UIApplicationDelegate {
    static let logger = Logger(subsystem: "Applin", category: "Main")
    let lamportClock = LamportClock()
    let navigationController = NavigationController()
    let wallClock = WallClock()
    let config: ApplinConfig
    //let streamer: Streamer
    var varSet: VarSet?
    var pageStack: PageStack?
    var poller: Poller?
    var serverCaller: ServerCaller?
    var stateFileOwner: StateFileOwner?
    var window: UIWindow?

    override init() {
        // Note: This code runs during app prewarming.
        do {
            URLCache.shared = URLCache(memoryCapacity: 10 * 1024 * 1024, diskCapacity: 500 * 1024 * 1024, diskPath: nil)
            self.config = try ApplinConfig(cacheDirPath: getCacheDirPath(), dataDirPath: getDataDirPath())
            try createDir(self.config.cacheDirPath)
            try createDir(self.config.dataDirPath)
            //self.streamer = Streamer(config, self.session)
            super.init()
        } catch let e {
            Self.logger.fault("error starting app: \(e)")
            fatalError("error starting app: \(e)")
        }
    }

    // impl UIApplicationDelegate

    func application(
            _ application: UIApplication,
            didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        Self.logger.info("launch")
        // https://betterprogramming.pub/creating-ios-apps-without-storyboards-42a63c50756f
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window!.rootViewController = self.navigationController
        self.window!.makeKeyAndVisible()
        Task(priority: .high) {
            let optState = await StateFileOwner.read(self.config)
            self.varSet = VarSet(optState?.boolVars ?? [:], optState?.stringVars ?? [:])
            var pageKeys: [String]
            if let state = optState {
                pageKeys = state.pageKeys ?? []
                if pageKeys.isEmpty {
                    pageKeys = ["/"]
                }
            } else if hasSessionCookie(self.config) {
                Self.logger.info("has session")
                pageKeys = [StaticPageKeys.APPLIN_STATE_LOAD_ERROR]
            } else {
                Self.logger.info("no session")
                pageKeys = [config.showPageOnFirstStartup]
            }
            self.pageStack = PageStack(self.config, self.lamportClock, self.navigationController, varSet, self.wallClock, pageKeys: pageKeys)
            self.serverCaller = ServerCaller(self.config, self.pageStack, self.varSet)
            self.pageStack!.weakServerCaller = self.serverCaller
            self.poller = Poller(self.config, self.pageStack, self.serverCaller, self.wallClock)
            self.stateFileOwner = StateFileOwner(self.config, self.varSet, self.pageStack)
            self.applicationDidBecomeActive(application)
            Task {
                await self.pageStack!.doActions(pageKey: pageKeys.last!, [.poll])
            }
        }
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        Self.logger.info("active")
        self.poller?.start()
        self.stateFileOwner?.start()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        Self.logger.info("background")
        self.stateFileOwner?.stop()
        self.poller?.stop()
        // TODO: When user kills app, throw away stack.
    }
}
