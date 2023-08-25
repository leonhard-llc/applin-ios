import Foundation
import UIKit

public struct FormButtonSpec: Equatable, Hashable, ToSpec {
    static let TYP = "form-button"
    let actions: [ActionSpec]
    let alignment: ApplinHAlignment?
    let text: String

    init(_ item: JsonItem) throws {
        self.actions = try item.optActions() ?? []
        self.alignment = item.optAlign()
        self.text = try item.requireText()
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(FormButtonSpec.TYP)
        item.actions = self.actions.map({ action in action.toString() })
        item.setAlign(self.alignment)
        item.text = self.text
        return item
    }

    init(text: String, _ actions: [ActionSpec]) {
        self.actions = actions
        self.alignment = .center
        self.text = text
    }

    public func toSpec() -> Spec {
        Spec(.formButton(self))
    }

    func keys() -> [String] {
        ["form-button:\(self.actions)", "form-button:\(self.text)"]
    }

    func priority() -> WidgetPriority {
        .focusable
    }

    func subs() -> [Spec] {
        []
    }

    func widgetClass() -> AnyClass {
        FormButtonWidget.self
    }

    func newWidget(_ ctx: PageContext) -> Widget {
        FormButtonWidget(self, ctx)
    }

    func vars() -> [(String, Var)] {
        []
    }

    func visitActions(_ f: (ActionSpec) -> ()) {
        self.actions.forEach(f)
    }
}

class FormButtonWidget: Widget {
    static let INSET: CGFloat = 8.0
    let constraints = ConstraintSet()
    var spec: FormButtonSpec
    var container: TappableView!
    var button: UIButton!
    let ctx: PageContext

    init(_ spec: FormButtonSpec, _ ctx: PageContext) {
        print("FormButtonWidget.init(\(spec))")
        self.spec = spec
        self.ctx = ctx

        self.container = TappableView()
        self.container.translatesAutoresizingMaskIntoConstraints = false
        //self.container.backgroundColor = pastelBlue

        weak var weakSelf: FormButtonWidget? = self
        let action = UIAction(title: "uninitialized", handler: { [weakSelf] _ in
            print("form-button \(String(describing: spec.text)) UIAction")
            weakSelf?.tap()
        })
        self.button = UIButton(type: .custom, primaryAction: action)
        self.button.translatesAutoresizingMaskIntoConstraints = false
        //self.button.backgroundColor = pastelGreen
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
            self.container.widthAnchor.constraint(equalToConstant: 100_000.0).withPriority(.fittingSizeLevel),
            self.button.centerYAnchor.constraint(equalTo: self.container.centerYAnchor),
            self.button.topAnchor.constraint(greaterThanOrEqualTo: self.container.topAnchor, constant: Self.INSET),
            self.button.bottomAnchor.constraint(lessThanOrEqualTo: self.container.bottomAnchor, constant: -Self.INSET),
        ])
    }

    func tap() {
        if self.spec.actions.isEmpty {
            return
        }
        Task {
            print("form-button \(String(describing: spec.text)) tap")
            let _ = await ctx.pageStack?.doActions(pageKey: ctx.pageKey, self.spec.actions)
        }
    }

    func getView() -> UIView {
        self.container
    }

    func isFocused() -> Bool {
        self.button.isFocused
    }

    func update(_ ctx: PageContext, _ spec: Spec, _ subs: [Widget]) throws {
        guard case let .formButton(formButtonSpec) = spec.value else {
            throw "Expected .formButton got: \(spec)"
        }
        self.spec = formButtonSpec
        self.button.setTitle("  \(formButtonSpec.text)  ", for: .normal)
        self.button.isEnabled = !self.spec.actions.isEmpty
        switch self.spec.alignment {
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
