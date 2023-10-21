import Foundation
import OSLog

public class ApplinConfig {
    static let logger = Logger(subsystem: "Applin", category: "ApplinConfig")

    public let appStoreAppId: UInt64
    public let applinClientErrorPage: (_ config: ApplinConfig, _ pageKey: String) -> PageSpec
    public let applinNetworkErrorPage: (_ config: ApplinConfig, _ pageKey: String) -> PageSpec
    public let applinPageNotLoadedPage: (_ config: ApplinConfig, _ pageKey: String) -> PageSpec
    public let applinServerErrorPage: (_ config: ApplinConfig, _ pageKey: String) -> PageSpec
    public let applinStateLoadErrorPage: (_ config: ApplinConfig, _ pageKey: String) -> PageSpec
    public let applinUserErrorPage: (_ config: ApplinConfig, _ pageKey: String) -> PageSpec
    public let dataDirPath: String
    public let licenseKey: ApplinLicenseKey?
    public let showPageOnFirstStartup: String
    public let staticPages: [String: (_ config: ApplinConfig, _ pageKey: String) -> PageSpec]
    public let statusPageUrl: URL?
    public let supportChatUrl: URL?
    public let supportEmailAddress: String?
    public let supportSmsTel: String?
    public var baseUrl: URL

    public init(
            appStoreAppId: UInt64,
            dataDirPath: String = getDataDirPath(),
            showPageOnFirstStartup: String,
            staticPages: [String: (_ config: ApplinConfig, _ pageKey: String) -> PageSpec],
            urlForDebugBuilds: URL,
            urlForSimulatorBuilds: URL,
            licenseKey: ApplinLicenseKey?,
            statusPageUrl: URL? = nil,
            supportChatUrl: URL? = nil,
            supportEmailAddress: String? = nil,
            supportSmsTel: String? = nil
    ) throws {
        self.appStoreAppId = appStoreAppId
        self.dataDirPath = dataDirPath
        self.licenseKey = licenseKey
        self.staticPages = staticPages
        self.applinClientErrorPage = self.staticPages[StaticPageKeys.APPLIN_CLIENT_ERROR]!
        self.applinNetworkErrorPage = self.staticPages[StaticPageKeys.APPLIN_NETWORK_ERROR]!
        self.applinPageNotLoadedPage = self.staticPages[StaticPageKeys.APPLIN_PAGE_NOT_LOADED]!
        self.applinServerErrorPage = self.staticPages[StaticPageKeys.APPLIN_SERVER_ERROR]!
        self.applinStateLoadErrorPage = self.staticPages[StaticPageKeys.APPLIN_STATE_LOAD_ERROR]!
        self.applinUserErrorPage = self.staticPages[StaticPageKeys.APPLIN_USER_ERROR]!
        self.showPageOnFirstStartup = showPageOnFirstStartup
        self.statusPageUrl = statusPageUrl
        self.supportChatUrl = supportChatUrl
        self.supportEmailAddress = supportEmailAddress
        self.supportSmsTel = supportSmsTel
        #if targetEnvironment(simulator)
        self.baseUrl = urlForSimulatorBuilds
        #elseif DEBUG
        self.baseUrl = urlForDebugBuilds
        #else
        self.baseUrl = self.licenseKey!.url
        #endif
        Self.logger.info("dataDirPath=\(dataDirPath) baseUrl=\(self.baseUrl)")
        try createDir(self.dataDirPath)
    }

    public func appstoreUrl() -> URL {
        URL(string: "itms-apps://itunes.apple.com/app/id\(self.appStoreAppId)")!
    }

    public func staticPageSpec(pageKey: String) -> PageSpec? {
        self.staticPages[pageKey]?(self, pageKey)
    }

    public func stateFilePath() -> String {
        self.dataDirPath + "/applin_state.json"
    }
}
