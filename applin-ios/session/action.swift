import Foundation
import UIKit

enum ActionSpec: Codable, CustomStringConvertible, Equatable, Hashable {
    case choosePhoto(String)
    case copyToClipboard(String)
    case launchUrl(URL)
    case logout
    case nothing
    case poll
    case pop
    case push(String)
    case pushPreloaded(String)
    case replaceAll(String)
    case rpc(String)
    case takePhoto(String)

    // swiftlint:disable cyclomatic_complexity
    init(_ string: String) throws {
        switch string {
        case "":
            throw ApplinError.appError("action is empty")
        case "logout":
            self = .logout
            return
        case "nothing":
            self = .nothing
            return
        case "poll":
            self = .poll
            return
        case "pop":
            self = .pop
            return
        default:
            break
        }
        let parts = string.split(separator: ":", maxSplits: 1)
        if parts.count != 2 || parts[1].isEmpty {
            throw ApplinError.appError("invalid action: \(string)")
        }
        let part1 = String(parts[1])
        switch parts[0] {
        case "choose-photo":
            self = .choosePhoto(part1)
        case "copy-to-clipboard":
            self = .copyToClipboard(part1)
        case "launch-url":
            if let url = URL(string: part1) {
                self = .launchUrl(url)
            } else {
                throw ApplinError.appError("failed parsing url: \(part1)")
            }
        case "push":
            self = .push(part1)
        case "push-preloaded":
            self = .push(part1)
        case "replace-all":
            self = .replaceAll(part1)
        case "rpc":
            self = .rpc(part1)
        case "take-photo":
            self = .takePhoto(part1)
        default:
            throw ApplinError.appError("unknown action: \(string)")
        }
    }

    func toString() -> String {
        switch self {
        case let .choosePhoto(value):
            return "choose-photo:\(value)"
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
        case .poll:
            return "poll"
        case let .push(value):
            return "push:\(value)"
        case let .pushPreloaded(value):
            return "push-preloaded:\(value)"
        case let .replaceAll(value):
            return "replace-all:\(value)"
        case let .rpc(value):
            return "rpc:\(value)"
        case let .takePhoto(value):
            return "take-photo:\(value)"
        }
    }

    var description: String {
        switch self {
        case let .choosePhoto(value):
            return "choosePhoto(\(value))"
        case let .copyToClipboard(value):
            return "copyToClipboard(\(value))"
        case let .launchUrl(value):
            return "launchUrl(\(value))"
        case .logout:
            return "logout"
        case .nothing:
            return "nothing"
        case .pop:
            return "pop"
        case .poll:
            return "poll"
        case let .push(value):
            return "push(\(value))"
        case let .pushPreloaded(value):
            return "pushPreloaded(\(value))"
        case let .replaceAll(value):
            return "replaceAll(\(value))"
        case let .rpc(value):
            return "rpc(\(value))"
        case let .takePhoto(value):
            return "takePhoto(\(value))"
        }
    }
}

extension Array where Element == ActionSpec {
    func toString() -> String {
        "[\(self.map({ action in action.toString() }).joined(separator: ","))]"
    }
}
