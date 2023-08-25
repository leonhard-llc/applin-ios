import Foundation

public class ApplinCustomConfig {
    static let APPSTORE_APP_ID: UInt64 = 0000000000
    static let APPLIN_LICENSE_KEY: String? = nil
    static let URL_FOR_SIMULATOR_BUILDS = URL(string: "http://127.0.0.1:8000/")!
    static let URL_FOR_DEBUG_BUILDS = URL(string: "http://192.168.0.5:8000/")!
    static let SUPPORT_CHAT_URL: URL? = nil // URL(string: "https://www.example.com/support")!
    static let SUPPORT_EMAIL_ADDRESS: String = "info@example.com"
    static let SUPPORT_SMS_TEL: String? = nil // "+15551112222"
    static let STATUS_MARKDOWN_PAGE_URL = URL(string: "https://example-status.com/index.md")!
    static let SHOW_PAGE_ON_FIRST_STARTUP: String = "/legal-form"
    static let STATIC_PAGES: [String: (_ config: ApplinConfig, _ pageKey: String) -> PageSpec] = [
        // Required
        StaticPageKeys.APPLIN_CLIENT_ERROR: StaticPages.applinClientError,
        StaticPageKeys.APPLIN_PAGE_NOT_LOADED: StaticPages.pageNotLoaded,
        StaticPageKeys.APPLIN_NETWORK_ERROR: StaticPages.applinNetworkError,
        StaticPageKeys.APPLIN_SERVER_ERROR: StaticPages.applinServerError,
        StaticPageKeys.APPLIN_STATE_LOAD_ERROR: StaticPages.applinStateLoadError,
        StaticPageKeys.APPLIN_USER_ERROR: StaticPages.applinUserError,
        // Optional
        StaticPageKeys.ERROR_DETAILS: StaticPages.errorDetails,
        StaticPageKeys.SERVER_STATUS: StaticPages.serverStatus,
        StaticPageKeys.SUPPORT: StaticPages.support,
        "/legal-form": StaticPages.legalForm,
        StaticPageKeys.TERMS: StaticPages.terms,
        StaticPageKeys.PRIVACY_POLICY: StaticPages.privacyPolicy,
    ]
    static let pageNotFoundPage = StaticPages.pageNotFound
}
