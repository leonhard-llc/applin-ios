import Foundation
import UIKit

struct ApplinLastErrorTextData: Equatable, Hashable {
    static let TYP = "applin-last-error-text"

    func toJsonItem() -> JsonItem {
        let item = JsonItem(ApplinLastErrorTextData.TYP)
        return item
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
        ApplinLastErrorTextWidget.self
    }

    func newWidget() -> Widget {
        ApplinLastErrorTextWidget()
    }

    func vars() -> [(String, Var)] {
        []
    }
}

class ApplinLastErrorTextWidget: Widget {
    let label: UILabel
    let container: UIView

    init() {
        print("ApplinLastErrorTextWidget.init")
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
        guard case .applinLastErrorText = spec.value else {
            throw "Expected .applinLastErrorText got: \(spec)"
        }
        if !subs.isEmpty {
            throw "Expected no subs got: \(subs)"
        }
        self.label.text = session.error ?? "Error details not found."
    }
}
