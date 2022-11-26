import Foundation
import UIKit

let FORM_CELL_HEIGHT = 44.0

enum WidgetPriority {
    case focusable
    case stateful
    case stateless
}

protocol Widget {
    func getView() -> UIView
    func isFocused() -> Bool
    func update(_ session: ApplinSession, _ data: Spec, _ subs: [Widget]) throws
}

// Spec is an immutable tree of widget specifications.

//
// It is a reference-counted wrapper around the enum, to prevent unnecessary copies of the widget tree.
// This changes algorithms that would take O(n^2) memory into O(n).
class Spec: Equatable, Hashable {
    enum Value: Equatable, Hashable {
        case applinLastErrorText(ApplinLastErrorTextData)
        case backButton(BackButtonData)
        case button(ButtonData)
        case checkbox(CheckboxData)
        indirect case column(ColumnData)
        case empty(EmptyData)
        case errorText(ErrorTextData)
        case form(FormData)
        case formButton(FormButtonData)
        case formSection(FormSectionData)
        case formTextfield(FormTextfieldData)
        case navButton(NavButtonData)
        case textfield(TextfieldData)
        indirect case scroll(ScrollData)
        case text(TextData)
    }

    static func ==(lhs: Spec, rhs: Spec) -> Bool {
        lhs.value == rhs.value
    }

    public let value: Value

    init(_ value: Value) {
        self.value = value
    }

    init(_ session: ApplinSession?, pageKey: String, _ item: JsonItem) throws {
        switch item.typ {
        case ApplinLastErrorTextData.TYP:
            self.value = .applinLastErrorText(ApplinLastErrorTextData())
        case BackButtonData.TYP:
            self.value = .backButton(try BackButtonData(pageKey: pageKey, item))
        case ButtonData.TYP:
            self.value = .button(try ButtonData(pageKey: pageKey, item))
        case CheckboxData.TYP:
            self.value = .checkbox(try CheckboxData(pageKey: pageKey, item))
        case ColumnData.TYP:
            self.value = .column(try ColumnData(session, pageKey: pageKey, item))
        case EmptyData.TYP:
            self.value = .empty(EmptyData())
        case ErrorTextData.TYP:
            self.value = .errorText(try ErrorTextData(item))
        case FormData.TYP:
            self.value = .form(try FormData(session, pageKey: pageKey, item))
        case FormButtonData.TYP:
            self.value = .formButton(try FormButtonData(pageKey: pageKey, item))
        case FormSectionData.TYP:
            self.value = .formSection(try FormSectionData(session, pageKey: pageKey, item))
        case FormTextfieldData.TYP:
            self.value = .formTextfield(try FormTextfieldData(pageKey: pageKey, item))
        case NavButtonData.TYP:
            self.value = .navButton(try NavButtonData(session, pageKey: pageKey, item))
        case TextfieldData.TYP:
            self.value = .textfield(try TextfieldData(pageKey: pageKey, item))
        case ScrollData.TYP:
            self.value = .scroll(try ScrollData(session, pageKey: pageKey, item))
        case TextData.TYP:
            self.value = .text(try TextData(item))
        default:
            throw ApplinError.deserializeError("unexpected widget 'typ' value: \(item.typ)")
        }
    }

    func toJsonItem() -> JsonItem {
        switch self.value {
        case let .applinLastErrorText(inner):
            return inner.toJsonItem()
        case let .backButton(inner):
            return inner.toJsonItem()
        case let .button(inner):
            return inner.toJsonItem()
        case let .checkbox(inner):
            return inner.toJsonItem()
        case let .column(inner):
            return inner.toJsonItem()
        case let .empty(inner):
            return inner.toJsonItem()
        case let .errorText(inner):
            return inner.toJsonItem()
        case let .form(inner):
            return inner.toJsonItem()
        case let .formButton(inner):
            return inner.toJsonItem()
        case let .formSection(inner):
            return inner.toJsonItem()
        case let .formTextfield(inner):
            return inner.toJsonItem()
        case let .navButton(inner):
            return inner.toJsonItem()
        case let .textfield(inner):
            return inner.toJsonItem()
        case let .scroll(inner):
            return inner.toJsonItem()
        case let .text(inner):
            return inner.toJsonItem()
        }
    }

    func keys() -> [String] {
        switch self.value {
        case let .applinLastErrorText(inner):
            return inner.keys()
        case let .backButton(inner):
            return inner.keys()
        case let .button(inner):
            return inner.keys()
        case let .checkbox(inner):
            return inner.keys()
        case let .column(inner):
            return inner.keys()
        case let .empty(inner):
            return inner.keys()
        case let .errorText(inner):
            return inner.keys()
        case let .form(inner):
            return inner.keys()
        case let .formButton(inner):
            return inner.keys()
        case let .formSection(inner):
            return inner.keys()
        case let .formTextfield(inner):
            return inner.keys()
        case let .navButton(inner):
            return inner.keys()
        case let .textfield(inner):
            return inner.keys()
        case let .scroll(inner):
            return inner.keys()
        case let .text(inner):
            return inner.keys()
        }
    }

