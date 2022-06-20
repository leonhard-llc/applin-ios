import Foundation

struct BackButtonData: Equatable, Hashable {
    static let TYP = "back-button"
    let actions: [ActionData]

    init(_ actions: [ActionData], _ session: ApplinSession?) {
        self.actions = actions
    }

    init(_ item: JsonItem) throws {
        self.actions = try item.optActions() ?? []
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(BackButtonData.TYP)
        item.actions = self.actions.map({ action in action.toString() })
        return item
    }
}
