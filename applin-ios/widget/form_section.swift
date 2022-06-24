import Foundation
import UIKit

struct FormSectionData: Equatable, Hashable, WidgetDataProto {
    static let TYP = "form-section"
    let title: String
    let widgets: [WidgetData]

    init(_ title: String, _ widgets: [WidgetData]) {
        self.title = title
        self.widgets = widgets
    }

    init(_ item: JsonItem, _ session: ApplinSession) throws {
        self.title = try item.requireTitle()
        self.widgets = try item.optWidgets(session) ?? []
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(FormSectionData.TYP)
        item.title = self.title
        item.widgets = self.widgets.map({ widgets in widgets.inner().toJsonItem() })
        return item
    }

    func keys() -> [String] {
        []
    }

    func getTapActions() -> [ActionData]? {
        nil
    }

    func getView(_ session: ApplinSession, _ widgetCache: WidgetCache) -> UIView {
        TextData("error: form-section not in form").getView(session, widgetCache)
    }
}
