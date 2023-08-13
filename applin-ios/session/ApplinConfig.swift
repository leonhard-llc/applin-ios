import Foundation

class ApplinConfig {
    let appStoreAppId: UInt64
    let dataDirPath: String
    let cacheDirPath: String
    let licenseKey: String?
    let pageNotFoundPage: (_ config: ApplinConfig, _ pageKey: String) -> PageSpec
    let showPageOnFirstStartup: String
    let supportChatUrl: URL?
    let supportEmailAddress: String
    let supportSmsTel: String?
    let statusMarkdownPageUrl: URL
    let staticPages: [String: (_ config: ApplinConfig, _ pageKey: String) -> PageSpec]
    let url: URL
    let applinClientErrorPage: (_ config: ApplinConfig, _ pageKey: String) -> PageSpec
    let applinPageNotLoadedPage: (_ config: ApplinConfig, _ pageKey: String) -> PageSpec
    let applinNetworkErrorPage: (_ config: ApplinConfig, _ pageKey: String) -> PageSpec
    let applinServerErrorPage: (_ config: ApplinConfig, _ pageKey: String) -> PageSpec
    let applinStateLoadErrorPage: (_ config: ApplinConfig, _ pageKey: String) -> PageSpec
    let applinUserErrorPage: (_ config: ApplinConfig, _ pageKey: String) -> PageSpec

    init(cacheDirPath: String, dataDirPath: String) throws {
        self.appStoreAppId = ApplinCustomConfig.APPSTORE_APP_ID
        self.cacheDirPath = cacheDirPath
        self.dataDirPath = dataDirPath
        self.licenseKey = ApplinCustomConfig.APPLIN_LICENSE_KEY
        self.pageNotFoundPage = ApplinCustomConfig.pageNotFoundPage
        self.showPageOnFirstStartup = ApplinCustomConfig.SHOW_PAGE_ON_FIRST_STARTUP
        self.supportChatUrl = ApplinCustomConfig.SUPPORT_CHAT_URL
        self.supportEmailAddress = ApplinCustomConfig.SUPPORT_EMAIL_ADDRESS
        self.supportSmsTel = ApplinCustomConfig.SUPPORT_SMS_TEL
        self.statusMarkdownPageUrl = ApplinCustomConfig.STATUS_MARKDOWN_PAGE_URL
        self.staticPages = ApplinCustomConfig.STATIC_PAGES
        self.applinClientErrorPage = self.staticPages[StaticPageKeys.APPLIN_CLIENT_ERROR]!
        self.applinPageNotLoadedPage = self.staticPages[StaticPageKeys.APPLIN_PAGE_NOT_LOADED]!
        self.applinNetworkErrorPage = self.staticPages[StaticPageKeys.APPLIN_NETWORK_ERROR]!
        self.applinServerErrorPage = self.staticPages[StaticPageKeys.APPLIN_SERVER_ERROR]!
        self.applinStateLoadErrorPage = self.staticPages[StaticPageKeys.APPLIN_STATE_LOAD_ERROR]!
        self.applinUserErrorPage = self.staticPages[StaticPageKeys.APPLIN_USER_ERROR]!
        #if targetEnvironment(simulator)
        self.url = ApplinCustomConfig.URL_FOR_SIMULATOR_BUILDS
        #elseif DEBUG
        self.url = ApplinCustomConfig.URL_FOR_DEBUG_BUILDS
        #else
        self.url = try checkLicenseKey(ApplinCustomConfig.APPLIN_LICENSE_KEY)
        #endif
        print("ApplinConfig dataDirPath=\(dataDirPath) url=\(self.url)")
    }

    func appstoreUrl() -> URL {
        URL(string: "itms-apps://itunes.apple.com/app/id\(self.appStoreAppId)")!
    }

    func staticPageSpec(pageKey: String) -> PageSpec? {
        self.staticPages[pageKey]?(self, pageKey)
    }

    func stateFilePath() -> String {
        self.dataDirPath + "/state.json"
    }
}
