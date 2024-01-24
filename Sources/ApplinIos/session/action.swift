import Foundation
import UIKit

public struct ModalButtonSpec: Equatable, Hashable {
    let text: String
    let actions: [ActionSpec]
}

public struct ModalActionSpec: Equatable, Hashable {
    let title: String
    let message: String?
    let buttons: [ModalButtonSpec]
}

public struct RpcActionSpec: Equatable, Hashable {
    let url: URL
    let on_user_error_poll: Bool?
}

public struct UploadPhotoActionSpec: Equatable, Hashable {
    let url: URL
    let aspect_ratio: Float32?
}

public indirect enum ActionSpec: CustomStringConvertible, Equatable, Hashable {
    case choosePhoto(UploadPhotoActionSpec)
    case copyToClipboard(String)
    case launchUrl(URL)
    case logout
    case poll
    case pop
    case push(String)
    // TODO: Add push-preload.
    case replaceAll(String)
    case rpc(RpcActionSpec)
    case stopActions
    case takePhoto(UploadPhotoActionSpec)
    case modal(ModalActionSpec)
    // TODO: Add a `confirm:MESSAGE` action.

    init(_ config: ApplinConfig, _ jsonAction: JsonAction) throws {
        switch jsonAction.typ {
        case "logout":
            self = .logout
        case "poll":
            self = .poll
        case "pop":
            self = .pop
        case "choose_photo":
            self = .choosePhoto(UploadPhotoActionSpec(
                    url: try jsonAction.requireRelativeUrl(config),
                    aspect_ratio: jsonAction.aspect_ratio
            ))
        case "copy_to_clipboard":
            self = .copyToClipboard(try jsonAction.requireStringValue())
        case "launch_url":
            self = .launchUrl(try jsonAction.requireUrl())
        case "modal":
            let buttons = try jsonAction.requireButtons().map({ jsonButton in
                ModalButtonSpec(
                        text: jsonButton.text,
                        actions: try jsonButton.actions.map({ jA in try ActionSpec(config, jA) })
                )
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
            self = .rpc(RpcActionSpec(
                    url: try jsonAction.requireRelativeUrl(config),
                    on_user_error_poll: jsonAction.on_user_error_poll
            ))
        case "stop_actions":
            self = .stopActions
        case "take_photo":
            self = .takePhoto(UploadPhotoActionSpec(
                    url: try jsonAction.requireRelativeUrl(config),
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
            jsonAction.buttons = spec.buttons.map({ b in
                JsonModalButton(
                        text: b.text,
                        actions: b.actions.map({ s in s.toJsonAction() })
                )
            })
            return jsonAction
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
        case let .rpc(spec):
            let jsonAction = JsonAction(typ: "rpc")
            jsonAction.url = spec.url.absoluteString
            jsonAction.on_user_error_poll = spec.on_user_error_poll
            return jsonAction
        case .stopActions:
            return JsonAction(typ: "stop_actions")
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
        case .poll:
            return "poll"
        case .pop:
            return "pop"
        case let .push(pageKey):
            return "push(\(pageKey))"
        case let .replaceAll(pageKey):
            return "replaceAll(\(pageKey))"
        case let .rpc(spec):
            return "rpc(\(spec.url.relativeString),on_user_error_poll=\(spec.on_user_error_poll?.description ?? "null")"
        case .stopActions:
            return "stop_actions"
        case let .takePhoto(spec):
            return "takePhoto(url=\(spec.url.absoluteString),aspect_ratio=\(spec.aspect_ratio?.description ?? "")"
        }
    }

    var showWorking: Bool {
        switch self {
        case .choosePhoto, .copyToClipboard, .launchUrl, .logout, .modal, .pop, .stopActions, .takePhoto:
            return false
        case .poll, .push, .replaceAll, .rpc:
            return true
        }
    }
}

extension Array where Element == ActionSpec {
    public var description: String {
        "[\(self.map({ action in action.description }).joined(separator: ","))]"
    }
}
