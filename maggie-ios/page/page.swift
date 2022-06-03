import Foundation
import UIKit

enum PageController: Equatable {
//    case modal(ModalController)
//    case markdownPage(MarkdownPageController)
    case navPage(NavPageController)
    case plainPage(PlainPageController)

    init(_ navController: NavigationController, _ session: MaggieSession, _ page: MaggiePage, _ hasPrev: Bool) {
        switch page {
        case let .navPage(inner):
            self = .navPage(NavPageController(navController, session, inner, hasPrev))
        case let .plainPage(inner):
            self = .plainPage(PlainPageController(session, inner))
        default:
            fatalError("unimplemented")
        }
    }

    mutating func setPage(
            _ navController: NavigationController,
            _ session: MaggieSession,
            _ page: MaggiePage,
            _ hasPrev: Bool
    ) {
        if case let .plainPage(controller) = self, case let .plainPage(maggiePlainPage) = page {
            controller.setPage(maggiePlainPage)
        } else if case let .navPage(controller) = self, case let .navPage(maggieNavPage) = page {
            controller.setPage(maggieNavPage, hasPrev)
        } else {
            self = PageController(navController, session, page, hasPrev)
        }
    }

    func inner() -> UIViewController {
        switch self {
        case let .navPage(inner):
            return inner
        case let .plainPage(inner):
            return inner
        }
    }

    func showNavigationBar() -> Bool {
        switch self {
        case .navPage:
            return true
        case .plainPage:
            return false
        }
    }
}

enum MaggiePage: Equatable {
    case modal(MaggieModal)
    case markdownPage(MaggieMarkdownPage)
    case navPage(MaggieNavPage)
    case plainPage(MaggiePlainPage)

    static func notFound() -> MaggiePage {
        .navPage(MaggieNavPage(
                title: "Not Found",
                widget: .expand(MaggieExpand(
                        .text(MaggieText("Page not found."))
                ))
        ))
    }

    static func blankPage() -> MaggiePage {
        .plainPage(MaggiePlainPage(
                title: "Empty",
                .empty(MaggieEmpty())
        ))
    }

    init(_ item: JsonItem, _ session: MaggieSession) throws {
        switch item.typ {
        case ModalKind.alert.typ():
            self = try .modal(MaggieModal(.alert, item, session))
        case ModalKind.info.typ():
            self = try .modal(MaggieModal(.info, item, session))
        case ModalKind.question.typ():
            self = try .modal(MaggieModal(.question, item, session))
        case MaggieMarkdownPage.TYP:
            self = try .markdownPage(MaggieMarkdownPage(item, session))
        case MaggieNavPage.TYP:
            self = try .navPage(MaggieNavPage(item, session))
        case MaggiePlainPage.TYP:
            self = try .plainPage(MaggiePlainPage(item, session))
        default:
            throw MaggieError.deserializeError("unexpected page 'typ' value: \(item.typ)")
        }
    }

    // TODO: Use an interface to eliminate this method and others.
    func toJsonItem() -> JsonItem {
        switch self {
        case let .modal(inner):
            return inner.toJsonItem()
        case let .markdownPage(inner):
            return inner.toJsonItem()
        case let .navPage(inner):
            return inner.toJsonItem()
        case let .plainPage(inner):
            return inner.toJsonItem()
        }
    }

    var isModal: Bool {
        switch self {
        case .modal:
            return true
        case .markdownPage, .navPage, .plainPage:
            return false
        }
    }

    var asModal: MaggieModal? {
        switch self {
        case let .modal(inner):
            return inner
        case .markdownPage, .navPage, .plainPage:
            return nil
        }
    }

    var title: String? {
        switch self {
        case let .modal(inner):
            return inner.title
        case let .markdownPage(inner):
            return inner.title
        case let .navPage(inner):
            return inner.title
        case .plainPage:
            return nil
        }
    }

    public func allowBackSwipe() -> Bool {
        switch self {
        case .markdownPage, .modal:
            return true
        case let .navPage(inner):
            return inner.allowBackSwipe()
        case let .plainPage(inner):
            return inner.allowBackSwipe()
        }
    }
}
