import Foundation
import OSLog

extension URL {
    func asOrigin() throws -> String {
        // https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Origin
        guard let scheme = self.scheme else {
            throw "url has no scheme: \(String(describing: self))"
        }
        guard let host = self.host else {
            throw "url has no scheme: \(String(describing: self))"
        }
        let portString = self.port == nil ? "" : ":\(self.port!)"
        return "\(scheme)://\(host)\(portString)"
    }
}

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
    public let originUrl: String

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
        self.originUrl = try self.baseUrl.asOrigin()
        Self.logger.info("dataDirPath=\(dataDirPath) baseUrl=\(self.baseUrl)")
        try createDir(self.dataDirPath)
    }

    public func appstoreUrl() -> URL {
        URL(string: "itms-apps://itunes.apple.com/app/id\(self.appStoreAppId)")!
    }

    public func staticPageSpec(pageKey: String) -> PageSpec? {
        self.staticPages[pageKey]?(self, pageKey).toPageSpec()
    }

    public func stateFilePath() -> String {
        self.dataDirPath + "/applin_state.json"
    }

    private init(_ config: ApplinConfig, baseUrl: URL) throws {
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
        self.originUrl = try self.baseUrl.asOrigin()
    }

    public func restricted_withBaseUrl(_ baseUrl: URL) throws -> ApplinConfig {
        guard let key = self.licenseKey else {
            throw "licenseKey required"
        }
        if !key.string.starts(with: "14NNS-2E") {
            throw "this method is restricted"
        }
        return try ApplinConfig(self, baseUrl: baseUrl)
    }
}
