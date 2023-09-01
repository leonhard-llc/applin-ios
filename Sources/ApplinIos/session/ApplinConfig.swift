import Foundation
import OSLog

public class ApplinConfig {
    static let logger = Logger(subsystem: "Applin", category: "ApplinConfig")

    let appStoreAppId: UInt64
    let applinClientErrorPage: (_ config: ApplinConfig, _ pageKey: String) -> PageSpec
    let applinNetworkErrorPage: (_ config: ApplinConfig, _ pageKey: String) -> PageSpec
    let applinPageNotLoadedPage: (_ config: ApplinConfig, _ pageKey: String) -> PageSpec
    let applinServerErrorPage: (_ config: ApplinConfig, _ pageKey: String) -> PageSpec
    let applinStateLoadErrorPage: (_ config: ApplinConfig, _ pageKey: String) -> PageSpec
    let applinUserErrorPage: (_ config: ApplinConfig, _ pageKey: String) -> PageSpec
    let dataDirPath: String
    let licenseKey: ApplinLicenseKey?
    let showPageOnFirstStartup: String
    let staticPages: [String: (_ config: ApplinConfig, _ pageKey: String) -> PageSpec]
    let statusPageUrl: URL?
    let supportChatUrl: URL?
    let supportEmailAddress: String?
    let supportSmsTel: String?
    var url: URL

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
        self.url = urlForSimulatorBuilds
        #elseif DEBUG
        self.url = urlForDebugBuilds
        #else
        self.url = self.licenseKey!.url
        #endif
        Self.logger.info("dataDirPath=\(dataDirPath) url=\(self.url)")
        try createDir(self.dataDirPath)
    }

    func appstoreUrl() -> URL {
        URL(string: "itms-apps://itunes.apple.com/app/id\(self.appStoreAppId)")!
    }

    func staticPageSpec(pageKey: String) -> PageSpec? {
        self.staticPages[pageKey]?(self, pageKey)
    }

    func stateFilePath() -> String {
        self.dataDirPath + "/applin_state.json"
    }

    func restrictedSetUrl(_ url: URL) throws {
        guard let key = self.licenseKey else {
            throw "licenseKey required"
        }
        if !key.string.starts(with: "BdUbQklK") {
            throw "this method is restricted"
        }
        self.url = url
    }
}
