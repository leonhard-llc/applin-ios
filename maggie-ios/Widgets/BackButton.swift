import Foundation
import SwiftUI

struct MaggieBackButton: Equatable, Hashable, View {
    static func ==(lhs: MaggieBackButton, rhs: MaggieBackButton) -> Bool {
        return lhs.actions == rhs.actions
    }

    static let TYP = "back-button"
    let actions: [MaggieAction]
    weak var session: MaggieSession?

    init(_ actions: [MaggieAction], _ session: MaggieSession) {
        self.actions = actions
        self.session = session
    }

    init(_ item: JsonItem, _ session: MaggieSession) throws {
        self.actions = try item.takeOptActions() ?? []
        self.session = session
    }

    func hash(into hasher: inout Hasher) {
        self.actions.hash(into: &hasher)
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(MaggieBackButton.TYP)
        item.actions = self.actions.map({ action in action.toString() })
        return item
    }

    func doActions() {
        self.session?.doActions(self.actions)
    }

    var body: some View {
        Button(action: self.doActions) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.backward")
                        .font(Font.body.weight(.semibold))
                Text("Back")
            }
        }
                .disabled(self.actions.isEmpty)
    }
}
