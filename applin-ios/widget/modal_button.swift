import Foundation
import UIKit

struct ModalButtonData: Equatable, Hashable {
    static let TYP = "modal-button"
    let actions: [ApplinAction]
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

    init(_ actions: [ApplinAction], text: String) {
        self.actions = actions
        self.isCancel = false
        self.isDefault = false
        self.isDestructive = false
        self.text = text
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(ModalButtonData.TYP)
        item.actions = self.actions.map({ action in action.toString() })
        item.isDefault = self.isDefault
        item.isDestructive = self.isDestructive
        item.text = self.text
        return item
    }

    func toAlertAction(_ session: ApplinSession) -> UIAlertAction {
        let style: UIAlertAction.Style
        if self.isCancel {
            style = .cancel
        } else if self.isDestructive {
            style = .destructive
        } else {
            style = .default
        }
        let handler = { [weak session] (_: UIAlertAction) in
            print("modal-button actions")
            session?.doActions(self.actions)
        }
        let action = UIAlertAction(title: self.text, style: style, handler: handler)
        action.isEnabled = !self.actions.isEmpty
        return action
    }
}
