import Foundation
import SwiftUI

struct MaggieButton: Equatable, Hashable, View {
    static func == (lhs: MaggieButton, rhs: MaggieButton) -> Bool {
        return lhs.text == rhs.text
        && lhs.isDefault == rhs.isDefault
        && lhs.isDestructive == rhs.isDestructive
        && lhs.actions == rhs.actions
    }
    
    static let TYP = "button"
    let text: String
    let isDefault: Bool
    let isDestructive: Bool
    let actions: [MaggieAction]
    weak var session: MaggieSession?
    
    init(_ item: JsonItem, _ session: MaggieSession) throws {
        self.text = try item.takeText()
        self.isDefault = item.takeOptIsDefault() ?? false
        self.isDestructive = item.takeOptIsDestructive() ?? false
        self.actions = try item.takeOptActions() ?? []
        self.session = session
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.text)
        hasher.combine(self.isDefault)
        hasher.combine(self.isDestructive)
        hasher.combine(self.actions)
    }
    
    func toJsonItem() -> JsonItem {
        let item = JsonItem(MaggieButton.TYP)
        item.text = self.text
        item.isDefault = self.isDefault
        item.isDestructive = self.isDestructive
        item.actions = self.actions.map({action in action.toString()})
        return item
    }
    
    var body: some View {
        Button(
            self.text,
            role: self.isDestructive ? .destructive : nil,
            action: { () in
                print("Button(\(self.text)) action")
                self.session?.doActions(self.actions)
            }
        )
            .disabled(self.actions.isEmpty)
            .buttonStyle(.bordered)
    }
}

