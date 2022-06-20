import Foundation
import UIKit

protocol WidgetProto {
    func keys() -> [String]
}

// swiftlint:disable cyclomatic_complexity
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

    // TODO: Use an interface to eliminate this method and others.
    func toJsonItem() -> JsonItem {
        switch self {
        case let .backButton(inner):
            return inner.toJsonItem()
        case let .button(inner):
            return inner.toJsonItem()
        case let .checkbox(inner):
            return inner.toJsonItem()
        case let .column(inner):
            return inner.toJsonItem()
        case .empty:
            return EmptyData.toJsonItem()
        case let .scroll(inner):
            return inner.toJsonItem()
        case let .text(inner):
            return inner.toJsonItem()
        }
    }

    func getView(_ session: ApplinSession, _ widgetCache: WidgetCache) -> UIView {
        switch self {
        case let .backButton(inner):
            return ButtonData(inner.actions, text: "Back").getView(session, widgetCache)
        case let .button(inner):
            return inner.getView(session, widgetCache)
        case let .checkbox(inner):
            return inner.getView(session, widgetCache)
        case let .column(inner):
            return inner.getView(session, widgetCache)
        case .empty:
            return EmptyData.getView()
        case let .text(inner):
            return inner.getView(session, widgetCache)
        case let .scroll(inner):
            return inner.getView(session, widgetCache)
        default:
            print("widget unimplemented: \(self)")
            return UIView()
        }
    }
}