    func priority() -> WidgetPriority {
        switch self.value {
        case let .applinLastErrorText(inner):
            return inner.priority()
        case let .backButton(inner):
            return inner.priority()
        case let .button(inner):
            return inner.priority()
        case let .checkbox(inner):
            return inner.priority()
        case let .column(inner):
            return inner.priority()
        case let .empty(inner):
            return inner.priority()
        case let .errorText(inner):
            return inner.priority()
        case let .form(inner):
            return inner.priority()
        case let .formButton(inner):
            return inner.priority()
        case let .formSection(inner):
            return inner.priority()
        case let .formTextfield(inner):
            return inner.priority()
        case let .navButton(inner):
            return inner.priority()
        case let .textfield(inner):
            return inner.priority()
        case let .scroll(inner):
            return inner.priority()
        case let .text(inner):
            return inner.priority()
        }
    }

    func subs() -> [Spec] {
        switch self.value {
        case let .applinLastErrorText(inner):
            return inner.subs()
        case let .backButton(inner):
            return inner.subs()
        case let .button(inner):
            return inner.subs()
        case let .checkbox(inner):
            return inner.subs()
        case let .column(inner):
            return inner.subs()
        case let .empty(inner):
            return inner.subs()
        case let .errorText(inner):
            return inner.subs()
        case let .form(inner):
            return inner.subs()
        case let .formButton(inner):
            return inner.subs()
        case let .formSection(inner):
            return inner.subs()
        case let .formTextfield(inner):
            return inner.subs()
        case let .navButton(inner):
            return inner.subs()
        case let .textfield(inner):
            return inner.subs()
        case let .scroll(inner):
            return inner.subs()
        case let .text(inner):
            return inner.subs()
        }
    }

    func vars() -> [(String, Var)] {
        switch self.value {
        case let .applinLastErrorText(inner):
            return inner.vars()
        case let .backButton(inner):
            return inner.vars()
        case let .button(inner):
            return inner.vars()
        case let .checkbox(inner):
            return inner.vars()
        case let .column(inner):
            return inner.vars()
        case let .empty(inner):
            return inner.vars()
        case let .errorText(inner):
            return inner.vars()
        case let .form(inner):
            return inner.vars()
        case let .formButton(inner):
            return inner.vars()
        case let .formSection(inner):
            return inner.vars()
        case let .formTextfield(inner):
            return inner.vars()
        case let .navButton(inner):
            return inner.vars()
        case let .textfield(inner):
            return inner.vars()
        case let .scroll(inner):
            return inner.vars()
        case let .text(inner):
            return inner.vars()
        }
    }

    func widgetClass() -> AnyClass {
        switch self.value {
        case let .applinLastErrorText(inner):
            return inner.widgetClass()
        case let .backButton(inner):
            return inner.widgetClass()
        case let .button(inner):
            return inner.widgetClass()
        case let .checkbox(inner):
            return inner.widgetClass()
        case let .column(inner):
            return inner.widgetClass()
        case let .empty(inner):
            return inner.widgetClass()
        case let .errorText(inner):
            return inner.widgetClass()
        case let .form(inner):
            return inner.widgetClass()
        case let .formButton(inner):
            return inner.widgetClass()
        case let .formSection(inner):
            return inner.widgetClass()
        case let .formTextfield(inner):
            return inner.widgetClass()
        case let .navButton(inner):
            return inner.widgetClass()
        case let .textfield(inner):
            return inner.widgetClass()
        case let .scroll(inner):
            return inner.widgetClass()
        case let .text(inner):
            return inner.widgetClass()
        }
    }

    func newWidget() -> Widget {
        switch self.value {
        case let .applinLastErrorText(inner):
            return inner.newWidget()
        case let .backButton(inner):
            return inner.newWidget()
        case let .button(inner):
            return inner.newWidget()
        case let .checkbox(inner):
            return inner.newWidget()
        case let .column(inner):
            return inner.newWidget()
        case let .empty(inner):
            return inner.newWidget()
        case let .errorText(inner):
            return inner.newWidget()
        case let .form(inner):
            return inner.newWidget()
        case let .formButton(inner):
            return inner.newWidget()
        case let .formSection(inner):
            return inner.newWidget()
        case let .formTextfield(inner):
            return inner.newWidget()
        case let .navButton(inner):
            return inner.newWidget()
        case let .textfield(inner):
            return inner.newWidget()
        case let .scroll(inner):
            return inner.newWidget()
        case let .text(inner):
            return inner.newWidget()
        }
    }

    func hash(into hasher: inout Hasher) {
        self.value.hash(into: &hasher)
    }
}
