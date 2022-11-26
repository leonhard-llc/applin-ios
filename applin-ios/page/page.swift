import Foundation
import UIKit

protocol PageController: UIViewController {
    func allowBackSwipe() -> Bool
    func isModal() -> Bool
}

enum PageSpec: Equatable {
    case modal(ModalSpec)
    case navPage(NavPageSpec)
    case plainPage(PlainPageSpec)

    init(_ session: ApplinSession, pageKey: String, _ item: JsonItem) throws {
        switch item.typ {
        case ModalKind.alert.typ():
            self = try .modal(ModalSpec(pageKey: pageKey, .alert, item))
        case ModalKind.drawer.typ():
            self = try .modal(ModalSpec(pageKey: pageKey, .drawer, item))
        case NavPageSpec.TYP:
            self = try .navPage(NavPageSpec(session, pageKey: pageKey, item))
        case PlainPageSpec.TYP:
            self = try .plainPage(PlainPageSpec(session, pageKey: pageKey, item))
        default:
            throw ApplinError.deserializeError("unexpected page 'typ' value: \(item.typ)")
        }
    }

    var connectionMode: ConnectionMode {
        get {
            switch self {
            case let .modal(inner):
                return inner.connectionMode
            case let .navPage(inner):
                return inner.connectionMode
            case let .plainPage(inner):
                return inner.connectionMode
            }
        }
    }

    func toJsonItem() -> JsonItem {
        switch self {
        case let .modal(inner):
            return inner.toJsonItem()
        case let .navPage(inner):
            return inner.toJsonItem()
        case let .plainPage(inner):
            return inner.toJsonItem()
        }
    }

    func vars() -> [(String, Var)] {
        switch self {
        case let .modal(inner):
            return inner.vars()
        case let .navPage(inner):
            return inner.vars()
        case let .plainPage(inner):
            return inner.vars()
        }
    }
}
