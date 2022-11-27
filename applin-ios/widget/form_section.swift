import Foundation
import UIKit

struct FormSectionSpec: Equatable, Hashable {
    static let TYP = "form-section"
    let optTitle: String?
    let widgets: [Spec]

    init(_ title: String?, _ widgets: [Spec]) {
        self.optTitle = title
        self.widgets = widgets
    }

    init(_ config: ApplinConfig, pageKey: String, _ item: JsonItem) throws {
        self.optTitle = item.title
        self.widgets = try item.optWidgets(config, pageKey: pageKey) ?? []
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(FormSectionSpec.TYP)
        item.title = self.optTitle
        item.widgets = self.widgets.map({ widgets in widgets.toJsonItem() })
        return item
    }

    func keys() -> [String] {
        []
    }

    func priority() -> WidgetPriority {
        .stateless
    }

    func subs() -> [Spec] {
        self.widgets
    }

    func vars() -> [(String, Var)] {
        self.widgets.flatMap({ widget in widget.vars() })
    }

    func widgetClass() -> AnyClass {
        FormSectionWidget.self
    }

    func newWidget() -> Widget {
        FormSectionWidget()
    }
}

class FormSectionWidget: Widget {
    let container: UIView
    let header: UIView
    let label: UILabel
    let columnView: ColumnView

    init() {
        print("FormSectionWidget.init()")
        self.container = UIView()
        self.container.translatesAutoresizingMaskIntoConstraints = false
        //self.container.backgroundColor = pastelBlue

        self.header = UIView()
        self.header.translatesAutoresizingMaskIntoConstraints = false
        self.header.backgroundColor = .systemGroupedBackground
        self.container.addSubview(self.header)

        self.label = UILabel()
        self.label.translatesAutoresizingMaskIntoConstraints = false
        self.label.font = UIFont.preferredFont(forTextStyle: .caption1)
        self.label.numberOfLines = 0
        self.label.text = ""
        self.label.textAlignment = .left
        //self.label.backgroundColor = pastelYellow
        self.container.addSubview(self.label)

        self.columnView = ColumnView()
        self.columnView.translatesAutoresizingMaskIntoConstraints = false
        //self.columnView.backgroundColor = pastelMint
        self.container.addSubview(self.columnView)

        NSLayoutConstraint.activate([
            self.container.widthAnchor.constraint(equalToConstant: 100_000.0).withPriority(.defaultLow),
            self.container.heightAnchor.constraint(equalToConstant: 0.0).withPriority(.defaultLow),
            self.header.leftAnchor.constraint(equalTo: self.container.leftAnchor),
            self.header.rightAnchor.constraint(equalTo: self.container.rightAnchor),
            self.header.topAnchor.constraint(equalTo: self.container.topAnchor),
            self.header.heightAnchor.constraint(greaterThanOrEqualToConstant: 16.0),
            self.header.bottomAnchor.constraint(lessThanOrEqualTo: self.container.bottomAnchor),
            self.label.leftAnchor.constraint(equalTo: self.container.leftAnchor, constant: 8.0),
            self.label.rightAnchor.constraint(equalTo: self.container.rightAnchor, constant: -8.0),
            self.label.topAnchor.constraint(equalTo: self.container.topAnchor, constant: 12.0),
            self.label.bottomAnchor.constraint(equalTo: self.header.bottomAnchor, constant: -4.0),
            self.columnView.leftAnchor.constraint(equalTo: self.container.leftAnchor),
            self.columnView.rightAnchor.constraint(equalTo: self.container.rightAnchor),
            self.columnView.topAnchor.constraint(equalTo: self.header.bottomAnchor),
            self.columnView.bottomAnchor.constraint(equalTo: self.container.bottomAnchor),
        ])
    }

    func getView() -> UIView {
        self.container
    }

    func isFocused() -> Bool {
        false
    }

    func update(_ session: ApplinSession, _ spec: Spec, _ subs: [Widget]) throws {
        guard case let .formSection(formSectionSpec) = spec.value else {
            throw "Expected .formSection got: \(spec)"
        }
        self.label.text = formSectionSpec.optTitle?.uppercased()
        self.columnView.update(
                .start,
                separator: .separator,
                spacing: FormWidget.SPACING,
                subviews: subs.map { widget in
                    widget.getView()
                }
        )
    }
}
