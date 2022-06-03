import Foundation

enum MaggieError: Error {
    case deserializeError(String)
    case networkError(String)
}
