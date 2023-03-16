import Foundation
import UIKit

protocol PageController: UIViewController {
    func allowBackSwipe() -> Bool
    func klass() -> AnyClass
    func update(_ session: ApplinSession, _ cache: WidgetCache, _ state: ApplinState, _ newPageSpec: PageSpec, hasPrevPage: Bool)
}

enum PageSpec: CustomStringConvertible, Equatable {
    case modal(ModalSpec)
    case navPage(NavPageSpec)
    case plainPage(PlainPageSpec)

    init(_ config: ApplinConfig, pageKey: String, _ item: JsonItem) throws {
        switch item.typ {
        case ModalKind.alert.typ():
            self = try .modal(ModalSpec(pageKey: pageKey, .alert, item))
        case ModalKind.drawer.typ():
            self = try .modal(ModalSpec(pageKey: pageKey, .drawer, item))
        case NavPageSpec.TYP:
            self = try .navPage(NavPageSpec(config, pageKey: pageKey, item))
        case PlainPageSpec.TYP:
            self = try .plainPage(PlainPageSpec(config, pageKey: pageKey, item))
        default:
            throw ApplinError.appError("unexpected page 'typ' value: \(item.typ)")
        }
    }

    var connectionMode: ConnectionMode {
        switch self {
        case let .modal(inner):
            return inner.connectionMode
        case let .navPage(inner):
            return inner.connectionMode
        case let .plainPage(inner):
            return inner.connectionMode
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

    var description: String {
        switch self {
        case let .modal(inner):
            return "\(inner)"
        case let .navPage(inner):
            return "\(inner)"
        case let .plainPage(inner):
            return "\(inner)"
        }
    }
}
