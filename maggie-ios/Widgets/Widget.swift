import Foundation
import UIKit

// swiftlint:disable cyclomatic_complexity
enum MaggieWidget: Equatable, Hashable, Identifiable {
    case backButton(MaggieBackButton)
    case button(MaggieButton)
    indirect case column(MaggieColumn)
    case detailCell(MaggieDetailCell)
    case empty(MaggieEmpty)
    case errorDetails(MaggieErrorDetails)
    indirect case expand(MaggieExpand)
    indirect case horizontalScroll(MaggieHorizontalScroll)
    case image(MaggieImage)
    indirect case row(MaggieRow)
    indirect case scroll(MaggieScroll)
    indirect case spacer(MaggieSpacer)
    indirect case spinner(MaggieSpinner)
    indirect case tall(MaggieTall)
    case text(MaggieText)
    indirect case wide(MaggieWide)

    init(_ item: JsonItem, _ session: MaggieSession) throws {
        switch item.typ {
        case MaggieBackButton.TYP:
            self = try .backButton(MaggieBackButton(item, session))
        case MaggieButton.TYP:
            self = try .button(MaggieButton(item, session))
        case MaggieColumn.TYP:
            self = try .column(MaggieColumn(item, session))
        case MaggieDetailCell.TYP:
            self = try .detailCell(MaggieDetailCell(item, session))
        case MaggieEmpty.TYP:
            self = .empty(MaggieEmpty())
        case MaggieErrorDetails.TYP:
            self = .errorDetails(MaggieErrorDetails(session))
        case MaggieExpand.TYP:
            self = try .expand(MaggieExpand(item, session))
        case MaggieHorizontalScroll.TYP:
            self = try .horizontalScroll(MaggieHorizontalScroll(item, session))
        case MaggieImage.TYP:
            self = try .image(MaggieImage(item, session))
        case MaggieRow.TYP:
            self = try .row(MaggieRow(item, session))
        case MaggieScroll.TYP:
            self = try .scroll(MaggieScroll(item, session))
        case MaggieSpacer.TYP:
            self = .spacer(MaggieSpacer())
        case MaggieSpinner.TYP:
            self = .spinner(MaggieSpinner())
        case MaggieTall.TYP:
            self = try .tall(MaggieTall(item, session))
        case MaggieText.TYP:
            self = try .text(MaggieText(item))
        case MaggieWide.TYP:
            self = try .wide(MaggieWide(item, session))
        default:
            throw MaggieError.deserializeError("unexpected widget 'typ' value: \(item.typ)")
        }
    }

    func toJsonItem() -> JsonItem {
        switch self {
        case let .backButton(inner):
            return inner.toJsonItem()
        case let .button(inner):
            return inner.toJsonItem()
        case let .column(inner):
            return inner.toJsonItem()
        case let .detailCell(inner):
            return inner.toJsonItem()
        case .empty:
            return JsonItem(MaggieEmpty.TYP)
        case .errorDetails:
            return JsonItem(MaggieErrorDetails.TYP)
        case let .expand(inner):
            return inner.toJsonItem()
        case let .horizontalScroll(inner):
            return inner.toJsonItem()
        case let .image(inner):
            return inner.toJsonItem()
        case let .row(inner):
            return inner.toJsonItem()
        case let .scroll(inner):
            return inner.toJsonItem()
        case .spacer:
            return JsonItem(MaggieSpacer.TYP)
        case .spinner:
            return JsonItem(MaggieSpinner.TYP)
        case let .tall(inner):
            return inner.toJsonItem()
        case let .text(inner):
            return inner.toJsonItem()
        case let .wide(inner):
            return inner.toJsonItem()
        }
    }

    var id: Int {
        var hasher = Hasher()
        hasher.combine(self)
        return hasher.finalize()
    }

    func makeView(_ session: MaggieSession) -> UIView {
        switch self {
        case let .button(inner):
            return inner.makeView(session)
        case let .column(inner):
            return inner.makeView(session)
        case let .empty(inner):
            return inner.makeView()
        case let .errorDetails(inner):
            return inner.makeView()
        case let .expand(inner):
            return inner.makeView(session)
        case let .horizontalScroll(inner):
            return inner.makeView(session)
        case let .spacer(inner):
            return inner.makeView()
        case let .tall(inner):
            return inner.makeView(session)
        case let .text(inner):
            return inner.makeView()
        case let .wide(inner):
            return inner.makeView(session)
        default:
            fatalError("unimplemented")
        }
    }
}
