//import Foundation
//import UIKit
//
//struct MaggieExpand: Equatable, Hashable {
//    static let TYP = "expand"
//    let widget: WidgetData
//    let optMinWidth: Float32?
//    let optMaxWidth: Float32?
//    let optMinHeight: Float32?
//    let optMaxHeight: Float32?
//    let alignment: MaggieAlignment
//
//    init(_ widget: WidgetData) {
//        self.widget = widget
//        self.optMinWidth = nil
//        self.optMaxWidth = nil
//        self.optMinHeight = nil
//        self.optMaxHeight = nil
//        self.alignment = .center
//    }
//
//    init(_ item: JsonItem, _ session: MaggieSession) throws {
//        self.widget = try item.requireWidget(session)
//        (self.optMinWidth, self.optMaxWidth) = item.getMinMaxWidth()
//        (self.optMinHeight, self.optMaxHeight) = item.getMinMaxHeight()
//        self.alignment = item.optAlign() ?? .center
//    }
//
//    func toJsonItem() -> JsonItem {
//        let item = JsonItem(MaggieExpand.TYP)
//        item.widget = self.widget.toJsonItem()
//        item.minWidth = self.optMinWidth
//        item.maxWidth = self.optMaxWidth
//        item.minHeight = self.optMinHeight
//        item.maxHeight = self.optMaxHeight
//        item.setAlign(self.alignment)
//        return item
//    }
//
//    func makeView(_ session: MaggieSession) -> UIView {
//        let subView = self.widget.makeView(session)
//        let container = UIView()
//        container.translatesAutoresizingMaskIntoConstraints = false
//        container.backgroundColor = pastelLavender
//        container.addSubview(subView)
//        var constraints: [NSLayoutConstraint] = [
//            subView.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor),
//            subView.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor),
//            subView.topAnchor.constraint(greaterThanOrEqualTo: container.topAnchor),
//            subView.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor),
//            subView.widthAnchor.constraint(equalToConstant: 100_000.0).withPriority(.defaultLow),
//            subView.heightAnchor.constraint(equalToConstant: 100_000.0).withPriority(.defaultLow),
//        ]
//        switch self.alignment.horizontal() {
//        case .center:
//            constraints.append(subView.centerXAnchor.constraint(equalTo: container.centerXAnchor))
//        case .start:
//            constraints.append(subView.leadingAnchor.constraint(equalTo: container.leadingAnchor))
//        case .end:
//            constraints.append(subView.trailingAnchor.constraint(equalTo: container.trailingAnchor))
//        }
//        switch self.alignment.vertical() {
//        case .center:
//            constraints.append(subView.centerYAnchor.constraint(equalTo: container.centerYAnchor))
//        case .top:
//            constraints.append(subView.topAnchor.constraint(equalTo: container.topAnchor))
//        case .bottom:
//            constraints.append(subView.bottomAnchor.constraint(equalTo: container.bottomAnchor))
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
//        if let minHeight = self.optMinHeight {
//            constraints.append(
//                    container.heightAnchor.constraint(greaterThanOrEqualToConstant: CGFloat(minHeight)))
//        }
//        if let maxHeight = self.optMaxHeight {
//            constraints.append(
//                    container.heightAnchor.constraint(lessThanOrEqualToConstant: CGFloat(maxHeight)))
//        } else {
//            constraints.append(container.heightAnchor.constraint(equalToConstant: 100_000.0).withPriority(.defaultHigh))
//        }
//        NSLayoutConstraint.activate(constraints)
//        return container
//    }
//}
