import Foundation
import UIKit

struct ScrollData: Equatable, Hashable {
    static let TYP = "scroll"
    let widget: WidgetData

    init(_ item: JsonItem, _ session: MaggieSession) throws {
        self.widget = try item.requireWidget(session)
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(ScrollData.TYP)
        item.widget = self.widget.toJsonItem()
        return item
    }

    func getView(_ session: MaggieSession, _ widgetCache: WidgetCache) -> UIView {
        var scrollWidget: ScrollWidget
        if widgetCache.scroll.isEmpty {
            scrollWidget = ScrollWidget(self)
        } else {
            scrollWidget = widgetCache.scroll.remove(at: 0)
            scrollWidget.data = self
        }
        widgetCache.nextScroll.append(scrollWidget)
        return scrollWidget.getView(session, widgetCache)
    }
}

class ScrollWidget {
    var data: ScrollData
    let view: UIScrollView
    let helper = SuperviewHelper()

    init(_ data: ScrollData) {
        self.data = data
        self.view = UIScrollView()
        self.view.translatesAutoresizingMaskIntoConstraints = false
    }

    func getView(_ session: MaggieSession, _ widgetCache: WidgetCache) -> UIView {
        self.helper.removeSubviewsAndConstraints(self.view)
        let subView = self.data.widget.getView(session, widgetCache)
        self.view.addSubview(subView)
        self.helper.setConstraints([
            subView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            subView.bottomAnchor.constraint(lessThanOrEqualTo: self.view.safeAreaLayoutGuide.bottomAnchor),
            subView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
            subView.trailingAnchor.constraint(lessThanOrEqualTo: self.view.safeAreaLayoutGuide.trailingAnchor),
        ])
        return self.view
    }
}
