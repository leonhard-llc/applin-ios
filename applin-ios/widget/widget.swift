import Foundation
import UIKit

enum WidgetPriority {
    case focusable
    case stateful
    case stateless
}

protocol WidgetProto {
    func getView() -> UIView
    func isFocused(_ session: ApplinSession, _ data: WidgetData) -> Bool
    func update(_ session: ApplinSession, _ data: WidgetData, _ subs: [WidgetProto]) throws
}

protocol WidgetDataProto {
    func toJsonItem() -> JsonItem
    func keys() -> [String]
    func priority() -> WidgetPriority
    func subs() -> [WidgetData]
    func vars() -> [(String, Var)]
    func widgetClass() -> AnyClass
    func widget() -> WidgetProto
}

enum WidgetData: Equatable, Hashable {
    case backButton(BackButtonData)
    case button(ButtonData)
    indirect case column(ColumnData)
    case empty(EmptyData)
    case errorDetails(ErrorDetailsData)
    //case form(FormData)
    //case formButton(FormButtonData)
    //case formCheckbox(FormCheckboxData)
    //case formDetail(FormDetailData)
    //case formError(FormErrorData)
    //case formSection(FormSectionData)
    //case formTextfield(FormTextfieldData)
    case textfield(TextfieldData)
    indirect case scroll(ScrollData)
    case text(TextData)

    // TODO(mleonhard) Try to remove pageKey param.

    init(pageKey: String, _ item: JsonItem) throws {
        switch item.typ {
        case BackButtonData.TYP:
            self = try .backButton(BackButtonData(pageKey: pageKey, item))
        case ButtonData.TYP:
            self = try .button(ButtonData(pageKey: pageKey, item))
        case ColumnData.TYP:
            self = try .column(ColumnData(pageKey: pageKey, item))
        case EmptyData.TYP:
            self = .empty(EmptyData())
        case ErrorDetailsData.TYP:
            self = .errorDetails(ErrorDetailsData())
                //case FormData.TYP:
                //    self = try .form(FormData(pageKey: pageKey, item))
                //case FormCheckboxData.TYP:
                //    self = try .formCheckbox(FormCheckboxData(pageKey: pageKey, item))
                //case FormButtonData.TYP:
                //    self = try .formButton(FormButtonData(pageKey: pageKey, item))
                //case FormDetailData.TYP:
                //    self = try .formDetail(FormDetailData(pageKey: pageKey, item))
                //case FormErrorData.TYP:
                //    self = try .formError(FormErrorData(item))
                //case FormSectionData.TYP:
                //    self = try .formSection(FormSectionData(pageKey: pageKey, item))
                //case FormTextfieldData.TYP:
                //    self = try .formTextfield(FormTextfieldData(pageKey: pageKey, item))
        case TextfieldData.TYP:
            self = try .textfield(TextfieldData(pageKey: pageKey, item))
        case ScrollData.TYP:
            self = try .scroll(ScrollData(pageKey: pageKey, item))
        case TextData.TYP:
            self = try .text(TextData(item))
        default:
            throw ApplinError.deserializeError("unexpected widget 'typ' value: \(item.typ)")
        }
    }

    // We can get rid of this if Swift ever gets named enum associated values.

    func inner() -> WidgetDataProto {
        switch self {
        case let .backButton(inner):
            return inner
        case let .button(inner):
            return inner
        case let .column(inner):
            return inner
        case let .empty(inner):
            return inner
        case let .errorDetails(inner):
            return inner
                //case let .form(inner):
                //    return inner
                //case let .formButton(inner):
                //    return inner
                //case let .formCheckbox(inner):
                //    return inner
                //case let .formDetail(inner):
                //    return inner
                //case let .formError(inner):
                //    return inner
                //case let .formSection(inner):
                //    return inner
                //case let .formTextField(inner):
                //    return inner
        case let .textfield(inner):
            return inner
        case let .scroll(inner):
            return inner
        case let .text(inner):
            return inner
        }
    }
}
