import Foundation
import UIKit

struct FormButtonData: Equatable, Hashable, WidgetDataProto {
    static let TYP = "form-button"
    let actions: [ActionData]
    let alignment: ApplinHAlignment?
    let pageKey: String
    let text: String

    init(pageKey: String, _ actions: [ActionData], text: String) {
        self.actions = actions
        self.alignment = .center
        self.pageKey = pageKey
        self.text = text
    }

    init(pageKey: String, _ item: JsonItem) throws {
        self.actions = try item.optActions() ?? []
        self.alignment = item.optAlign()
        self.pageKey = pageKey
        self.text = try item.requireText()
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(FormButtonData.TYP)
        item.actions = self.actions.map({ action in action.toString() })
        item.setAlign(self.alignment)
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
    static let INSET: CGFloat = 8.0
    let constraints = ConstraintSet()
    var data: FormButtonData
    var container: TappableView!
    var button: UIButton!
    weak var session: ApplinSession?

    init(_ data: FormButtonData) {
        print("FormButtonWidget.init(\(data))")
        self.data = data

        self.container = TappableView()
        self.container.translatesAutoresizingMaskIntoConstraints = false
        //self.container.backgroundColor = pastelBlue

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
        self.container.addSubview(self.button)
        self.container.onTap = { [weak self] in
            self?.tap()
        }

        NSLayoutConstraint.activate([
            self.container.widthAnchor.constraint(equalToConstant: 100_000.0).withPriority(.defaultLow),
            self.button.centerYAnchor.constraint(equalTo: self.container.centerYAnchor),
            self.button.topAnchor.constraint(greaterThanOrEqualTo: self.container.topAnchor, constant: Self.INSET),
            self.button.bottomAnchor.constraint(lessThanOrEqualTo: self.container.bottomAnchor, constant: -Self.INSET),
        ])
    }

    func tap() {
        if self.data.actions.isEmpty {
            return
        }
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
        switch self.data.alignment {
        case nil, .center:
            self.constraints.set([
                self.button.leftAnchor.constraint(greaterThanOrEqualTo: self.container.leftAnchor, constant: Self.INSET),
                self.button.rightAnchor.constraint(lessThanOrEqualTo: self.container.rightAnchor, constant: -Self.INSET),
                self.button.centerXAnchor.constraint(equalTo: self.container.centerXAnchor),
            ])
        case .start:
            self.constraints.set([
                self.button.leftAnchor.constraint(equalTo: self.container.leftAnchor, constant: Self.INSET),
                self.button.rightAnchor.constraint(lessThanOrEqualTo: self.container.rightAnchor, constant: -Self.INSET),
            ])
        case .end:
            self.constraints.set([
                self.button.leftAnchor.constraint(greaterThanOrEqualTo: self.container.leftAnchor, constant: Self.INSET),
                self.button.rightAnchor.constraint(equalTo: self.container.rightAnchor, constant: -Self.INSET),
            ])
        }
    }
}
