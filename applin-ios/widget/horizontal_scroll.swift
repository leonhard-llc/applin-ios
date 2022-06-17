//import Foundation
//import UIKit
//
//struct ApplinHorizontalScroll: Equatable, Hashable {
//    static let TYP = "horizontal-scroll"
//    let widget: WidgetData
//
//    init(_ item: JsonItem, _ session: ApplinSession) throws {
//        self.widget = try item.requireWidget(session)
//    }
//
//    func toJsonItem() -> JsonItem {
//        let item = JsonItem(ApplinHorizontalScroll.TYP)
//        item.widget = self.widget.toJsonItem()
//        return item
//    }
//
//    func makeView(_ session: ApplinSession) -> UIView {
//        let subView = self.widget.makeView(session)
//        let scrollView = UIScrollView()
//        scrollView.translatesAutoresizingMaskIntoConstraints = false
//        scrollView.backgroundColor = pastelGreen
//        scrollView.addSubview(subView)
//        var constraints: [NSLayoutConstraint] = [
//            subView.leadingAnchor.constraint(greaterThanOrEqualTo: scrollView.leadingAnchor),
//            subView.topAnchor.constraint(greaterThanOrEqualTo: scrollView.topAnchor),
//            subView.bottomAnchor.constraint(lessThanOrEqualTo: scrollView.bottomAnchor),
//        ]
//        constraints.append(scrollView.widthAnchor.constraint(equalToConstant: 100_000.0).withPriority(.defaultLow))
//        NSLayoutConstraint.activate(constraints)
//        print("horizontal-scroll constraints: \(constraints)")
//        return scrollView
//    }
//}
