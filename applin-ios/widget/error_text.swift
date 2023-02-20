import UIKit

struct ErrorTextSpec: Equatable, Hashable, ToSpec {
    static let TYP = "error-text"
    let text: String

    init(_ item: JsonItem) throws {
        self.text = try item.requireText()
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(ErrorTextSpec.TYP)
        item.text = self.text
        return item
    }

    func toSpec() -> Spec {
        Spec(.errorText(self))
    }

    func keys() -> [String] {
        []
    }

    func priority() -> WidgetPriority {
        .stateless
    }

    func subs() -> [Spec] {
        []
    }

    func widgetClass() -> AnyClass {
        ErrorTextWidget.self
    }

    func newWidget() -> Widget {
        ErrorTextWidget(self)
    }

    func vars() -> [(String, Var)] {
        []
    }
}

class ErrorTextWidget: Widget {
    let errorView = ErrorView()

    init(_ spec: ErrorTextSpec) {
        print("ErrorTextWidget.init(\(spec))")
        self.errorView.setText(spec.text)
    }

    func getView() -> UIView {
        self.errorView
    }

    func isFocused() -> Bool {
        false
    }

    func update(_ session: ApplinSession, _ state: ApplinState, _ spec: Spec, _ subs: [Widget]) throws {
        guard case let .errorText(errorTextSpec) = spec.value else {
            throw "Expected .errorText got: \(spec)"
        }
        if !subs.isEmpty {
            throw "Expected no subs got: \(subs)"
        }
        self.errorView.setText(errorTextSpec.text)
    }
}
