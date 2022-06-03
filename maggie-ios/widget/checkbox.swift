import Foundation
import UIKit

struct MaggieCheckbox: Equatable, Hashable {
    static func ==(lhs: MaggieCheckbox, rhs: MaggieCheckbox) -> Bool {
        lhs.id == rhs.id
                && lhs.initialBool == rhs.initialBool
                && lhs.actions == rhs.actions
    }

    static let TYP = "checkbox"
    let id: String
    let initialBool: Bool
    let actions: [MaggieAction]
    weak var session: MaggieSession?

    init(_ item: JsonItem, _ session: MaggieSession) throws {
        self.actions = try item.optActions() ?? []
        self.id = try item.requireId()
        self.initialBool = item.initialBool ?? false
        self.session = session
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.actions)
        hasher.combine(self.id)
        hasher.combine(self.initialBool)
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(MaggieCheckbox.TYP)
        item.actions = self.actions.map({ action in action.toString() })
        item.id = self.id
        item.initialBool = self.initialBool
        return item
    }

    func makeView(_ session: MaggieSession) -> UIView {
        let widget = UISwitch()
        widget.translatesAutoresizingMaskIntoConstraints = false
        widget.addAction(for: .valueChanged, handler: { _ in
            print("checkbox actions")
            session.doActions(self.actions)
        })
        widget.preferredStyle = .checkbox
        widget.setOn(self.initialBool, animated: true)
        return widget
    }
}
