import Foundation
import SwiftUI

// swiftlint:disable cyclomatic_complexity
enum MaggieWidget: Equatable, Hashable, Identifiable, View {
    case backButton(MaggieBackButton)
    case button(MaggieButton)
    indirect case column(MaggieColumn)
    case detailCell(MaggieDetailCell)
    case empty(MaggieEmpty)
    case errorDetails(MaggieErrorDetails)
    indirect case expand(MaggieExpand)
    indirect case horizontalScroll(MaggieHorizontalScroll)
    case image(MaggieImage)
    case list(MaggieList)
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
            self = try .image(MaggieImage(item))
        case MaggieList.TYP:
            self = try .list(MaggieList(item, session))
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
        case let .backButton(widget):
            return widget.toJsonItem()
        case let .button(widget):
            return widget.toJsonItem()
        case let .column(widget):
            return widget.toJsonItem()
        case let .detailCell(widget):
            return widget.toJsonItem()
        case .empty:
            return JsonItem(MaggieEmpty.TYP)
        case .errorDetails:
            return JsonItem(MaggieErrorDetails.TYP)
        case let .expand(widget):
            return widget.toJsonItem()
        case let .horizontalScroll(widget):
            return widget.toJsonItem()
        case let .image(widget):
            return widget.toJsonItem()
        case let .list(widget):
            return widget.toJsonItem()
        case let .row(widget):
            return widget.toJsonItem()
        case let .scroll(widget):
            return widget.toJsonItem()
        case .spacer:
            return JsonItem(MaggieSpacer.TYP)
        case .spinner:
            return JsonItem(MaggieSpinner.TYP)
        case let .tall(widget):
            return widget.toJsonItem()
        case let .text(widget):
            return widget.toJsonItem()
        case let .wide(widget):
            return widget.toJsonItem()
        }
    }

    var body: some View {
        switch self {
        case let .backButton(inner):
            return AnyView(inner)
        case let .button(inner):
            return AnyView(inner)
        case let .column(inner):
            return AnyView(inner)
        case let .detailCell(inner):
            return AnyView(inner)
        case let .empty(inner):
            return AnyView(inner)
        case let .errorDetails(inner):
            return AnyView(inner)
        case let .expand(inner):
            return AnyView(inner)
        case let .horizontalScroll(inner):
            return AnyView(inner)
        case let .image(inner):
            return AnyView(inner)
        case let .list(inner):
            return AnyView(inner)
        case let .row(inner):
            return AnyView(inner)
        case let .scroll(inner):
            return AnyView(inner)
        case let .spacer(inner):
            return AnyView(inner)
        case let .spinner(inner):
            return AnyView(inner)
        case let .tall(inner):
            return AnyView(inner)
        case let .text(inner):
            return AnyView(inner)
        case let .wide(inner):
            return AnyView(inner)
        }
    }

    var id: Int {
        var hasher = Hasher()
        hasher.combine(self)
        return hasher.finalize()
    }
}
