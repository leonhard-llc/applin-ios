import Foundation

public enum ConnectionMode: CustomStringConvertible, Equatable, Comparable {
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
            print("WARNING: Ignoring pollSeconds=0")
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

func logout(_ config: ApplinConfig) async throws {
    print("Logout")
    HTTPCookieStorage.shared.cookies?.forEach(HTTPCookieStorage.shared.deleteCookie)
    // TODO: Delete state file.
    // TODO: Stop state file writer.
    // TODO: Erase session saved state.
    // TODO: Disconnect streamer.
    // TODO: Stop poller.
    // TODO: Interrupt sequence of actions.
}

func hasSessionCookie(_ config: ApplinConfig) -> Bool {
    let cookies = HTTPCookieStorage.shared.cookies(for: config.url) ?? []
    let session_cookies = cookies.filter({ c in c.name == "session" })
    return !session_cookies.isEmpty
}
