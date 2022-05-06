import Foundation
import SwiftUI

enum MaggieWidget: Equatable, Hashable, Identifiable, View {
    case BackButton(MaggieBackButton)
    case Button(MaggieButton)
    indirect case Column(MaggieColumn)
    case DetailCell(MaggieDetailCell)
    case Empty(MaggieEmpty)
    case ErrorDetails(MaggieErrorDetails)
    indirect case Expand(MaggieExpand)
    indirect case HorizontalScroll(MaggieHorizontalScroll)
    case Image(MaggieImage)
    indirect case Row(MaggieRow)
    indirect case Scroll(MaggieScroll)
    indirect case Spacer(MaggieSpacer)
    indirect case Spinner(MaggieSpinner)
    indirect case Tall(MaggieTall)
    case Text(MaggieText)
    indirect case Wide(MaggieWide)
    
    init(_ item: JsonItem, _ session: MaggieSession) throws {
        switch item.typ {
        case MaggieBackButton.TYP:
            self = try .BackButton(MaggieBackButton(item, session))
        case MaggieButton.TYP:
            self = try .Button(MaggieButton(item, session))
        case MaggieColumn.TYP:
            self = try .Column(MaggieColumn(item, session))
        case MaggieDetailCell.TYP:
            self = try .DetailCell(MaggieDetailCell(item, session))
        case MaggieEmpty.TYP:
            self = .Empty(MaggieEmpty())
        case MaggieErrorDetails.TYP:
            self = .ErrorDetails(MaggieErrorDetails(session))
        case MaggieExpand.TYP:
            self = try .Expand(MaggieExpand(item, session))
        case MaggieHorizontalScroll.TYP:
            self = try .HorizontalScroll(MaggieHorizontalScroll(item, session))
        case MaggieImage.TYP:
            self = try .Image(MaggieImage(item))
        case MaggieRow.TYP:
            self = try .Row(MaggieRow(item, session))
        case MaggieScroll.TYP:
            self = try .Scroll(MaggieScroll(item, session))
        case MaggieSpacer.TYP:
            self = .Spacer(MaggieSpacer())
        case MaggieSpinner.TYP:
            self = .Spinner(MaggieSpinner())
        case MaggieTall.TYP:
            self = try .Tall(MaggieTall(item, session))
        case MaggieText.TYP:
            self = try .Text(MaggieText(item))
        case MaggieWide.TYP:
            self = try .Wide(MaggieWide(item, session))
        default:
            throw MaggieError.deserializeError("unexpected widget 'typ' value: \(item.typ)")
        }
    }
    
    func toJsonItem() -> JsonItem {
        switch self {
        case let .BackButton(widget):
            return widget.toJsonItem()
        case let .Button(widget):
            return widget.toJsonItem()
        case let .Column(widget):
            return widget.toJsonItem()
        case let .DetailCell(widget):
            return widget.toJsonItem()
        case .Empty(_):
            return JsonItem(MaggieEmpty.TYP)
        case .ErrorDetails(_):
            return JsonItem(MaggieErrorDetails.TYP)
        case let .Expand(widget):
            return widget.toJsonItem()
        case let .HorizontalScroll(widget):
            return widget.toJsonItem()
        case let .Image(widget):
            return widget.toJsonItem()
        case let .Row(widget):
            return widget.toJsonItem()
        case let .Scroll(widget):
            return widget.toJsonItem()
        case .Spacer(_):
            return JsonItem(MaggieSpacer.TYP)
        case .Spinner(_):
            return JsonItem(MaggieSpinner.TYP)
        case let .Tall(widget):
            return widget.toJsonItem()
        case let .Text(widget):
            return widget.toJsonItem()
        case let .Wide(widget):
            return widget.toJsonItem()
        }
    }
    
    var body: some View {
        switch self {
        case let .BackButton(inner):
            return AnyView(inner)
        case let .Button(inner):
            return AnyView(inner)
        case let .Column(inner):
            return AnyView(inner)
        case let .DetailCell(inner):
            return AnyView(inner)
        case let .Empty(inner):
            return AnyView(inner)
        case let .ErrorDetails(inner):
            return AnyView(inner)
        case let .Expand(inner):
            return AnyView(inner)
        case let .HorizontalScroll(inner):
            return AnyView(inner)
        case let .Image(inner):
            return AnyView(inner)
        case let .Row(inner):
            return AnyView(inner)
        case let .Scroll(inner):
            return AnyView(inner)
        case let .Spacer(inner):
            return AnyView(inner)
        case let .Spinner(inner):
            return AnyView(inner)
        case let .Tall(inner):
            return AnyView(inner)
        case let .Text(inner):
            return AnyView(inner)
        case let .Wide(inner):
            return AnyView(inner)
        }
    }
    
    var id: Int {
        var hasher = Hasher()
        hasher.combine(self)
        return hasher.finalize()
    }
}
