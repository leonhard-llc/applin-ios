import Foundation
import UIKit

enum MaggieAction: Equatable {
    static func == (lhs: MaggieAction, rhs: MaggieAction) -> Bool {
        switch (lhs, rhs) {
        case let (.CopyToClipboard(a), .CopyToClipboard(b)) where a == b:
            return true
        case let (.LaunchUrl(a), .LaunchUrl(b)) where a == b:
            return true
        case (.Logout, .Logout):
            return true
        case (.Pop, .Pop):
            return true
        case let (.Push(a, _), .Push(b, _)) where a == b:
            return true
        case let (.Rpc(a, _), .Rpc(b, _)) where a == b:
            return true
        default:
            return false
        }
    }
    
    case CopyToClipboard(String)
    case LaunchUrl(URL)
    case Logout(MaggieSession)
    case Pop(MaggieSession)
    case Push(String, MaggieSession)
    case Rpc(String, MaggieSession)

    init(_ string: String, _ session: MaggieSession) throws {
        switch string {
        case "":
            throw MaggieError.deserializeError("action is empty")
        case "logout":
            self = .Logout(session)
            return
        case "pop":
            self = .Pop(session)
            return
        default:
            break
        }
        let parts = string.split(separator: ":", maxSplits: 1)
        if parts.count != 2 || parts[1].isEmpty {
            throw MaggieError.deserializeError("invalid action: \(string)")
        }
        let part1 = String(parts[1])
        switch parts[0] {
        case "copy-to-clipboard":
            self = .CopyToClipboard(part1)
        case "launch-url":
            if let url = URL(string: part1) {
                self = .LaunchUrl(url)
            } else {
                throw MaggieError.deserializeError("failed parsing url: \(part1)")
            }
        case "push":
            self = .Push(part1, session)
        case "rpc":
            self = .Rpc(part1, session)
        default:
            throw MaggieError.deserializeError("unknown action: \(string)")
        }
    }
    
    func perform() {
        switch self {
        case let .CopyToClipboard(string):
            UIPasteboard.general.string = string
            // TODO: Show popver.
        case let .Pop(session):
            session.pop()
        case let .Push(key, session):
            session.push(pageKey: key)
        default:
            print("unimplemented")
        }
    }
}
