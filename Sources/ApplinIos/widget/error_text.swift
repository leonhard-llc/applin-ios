import UIKit

public struct ErrorTextSpec: Equatable, Hashable, ToSpec {
    static let TYP = "error_text"
    let text: String

    public init(_ text: String) {
        self.text = text
    }

    init(_ item: JsonItem) throws {
        self.text = try item.requireText()
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(ErrorTextSpec.TYP)
        item.text = self.text
        return item
    }

    func hasValidatedInput() -> Bool {
        false
    }

    func keys() -> [String] {
        []
    }

    func newWidget() -> Widget {
        ErrorTextWidget(self)
    }

    func priority() -> WidgetPriority {
        .stateless
    }

    func subs() -> [Spec] {
        []
    }

    public func toSpec() -> Spec {
        Spec(.errorText(self))
    }

    func vars() -> [(String, Var)] {
        []
    }

    func widgetClass() -> AnyClass {
        ErrorTextWidget.self
    }
}

class ErrorTextWidget: Widget {
    let errorView = ErrorView()

    init(_ spec: ErrorTextSpec) {
        self.errorView.text = spec.text
    }

    func getView() -> UIView {
        self.errorView
    }

    func isFocused() -> Bool {
        false
    }

    func update(_ ctx: PageContext, _ spec: Spec, _ subs: [Widget]) throws {
        guard case let .errorText(errorTextSpec) = spec.value else {
            throw "Expected .errorText got: \(spec)"
        }
        if !subs.isEmpty {
            throw "Expected no subs got: \(subs)"
        }
        let message = ctx.varSet?.getInteractiveError()?.message() ?? "No error"
        let substitutedMessage =
                errorTextSpec.text.replacingOccurrences(of: "${INTERACTIVE_ERROR_DETAILS}", with: message)
        self.errorView.text = substitutedMessage
    }
}
