import Foundation
import UIKit

protocol WidgetProto {
    func keys() -> [String]
}

protocol WidgetDataProto {
    func toJsonItem() -> JsonItem
    func keys() -> [String]
    func getTapActions() -> [ActionData]?
    func getView(_ session: ApplinSession, _ widgetCache: WidgetCache) -> UIView
}

enum WidgetData: Equatable, Hashable {
    case backButton(BackButtonData)
    case button(ButtonData)
    case checkbox(CheckboxData)
    indirect case column(ColumnData)
    case empty(EmptyData)
    case errorDetails(ErrorDetailsData)
    case form(FormData)
    case formDetail(FormDetailData)
    indirect case scroll(ScrollData)
    case formSection(FormSectionData)
    case text(TextData)

    init(_ item: JsonItem, _ session: ApplinSession) throws {
        switch item.typ {
        case ButtonData.TYP:
            self = try .button(ButtonData(item))
        case CheckboxData.TYP:
            self = try .checkbox(CheckboxData(item, session))
        case ColumnData.TYP:
            self = try .column(ColumnData(item, session))
        case EmptyData.TYP:
            self = .empty(EmptyData())
        case ErrorDetailsData.TYP:
            self = .errorDetails(ErrorDetailsData())
        case FormData.TYP:
            self = try .form(FormData(item, session))
        case FormDetailData.TYP:
            self = try .formDetail(FormDetailData(item, session))
        case ScrollData.TYP:
            self = try .scroll(ScrollData(item, session))
        case FormSectionData.TYP:
            self = try .formSection(FormSectionData(item, session))
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
        case let .empty(inner):
            return inner
        case let .errorDetails(inner):
            return inner
        case let .form(inner):
            return inner
        case let .formDetail(inner):
            return inner
        case let .scroll(inner):
            return inner
        case let .formSection(inner):
            return inner
        case let .text(inner):
            return inner
        }
    }
}
