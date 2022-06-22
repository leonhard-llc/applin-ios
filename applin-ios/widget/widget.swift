import Foundation
import UIKit

protocol WidgetProto {
    func keys() -> [String]
}

protocol WidgetDataProto {
    func toJsonItem() -> JsonItem
    func keys() -> [String]
    func getView(_ session: ApplinSession, _ widgetCache: WidgetCache) -> UIView
}

enum WidgetData: Equatable, Hashable {
    case backButton(BackButtonData)
    case button(ButtonData)
    case checkbox(CheckboxData)
    indirect case column(ColumnData)
    case empty
    indirect case scroll(ScrollData)
    case text(TextData)

    init(_ item: JsonItem, _ session: ApplinSession) throws {
        switch item.typ {
        case ButtonData.TYP:
            self = try .button(ButtonData(item))
        case CheckboxData.TYP:
            self = try .checkbox(CheckboxData(item, session))
        case ColumnData.TYP:
            self = try .column(ColumnData(item, session))
        case ScrollData.TYP:
            self = try .scroll(ScrollData(item, session))
        case TextData.TYP:
            self = try .text(TextData(item))
        default:
            throw ApplinError.deserializeError("unexpected widget 'typ' value: \(item.typ)")
        }
    }

    func inner() -> WidgetDataProto {
        switch self {
        case let .backButton(inner):
            return inner
        case let .button(inner):
            return inner
        case let .checkbox(inner):
            return inner
        case let .column(inner):
            return inner
        case .empty:
            return EmptyData()
        case let .scroll(inner):
            return inner
        case let .text(inner):
            return inner
        }
    }
}
