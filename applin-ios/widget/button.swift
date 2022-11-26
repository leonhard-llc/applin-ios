import Foundation
import UIKit

struct ButtonSpec: Equatable, Hashable {
    static let TYP = "button"
    let actions: [ActionSpec]
    let pageKey: String
    let text: String

    init(pageKey: String, _ item: JsonItem) throws {
        self.pageKey = pageKey
        self.actions = try item.optActions() ?? []
        self.text = try item.requireText()
    }

    init(pageKey: String, text: String, actions: [ActionSpec] = []) {
        self.pageKey = pageKey
        self.text = text
        self.actions = actions
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(ButtonSpec.TYP)
        item.actions = self.actions.map({ action in action.toString() })
        item.text = self.text
        return item
    }

    func keys() -> [String] {
        ["button:\(self.actions)", "button:\(self.text)"]
    }

    func priority() -> WidgetPriority {
        .focusable
    }

    func subs() -> [Spec] {
        []
    }

    func widgetClass() -> AnyClass {
        ButtonWidget.self
    }

    func newWidget() -> Widget {
        ButtonWidget(self)
    }

    func vars() -> [(String, Var)] {
        []
    }
}

class ButtonWidget: Widget {
    var spec: ButtonSpec
    var button: UIButton!
    weak var session: ApplinSession?

    init(_ spec: ButtonSpec) {
        print("ButtonWidget.init(\(spec))")
        self.spec = spec
        weak var weakSelf: ButtonWidget? = self
        let action = UIAction(title: "uninitialized", handler: { [weakSelf] _ in
            print("button UIAction")
            weakSelf?.tap()
        })
        self.button = UIButton(type: .custom, primaryAction: action)
        self.button.translatesAutoresizingMaskIntoConstraints = false
        self.button.backgroundColor = .tertiarySystemFill
        self.button.setTitleColor(.label, for: .normal)
        self.button.setTitleColor(.systemGray, for: .focused)
        self.button.setTitleColor(.systemGray, for: .selected)
        self.button.setTitleColor(.systemGray, for: .highlighted)
        self.button.setTitleColor(.systemGray, for: .disabled)
        self.button.layer.borderWidth = 2.0
        self.button.layer.cornerRadius = 8.0
    }

    func tap() {
        print("button actions")
        self.session?.doActions(pageKey: self.spec.pageKey, self.spec.actions)
    }

    func getView() -> UIView {
        self.button
    }

    func isFocused() -> Bool {
        self.button.isFocused
    }

    func update(_ session: ApplinSession, _ spec: Spec, _ subs: [Widget]) throws {
        guard case let .button(buttonSpec) = spec.value else {
            throw "Expected .button got: \(spec)"
        }
        if !subs.isEmpty {
            throw "Expected no subs got: \(subs)"
        }
        self.spec = buttonSpec
        self.session = session
        self.button.setTitle("  \(buttonSpec.text)  ", for: .normal)
        self.button.isEnabled = !self.spec.actions.isEmpty
        self.button.layer.borderColor = self.spec.actions.isEmpty ? UIColor.systemGray.cgColor : UIColor.tintColor.cgColor
    }
}
