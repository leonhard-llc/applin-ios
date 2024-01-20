import OSLog
import UIKit

public class ApplinApp {
    static let logger = Logger(subsystem: "Applin", category: "ApplinApp")
    let lamportClock = LamportClock()
    public let navigationController = NavigationController()
    let wallClock = WallClock()
    public let config: ApplinConfig
    //let streamer: Streamer
    var foregroundPoller: ForegroundPoller?
    var pageStack: PageStack?
    var poller: Poller?
    var serverCaller: ServerCaller?
    var stateFileOwner: StateFileOwner?
    var varSet: VarSet?

    public init(_ config: ApplinConfig) {
        Self.logger.info("init")
        self.config = config
    }

    public func application(
            didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?,
            customUrl inputCustomUrl: ApplinCustomUrl? = nil
    ) -> Bool {
        Self.logger.info("didFinishLaunchingWithOptions")
        let optState = StateFileOwner.read(self.config)
        self.varSet = VarSet(optState?.boolVars ?? [:], optState?.stringVars ?? [:])
        var pageKeys: [String]
        let optCustomUrl: ApplinCustomUrl?
        if let customUrl = inputCustomUrl ?? ApplinCustomUrl(launchOptions: launchOptions) {
            if customUrl.baseUrl == self.config.baseUrl {
                optCustomUrl = customUrl
            } else {
                Self.logger.error("ignoring custom URL which has the wrong base URL: \(String(describing: customUrl))")
                optCustomUrl = nil
            }
        } else {
            optCustomUrl = nil
        }
        if let customUrl = optCustomUrl {
            pageKeys = customUrl.pageKeys
        } else if let state = optState {
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
        self.foregroundPoller = ForegroundPoller()
        self.pageStack = PageStack(
                self.config,
                self.lamportClock,
                self.foregroundPoller,
                self.navigationController,
                varSet,
                self.wallClock, pageKeys: pageKeys
        )
        self.foregroundPoller!.weakPageStack = self.pageStack!
        self.serverCaller = ServerCaller(self.config, self.pageStack, self.varSet)
        self.pageStack!.weakServerCaller = self.serverCaller
        self.poller = Poller(self.config, self.pageStack, self.serverCaller, self.wallClock)
        self.stateFileOwner = StateFileOwner(self.config, self.varSet, self.pageStack)
        Task {
            await self.pageStack!.doActions([.poll])
        }
        return true
    }

    public func openUrl(_ customUrl: ApplinCustomUrl) throws {
        guard customUrl.baseUrl == self.config.baseUrl else {
            throw "openUrl called URL that does not match config baseUrl \(String(describing: self.config.baseUrl.absoluteString)): \(String(describing: customUrl))"
        }
        Task {
            guard let pageStack = self.pageStack else {
                return
            }
            if pageStack.nonEphemeralStackPageKeys() == customUrl.pageKeys {
                // Page is already visible.  Poll it.
                let _ = await self.pageStack?.doActions([.poll])
                return
            }
            let firstAction = [ActionSpec.replaceAll(customUrl.pageKeys.first!)]
            let otherActions = customUrl.pageKeys.dropFirst().map({ pageKey in ActionSpec.push(pageKey) })
            let _ = await self.pageStack?.doActions(firstAction + otherActions)
        }
    }

    public func applicationDidBecomeActive() {
        Self.logger.info("applicationDidBecomeActive")
        self.poller?.start()
        self.stateFileOwner?.start()
    }

    public func applicationDidEnterBackground() {
        Self.logger.info("applicationDidEnterBackground")
        self.poller?.stop()
        self.stateFileOwner?.stop()
    }

    public func applicationWillTerminate() {
        // App is running and gets terminated by the user or iOS.
        Self.logger.info("applicationWillTerminate")
        self.stateFileOwner?.eraseStack()
    }
}
