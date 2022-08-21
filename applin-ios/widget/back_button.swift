import Foundation
import UIKit

struct BackButtonData: Equatable, Hashable, WidgetDataProto {
    static let TYP = "back-button"
    let actions: [ActionData]
    let pageKey: String

    init(pageKey: String, _ item: JsonItem) throws {
        self.actions = try item.optActions() ?? []
        self.pageKey = pageKey
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(BackButtonData.TYP)
        item.actions = self.actions.map({ action in action.toString() })
        return item
    }

    func keys() -> [String] {
        []
    }

    func canTap() -> Bool {
        true
    }

    func tap(_ session: ApplinSession, _ cache: WidgetCache) {
        print("back-button tap")
        session.doActions(pageKey: self.pageKey, self.actions)
    }

    func getView(_ session: ApplinSession, _ widgetCache: WidgetCache) -> UIView {
        ButtonData(pageKey: self.pageKey, actions, text: "Back").getView(session, widgetCache)
    }

    func vars() -> [(String, Var)] {
        []
    }
}
