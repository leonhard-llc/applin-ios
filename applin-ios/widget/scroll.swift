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
        let widget = cache.removeScroll() ?? ScrollWidget()
        widget.update(session, cache, self)
        cache.putNextScroll(widget)
        return widget.view
    }

    func vars() -> [(String, Var)] {
        self.widget.inner().vars()
    }
}

class ScrollWidget {
    let view: UIScrollView
    private var data: ScrollData!
    private let helper: SingleViewContainerHelper

    init() {
        self.view = UIScrollView()
        self.view.translatesAutoresizingMaskIntoConstraints = false
        self.helper = SingleViewContainerHelper(superView: self.view)
    }

    func update(_ session: ApplinSession, _ cache: WidgetCache, _ data: ScrollData) {
        self.data = data
        let subView = self.data.widget.inner().getView(session, cache)
        self.helper.update(subView) {
            [
                subView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
                subView.bottomAnchor.constraint(lessThanOrEqualTo: self.view.safeAreaLayoutGuide.bottomAnchor),
                subView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
                subView.trailingAnchor.constraint(lessThanOrEqualTo: self.view.safeAreaLayoutGuide.trailingAnchor),
            ]
        }
    }
}
