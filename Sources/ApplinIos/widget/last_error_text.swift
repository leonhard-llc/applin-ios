import Foundation
import UIKit

public struct LastErrorTextSpec: Equatable, Hashable, ToSpec {
    static let TYP = "last_error_text"

    func toJsonItem() -> JsonItem {
        let item = JsonItem(LastErrorTextSpec.TYP)
        return item
    }

    public func toSpec() -> Spec {
        Spec(.lastErrorText(self))
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
        LastErrorTextWidget.self
    }

    func newWidget() -> Widget {
        LastErrorTextWidget()
    }

    func vars() -> [(String, Var)] {
        []
    }

    func visitActions(_ f: (ActionSpec) -> ()) {
    }
}

class LastErrorTextWidget: Widget {
    let label: Label
    let container: UIView
    var initialized = false

    init() {
        self.label = Label()
        self.label.name = "LastErrorTextWidget.label"
        self.label.translatesAutoresizingMaskIntoConstraints = false
        self.label.font = UIFont.preferredFont(forTextStyle: .body)
        self.label.numberOfLines = 0
        self.label.text = ""
        self.container = NamedUIView(name: "LastErrorTextWidget.container")
        self.container.translatesAutoresizingMaskIntoConstraints = false
        self.container.addSubview(label)
        //self.container.backgroundColor = pastelYellow
        NSLayoutConstraint.activate([
            self.label.leadingAnchor.constraint(equalTo: self.container.leadingAnchor, constant: 8.0),
            self.label.trailingAnchor.constraint(equalTo: self.container.trailingAnchor, constant: -8.0),
            self.label.topAnchor.constraint(equalTo: self.container.topAnchor, constant: 8.0),
            self.label.bottomAnchor.constraint(equalTo: self.container.bottomAnchor, constant: -8.0)
        ])
    }

    func getView() -> UIView {
        self.container
    }

    func isFocused() -> Bool {
        false
    }

    func update(_ ctx: PageContext, _ spec: Spec, _ subs: [Widget]) throws {
        guard let varSet = ctx.varSet else {
            return
        }
        guard case .lastErrorText = spec.value else {
            throw "Expected .lastErrorText got: \(spec)"
        }
        if !subs.isEmpty {
            throw "Expected no subs got: \(subs)"
        }
        if !self.initialized {
            self.label.text = varSet.getInteractiveError()?.message()
                    ?? varSet.getConnectionError()?.message()
                    ?? "Error details not found."
            self.initialized = true
        }
    }
}
