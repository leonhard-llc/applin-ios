import Foundation
import UIKit

protocol PageController: UIViewController {
    func allowBackSwipe() -> Bool
    func isModal() -> Bool
}

protocol PageDataProto {
    var connectionMode: ConnectionMode { get }
    func toJsonItem() -> JsonItem
}

enum PageData: Equatable {
    case modal(ModalData)
    case navPage(NavPageData)
    case plainPage(PlainPageData)

    static func notFound() -> PageData {
        .navPage(NavPageData(
                title: "Not Found",
                widget: .text(TextData("Page not found."))
        ))
    }

    static func blankPage() -> PageData {
        .plainPage(PlainPageData.blank())
    }

    init(_ item: JsonItem, _ session: ApplinSession) throws {
        switch item.typ {
        case ModalKind.alert.typ():
            self = try .modal(ModalData(.alert, item))
        case ModalKind.drawer.typ():
            self = try .modal(ModalData(.drawer, item))
        case NavPageData.TYP:
            self = try .navPage(NavPageData(item, session))
        case PlainPageData.TYP:
            self = try .plainPage(PlainPageData(item, session))
        default:
            throw ApplinError.deserializeError("unexpected page 'typ' value: \(item.typ)")
        }
    }

    func inner() -> PageDataProto {
        switch self {
        case let .modal(inner):
            return inner
        case let .navPage(inner):
            return inner
        case let .plainPage(inner):
            return inner
        }
    }
}
