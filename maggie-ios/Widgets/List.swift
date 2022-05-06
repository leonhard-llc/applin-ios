import Foundation
import SwiftUI

struct MaggieList: Equatable, Hashable, View {
    static let TYP = "list"
    let title: String?
    let widgets: [MaggieWidget]
    
    init(_ item: JsonItem, _ session: MaggieSession) throws {
        self.title = try item.takeOptTitle()
        self.widgets = try item.takeOptWidgets(session) ?? []
    }
    
    func toJsonItem() -> JsonItem {
        let item = JsonItem(MaggieList.TYP)
        item.title = self.title
        item.widgets = self.widgets.map({widgets in widgets.toJsonItem()})
        return item
    }
    
    var body: some View {
        List(self.widgets) {
            $0
        }
        .listStyle(.plain)
    }
}
