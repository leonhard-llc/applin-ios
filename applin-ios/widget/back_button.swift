import Foundation
import UIKit

struct BackButtonData: Equatable, Hashable, WidgetDataProto {
    static let TYP = "back-button"
    let actions: [ActionData]

    init(_ item: JsonItem) throws {
        self.actions = try item.optActions() ?? []
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(BackButtonData.TYP)
        item.actions = self.actions.map({ action in action.toString() })
        return item
    }

    func keys() -> [String] {
        ButtonData(actions, text: "Back").keys()
    }

    func getTapActions() -> [ActionData]? {
        nil
    }

    func getView(_ session: ApplinSession, _ widgetCache: WidgetCache) -> UIView {
        ButtonData(actions, text: "Back").getView(session, widgetCache)
    }
}
