import Foundation
import UIKit

struct ColumnSpec: Equatable, Hashable {
    static let TYP = "column"
    let widgets: [Spec]
    let alignment: ApplinHAlignment
    let spacing: Float32

    init(_ config: ApplinConfig, pageKey: String, _ item: JsonItem) throws {
        self.widgets = try item.optWidgets(config, pageKey: pageKey) ?? []
        self.alignment = item.optAlign() ?? .start
        self.spacing = item.spacing ?? 0.0
    }

    init(_ widgets: [Spec], _ alignment: ApplinHAlignment, spacing: Float32) {
        self.widgets = widgets
        self.alignment = alignment
        self.spacing = spacing
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(ColumnSpec.TYP)
        item.widgets = self.widgets.map({ widgets in widgets.toJsonItem() })
        item.setAlign(self.alignment)
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
        ColumnWidget.self
    }

    func newWidget() -> Widget {
        print("ColumnSpec.newWidget()")
        return ColumnWidget()
    }
}

class ColumnWidget: Widget {
    let columnView: ColumnView

    init() {
        self.columnView = ColumnView()
        self.columnView.translatesAutoresizingMaskIntoConstraints = false
        //self.columnView.backgroundColor = pastelLavender
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

    func update(_: ApplinSession, _ spec: Spec, _ subs: [Widget]) throws {
        guard case let .column(columnSpec) = spec.value else {
            throw "Expected .column got: \(spec)"
        }
        self.columnView.update(
                columnSpec.alignment,
                separator: nil,
                spacing: columnSpec.spacing,
                subviews: subs.map { widget in
                    widget.getView()
                }
        )
    }
}
