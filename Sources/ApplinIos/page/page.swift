import Foundation
import UIKit

class PageContext {
    weak var cache: WidgetCache?
    let hasPrevPage: Bool
    let pageKey: String
    weak var foregroundPoller: ForegroundPoller?
    weak var pageStack: PageStack?
    weak var varSet: VarSet?

    init(_ cache: WidgetCache?,
         hasPrevPage: Bool,
         pageKey: String,
         _ foregroundPoller: ForegroundPoller?,
         _ pageStack: PageStack?,
         _ varSet: VarSet?
    ) {
        self.cache = cache
        self.hasPrevPage = hasPrevPage
        self.pageKey = pageKey
        self.foregroundPoller = foregroundPoller
        self.pageStack = pageStack
        self.varSet = varSet
    }
}

protocol PageController: UIViewController {
    func allowBackSwipe() -> Bool
    func klass() -> AnyClass
    func update(_ ctx: PageContext, _ newPageSpec: PageSpec)
}

public protocol ToPageSpec {
    func toPageSpec() -> PageSpec
}

public enum PageSpec: CustomStringConvertible, Equatable, ToPageSpec {
    case loadingPage
    case navPage(NavPageSpec)
    case plainPage(PlainPageSpec)

    init(_ config: ApplinConfig, _ item: JsonItem) throws {
        switch item.typ {
        case NavPageSpec.TYP:
            self = try .navPage(NavPageSpec(config, item))
        case PlainPageSpec.TYP:
            self = try .plainPage(PlainPageSpec(config, item))
        default:
            throw ApplinError.appError("unexpected page 'typ' value: \(item.typ)")
        }
    }

    var connectionMode: ConnectionMode {
        switch self {
        case .loadingPage:
            return .disconnect
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
        case let .navPage(inner):
            return "\(inner)"
        case let .plainPage(inner):
            return "\(inner)"
        }
    }

    public var isEphemeral: Bool {
        switch self {
        case .loadingPage:
            return true
        case let .navPage(inner):
            return inner.ephemeral ?? false
        case let .plainPage(inner):
            return inner.ephemeral ?? false
        }
    }

    public func toPageSpec() -> PageSpec {
        self
    }

    func vars() -> [(String, Var)] {
        switch self {
        case .loadingPage:
            return []
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
        case let .navPage(inner):
            return inner.visitActions(f)
        case let .plainPage(inner):
            return inner.visitActions(f)
        }
    }
}
