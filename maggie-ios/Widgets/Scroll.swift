import Foundation
import SwiftUI

struct MaggieScroll: Equatable, Hashable, View {
    static let TYP = "scroll"
    let widget: MaggieWidget
    
    init(_ item: JsonItem, _ session: MaggieSession) throws {
        self.widget = try item.takeWidget(session)
    }
    
    func toJsonItem() -> JsonItem {
        let item = JsonItem(MaggieScroll.TYP)
        item.widget = self.widget.toJsonItem()
        return item
    }
    
    var body: some View {
        ScrollView(Axis.Set.vertical) {
            self.widget
        }
    }
}
