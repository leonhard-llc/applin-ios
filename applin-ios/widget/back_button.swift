import Foundation
import UIKit

struct BackButtonSpec: Equatable, Hashable {
    static let TYP = "back-button"
    let actions: [ActionSpec]
    let pageKey: String

    init(pageKey: String, _ item: JsonItem) throws {
        self.actions = try item.optActions() ?? []
        self.pageKey = pageKey
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(BackButtonSpec.TYP)
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

    func newWidget() -> Widget {
        print("BackButtonSpec.newWidget(\(self))")
        return BackButtonWidget()
    }

    func tap(_ session: ApplinSession, _ cache: WidgetCache) {
        print("back-button tap")
        session.doActions(pageKey: self.pageKey, self.actions)
    }
}

class BackButtonWidget: Widget {
    func isFocused() -> Bool {
        false
    }

    func update(_ session: ApplinSession, _ state: ApplinState, _ spec: Spec, _ subs: [Widget]) throws {
    }

    func getView() -> UIView {
        NamedUIView(name: "BackButtonWidget")
    }
}
