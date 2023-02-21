import Foundation

enum ApplinError: Error {
    case appError(String)
    case networkError(String)
    case serverError(String)
    case userError(String)

    func message() -> String {
        switch self {
        case let .appError(msg), let .networkError(msg), let .serverError(msg), let .userError(msg):
            return msg
        }
    }
}
