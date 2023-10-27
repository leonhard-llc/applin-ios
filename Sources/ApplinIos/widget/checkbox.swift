import Foundation
import OSLog
import UIKit

public struct CheckboxSpec: Equatable, Hashable, ToSpec {
    static let TYP = "checkbox"
    let initialBool: Bool?
    let rpc: String?
    let text: String?
    let varName: String

    init(varName: String, initialBool: Bool? = nil, text: String? = nil, rpc: String? = nil) {
        self.initialBool = initialBool
        self.rpc = rpc
        self.text = text
        self.varName = varName
    }

    init(_ item: JsonItem) throws {
        self.initialBool = item.initial_bool
        self.rpc = item.rpc
        self.text = item.text
        self.varName = try item.requireVar()
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(CheckboxSpec.TYP)
        item.initial_bool = self.initialBool
        item.rpc = self.rpc
        item.text = self.text
        item.var_name = self.varName
        return item
    }

    public func toSpec() -> Spec {
        Spec(.checkbox(self))
    }

    func keys() -> [String] {
        ["checkbox:\(self.varName)"]
    }

    func priority() -> WidgetPriority {
        .focusable
    }

    func subs() -> [Spec] {
        []
    }

    func widgetClass() -> AnyClass {
        CheckboxWidget.self
    }

    func newWidget(_ ctx: PageContext) -> Widget {
        CheckboxWidget(self, ctx)
    }

    func vars() -> [(String, Var)] {
        [(self.varName, .bool(self.initialBool ?? false))]
    }

    func visitActions(_ f: (ActionSpec) -> ()) {
    }
}

class CheckboxWidget: Widget {
    static let logger = Logger(subsystem: "Applin", category: "CheckboxWidget")
    let checked = UIImage(systemName: "checkmark.square.fill")!
    let unchecked = UIImage(systemName: "square")!
    var container: TappableView
    var spec: CheckboxSpec
    var button: UIButton!
    let ctx: PageContext

    init(_ spec: CheckboxSpec, _ ctx: PageContext) {
        self.container = TappableView()
        self.container.translatesAutoresizingMaskIntoConstraints = false
        self.spec = spec
        self.ctx = ctx
        // For unknown reasons, when the handler takes `[weak self]`, the first
        // checkbox on the page gets self set to 'nil'.  The strange work
        // around is to bind `weak self` before creating the handler.
        weak var weakSelf: CheckboxWidget? = self
        let action = UIAction(title: "uninitialized", handler: { [weakSelf] _ in
            Self.logger.debug("UIAction")
            Task {
                await weakSelf?.tap()
            }
        })
        var config = UIButton.Configuration.borderless()
        config.imagePadding = 8.0
        self.button = UIButton(configuration: config, primaryAction: action)
        self.button.translatesAutoresizingMaskIntoConstraints = false
        self.button.setImage(self.checked, for: .highlighted)
        self.container.addSubview(self.button)
        self.container.onTap = { [weakSelf] in
            Task {
                await weakSelf?.tap()
            }
        }

        NSLayoutConstraint.activate([
            self.container.widthAnchor.constraint(equalToConstant: 100_000.0).withPriority(.fittingSizeLevel),
            self.button.centerYAnchor.constraint(equalTo: self.container.centerYAnchor),
            self.button.topAnchor.constraint(greaterThanOrEqualTo: self.container.topAnchor),
            self.button.bottomAnchor.constraint(lessThanOrEqualTo: self.container.bottomAnchor),
            self.button.leftAnchor.constraint(equalTo: self.container.leftAnchor),
            self.button.rightAnchor.constraint(lessThanOrEqualTo: self.container.rightAnchor),
        ])
    }

    func getView() -> UIView {
        self.container
    }

    func isFocused() -> Bool {
        self.button.isFocused
    }

    @MainActor
    private func updateButton(checked: Bool, title: String?) {
        if checked {
            self.button.setImage(self.checked, for: .normal)
        } else {
            self.button.setImage(self.unchecked, for: .normal)
        }
        self.button.setTitle(title, for: .normal)
    }

    @MainActor
    private func tap() async {
        Self.logger.debug("tap")
        guard let varSet = self.ctx.varSet, let pageStack = self.ctx.pageStack else {
            return
        }
        let originalVarValue: Bool? = varSet.bool(self.spec.varName)
        let originalValue = originalVarValue ?? self.spec.initialBool ?? false
        let newValue: Bool = !originalValue
        varSet.set(self.spec.varName, .bool(newValue))
        self.updateButton(checked: newValue, title: self.spec.text)
        if let rpc = self.spec.rpc {
            let ok = await pageStack.doActions(pageKey: self.ctx.pageKey, [.rpc(rpc)])
            if !ok {
                varSet.setBool(self.spec.varName, originalVarValue)
                self.updateButton(checked: !newValue, title: self.spec.text)
            }
        }
    }

    func update(_ ctx: PageContext, _ spec: Spec, _ subs: [Widget]) throws {
        guard let varSet = self.ctx.varSet else {
            return
        }
        guard case let .checkbox(checkboxSpec) = spec.value else {
            throw "Expected .checkbox got: \(spec)"
        }
        if !subs.isEmpty {
            throw "Expected no subs got: \(subs)"
        }
        self.spec = checkboxSpec
        self.button.setTitle(self.spec.text, for: .normal)
        let checked = varSet.bool(self.spec.varName) ?? self.spec.initialBool ?? false
        Task {
            await self.updateButton(checked: checked, title: self.spec.text)
        }
    }
}
