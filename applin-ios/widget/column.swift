import Foundation
import UIKit

struct ColumnData: Equatable, Hashable, WidgetDataProto {
    static let TYP = "column"
    let widgets: [WidgetData]
    let alignment: ApplinHAlignment
    let spacing: Float32

    init(_ item: JsonItem, _ session: ApplinSession) throws {
        self.widgets = try item.optWidgets(session) ?? []
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

    func getTapActions() -> [ActionData]? {
        nil
    }

    func getView(_ session: ApplinSession, _ widgetCache: WidgetCache) -> UIView {
        let subViews = self.widgets.map({ widget in widget.inner().getView(session, widgetCache) })
        let view = UIStackView(arrangedSubviews: subViews)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .vertical
        view.backgroundColor = pastelPink
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
}
