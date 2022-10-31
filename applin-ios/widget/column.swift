import Foundation
import UIKit

// TODONT(mleonhard) Don't use UITableView since it is incapable of updating widgets

// without making them lose focus and dismiss the keyboard.

struct ColumnData: Equatable, Hashable, WidgetDataProto {
    static let TYP = "column"
    let widgets: [WidgetData]
    let alignment: ApplinHAlignment
    let spacing: Float32

    init(pageKey: String, _ item: JsonItem) throws {
        self.widgets = try item.optWidgets(pageKey: pageKey) ?? []
        self.alignment = item.optAlign() ?? .start
        self.spacing = item.spacing ?? 0.0
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
    let view: UIView
    var alignment: ApplinHAlignment = .start
    var spacing: Float32 = 0
    var constraints = ConstraintSet()

    init(_ data: ColumnData) {
        self.view = UIStackView()
        self.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.backgroundColor = pastelLavender
        self.update(data, [])
    }

    func getView() -> UIView {
        self.view
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
        let viewsToRemove: [UIView] = self.view.subviews.filter({ v in newViewsSet.contains(v) })
        for viewToRemove in viewsToRemove {
            viewToRemove.removeFromSuperview()
        }
        for newView in newViews {
            self.view.addSubview(newView)
        }
        var newConstraints: [NSLayoutConstraint] = []
        newConstraints.reserveCapacity(3 * newViews.count + 1)
        // Top
        if let first = newViews.first {
            newConstraints.append(first.topAnchor.constraint(equalTo: self.view.topAnchor))
        }
        // Between
        for (n, a) in newViews.dropLast(1).enumerated() {
            let b = newViews[n + 1]
            newConstraints.append(b.topAnchor.constraint(equalTo: a.bottomAnchor, constant: CGFloat(self.spacing)))
        }
        // Bottom
        if let last = newViews.last {
            newConstraints.append(last.bottomAnchor.constraint(equalTo: self.view.bottomAnchor))
        }
        // Left, Right, and Alignment
        for view in newViews {
            switch self.alignment {
            case .start:
                newConstraints.append(view.leftAnchor.constraint(equalTo: self.view.leftAnchor))
                newConstraints.append(view.rightAnchor.constraint(lessThanOrEqualTo: self.view.rightAnchor))
            case .center:
                newConstraints.append(view.leftAnchor.constraint(greaterThanOrEqualTo: self.view.leftAnchor))
                newConstraints.append(view.centerXAnchor.constraint(equalTo: self.view.centerXAnchor))
                newConstraints.append(view.rightAnchor.constraint(lessThanOrEqualTo: self.view.rightAnchor))
            case .end:
                newConstraints.append(view.leftAnchor.constraint(greaterThanOrEqualTo: self.view.leftAnchor))
                newConstraints.append(view.rightAnchor.constraint(equalTo: self.view.rightAnchor))
            }
        }
        self.constraints.set(newConstraints)
    }
}
