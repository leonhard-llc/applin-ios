import Foundation
import SwiftUI

struct MaggieTall: Equatable, Hashable, View {
    static let TYP = "tall"
    let widget: MaggieWidget
    let minHeight: CGFloat?
    let maxHeight: CGFloat?
    let alignment: VerticalAlignment?

    init(_ item: JsonItem, _ session: MaggieSession) throws {
        self.widget = try item.takeWidget(session)
        self.minHeight = item.takeOptMinHeight()
        self.maxHeight = item.takeOptMaxHeight()
        self.alignment = item.takeOptVerticalAlignment()
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(MaggieExpand.TYP)
        item.widget = self.widget.toJsonItem()
        item.minHeight = self.minHeight?.toDouble()
        item.maxHeight = self.maxHeight?.toDouble()
        item.setVerticalAlignment(self.alignment)
        return item
    }

    var body: some View {
        self.widget
                .frame(
                        minHeight: self.minHeight ?? 0.0,
                        maxHeight: self.maxHeight ?? .infinity,
                        alignment: self.alignment?.toAlignment() ?? .center
                )
                .border(Color.brown)
                .padding(1.0)
    }
}
