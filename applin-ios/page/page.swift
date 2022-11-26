import Foundation
import UIKit

protocol PageController: UIViewController {
    func allowBackSwipe() -> Bool
    func klass() -> AnyClass
    func update(_ session: ApplinSession, _ cache: WidgetCache, _ newPageSpec: PageSpec, hasPrevPage: Bool)
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

    func controllerClass() -> AnyClass {
        switch self {
        case .modal:
            print("FATAL: PageSpec.controllerClass() called on \(self)")
            abort() // This should never happen.
        case let .navPage(inner):
            return inner.controllerClass()
        case let .plainPage(inner):
            return inner.controllerClass()
        }
    }

    func newController(_ navController: NavigationController?, _ session: ApplinSession?, _ cache: WidgetCache) -> PageController {
        switch self {
        case .modal:
            print("FATAL: PageSpec.newController() called on \(self)")
            abort() // This should never happen.
        case let .navPage(inner):
            return inner.newController(navController, session, cache)
        case let .plainPage(inner):
            return inner.newController()
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
