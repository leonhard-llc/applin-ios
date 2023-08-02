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
        #if DEBUG
        self.url = ApplinCustomConfig.URL_FOR_DEBUG_BUILDS
        #elseif targetEnvironment(simulator)
        self.url = ApplinCustomConfig.URL_FOR_SIMULATOR_BUILDS
        #else
        self.url = try checkLicenseKey(ApplinCustomConfig.APPLIN_LICENSE_KEY)
        #endif
        print("ApplinConfig dataDirPath=\(dataDirPath) url=\(self.url)")
    }

    func appstoreUrl() -> URL {
        URL(string: "itms-apps://itunes.apple.com/app/id\(self.appStoreAppId)")!
    }

    func stateFilePath() -> String {
        self.dataDirPath + "/state.json"
    }
}
