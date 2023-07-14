import Foundation

class ApplinCustomConfig {
    static let APPSTORE_APP_ID: UInt64 = 0000000000
    static let APPLIN_LICENSE_KEY: String? = nil
    static let URL_FOR_SIMULATOR_BUILDS = URL(string: "http://127.0.0.1:8000/")!
    static let URL_FOR_DEBUG_BUILDS = URL(string: "http://192.168.0.5:8000/")!
    static let SUPPORT_EMAIL_ADDRESS: String = "info@example.com"
    static let STATUS_MARKDOWN_PAGE_URL: String = "https://example-status.com/index.md"
    static let STATIC_PAGES: [String: (_ config: ApplinConfig) -> PageSpec] = [
        APPLIN_NETWORK_ERROR_PAGE_KEY: ApplinConfig.defaultNetworkErrorPage,
        APPLIN_SERVER_ERROR_PAGE_KEY: ApplinConfig.defaultServerErrorPage,
        APPLIN_CLIENT_ERROR_PAGE_KEY: ApplinConfig.defaultClientErrorPage,
        APPLIN_STATE_LOAD_ERROR_PAGE_KEY: ApplinConfig.defaultStateLoadErrorPage,
        APPLIN_PAGE_NOT_FOUND_PAGE_KEY: ApplinConfig.defaultPageNotFoundPage,
        APPLIN_USER_ERROR_PAGE_KEY: ApplinConfig.defaultUserErrorPage,
        APPLIN_ERROR_DETAILS_PAGE_KEY: ApplinConfig.defaultErrorDetailsPage,
        APPLIN_STATUS_PAGE_KEY: ApplinConfig.defaultStatusPage,
        APPLIN_SUPPORT_PAGE_KEY: ApplinConfig.defaultSupportPage,
        "/legal-form": ApplinConfig.defaultLegalFormPage,
        "/terms": ApplinConfig.defaultTermsPage,
        "/privacy": ApplinConfig.defaultPrivacyPolicyPage,
    ]
    static let SHOW_PAGE_ON_FIRST_STARTUP: String = "/legal-form"
}
