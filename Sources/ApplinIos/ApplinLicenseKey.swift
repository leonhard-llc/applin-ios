import CryptoKit
import Foundation

public class ApplinLicenseKey {
    static func addBase64Padding(_ s: String) -> String {
        let n = s.count % 4
        if n == 3 {
            return s + "="
        } else if n == 2 {
            return s + "=="
        } else if n == 1 {
            return s + "==="
        } else {
            return s
        }
    }

    static func base64UrlSafeToStandard(_ s: String) -> String {
        s.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
    }

    static func checkLicenseKey(_ key: String) throws -> URL {
        let key_parts = key.split(separator: ",", omittingEmptySubsequences: false)
        let sig_string = addBase64Padding(base64UrlSafeToStandard(String(key_parts.get(0)!)))
        guard let url_subseq = key_parts.get(1) else {
            throw "error in license key: missing comma separator"
        }
        let url_string = String(url_subseq)
        guard let url = URL(string: url_string) else {
            throw "error in license key: url is invalid"
        }
        if url.scheme != "https" {
            throw "error in license key: scheme is not https"
        }
        if sig_string.isEmpty {
            throw "error in license key: signature part is empty"
        }
        guard let sig_bytes = Data(base64Encoded: sig_string) else {
            throw "error in license key: error decoding signature part as Base64"
        }
        if sig_bytes.count != 64 {
            throw "error in license key: signature has incorrect length"
        }
        let publicKeyBytes = Data(base64Encoded: "uE9Q7epkUN+4arW0I5a7vTuO4Bbl1g+69Iu2O4OHRCg=")!
        let publicKey = try Curve25519.Signing.PublicKey.init(rawRepresentation: publicKeyBytes)
        if publicKey.isValidSignature(sig_bytes, for: [UInt8](url_string.utf8)) {
            return url
        } else {
            throw "error in license key: signature is not valid"
        }
    }

    public let string: String
    public let url: URL

    public init(_ key: String) throws {
        self.string = key
        self.url = try Self.checkLicenseKey(key)
    }
}
