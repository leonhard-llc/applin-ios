import Foundation
import SwiftUI

struct MaggieRow: Equatable, Hashable, View {
    static let TYP = "row"
    let widgets: [MaggieWidget]
    let alignment: VerticalAlignment
    let spacing: CGFloat?
    
    init(_ item: JsonItem, _ session: MaggieSession) throws {
        self.widgets = try item.takeOptWidgets(session) ?? []
        self.alignment = item.takeOptVerticalAlignment() ?? .top
        self.spacing = item.takeOptSpacing()
    }
    
    func toJsonItem() -> JsonItem {
        let item = JsonItem(MaggieRow.TYP)
        item.widgets = self.widgets.map({widgets in widgets.toJsonItem()})
        item.setVerticalAlignment(self.alignment)
        item.spacing = self.spacing?.toDouble()
        return item
    }
    
    var body: some View {
        HStack(alignment: self.alignment, spacing: self.spacing ?? 4.0) {
            ForEach(self.widgets) {
                widget in widget
            }
        }
        .border(Color.blue)
        .padding(1.0)
    }
}
