import Foundation
import UIKit

struct ModalButtonData: Equatable, Hashable {
    static let TYP = "modal-button"
    let actions: [ActionData]
    let isCancel: Bool
    let isDefault: Bool
    let isDestructive: Bool
    let text: String

    init(_ item: JsonItem) throws {
        self.actions = try item.optActions() ?? []
        self.isCancel = item.isCancel ?? false
        self.isDefault = item.isDefault ?? false
        self.isDestructive = item.isDestructive ?? false
        self.text = try item.requireText()
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(ModalButtonData.TYP)
        item.actions = self.actions.map({ action in action.toString() })
        item.isDefault = self.isDefault
        item.isDestructive = self.isDestructive
        item.text = self.text
        return item
    }

    func style() -> UIAlertAction.Style {
        if self.isCancel {
            return .cancel
        } else if self.isDestructive {
            return .destructive
        } else {
            return .default
        }
    }

    func toAlertAction(_ session: ApplinSession, pageKey: String) -> UIAlertAction {
        let handler = { [weak session] (_: UIAlertAction) in
            print("modal-button actions")
            session?.doActions(pageKey: pageKey, self.actions)
        }
        let action = UIAlertAction(title: self.text, style: self.style(), handler: handler)
        action.isEnabled = !self.actions.isEmpty
        return action
    }
}
