import Foundation
import UIKit

struct LastErrorTextSpec: Equatable, Hashable, ToSpec {
    static let TYP = "last-error-text"

    func toJsonItem() -> JsonItem {
        let item = JsonItem(LastErrorTextSpec.TYP)
        return item
    }

    func toSpec() -> Spec {
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
}

class LastErrorTextWidget: Widget {
    let label: UILabel
    let container: UIView

    init() {
        print("LastErrorTextWidget.init")
        self.label = UILabel()
        self.label.translatesAutoresizingMaskIntoConstraints = false
        self.label.font = UIFont.preferredFont(forTextStyle: .body)
        self.label.numberOfLines = 0
        self.label.text = ""
        self.container = UIView()
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

    func update(_ session: ApplinSession, _ spec: Spec, _ subs: [Widget]) throws {
        guard case .lastErrorText = spec.value else {
            throw "Expected .lastErrorText got: \(spec)"
        }
        if !subs.isEmpty {
            throw "Expected no subs got: \(subs)"
        }
        self.label.text = session.stateStore.read({ state in state.error ?? "Error details not found." })
    }
}
