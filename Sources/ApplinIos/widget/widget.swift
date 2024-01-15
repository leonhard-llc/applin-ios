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
    func update(_ ctx: PageContext, _ spec: Spec, _ subs: [Widget]) throws
}

public protocol ToSpec {
    func toSpec() -> Spec
}

/// Spec is an immutable tree of widget specifications.
///
/// It is a reference-counted wrapper around the enum, to prevent unnecessary copies of the widget tree.
/// This changes algorithms that would take O(n^2) memory into O(n).
public class Spec: CustomStringConvertible, Equatable, Hashable, ToSpec {
    public enum Value: Equatable, Hashable {
        case backButton(BackButtonSpec)
        case button(ButtonSpec)
        case checkbox(CheckboxSpec)
        case column(ColumnSpec)
        case empty(EmptySpec)
        case errorText(ErrorTextSpec)
        case form(FormSpec)
        case formButton(FormButtonSpec)
        case formSection(FormSectionSpec)
        case groupedRowTable(GroupedRowTableSpec)
        case image(ImageSpec)
        case lastErrorText(LastErrorTextSpec)
        case navButton(NavButtonSpec)
        case textfield(TextfieldSpec)
        case scroll(ScrollSpec)
        case selector(SelectorSpec)
        case text(TextSpec)
    }

    public static func ==(lhs: Spec, rhs: Spec) -> Bool {
        lhs.value == rhs.value
    }

    // NOTE: This class must be immutable.

    public let value: Value

    init(_ value: Value) {
        self.value = value
    }

    init(_ config: ApplinConfig, _ item: JsonItem) throws {
        switch item.typ {
        case BackButtonSpec.TYP:
            self.value = .backButton(try BackButtonSpec(config, item))
        case ButtonSpec.TYP:
            self.value = .button(try ButtonSpec(config, item))
        case CheckboxSpec.TYP:
            self.value = .checkbox(try CheckboxSpec(config, item))
        case ColumnSpec.TYP:
            self.value = .column(try ColumnSpec(config, item))
        case EmptySpec.TYP:
            self.value = .empty(EmptySpec())
        case ErrorTextSpec.TYP:
            self.value = .errorText(try ErrorTextSpec(item))
        case FormSpec.TYP:
            self.value = .form(try FormSpec(config, item))
        case FormButtonSpec.TYP:
            self.value = .formButton(try FormButtonSpec(config, item))
        case FormSectionSpec.TYP:
            self.value = .formSection(try FormSectionSpec(config, item))
        case GroupedRowTableSpec.TYP:
            self.value = .groupedRowTable(try GroupedRowTableSpec(config, item))
        case ImageSpec.TYP:
            self.value = .image(try ImageSpec(config, item))
        case LastErrorTextSpec.TYP:
            self.value = .lastErrorText(LastErrorTextSpec())
        case NavButtonSpec.TYP:
            self.value = .navButton(try NavButtonSpec(config, item))
        case TextfieldSpec.TYP:
            self.value = .textfield(try TextfieldSpec(item))
        case ScrollSpec.TYP:
            self.value = .scroll(try ScrollSpec(config, item))
        case SelectorSpec.TYP:
            self.value = .selector(try SelectorSpec(item))
        case TextSpec.TYP:
            self.value = .text(try TextSpec(item))
        default:
            throw ApplinError.appError("unexpected widget 'typ' value: \(item.typ)")
        }
    }

    func toJsonItem() -> JsonItem {
        switch self.value {
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
        case let .groupedRowTable(inner):
            return inner.toJsonItem()
        case let .image(inner):
            return inner.toJsonItem()
        case let .lastErrorText(inner):
            return inner.toJsonItem()
        case let .navButton(inner):
            return inner.toJsonItem()
        case let .textfield(inner):
            return inner.toJsonItem()
        case let .scroll(inner):
            return inner.toJsonItem()
        case let .selector(inner):
            return inner.toJsonItem()
        case let .text(inner):
            return inner.toJsonItem()
        }
    }

    public func toSpec() -> Spec {
        self
    }

    func hasValidatedInput() -> Bool {
        switch self.value {
        case let .backButton(inner):
            return inner.hasValidatedInput()
        case let .button(inner):
            return inner.hasValidatedInput()
        case let .checkbox(inner):
            return inner.hasValidatedInput()
        case let .column(inner):
            return inner.hasValidatedInput()
        case let .empty(inner):
            return inner.hasValidatedInput()
        case let .errorText(inner):
            return inner.hasValidatedInput()
        case let .form(inner):
            return inner.hasValidatedInput()
        case let .formButton(inner):
            return inner.hasValidatedInput()
        case let .formSection(inner):
            return inner.hasValidatedInput()
        case let .groupedRowTable(inner):
            return inner.hasValidatedInput()
        case let .image(inner):
            return inner.hasValidatedInput()
        case let .lastErrorText(inner):
            return inner.hasValidatedInput()
        case let .navButton(inner):
            return inner.hasValidatedInput()
        case let .textfield(inner):
            return inner.hasValidatedInput()
        case let .scroll(inner):
            return inner.hasValidatedInput()
        case let .selector(inner):
            return inner.hasValidatedInput()
        case let .text(inner):
            return inner.hasValidatedInput()
        }
    }

