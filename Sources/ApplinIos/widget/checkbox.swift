import Foundation
import OSLog
import UIKit

public struct CheckboxSpec: Equatable, Hashable, ToSpec {
    static let TYP = "checkbox"
    let actions: [ActionSpec]
    let initialBool: Bool?
    let pollDelayMs: UInt32?
    let text: String?
    let validated: Bool?
    let varName: String

    public init(
            varName: String,
            actions: [ActionSpec] = [],
            initialBool: Bool? = nil,
            pollDelayMs: UInt32? = nil,
            text: String? = nil,
            validated: Bool? = nil
    ) {
        self.actions = actions
        self.initialBool = initialBool
        self.pollDelayMs = pollDelayMs
        self.text = text
        self.validated = validated
        self.varName = varName
    }

    init(_ config: ApplinConfig, _ item: JsonItem) throws {
        self.actions = try item.optActions(config) ?? []
        self.initialBool = item.initial_bool
        self.pollDelayMs = item.poll_delay_ms
        self.text = item.text
        self.validated = item.validated
        self.varName = try item.requireVar()
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(CheckboxSpec.TYP)
        item.actions = self.actions.map({ action in action.toJsonAction() })
        item.initial_bool = self.initialBool
        item.poll_delay_ms = self.pollDelayMs
        item.text = self.text
        item.validated = self.validated
        item.var_name = self.varName
        return item
    }

    func hasValidatedInput() -> Bool {
        self.validated ?? false
    }

    func keys() -> [String] {
        ["checkbox:\(self.varName)"]
    }

    func newWidget(_ ctx: PageContext) -> Widget {
        CheckboxWidget(.checkbox(self), ctx)
    }

    func priority() -> WidgetPriority {
        .focusable
    }

    func subs() -> [Spec] {
        []
    }

    public func toSpec() -> Spec {
        Spec(.checkbox(self))
    }

    func vars() -> [(String, Var)] {
        [(self.varName, .bool(self.initialBool ?? false))]
    }

    func widgetClass() -> AnyClass {
        CheckboxWidget.self
    }
}

public struct CheckboxButtonSpec: Equatable, Hashable, ToSpec {
    static let TYP = "checkbox_button"
    let actions: [ActionSpec]
    let initialBool: Bool?
    let text: String?

    public init(
            actions: [ActionSpec] = [],
            initialBool: Bool? = nil,
            text: String? = nil
    ) {
        self.actions = actions
        self.initialBool = initialBool
        self.text = text
    }

    init(_ config: ApplinConfig, _ item: JsonItem) throws {
        self.actions = try item.optActions(config) ?? []
        self.initialBool = item.initial_bool
        self.text = item.text
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(CheckboxSpec.TYP)
        item.actions = self.actions.map({ action in action.toJsonAction() })
        item.initial_bool = self.initialBool
        item.text = self.text
        return item
    }

    func hasValidatedInput() -> Bool {
        false
    }

    func keys() -> [String] {
        var result: [String] = []
        if !self.actions.isEmpty {
            result.append("checkbox_button:\(self.actions)")
        }
        if let text = self.text {
            result.append("checkbox_button:\(text)")
        }
        return result
    }

    func newWidget(_ ctx: PageContext) -> Widget {
        CheckboxWidget(.checkboxButton(self), ctx)
    }

    func priority() -> WidgetPriority {
        .focusable
    }

    func subs() -> [Spec] {
        []
    }

    public func toSpec() -> Spec {
        Spec(.checkboxButton(self))
    }

    func vars() -> [(String, Var)] {
        []
    }

    func widgetClass() -> AnyClass {
        CheckboxWidget.self
    }
}

enum CheckboxWidgetSpec {
    case checkbox(CheckboxSpec)
    case checkboxButton(CheckboxButtonSpec)
}

class CheckboxWidget: Widget {
    static let logger = Logger(subsystem: "Applin", category: "CheckboxWidget")
    let checked = UIImage(systemName: "checkmark.square.fill")!
    let unchecked = UIImage(systemName: "square")!
    var container: TappableView
    var spec: CheckboxWidgetSpec
    var button: UIButton!
    let ctx: PageContext

    init(_ spec: CheckboxWidgetSpec, _ ctx: PageContext) {
        self.container = TappableView()
        self.container.translatesAutoresizingMaskIntoConstraints = false
        self.spec = spec
        self.ctx = ctx
        // For unknown reasons, when the handler takes `[weak self]`, the first
        // checkbox on the page gets self set to 'nil'.  The strange work
        // around is to bind `weak self` before creating the handler.
        weak var weakSelf: CheckboxWidget? = self
        let action = UIAction(title: "uninitialized", handler: { [weakSelf] _ in
            Self.logger.dbg("UIAction")
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
        Self.logger.dbg("tap")
        guard let varSet = self.ctx.varSet, let pageStack = self.ctx.pageStack else {
            return
        }
        switch self.spec {
        case let .checkbox(spec):
            let originalVarValue: Bool? = varSet.bool(spec.varName)
            let originalValue = originalVarValue ?? spec.initialBool ?? false
            let newValue: Bool = !originalValue
            varSet.set(spec.varName, .bool(newValue))
            self.updateButton(checked: newValue, title: spec.text)
            if !spec.actions.isEmpty {
                let ok = await pageStack.doActions(spec.actions)
                if !ok {
                    varSet.setBool(spec.varName, originalVarValue)
                    self.updateButton(checked: !newValue, title: spec.text)
                }
            }
            if let pollDelayMs = spec.pollDelayMs {
                self.ctx.foregroundPoller?.schedulePoll(delayMillis: pollDelayMs)
            }
        case let .checkboxButton(spec):
            let _ = await pageStack.doActions(spec.actions)
        }
    }

    func update(_ ctx: PageContext, _ spec: Spec, _ subs: [Widget]) throws {
        guard let varSet = self.ctx.varSet else {
            return
        }
        switch spec.value {
        case let .checkbox(spec):
            self.spec = .checkbox(spec)
        case let .checkboxButton(spec):
            self.spec = .checkboxButton(spec)
        default:
            throw "Expected .checkbox or .checkboxButton got: \(spec)"
        }
        if !subs.isEmpty {
            throw "Expected no subs got: \(subs)"
        }
        switch self.spec {
        case let .checkbox(spec):
            self.button.setTitle(spec.text ?? "", for: .normal)
            let checked = varSet.bool(spec.varName) ?? spec.initialBool ?? false
            Task {
                await self.updateButton(checked: checked, title: spec.text)
            }
        case let .checkboxButton(spec):
            self.button.setTitle(spec.text ?? "", for: .normal)
            let checked = spec.initialBool ?? false
            Task {
                await self.updateButton(checked: checked, title: spec.text)
            }
        }
    }
}
