import Foundation
import UIKit

public struct ModalActionSpec: Codable, Equatable, Hashable {
    let title: String
    let message: String?
    let buttons: [String: [ActionSpec]]
}

public struct UploadPhotoActionSpec: Codable, Equatable, Hashable {
    let url: URL
    let aspect_ratio: Float32?
}

public indirect enum ActionSpec: Codable, CustomStringConvertible, Equatable, Hashable {
    case choosePhoto(UploadPhotoActionSpec)
    case copyToClipboard(String)
    case launchUrl(URL)
    case logout
    // TODO: Move on_user_error_poll to an attribute of the `rpc` action.
    case onUserErrorPoll
    case poll
    case pop
    case push(String)
    // TODO: Add push-preload.
    case replaceAll(String)
    case rpc(URL)
    case takePhoto(UploadPhotoActionSpec)
    case modal(ModalActionSpec)
    // TODO: Add a `confirm:MESSAGE` action.

    init(_ config: ApplinConfig, _ jsonAction: JsonAction) throws {
        switch jsonAction.typ {
        case "logout":
            self = .logout
        case "on_user_error_poll":
            self = .onUserErrorPoll
        case "poll":
            self = .poll
        case "pop":
            self = .pop
        case "choose_photo":
            self = .choosePhoto(UploadPhotoActionSpec(
                    url: try jsonAction.requireUrl(config),
                    aspect_ratio: jsonAction.aspect_ratio
            ))
        case "copy_to_clipboard":
            self = .copyToClipboard(try jsonAction.requireStringValue())
        case "launch_url":
            self = .launchUrl(try jsonAction.requireUrl(config))
        case "modal":
            let buttons = try jsonAction.requireButtons().mapValues({ jsonActionList in
                try jsonActionList.map({ jA in try ActionSpec(config, jA) })
            })
            if buttons.isEmpty {
                throw ApplinError.appError("empty modal.buttons")
            }
            self = .modal(ModalActionSpec(
                    title: try jsonAction.requireTitle(),
                    message: jsonAction.message,
                    buttons: buttons
            ))
        case "push":
            self = .push(try jsonAction.requirePage())
        case "replace_all":
            self = .replaceAll(try jsonAction.requirePage())
        case "rpc":
            self = .rpc(try jsonAction.requireUrl(config))
        case "take_photo":
            self = .takePhoto(UploadPhotoActionSpec(
                    url: try jsonAction.requireUrl(config),
                    aspect_ratio: jsonAction.aspect_ratio
            ))
        default:
            throw ApplinError.appError("unexpected action 'typ' value: \(jsonAction.typ)")
        }
    }

    func toJsonAction() -> JsonAction {
        switch self {
        case let .choosePhoto(spec):
            let jsonAction = JsonAction(typ: "choose_photo")
            jsonAction.aspect_ratio = spec.aspect_ratio
            jsonAction.url = spec.url.absoluteString
            return jsonAction
        case let .copyToClipboard(string_value):
            let jsonAction = JsonAction(typ: "copy_to_clipboard")
            jsonAction.string_value = string_value
            return jsonAction
        case let .launchUrl(url):
            let jsonAction = JsonAction(typ: "launch_url")
            jsonAction.url = url.absoluteString
            return jsonAction
        case .logout:
            return JsonAction(typ: "logout")
        case let .modal(spec):
            let jsonAction = JsonAction(typ: "modal")
            jsonAction.title = spec.title
            jsonAction.message = spec.message
            jsonAction.buttons = spec.buttons.mapValues({ s in s.map({ s in s.toJsonAction() }) })
            return jsonAction
        case .onUserErrorPoll:
            return JsonAction(typ: "on_user_error_poll")
        case .poll:
            return JsonAction(typ: "poll")
        case .pop:
            return JsonAction(typ: "pop")
        case let .push(pageKey):
            let jsonAction = JsonAction(typ: "push")
            jsonAction.page = pageKey
            return jsonAction
        case let .replaceAll(pageKey):
            let jsonAction = JsonAction(typ: "replace_all")
            jsonAction.page = pageKey
            return jsonAction
        case let .rpc(url):
            let jsonAction = JsonAction(typ: "rpc")
            jsonAction.url = url.absoluteString
            return jsonAction
        case let .takePhoto(spec):
            let jsonAction = JsonAction(typ: "take_photo")
            jsonAction.aspect_ratio = spec.aspect_ratio
            jsonAction.url = spec.url.absoluteString
            return jsonAction
        }
    }

    public var description: String {
        switch self {
        case let .choosePhoto(spec):
            return "choosePhoto(url=\(spec.url.relativeString),aspect_ratio=\(spec.aspect_ratio?.description ?? "")"
        case let .copyToClipboard(string_value):
            return "copyToClipboard(\(string_value))"
        case let .launchUrl(url):
            return "launchUrl(\(url.relativeString))"
        case .logout:
            return "logout"
        case let .modal(spec):
            return "modal(title=\(spec.title.debug()),message=\(spec.message?.debug() ?? ""),buttons=\(spec.buttons))"
        case .onUserErrorPoll:
            return "on_user_error_poll"
        case .poll:
            return "poll"
        case .pop:
            return "pop"
        case let .push(pageKey):
            return "push(\(pageKey))"
        case let .replaceAll(pageKey):
            return "replaceAll(\(pageKey))"
        case let .rpc(url):
            return "rpc(\(url.relativeString))"
        case let .takePhoto(spec):
            return "takePhoto(url=\(spec.url.absoluteString),aspect_ratio=\(spec.aspect_ratio?.description ?? "")"
        }
    }

    var showWorking: Bool {
        switch self {
        case .choosePhoto, .copyToClipboard, .launchUrl, .logout, .modal, .pop, .takePhoto:
            return false
        case .onUserErrorPoll, .poll, .push, .replaceAll, .rpc:
            return true
        }
    }
}

extension Array where Element == ActionSpec {
    public var description: String {
        "[\(self.map({ action in action.description }).joined(separator: ","))]"
    }
}
