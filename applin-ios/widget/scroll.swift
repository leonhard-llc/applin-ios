import Foundation
import UIKit

struct ScrollData: Equatable, Hashable, WidgetDataProto {
    static let TYP = "scroll"
    let widget: WidgetData

    init(_ session: ApplinSession, pageKey: String, _ item: JsonItem) throws {
        self.widget = try item.requireWidget(session, pageKey: pageKey)
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(ScrollData.TYP)
        item.widget = self.widget.inner().toJsonItem()
        return item
    }

    func keys() -> [String] {
        []
    }

    func canTap() -> Bool {
        false
    }

    func tap(_ session: ApplinSession, _ cache: WidgetCache) {
    }

    func getView(_ session: ApplinSession, _ cache: WidgetCache) -> UIView {
        let widget = cache.removeScroll() ?? ScrollWidget(self)
        widget.data = self
        cache.putNextScroll(widget)
        return widget.getView(session, cache)
    }

    func vars() -> [(String, Var)] {
        self.widget.inner().vars()
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

    func getView(_ session: ApplinSession, _ cache: WidgetCache) -> UIView {
        self.helper.removeSubviewsAndConstraints(self.view)
        let subView = self.data.widget.inner().getView(session, cache)
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
