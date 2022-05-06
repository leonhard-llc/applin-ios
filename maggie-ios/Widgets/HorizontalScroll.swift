import Foundation
import SwiftUI

struct MaggieHorizontalScroll: Equatable, Hashable, View {
    static let TYP = "horizontal-scroll"
    let widget: MaggieWidget
    
    init(_ item: JsonItem, _ session: MaggieSession) throws {
        self.widget = try item.takeWidget(session)
    }
    
    func toJsonItem() -> JsonItem {
        let item = JsonItem(MaggieHorizontalScroll.TYP)
        item.widget = self.widget.toJsonItem()
        return item
    }
    
    var body: some View {
        ScrollView(Axis.Set.horizontal) {
            self.widget
        }
    }
}
