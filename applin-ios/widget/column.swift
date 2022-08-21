import Foundation
import UIKit

struct ColumnData: Equatable, Hashable, WidgetDataProto {
    static let TYP = "column"
    let widgets: [WidgetData]
    let alignment: ApplinHAlignment
    let spacing: Float32

    init(_ session: ApplinSession, pageKey: String, _ item: JsonItem) throws {
        self.widgets = try item.optWidgets(session, pageKey: pageKey) ?? []
        self.alignment = item.optAlign() ?? .start
        self.spacing = item.spacing ?? Float32(UIStackView.spacingUseDefault)
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

    func canTap() -> Bool {
        false
    }

    func tap(_ session: ApplinSession, _ cache: WidgetCache) {
    }

    func getView(_ session: ApplinSession, _ cache: WidgetCache) -> UIView {
        let subViews = self.widgets.map({ widget in widget.inner().getView(session, cache) })
        let view = UIStackView(arrangedSubviews: subViews)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .vertical
        // view.backgroundColor = pastelPink
        switch self.alignment {
        case .center:
            view.alignment = .center
        case .start:
            view.alignment = .leading
        case .end:
            view.alignment = .trailing
        }
        view.spacing = CGFloat(self.spacing)
        return view
    }

    func vars() -> [(String, Var)] {
        self.widgets.flatMap({ widget in widget.inner().vars() })
    }
}
