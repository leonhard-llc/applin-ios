import Foundation
import SwiftUI

struct MaggieExpand: Equatable, Hashable, View {
    static let TYP = "expand"
    let widget: MaggieWidget
    let minWidth: CGFloat?
    let maxWidth: CGFloat?
    let minHeight: CGFloat?
    let maxHeight: CGFloat?
    let alignment: Alignment

    init(_ widget: MaggieWidget) {
        self.widget = widget
        self.minWidth = nil
        self.maxWidth = nil
        self.minHeight = nil
        self.maxHeight = nil
        self.alignment = .center
    }

    init(_ item: JsonItem, _ session: MaggieSession) throws {
        self.widget = try item.takeWidget(session)
        self.minWidth = item.takeOptMinWidth()
        self.maxWidth = item.takeOptMaxWidth()
        self.minHeight = item.takeOptMinHeight()
        self.maxHeight = item.takeOptMaxHeight()
        self.alignment = item.takeOptAlignment() ?? .center
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(MaggieExpand.TYP)
        item.widget = self.widget.toJsonItem()
        item.minWidth = self.minWidth != nil ? Double(self.minWidth!) : nil
        item.maxWidth = self.maxWidth != nil ? Double(self.maxWidth!) : nil
        item.minHeight = self.minHeight != nil ? Double(self.minHeight!) : nil
        item.maxHeight = self.maxHeight != nil ? Double(self.maxHeight!) : nil
        item.setAlignment(self.alignment)
        return item
    }

    var body: some View {
        self.widget
                .frame(
                        minWidth: self.minWidth,
                        maxWidth: self.maxWidth ?? .infinity,
                        minHeight: self.minHeight,
                        maxHeight: self.maxHeight ?? .infinity,
                        alignment: self.alignment
                )
                .border(Color.red)
                .padding(1.0)
    }
}
