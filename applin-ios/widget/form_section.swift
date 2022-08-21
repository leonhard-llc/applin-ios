import Foundation
import UIKit

struct FormSectionData: Equatable, Hashable, WidgetDataProto {
    static let TYP = "form-section"
    let optTitle: String?
    let widgets: [WidgetData]

    init(_ title: String?, _ widgets: [WidgetData]) {
        self.optTitle = title
        self.widgets = widgets
    }

    init(_ session: ApplinSession, pageKey: String, _ item: JsonItem) throws {
        self.optTitle = item.title
        self.widgets = try item.optWidgets(session, pageKey: pageKey) ?? []
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(FormSectionData.TYP)
        item.title = self.optTitle
        item.widgets = self.widgets.map({ widgets in widgets.inner().toJsonItem() })
        return item
    }

    func keys() -> [String] {
        []
    }

    func getTapActions() -> [ActionData]? {
        nil
    }

    func getView(_ session: ApplinSession, _ cache: WidgetCache) -> UIView {
        TextData("error: form-section not in form").getView(session, cache)
    }

    func vars() -> [(String, Var)] {
        print("WARN form-section not in form")
        return []
    }
}
