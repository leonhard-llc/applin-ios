//import Foundation
//import UIKit
//
//struct ApplinWide: Equatable, Hashable {
//    static let TYP = "wide"
//    let alignment: ApplinHAlignment
//    let optMinWidth: Float32?
//    let optMaxWidth: Float32?
//    let widget: WidgetData
//
//    init(_ item: JsonItem, _ session: ApplinSession) throws {
//        self.alignment = item.optAlign() ?? .center
//        (self.optMinWidth, self.optMaxWidth) = item.getMinMaxWidth()
//        self.widget = try item.requireWidget(session)
//    }
//
//    func toJsonItem() -> JsonItem {
//        let item = JsonItem(ApplinWide.TYP)
//        item.setAlign(self.alignment)
//        item.minWidth = self.optMinWidth
//        item.maxWidth = self.optMaxWidth
//        item.widget = self.widget.toJsonItem()
//        return item
//    }
//
//    func makeView(_ session: ApplinSession) -> UIView {
//        let subView = self.widget.makeView(session)
//        let container = UIView()
//        container.translatesAutoresizingMaskIntoConstraints = false
//        container.backgroundColor = pastelMint
//        container.addSubview(subView)
//        var constraints: [NSLayoutConstraint] = [
//            subView.topAnchor.constraint(equalTo: container.topAnchor),
//            subView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
//            subView.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor),
//            subView.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor)
//        ]
//        switch self.alignment {
//        case .center:
//            constraints.append(subView.centerXAnchor.constraint(equalTo: container.centerXAnchor))
//        case .start:
//            constraints.append(subView.leadingAnchor.constraint(equalTo: container.leadingAnchor))
//        case .end:
//            constraints.append(subView.trailingAnchor.constraint(equalTo: container.trailingAnchor))
//        }
//        if let minWidth = self.optMinWidth {
//            constraints.append(
//                    container.widthAnchor.constraint(greaterThanOrEqualToConstant: CGFloat(minWidth)))
//        }
//        if let maxWidth = self.optMaxWidth {
//            constraints.append(
//                    container.widthAnchor.constraint(lessThanOrEqualToConstant: CGFloat(maxWidth)))
//        } else {
//            constraints.append(container.widthAnchor.constraint(equalToConstant: 100_000.0).withPriority(.defaultHigh))
//        }
//        NSLayoutConstraint.activate(constraints)
//        print("wide constraints: \(constraints)")
//        return container
//    }
//}
