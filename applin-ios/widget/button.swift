import Foundation
import UIKit

struct ButtonData: Equatable, Hashable, WidgetDataProto {
    static let TYP = "button"
    let actions: [ActionData]
    let pageKey: String
    let text: String

    init(pageKey: String, _ item: JsonItem) throws {
        self.pageKey = pageKey
        self.actions = try item.optActions() ?? []
        self.text = try item.requireText()
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(ButtonData.TYP)
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

    func subs() -> [WidgetData] {
        []
    }

    func widgetClass() -> AnyClass {
        ButtonWidget.self
    }

    func widget() -> WidgetProto {
        ButtonWidget(self)
    }

    func vars() -> [(String, Var)] {
        []
    }
}

class ButtonWidget: WidgetProto {
    var actions: [ActionData] = []
    var pageKey: String = ""
    var button: UIButton!
    weak var session: ApplinSession?

    init(_ data: ButtonData) {
        print("ButtonWidget.init(\(data))")
        self.actions = data.actions
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
        self.session?.doActions(pageKey: self.pageKey, self.actions)
    }

    func getView() -> UIView {
        self.button
    }

    func isFocused(_ session: ApplinSession, _ data: WidgetData) -> Bool {
        self.button.isFocused
    }

    func update(_ session: ApplinSession, _ data: WidgetData, _ subs: [WidgetProto]) throws {
        guard case let .button(buttonData) = data else {
            throw "Expected .button got: \(data)"
        }
        self.session = session
        self.button.setTitle("  \(buttonData.text)  ", for: .normal)
        self.actions = buttonData.actions
        self.button.isEnabled = !self.actions.isEmpty
        self.button.layer.borderColor = self.actions.isEmpty ? UIColor.systemGray.cgColor : UIColor.tintColor.cgColor
    }
}

