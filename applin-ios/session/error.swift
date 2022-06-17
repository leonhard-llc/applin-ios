import Foundation

enum ApplinError: Error {
    case deserializeError(String)
    case networkError(String)
}
