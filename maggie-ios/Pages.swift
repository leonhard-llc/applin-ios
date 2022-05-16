import Foundation
import SwiftUI

enum MaggiePage: Equatable {
    case Modal(MaggieModal)
    case MarkdownPage(MaggieMarkdownPage)
    case NavPage(MaggieNavPage)
    case PlainPage(MaggiePlainPage)

    static func notFound() -> MaggiePage {
        return .NavPage(MaggieNavPage(
                title: "Not Found",
                widget: .Expand(MaggieExpand(
                        .Text(MaggieText("Page not found."))
                ))
        ))
    }

    static func blankPage() -> MaggiePage {
        return .PlainPage(MaggiePlainPage(
                title: "Empty",
                .Empty(MaggieEmpty())
        ))
    }

    init(_ item: JsonItem, _ session: MaggieSession) throws {
        switch item.typ {
        case ModalKind.Alert.typ():
            self = try .Modal(MaggieModal(.Alert, item, session))
        case ModalKind.Info.typ():
            self = try .Modal(MaggieModal(.Info, item, session))
        case ModalKind.Question.typ():
            self = try .Modal(MaggieModal(.Question, item, session))
        case MaggieMarkdownPage.TYP:
            self = try .MarkdownPage(MaggieMarkdownPage(item))
        case MaggieNavPage.TYP:
            self = try .NavPage(MaggieNavPage(item, session))
        case MaggiePlainPage.TYP:
            self = try .PlainPage(MaggiePlainPage(item, session))
        default:
            throw MaggieError.deserializeError("unexpected page 'typ' value: \(item.typ)")
        }
    }

    func toJsonItem() -> JsonItem {
        switch self {
        case let .Modal(inner):
            return inner.toJsonItem()
        case let .MarkdownPage(inner):
            return inner.toJsonItem()
        case let .NavPage(inner):
            return inner.toJsonItem()
        case let .PlainPage(inner):
            return inner.toJsonItem()
        }
    }

    var isModal: Bool {
        get {
            switch self {
            case .Modal(_):
                return true
            case .MarkdownPage(_), .NavPage(_), .PlainPage(_):
                return false
            }
        }
    }

    var asModal: MaggieModal? {
        get {
            switch self {
            case let .Modal(inner):
                return inner
            case .MarkdownPage(_), .NavPage(_), .PlainPage(_):
                return nil
            }
        }
    }

    var title: String? {
        get {
            switch self {
            case let .Modal(inner):
                return inner.title
            case let .MarkdownPage(inner):
                return inner.title
            case let .NavPage(inner):
                return inner.title
            case .PlainPage(_):
                return nil
            }
        }
    }

    public func toView(_ session: MaggieSession, hasPrevPage: Bool) -> AnyView {
        switch self {
        case let .Modal(inner):
            return inner.toView()
        case let .MarkdownPage(inner):
            return inner.toView(session, hasPrevPage: hasPrevPage)
        case let .NavPage(inner):
            return inner.toView(session, hasPrevPage: hasPrevPage)
        case let .PlainPage(inner):
            return inner.toView()
        }
    }

    //public func allowBackSwipe() -> Bool {
    //    switch self {
    //    case .Alert(_), .Confirmation(_), .MarkdownPage(_):
    //        return true
    //    case let .NavPage(inner):
    //        return inner.allowBackSwipe()
    //    case .PlainPage(_):
    //        return false
    //    }
    //}
}
