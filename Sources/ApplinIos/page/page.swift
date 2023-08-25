import Foundation
import UIKit

class PageContext {
    weak var cache: WidgetCache?
    let hasPrevPage: Bool
    let pageKey: String
    weak var pageStack: PageStack?
    weak var serverCaller: ServerCaller?
    weak var varSet: VarSet?

    init(_ cache: WidgetCache, hasPrevPage: Bool, pageKey: String, _ pageStack: PageStack, _ varSet: VarSet) {
        self.cache = cache
        self.hasPrevPage = hasPrevPage
        self.pageKey = pageKey
        self.pageStack = pageStack
        self.varSet = varSet
    }
}

protocol PageController: UIViewController {
    func allowBackSwipe() -> Bool
    func klass() -> AnyClass
    func update(_ ctx: PageContext, _ newPageSpec: PageSpec)
}

public enum PageSpec: CustomStringConvertible, Equatable {
    case loadingPage
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
            self = try .navPage(NavPageSpec(config, item))
        case PlainPageSpec.TYP:
            self = try .plainPage(PlainPageSpec(config, pageKey: pageKey, item))
        default:
            throw ApplinError.appError("unexpected page 'typ' value: \(item.typ)")
        }
    }

    var connectionMode: ConnectionMode {
        switch self {
        case .loadingPage:
            return .disconnect
        case let .modal(inner):
            return inner.connectionMode
        case let .navPage(inner):
            return inner.connectionMode
        case let .plainPage(inner):
            return inner.connectionMode
        }
    }

    public var description: String {
        switch self {
        case .loadingPage:
            return "loadingPage"
        case let .modal(inner):
            return "\(inner)"
        case let .navPage(inner):
            return "\(inner)"
        case let .plainPage(inner):
            return "\(inner)"
        }
    }

    func vars() -> [(String, Var)] {
        switch self {
        case .loadingPage:
            return []
        case let .modal(inner):
            return inner.vars()
        case let .navPage(inner):
            return inner.vars()
        case let .plainPage(inner):
            return inner.vars()
        }
    }

    func visitActions(_ f: (ActionSpec) -> ()) {
        switch self {
        case .loadingPage:
            break
        case let .modal(inner):
            return inner.visitActions(f)
        case let .navPage(inner):
            return inner.visitActions(f)
        case let .plainPage(inner):
            return inner.visitActions(f)
        }
    }
}
