import Foundation
import OSLog

public enum ConnectionMode: CustomStringConvertible, Equatable, Comparable {
    static let logger = Logger(subsystem: "Applin", category: "ConnectionMode")

    case stream
    case pollSeconds(UInt32)
    case disconnect

    init(_ stream: Bool?, _ pollSeconds: UInt32?) {
        if stream == true {
            self = .stream
            return
        }
        switch pollSeconds {
        case .none:
            self = .disconnect
        case let .some(seconds) where seconds == 0:
            Self.logger.warning("ignoring pollSeconds=0")
            self = .disconnect
        case let .some(seconds):
            self = .pollSeconds(seconds)
        }
    }

    func getStream() -> Bool? {
        switch self {
        case .stream:
            return true
        default:
            return nil
        }
    }

    func getPollSeconds() -> UInt32? {
        switch self {
        case .stream, .disconnect:
            return nil
        case let .pollSeconds(seconds):
            return seconds
        }
    }

    public var description: String {
        switch self {
        case .stream:
            return "stream"
        case let .pollSeconds(n):
            return "pollSeconds(\(n))"
        case .disconnect:
            return "disconnect"
        }
    }
}
