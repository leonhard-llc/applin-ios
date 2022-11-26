import Foundation
import UIKit

struct BackButtonData: Equatable, Hashable {
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

    func subs() -> [Spec] {
        []
    }

    func vars() -> [(String, Var)] {
        []
    }

    func priority() -> WidgetPriority {
        .stateless
    }

    func widgetClass() -> AnyClass {
        BackButtonWidget.self
    }

    func widget() -> WidgetProto {
        BackButtonWidget()
    }

    func tap(_ session: ApplinSession, _ cache: WidgetCache) {
        print("back-button tap")
        session.doActions(pageKey: self.pageKey, self.actions)
    }
}

class BackButtonWidget: WidgetProto {
    func isFocused(_: ApplinSession, _: Spec) -> Bool {
        false
    }

    func update(_: ApplinSession, _: Spec, _: [WidgetProto]) throws {
    }

    func getView() -> UIView {
        UIView()
    }
}
