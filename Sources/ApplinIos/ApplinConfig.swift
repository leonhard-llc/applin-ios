import Foundation
import OSLog

public class ApplinConfig {
    static let logger = Logger(subsystem: "Applin", category: "ApplinConfig")

    public let appStoreAppId: UInt64
    public let applinClientErrorPage: (_ config: ApplinConfig, _ pageKey: String) -> ToPageSpec
    public let applinNetworkErrorPage: (_ config: ApplinConfig, _ pageKey: String) -> ToPageSpec
    public let applinPageNotLoadedPage: (_ config: ApplinConfig, _ pageKey: String) -> ToPageSpec
    public let applinServerErrorPage: (_ config: ApplinConfig, _ pageKey: String) -> ToPageSpec
    public let applinStateLoadErrorPage: (_ config: ApplinConfig, _ pageKey: String) -> ToPageSpec
    public let applinUserErrorPage: (_ config: ApplinConfig, _ pageKey: String) -> ToPageSpec
    public let dataDirPath: String
    public let licenseKey: ApplinLicenseKey?
    public let showPageOnFirstStartup: String
    public let staticPages: [String: (_ config: ApplinConfig, _ pageKey: String) -> ToPageSpec]
    public let statusPageUrl: URL?
    public let supportChatUrl: URL?
    public let supportEmailAddress: String?
    public let supportSmsTel: String?
    public let baseUrl: URL

    public init(
            appStoreAppId: UInt64,
            dataDirPath: String = getDataDirPath(),
            showPageOnFirstStartup: String,
            staticPages: [String: (_ config: ApplinConfig, _ pageKey: String) -> ToPageSpec],
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

    public func relativeUrl(url: String) throws -> URL {
        let trimmedUrl = url.removePrefix("/")
        if trimmedUrl.isEmpty {
            return self.baseUrl
        }
        guard let url = URL(string: trimmedUrl, relativeTo: self.baseUrl)
        else {
            throw ApplinError.appError("failed parsing url '\(url)'")
        }
        guard url.scheme == self.baseUrl.scheme,
              url.host == self.baseUrl.host,
              url.port == self.baseUrl.port,
              url.user == self.baseUrl.user,
              url.password == self.baseUrl.password,
              url.path.starts(with: self.baseUrl.path)
        else {
            throw ApplinError.appError("invalid url '\(url)'")
        }
        return url
    }

    public func staticPageSpec(pageKey: String) -> PageSpec? {
        self.staticPages[pageKey]?(self, pageKey).toPageSpec()
    }

    public func stateFilePath() -> String {
        self.dataDirPath + "/applin_state.json"
    }

    private init(_ config: ApplinConfig, baseUrl: URL) {
        self.appStoreAppId = config.appStoreAppId
        self.applinClientErrorPage = config.applinClientErrorPage
        self.applinNetworkErrorPage = config.applinNetworkErrorPage
        self.applinPageNotLoadedPage = config.applinPageNotLoadedPage
        self.applinServerErrorPage = config.applinServerErrorPage
        self.applinStateLoadErrorPage = config.applinStateLoadErrorPage
        self.applinUserErrorPage = config.applinUserErrorPage
        self.dataDirPath = config.dataDirPath
        self.licenseKey = config.licenseKey
        self.showPageOnFirstStartup = config.showPageOnFirstStartup
        self.staticPages = config.staticPages
        self.statusPageUrl = config.statusPageUrl
        self.supportChatUrl = config.supportChatUrl
        self.supportEmailAddress = config.supportEmailAddress
        self.supportSmsTel = config.supportSmsTel
        self.baseUrl = baseUrl
    }

    public func restricted_withBaseUrl(_ baseUrl: URL) throws -> ApplinConfig {
        guard let key = self.licenseKey else {
            throw "licenseKey required"
        }
        if !key.string.starts(with: "14NNS-2E") {
            throw "this method is restricted"
        }
        return ApplinConfig(self, baseUrl: baseUrl)
    }
}
