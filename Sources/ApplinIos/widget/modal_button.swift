import Foundation
import UIKit

public struct ModalButtonSpec: Equatable, Hashable {
    static let TYP = "modal_button"
    let actions: [ActionSpec]
    let isCancel: Bool
    let isDefault: Bool
    let isDestructive: Bool
    let text: String

    init(_ item: JsonItem) throws {
        self.actions = try item.optActions() ?? []
        self.isCancel = item.is_cancel ?? false
        self.isDefault = item.is_default ?? false
        self.isDestructive = item.is_destructive ?? false
        self.text = try item.requireText()
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(ModalButtonSpec.TYP)
        item.actions = self.actions.map({ action in action.toString() })
        item.is_default = self.isDefault
        item.is_destructive = self.isDestructive
        item.text = self.text
        return item
    }

    init(text: String, isCancel: Bool = false, isDefault: Bool = false, isDestructive: Bool = false, _ actions: [ActionSpec]) {
        self.actions = actions
        self.isCancel = isCancel
        self.isDefault = isDefault
        self.isDestructive = isDestructive
        self.text = text
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

    func toAlertAction(_ ctx: PageContext, pageKey: String) -> UIAlertAction {
        let handler = { (_: UIAlertAction) -> Void in
            Task {
                let _ = await ctx.pageStack?.doActions(pageKey: ctx.pageKey, self.actions)
            }
        }
        let action = UIAlertAction(title: self.text, style: self.style(), handler: handler)
        action.isEnabled = !self.actions.isEmpty
        return action
    }
}