    func keys() -> [String] {
        switch self.value {
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
        case let .groupedRowTable(inner):
            return inner.keys()
        case let .image(inner):
            return inner.keys()
        case let .lastErrorText(inner):
            return inner.keys()
        case let .navButton(inner):
            return inner.keys()
        case let .textfield(inner):
            return inner.keys()
        case let .scroll(inner):
            return inner.keys()
        case let .selector(inner):
            return inner.keys()
        case let .text(inner):
            return inner.keys()
        }
    }

    func priority() -> WidgetPriority {
        switch self.value {
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
        case let .groupedRowTable(inner):
            return inner.priority()
        case let .image(inner):
            return inner.priority()
        case let .lastErrorText(inner):
            return inner.priority()
        case let .navButton(inner):
            return inner.priority()
        case let .textfield(inner):
            return inner.priority()
        case let .scroll(inner):
            return inner.priority()
        case let .selector(inner):
            return inner.priority()
        case let .text(inner):
            return inner.priority()
        }
    }

    func subs() -> [Spec] {
        switch self.value {
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
        case let .groupedRowTable(inner):
            return inner.subs()
        case let .image(inner):
            return inner.subs()
        case let .lastErrorText(inner):
            return inner.subs()
        case let .navButton(inner):
            return inner.subs()
        case let .textfield(inner):
            return inner.subs()
        case let .scroll(inner):
            return inner.subs()
        case let .selector(inner):
            return inner.subs()
        case let .text(inner):
            return inner.subs()
        }
    }

    func vars() -> [(String, Var)] {
        switch self.value {
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
        case let .groupedRowTable(inner):
            return inner.vars()
        case let .image(inner):
            return inner.vars()
        case let .lastErrorText(inner):
            return inner.vars()
        case let .navButton(inner):
            return inner.vars()
        case let .textfield(inner):
            return inner.vars()
        case let .scroll(inner):
            return inner.vars()
        case let .selector(inner):
            return inner.vars()
        case let .text(inner):
            return inner.vars()
        }
    }

    func widgetClass() -> AnyClass {
        switch self.value {
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
        case let .groupedRowTable(inner):
            return inner.widgetClass()
        case let .image(inner):
            return inner.widgetClass()
        case let .lastErrorText(inner):
            return inner.widgetClass()
        case let .navButton(inner):
            return inner.widgetClass()
        case let .textfield(inner):
            return inner.widgetClass()
        case let .scroll(inner):
            return inner.widgetClass()
        case let .selector(inner):
            return inner.widgetClass()
        case let .text(inner):
            return inner.widgetClass()
        }
    }

    func newWidget(_ ctx: PageContext) -> Widget {
        switch self.value {
        case let .backButton(inner):
            return inner.newWidget()
        case let .button(inner):
            return inner.newWidget(ctx)
        case let .checkbox(inner):
            return inner.newWidget(ctx)
        case let .column(inner):
            return inner.newWidget()
        case let .empty(inner):
            return inner.newWidget()
        case let .errorText(inner):
            return inner.newWidget()
        case let .form(inner):
            return inner.newWidget()
        case let .formButton(inner):
            return inner.newWidget(ctx)
        case let .formSection(inner):
            return inner.newWidget()
        case let .groupedRowTable(inner):
            return inner.newWidget()
        case let .image(inner):
            return inner.newWidget()
        case let .lastErrorText(inner):
            return inner.newWidget()
        case let .navButton(inner):
            return inner.newWidget(ctx)
        case let .textfield(inner):
            return inner.newWidget(ctx)
        case let .scroll(inner):
            return inner.newWidget()
        case let .selector(inner):
            return inner.newWidget(ctx)
        case let .text(inner):
            return inner.newWidget()
        }
    }

    public var description: String {
        switch self.value {
        case let .backButton(inner):
            return "\(inner)"
        case let .button(inner):
            return "\(inner)"
        case let .checkbox(inner):
            return "\(inner)"
        case let .column(inner):
            return "\(inner)"
        case let .empty(inner):
            return "\(inner)"
        case let .errorText(inner):
            return "\(inner)"
        case let .form(inner):
            return "\(inner)"
        case let .formButton(inner):
            return "\(inner)"
        case let .formSection(inner):
            return "\(inner)"
        case let .groupedRowTable(inner):
            return "\(inner)"
        case let .image(inner):
            return "\(inner)"
        case let .lastErrorText(inner):
            return "\(inner)"
        case let .navButton(inner):
            return "\(inner)"
        case let .textfield(inner):
            return "\(inner)"
        case let .scroll(inner):
            return "\(inner)"
        case let .selector(inner):
            return "\(inner)"
        case let .text(inner):
            return "\(inner)"
        }
    }

    public func hash(into hasher: inout Hasher) {
        self.value.hash(into: &hasher)
    }

    func is_empty() -> Bool {
        if case .empty(_) = self.value {
            return true
        } else {
            return false
        }
    }
}
