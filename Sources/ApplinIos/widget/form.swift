import Foundation
import UIKit

// TODONT: Don't use UITableView because it cannot update its subviews without causing them to lose keyboard focus.
//         Also, the APIs of UITableView, UITableViewDataSource, and UITableViewDiffableDataSource are extremely hard
//         to use.

public struct FormSpec: Equatable, Hashable, ToSpec {
    static let TYP = "form"
    let widgets: [Spec]

    public init(_ widgets: [ToSpec]) {
        self.widgets = widgets.map({ widget in widget.toSpec() })
    }

    init(_ config: ApplinConfig, _ item: JsonItem) throws {
        self.widgets = try item.optWidgets(config)?.filter({ spec in !spec.is_empty() }) ?? []
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(FormSpec.TYP)
        item.widgets = self.widgets.map({ widgets in widgets.toJsonItem() })
        return item
    }

    public func toSpec() -> Spec {
        Spec(.form(self))
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
        FormWidget.self
    }

    func newWidget() -> Widget {
        FormWidget()
    }

    func visitActions(_ f: (ActionSpec) -> ()) {
        self.widgets.forEach({ widget in widget.visitActions(f) })
    }
}

class FormWidget: Widget {
    let columnView: ColumnView

    init() {
        self.columnView = ColumnView()
        self.columnView.translatesAutoresizingMaskIntoConstraints = false
        //self.columnView.backgroundColor = pastelMint
        NSLayoutConstraint.activate([
            self.columnView.widthAnchor.constraint(equalToConstant: 100_000.0).withPriority(.fittingSizeLevel),
            self.columnView.heightAnchor.constraint(equalToConstant: 0.0).withPriority(.fittingSizeLevel),
        ])
    }

    func getView() -> UIView {
        self.columnView
    }

    func isFocused() -> Bool {
        false
    }

    func update(_ ctx: PageContext, _ spec: Spec, _ subs: [Widget]) throws {
        guard case .form = spec.value else {
            throw "Expected .form got: \(spec)"
        }
        self.columnView.update(
                .start,
                separator: .separator,
                spacing: 0.0,
                subviews: subs.map { widget in
                    widget.getView()
                }
        )
    }
}
