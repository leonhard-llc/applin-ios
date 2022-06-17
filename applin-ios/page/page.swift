import Foundation
import UIKit

protocol PageController: UIViewController {
    func isModal() -> Bool
    func allowBackSwipe() -> Bool
}

enum PageData: Equatable {
    case modal(ModalData)
    case markdownPage(MarkdownPageData)
    case navPage(NavPageData)
    case plainPage(PlainPageData)

    static func notFound() -> PageData {
        .navPage(NavPageData(
                title: "Not Found",
                widget: .text(TextData("Page not found."))
        ))
    }

    static func blankPage() -> PageData {
        .plainPage(PlainPageData(title: "Empty", .empty))
    }

    init(_ item: JsonItem, _ session: ApplinSession) throws {
        switch item.typ {
        case ModalKind.alert.typ():
            self = try .modal(ModalData(.alert, item, session))
        case ModalKind.info.typ():
            self = try .modal(ModalData(.info, item, session))
        case ModalKind.question.typ():
            self = try .modal(ModalData(.question, item, session))
        case MarkdownPageData.TYP:
            self = try .markdownPage(MarkdownPageData(item, session))
        case NavPageData.TYP:
            self = try .navPage(NavPageData(item, session))
        case PlainPageData.TYP:
            self = try .plainPage(PlainPageData(item, session))
        default:
            throw ApplinError.deserializeError("unexpected page 'typ' value: \(item.typ)")
        }
    }

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
}
