import Foundation
import OSLog

public class Cookies {
    static let logger = Logger(subsystem: "Applin", category: "Cookies")
    static func sessionCookie(_ config: ApplinConfig) -> HTTPCookie? {
        HTTPCookieStorage.shared.cookies(for: config.baseUrl)?.first(where: { c in c.name == "session" })
    }

    static func deleteSessionCookie(_ config: ApplinConfig) {
        if let cookie = Self.sessionCookie(config) {
            Self.logger.info("deleting session cookie: \(cookie)")
            HTTPCookieStorage.shared.deleteCookie(cookie)
        }
    }

    static func hasSessionCookie(_ config: ApplinConfig) -> Bool {
        Self.sessionCookie(config) != nil
    }
}
