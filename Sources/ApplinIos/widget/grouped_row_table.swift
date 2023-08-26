import Foundation
import UIKit

public struct GroupedRowTableSpec: Equatable, Hashable, ToSpec {
    static let TYP = "grouped-row-table"
    let rowGroups: [[[Spec?]]]
    let spacing: Float32

    init(_ config: ApplinConfig, _ item: JsonItem) throws {
        self.rowGroups = try item.rowGroups?.map({ rows in
            try rows.map({ row in
                try row.map({ optItem in
                    if let item = optItem {
                        return try Spec(config, item)
                    } else {
                        return nil
                    }
                })
            })
        }) ?? []
        self.spacing = item.spacing ?? 0.0
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(GroupedRowTableSpec.TYP)
        item.rowGroups = self.rowGroups.map({ rows in rows.map({ row in row.map({ widget in widget?.toJsonItem() }) }) })
        item.spacing = self.spacing
        return item
    }

    init(_ rowGroups: [[[ToSpec?]]]) {
        self.rowGroups = rowGroups.map({ rows in rows.map({ row in row.map({ optWidget in optWidget?.toSpec() }) }) })
        self.spacing = 0.0
    }

    public func toSpec() -> Spec {
        Spec(.groupedRowTable(self))
    }

    func keys() -> [String] {
        []
    }

    func priority() -> WidgetPriority {
        .stateless
    }

    func subs() -> [Spec] {
        self.rowGroups.flatMap({ group in group.flatMap({ row in row.compactMap({ $0 }) }) })
    }

    func vars() -> [(String, Var)] {
        self.rowGroups.flatMap({ group in group.flatMap({ row in row.compactMap({ widget in widget?.vars() }) }).flatMap({ $0 }) })
    }

    func widgetClass() -> AnyClass {
        GroupedRowTableWidget.self
    }

    func newWidget() -> Widget {
        return GroupedRowTableWidget()
    }

    func visitActions(_ f: (ActionSpec) -> ()) {
        self.rowGroups.forEach({ rowGroup in rowGroup.forEach({ row in row.forEach({ widget in widget?.visitActions(f) }) }) })
    }
}

class GroupedRowTableWidget: Widget {
    let tableView: TableView

    init() {
        self.tableView = TableView()
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        //self.tableView.backgroundColor = pastelLavender
        NSLayoutConstraint.activate([
            self.tableView.widthAnchor.constraint(equalToConstant: 100_000.0).withPriority(.fittingSizeLevel),
            self.tableView.heightAnchor.constraint(equalToConstant: 0.0).withPriority(.fittingSizeLevel),
        ])
    }

    func getView() -> UIView {
        self.tableView
    }

    func isFocused() -> Bool {
        false
    }

    func update(_ ctx: PageContext, _ spec: Spec, _ subs: [Widget]) throws {
        guard case let .groupedRowTable(groupedRowTableSpec) = spec.value else {
            throw "Expected .groupedRowTable got: \(spec)"
        }
        var subs: [Widget] = subs.reversed()
        var viewRows: [[UIView?]] = []
        var rowNum: UInt = 0;
        var rowSeparators: [UInt] = []
        for groupSpecs in groupedRowTableSpec.rowGroups {
            var groupEmpty = true
            let prevGroupRowNum = rowNum
            for rowSpecs in groupSpecs {
                var viewRow: [UIView?] = []
                for optSpec in rowSpecs {
                    if optSpec == nil {
                        viewRow.append(nil)
                    } else {
                        groupEmpty = false
                        viewRow.append(subs.popLast()?.getView())
                    }
                }
                if !viewRow.isEmpty {
                    viewRows.append(viewRow)
                    rowNum += 1
                }
            }
            if !groupEmpty && prevGroupRowNum > 0 {
                rowSeparators.append(prevGroupRowNum)
            }
        }
        self.tableView.update(
                rowSeparators: rowSeparators,
                spacing: groupedRowTableSpec.spacing,
                newSubviewRows: viewRows
        )
    }
}
