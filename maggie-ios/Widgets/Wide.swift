import Foundation
import SwiftUI

struct MaggieWide: Equatable, Hashable, View {
    static let TYP = "wide"
    let widget: MaggieWidget
    let minWidth: CGFloat?
    let maxWidth: CGFloat?
    let alignment: HorizontalAlignment?

    init(_ item: JsonItem, _ session: MaggieSession) throws {
        self.widget = try item.takeWidget(session)
        self.minWidth = item.takeOptMinWidth()
        self.maxWidth = item.takeOptMaxWidth()
        self.alignment = item.takeOptHorizontalAlignment()
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(MaggieWide.TYP)
        item.widget = self.widget.toJsonItem()
        item.minWidth = self.minWidth?.toDouble()
        item.maxWidth = self.maxWidth?.toDouble()
        item.setHorizontalAlignment(self.alignment)
        return item
    }

    var body: some View {
        self.widget
                .frame(
                        minWidth: self.minWidth ?? 0.0,
                        maxWidth: self.maxWidth ?? .infinity,
                        alignment: self.alignment?.toAlignment() ?? .center
                )
                .border(Color.mint)
                .padding(1.0)
    }
}
