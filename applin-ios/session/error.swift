import Foundation

enum ApplinError: Error {
    case appError(String)
    case networkError(String)
    case serverError(String)
    case userError(String)
}
