import Foundation
import UIKit

struct FormButtonData: Equatable, Hashable, WidgetDataProto {
    static let TYP = "form-button"
    let actions: [ActionData]
    let pageKey: String
    let text: String

    init(pageKey: String, _ actions: [ActionData], text: String) {
        self.actions = actions
        self.pageKey = pageKey
        self.text = text
    }

    init(pageKey: String, _ item: JsonItem) throws {
        self.actions = try item.optActions() ?? []
        self.pageKey = pageKey
        self.text = try item.requireText()
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(FormButtonData.TYP)
        item.actions = self.actions.map({ action in action.toString() })
        item.text = self.text
        return item
    }

    func keys() -> [String] {
        ["form-button:\(self.actions)", "form-button:\(self.text)"]
    }

    func priority() -> WidgetPriority {
        .focusable
    }

    func subs() -> [WidgetData] {
        []
    }

    func widgetClass() -> AnyClass {
        FormButtonWidget.self
    }

    func widget() -> WidgetProto {
        FormButtonWidget(self)
    }

    func vars() -> [(String, Var)] {
        []
    }
}

class FormButtonWidget: WidgetProto {
    var data: FormButtonData
    var button: UIButton!
    var container: UIView!
    weak var session: ApplinSession?

    init(_ data: FormButtonData) {
        print("FormButtonWidget.init(\(data))")
        self.data = data
        weak var weakSelf: FormButtonWidget? = self
        let action = UIAction(title: "uninitialized", handler: { [weakSelf] _ in
            print("form-button \(String(describing: data.text)) UIAction")
            weakSelf?.tap()
        })
        self.button = UIButton(type: .custom, primaryAction: action)
        self.button.translatesAutoresizingMaskIntoConstraints = false
        self.button.backgroundColor = pastelGreen
        self.button.setTitleColor(.systemBlue, for: .normal)
        self.button.setTitleColor(.systemGray, for: .focused)
        self.button.setTitleColor(.systemGray, for: .selected)
        self.button.setTitleColor(.systemGray, for: .highlighted)
        self.button.setTitleColor(.systemGray, for: .disabled)
        self.container = UIView()
        self.container.translatesAutoresizingMaskIntoConstraints = false
        self.container.backgroundColor = pastelBlue
        self.container.addSubview(self.button)
        NSLayoutConstraint.activate([
            self.container.widthAnchor.constraint(equalToConstant: 100_000.0).withPriority(.defaultLow),
            self.container.heightAnchor.constraint(greaterThanOrEqualToConstant: FORM_CELL_HEIGHT),
            self.container.leftAnchor.constraint(lessThanOrEqualTo: self.button.leftAnchor),
            self.button.rightAnchor.constraint(lessThanOrEqualTo: self.container.rightAnchor),
            self.container.topAnchor.constraint(lessThanOrEqualTo: self.button.topAnchor),
            self.button.bottomAnchor.constraint(lessThanOrEqualTo: self.button.bottomAnchor),
            self.button.centerXAnchor.constraint(equalTo: self.container.centerXAnchor),
            self.button.centerYAnchor.constraint(equalTo: self.container.centerYAnchor),
        ])
    }

    func tap() {
        print("form-button \(String(describing: data.text)) tap")
        self.session?.doActions(pageKey: self.data.pageKey, self.data.actions)
    }

    func getView() -> UIView {
        self.container
    }

    func isFocused(_ session: ApplinSession, _ data: WidgetData) -> Bool {
        self.button.isFocused
    }

    func update(_ session: ApplinSession, _ data: WidgetData, _ subs: [WidgetProto]) throws {
        guard case let .formButton(formButtonData) = data else {
            throw "Expected .formButton got: \(data)"
        }
        self.data = formButtonData
        self.session = session
        self.button.setTitle("  \(formButtonData.text)  ", for: .normal)
        self.button.isEnabled = !self.data.actions.isEmpty
    }
}
