import Foundation
import UIKit

public struct ColumnSpec: Equatable, Hashable, ToSpec {
    static let TYP = "column"
    let widgets: [Spec]
    let alignment: ApplinHAlignment
    let spacing: Float32

    public init(alignment: ApplinHAlignment = .start, spacing: Float32 = 0.0, _ widgets: [ToSpec]) {
        self.widgets = widgets.map({ widget in widget.toSpec() })
        self.alignment = alignment
        self.spacing = spacing
    }

    init(_ config: ApplinConfig, _ item: JsonItem) throws {
        self.widgets = try item.optWidgets(config) ?? []
        self.alignment = item.optAlign() ?? .start
        self.spacing = item.spacing ?? 0.0
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(ColumnSpec.TYP)
        item.widgets = self.widgets.map({ widgets in widgets.toJsonItem() })
        item.setAlign(self.alignment)
        return item
    }

    public func toSpec() -> Spec {
        Spec(.column(self))
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
        ColumnWidget()
    }

    func visitActions(_ f: (ActionSpec) -> ()) {
        self.widgets.forEach({ widget in widget.visitActions(f) })
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

    func update(_ ctx: PageContext, _ spec: Spec, _ subs: [Widget]) throws {
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
