import Foundation
import UIKit

struct ColumnData: Equatable, Hashable, WidgetDataProto {
    static let TYP = "column"
    let widgets: [WidgetData]
    let alignment: ApplinHAlignment
    let spacing: Float32

    init(_ session: ApplinSession?, pageKey: String, _ item: JsonItem) throws {
        self.widgets = try item.optWidgets(session, pageKey: pageKey) ?? []
        self.alignment = item.optAlign() ?? .start
        self.spacing = item.spacing ?? 0.0
    }

    init(_ widgets: [WidgetData], _ alignment: ApplinHAlignment, spacing: Float32) {
        self.widgets = widgets
        self.alignment = alignment
        self.spacing = spacing
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(ColumnData.TYP)
        item.widgets = self.widgets.map({ widgets in widgets.inner().toJsonItem() })
        item.setAlign(self.alignment)
        return item
    }

    func keys() -> [String] {
        []
    }

    func priority() -> WidgetPriority {
        .stateless
    }

    func subs() -> [WidgetData] {
        self.widgets
    }

    func vars() -> [(String, Var)] {
        self.widgets.flatMap({ widget in widget.inner().vars() })
    }

    func widgetClass() -> AnyClass {
        ColumnWidget.self
    }

    func widget() -> WidgetProto {
        ColumnWidget()
    }
}

class ColumnWidget: WidgetProto {
    let columnView: ColumnView

    init() {
        self.columnView = ColumnView()
        self.columnView.translatesAutoresizingMaskIntoConstraints = false
        //self.columnView.backgroundColor = pastelLavender
        NSLayoutConstraint.activate([
            self.columnView.widthAnchor.constraint(equalToConstant: 100_000.0).withPriority(.defaultLow),
            self.columnView.heightAnchor.constraint(equalToConstant: 0.0).withPriority(.defaultLow),
        ])
    }

    func getView() -> UIView {
        self.columnView
    }

    func isFocused(_ session: ApplinSession, _ data: WidgetData) -> Bool {
        false
    }

    func update(_ session: ApplinSession, _ data: WidgetData, _ subs: [WidgetProto]) throws {
        guard case let .column(columnData) = data else {
            throw "Expected .column got: \(data)"
        }
        self.columnView.update(
                columnData.alignment,
                separator: nil,
                spacing: columnData.spacing,
                subviews: subs.map { widget in
                    widget.getView()
                }
        )
    }
}
