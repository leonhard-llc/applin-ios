import Foundation
import UIKit

struct ErrorDetailsData: Equatable, Hashable, WidgetDataProto {
    static let TYP = "error-details"

    func toJsonItem() -> JsonItem {
        let item = JsonItem(ErrorDetailsData.TYP)
        return item
    }

    func keys() -> [String] {
        []
    }

    func priority() -> WidgetPriority {
        .stateless
    }

    func subs() -> [WidgetData] {
        []
    }

    func widgetClass() -> AnyClass {
        ErrorDetailsWidget.self
    }

    func widget() -> WidgetProto {
        ErrorDetailsWidget()
    }

    func vars() -> [(String, Var)] {
        []
    }
}

class ErrorDetailsWidget: WidgetProto {
    let label: UILabel
    let container: UIView

    init() {
        self.label = UILabel()
        self.label.translatesAutoresizingMaskIntoConstraints = false
        self.label.font = UIFont.preferredFont(forTextStyle: .body)
        self.label.numberOfLines = 0
        self.label.text = ""
        self.container = UIView()
        self.container.translatesAutoresizingMaskIntoConstraints = false
        self.container.addSubview(label)
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

    func isFocused(_ session: ApplinSession, _ data: WidgetData) -> Bool {
        false
    }

    func update(_ session: ApplinSession, _ data: WidgetData, _ subs: [WidgetProto]) throws {
        guard case .errorDetails = data else {
            throw "Expected .errorDetails got: \(data)"
        }
        self.label.text = session.error ?? ""
    }
}
