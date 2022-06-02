import Foundation
import UIKit

struct MaggieColumn: Equatable, Hashable {
    static let TYP = "column"
    let widgets: [MaggieWidget]
    let alignment: MaggieHAlignment
    let spacing: Float32

    init(_ item: JsonItem, _ session: MaggieSession) throws {
        self.widgets = try item.optWidgets(session) ?? []
        self.alignment = item.optAlign() ?? .start
        self.spacing = item.spacing ?? Float32(UIStackView.spacingUseDefault)
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(MaggieColumn.TYP)
        item.widgets = self.widgets.map({ widgets in widgets.toJsonItem() })
        item.setAlign(self.alignment)
        return item
    }

    func makeView(_ session: MaggieSession) -> UIView {
        let subViews = self.widgets.map({ widget in widget.makeView(session) })
        let stack = UIStackView(arrangedSubviews: subViews)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.backgroundColor = pastelPink
        switch self.alignment {
        case .center:
            stack.alignment = .center
        case .start:
            stack.alignment = .leading
        case .end:
            stack.alignment = .trailing
        }
        stack.spacing = CGFloat(self.spacing)
        return stack
    }
}
