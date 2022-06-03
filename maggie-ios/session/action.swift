import Foundation
import UIKit

enum MaggieAction: Codable, Equatable, Hashable {
    case copyToClipboard(String)
    case launchUrl(URL)
    case logout
    case nothing
    case pop
    case push(String)
    case rpc(String)

    // swiftlint:disable cyclomatic_complexity
    init(_ string: String) throws {
        switch string {
        case "":
            throw MaggieError.deserializeError("action is empty")
        case "logout":
            self = .logout
            return
        case "nothing":
            self = .nothing
            return
        case "pop":
            self = .pop
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
            self = .copyToClipboard(part1)
        case "launch-url":
            if let url = URL(string: part1) {
                self = .launchUrl(url)
            } else {
                throw MaggieError.deserializeError("failed parsing url: \(part1)")
            }
        case "push":
            self = .push(part1)
        case "rpc":
            self = .rpc(part1)
        default:
            throw MaggieError.deserializeError("unknown action: \(string)")
        }
    }

    func toString() -> String {
        switch self {
        case let .copyToClipboard(value):
            return "copy-to-clipboard:\(value)"
        case let .launchUrl(value):
            return "launch-url:\(value)"
        case .logout:
            return "logout"
        case .nothing:
            return "nothing"
        case .pop:
            return "pop"
        case let .push(value):
            return "push:\(value)"
        case let .rpc(value):
            return "rpc:\(value)"
        }
    }
}
