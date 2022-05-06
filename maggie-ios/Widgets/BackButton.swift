import Foundation
import SwiftUI

// TODO: Remove.
func backButton(_ session: MaggieSession) -> some View {
    return Button(action: { session.pop() }) {
        HStack(spacing: 4) {
            Image(systemName: "chevron.backward")
                .font(Font.body.weight(.semibold))
            Text("Back")
        }
    }.padding(Edge.Set.leading, -8.0)
}

struct MaggieBackButton: Equatable, Hashable, View {
    static func == (lhs: MaggieBackButton, rhs: MaggieBackButton) -> Bool {
        return lhs.actions == rhs.actions
    }
    
    static let TYP = "back-button"
    let actions: [MaggieAction]
    weak var session: MaggieSession?
    
    init(_ item: JsonItem, _ session: MaggieSession) throws {
        self.actions = try item.takeOptActions() ?? []
        self.session = session
    }
    
    func hash(into hasher: inout Hasher) {
        self.actions.hash(into: &hasher)
    }
    
    func toJsonItem() -> JsonItem {
        let item = JsonItem(MaggieBackButton.TYP)
        item.actions = self.actions.map({action in action.toString()})
        return item
    }
    
    // TODO: Add chevron and fix styling.
    var body: some View {
        Button(
            "Back",
            action: { self.session?.doActions(self.actions) }
        ).disabled(self.actions.isEmpty)
    }
}
