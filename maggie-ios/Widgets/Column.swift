import Foundation
import SwiftUI

struct MaggieColumn: Equatable, Hashable, View {
    static let TYP = "column"
    let widgets: [MaggieWidget]
    let alignment: HorizontalAlignment
    let spacing: CGFloat

    init(_ item: JsonItem, _ session: MaggieSession) throws {
        self.widgets = try item.takeOptWidgets(session) ?? []
        self.alignment = item.takeOptHorizontalAlignment() ?? .leading
        self.spacing = item.takeOptSpacing() ?? 4.0
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(MaggieColumn.TYP)
        item.widgets = self.widgets.map({ widgets in widgets.toJsonItem() })
        item.setHorizontalAlignment(self.alignment)
        return item
    }

    var body: some View {
        VStack(alignment: self.alignment, spacing: self.spacing) {
            ForEach(self.widgets) { widget in
                widget
            }
        }
                .border(Color.green)
                .padding(1.0)
    }
}
