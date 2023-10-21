import OSLog
import UIKit

public class ApplinApp {
    static let logger = Logger(subsystem: "Applin", category: "ApplinApp")
    let lamportClock = LamportClock()
    public let navigationController = NavigationController()
    let wallClock = WallClock()
    let config: ApplinConfig
    //let streamer: Streamer
    var varSet: VarSet?
    var pageStack: PageStack?
    var poller: Poller?
    var serverCaller: ServerCaller?
    var stateFileOwner: StateFileOwner?
    var window: UIWindow?

    public init(_ config: ApplinConfig) {
        // Note: This code runs during app prewarming.
        self.config = config
    }

    public func makeWindow() {
        if self.window != nil {
            return
        }
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window!.rootViewController = self.navigationController
        self.window!.makeKeyAndVisible()
    }

    public func application(
            _ application: UIApplication,
            didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        Self.logger.info("launch")
        // https://betterprogramming.pub/creating-ios-apps-without-storyboards-42a63c50756f
        self.makeWindow()
        let optState = StateFileOwner.read(self.config)
        self.varSet = VarSet(optState?.boolVars ?? [:], optState?.stringVars ?? [:])
        var pageKeys: [String]
        if let state = optState {
            Self.logger.info("has state")
            pageKeys = state.pageKeys ?? []
            if pageKeys.isEmpty {
                pageKeys = ["/"]
            }
        } else if Cookies.hasSessionCookie(self.config) {
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
        let lastPageKey = pageKeys.last!
        Task {
            await self.pageStack!.doActions(pageKey: lastPageKey, [.poll])
        }
        return true
    }

    public func applicationDidBecomeActive(_ application: UIApplication) {
        Self.logger.info("active")
        self.poller?.start()
        self.stateFileOwner?.start()
    }

    public func applicationDidEnterBackground(_ application: UIApplication) {
        Self.logger.info("background")
        self.poller?.stop()
        self.stateFileOwner?.stop()
    }

    public func applicationWillTerminate(_ application: UIApplication) {
        // App is running and gets terminated by the user or iOS.
        Self.logger.info("terminate")
        self.stateFileOwner?.eraseStack()
    }
}
