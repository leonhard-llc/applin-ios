import Foundation
import UIKit

struct MaggieTall: Equatable, Hashable {
    static let TYP = "tall"
    let alignment: MaggieVAlignment
    let optMinHeight: Float32?
    let optMaxHeight: Float32?
    let widget: MaggieWidget

    init(_ item: JsonItem, _ session: MaggieSession) throws {
        self.alignment = item.optAlign() ?? .center
        (self.optMinHeight, self.optMaxHeight) = item.getMinMaxHeight()
        self.widget = try item.requireWidget(session)
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(MaggieExpand.TYP)
        item.widget = self.widget.toJsonItem()
        item.minHeight = self.optMinHeight
        item.maxHeight = self.optMaxHeight
        item.setAlign(self.alignment)
        return item
    }

    func makeView(_ session: MaggieSession) -> UIView {
        let subView = self.widget.makeView(session)
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = pastelLavender
        container.addSubview(subView)
        var constraints: [NSLayoutConstraint] = [
            subView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            subView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            subView.topAnchor.constraint(greaterThanOrEqualTo: container.topAnchor),
            subView.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor)
        ]
        switch self.alignment {
        case .center:
            constraints.append(subView.centerYAnchor.constraint(equalTo: container.centerYAnchor))
        case .top:
            constraints.append(subView.topAnchor.constraint(equalTo: container.topAnchor))
        case .bottom:
            constraints.append(subView.bottomAnchor.constraint(equalTo: container.bottomAnchor))
        }
        if let minHeight = self.optMinHeight {
            constraints.append(
                    container.heightAnchor.constraint(greaterThanOrEqualToConstant: CGFloat(minHeight)))
        }
        if let maxHeight = self.optMaxHeight {
            constraints.append(
                    container.heightAnchor.constraint(lessThanOrEqualToConstant: CGFloat(maxHeight)))
        } else {
            constraints.append(container.heightAnchor.constraint(equalToConstant: 100_000.0).withPriority(.defaultHigh))
        }
        NSLayoutConstraint.activate(constraints)
        return container
    }
}
