import Foundation
import OSLog
import UIKit

public class ApplinCustomUrl: CustomDebugStringConvertible {
    static let logger = Logger(subsystem: "ApplinTester", category: "ApplinCustomUrl")

    public let baseUrl: URL
    public let pageKeys: [String]

    public init(_ input: String) throws {
        let trimmedInput: String
        if !input.hasPrefix("http://"),
           !input.hasPrefix("https://"),
           let schemeRange = input.range(of: "^[a-zA-Z0-9]+:", options: .regularExpression) {
            trimmedInput = input.replacingCharacters(in: schemeRange, with: "")
        } else {
            trimmedInput = input
        }
        // URL doesn't parse the query part, so we use NSURLComponents.
        guard let components = NSURLComponents(string: trimmedInput ) else {
            throw "error converting to NSURLComponents: \(String(describing: input))"
        }
        Self.logger.debug("components \(components)")
        let scheme: String
        if components.scheme == "http" || components.scheme == "https" {
            scheme = components.scheme!
        } else {
            throw "unknown scheme: \(String(describing: input))"
        }
        guard components.user == nil, components.password == nil else {
            throw "has username or password: \(String(describing: input))"
        }
        guard let host = components.host, !host.isEmpty else {
            throw "host is empty: \(String(describing: input))"
        }
        let port = components.port == nil ? "" : ":\(components.port ?? 0)"
        let rawPath = components.path ?? "/"
        guard components.fragment == nil else {
            throw "has fragment: \(String(describing: input))"
        }
        let path = rawPath.hasSuffix("/") ? rawPath : "\(rawPath)/"
        let baseUrl = URL(string: "\(scheme)://\(host)\(port)\(path)")!
        let queryItems = components.queryItems ?? []
        let pItems = queryItems.filter({ qi in qi.name == "p" })
        if queryItems.count > pItems.count {
            throw "has query items other than p: \(String(describing: input))"
        }
        var pageKeys: [String] = []
        for pItem in pItems {
            let pageKey = pItem.value ?? "/"
            if pageKey.starts(with: "/") {
                pageKeys.append(pageKey)
            } else {
                pageKeys.append("/" + pageKey)
            }
        }
        if pageKeys.isEmpty {
            pageKeys.append("/")
        }
        self.baseUrl = baseUrl
        self.pageKeys = pageKeys
    }

    public convenience init?(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        guard let value = launchOptions?[UIApplication.LaunchOptionsKey.url] else {
            return nil
        }
        // https://developer.apple.com/documentation/uikit/uiapplication/launchoptionskey/1622996-url
        let nsUrl = value as! NSURL
        Self.logger.info("launchUrl \(String(describing: nsUrl.absoluteString))")
        do {
            try self.init(nsUrl.absoluteString!)
        } catch {
            Self.logger.error("error parsing URL: \(error)")
            return nil
        }
    }

    public var debugDescription: String {
        "ApplinCustomUrl{baseUrl=\(String(describing: self.baseUrl.absoluteString)),pageKeys=\(String(describing: self.pageKeys))"
    }
}
