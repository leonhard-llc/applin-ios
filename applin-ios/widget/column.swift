import Foundation
import UIKit

// TODONT(mleonhard) Don't use UITableView since it is incapable of updating widgets

// without making them lose focus and dismiss the keyboard.

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
        ColumnWidget(self)
    }
}

class ColumnWidget: WidgetProto {
    // TODONT: Don't use UIStackView because its API is very difficult to use for dynamic updates.
    let stackView: UIView
    var alignment: ApplinHAlignment = .start
    var spacing: Float32 = 0
    var constraints = ConstraintSet()

    init(_ data: ColumnData) {
        self.stackView = UIStackView()
        self.stackView.translatesAutoresizingMaskIntoConstraints = false
        //self.stackView.backgroundColor = pastelLavender
        NSLayoutConstraint.activate([
            self.stackView.widthAnchor.constraint(equalToConstant: 100_000.0).withPriority(.defaultLow),
            self.stackView.heightAnchor.constraint(equalToConstant: 0.0).withPriority(.defaultLow),
        ])
        self.update(data, [])
    }

    func getView() -> UIView {
        self.stackView
    }

    func isFocused(_ session: ApplinSession, _ data: WidgetData) -> Bool {
        false
    }

    func update(_ session: ApplinSession, _ data: WidgetData, _ subs: [WidgetProto]) throws {
        guard case let .column(columnData) = data else {
            throw "Expected .column got: \(data)"
        }
        self.update(columnData, subs)
    }

    func update(_ data: ColumnData, _ subs: [WidgetProto]) {
        self.alignment = data.alignment
        self.spacing = data.spacing
        let newViews: [UIView] = subs.map { widget in
            widget.getView()
        }
        let newViewsSet = Set(newViews)
        let viewsToRemove: [UIView] = self.stackView.subviews.filter({ v in newViewsSet.contains(v) })
        for viewToRemove in viewsToRemove {
            viewToRemove.removeFromSuperview()
        }
        for newView in newViews {
            self.stackView.addSubview(newView)
        }
        var newConstraints: [NSLayoutConstraint] = []
        // Top
        if let first = newViews.first {
            newConstraints.append(first.topAnchor.constraint(equalTo: self.stackView.topAnchor))
        }
        // Between
        for (n, a) in newViews.dropLast(1).enumerated() {
            let b = newViews[n + 1]
            newConstraints.append(b.topAnchor.constraint(equalTo: a.bottomAnchor, constant: CGFloat(self.spacing)))
        }
        // Bottom
        if let last = newViews.last {
            newConstraints.append(last.bottomAnchor.constraint(equalTo: self.stackView.bottomAnchor))
        }
        // Left, Right, and Alignment
        for view in newViews {
            switch self.alignment {
            case .start:
                newConstraints.append(view.leftAnchor.constraint(equalTo: self.stackView.leftAnchor))
                newConstraints.append(view.rightAnchor.constraint(lessThanOrEqualTo: self.stackView.rightAnchor))
            case .center:
                newConstraints.append(view.leftAnchor.constraint(greaterThanOrEqualTo: self.stackView.leftAnchor))
                newConstraints.append(view.centerXAnchor.constraint(equalTo: self.stackView.centerXAnchor))
                newConstraints.append(view.rightAnchor.constraint(lessThanOrEqualTo: self.stackView.rightAnchor))
            case .end:
                newConstraints.append(view.leftAnchor.constraint(greaterThanOrEqualTo: self.stackView.leftAnchor))
                newConstraints.append(view.rightAnchor.constraint(equalTo: self.stackView.rightAnchor))
            }
        }
        self.constraints.set(newConstraints)
    }
}
