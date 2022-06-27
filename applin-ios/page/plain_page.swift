import Foundation
import UIKit

struct PlainPageData: Equatable, PageDataProto {
    static func blank() -> PlainPageData {
        PlainPageData(title: "Empty", .empty(EmptyData()))
    }

    static let TYP = "plain-page"
    let connectionMode: ConnectionMode
    let title: String?
    let widget: WidgetData

    init(title: String?, _ widget: WidgetData) {
        self.connectionMode = .disconnect
        self.title = title
        self.widget = widget
    }

    init(_ item: JsonItem, _ session: ApplinSession) throws {
        self.connectionMode = ConnectionMode(item.stream, item.pollSeconds)
        self.title = item.title
        self.widget = try item.requireWidget(session)
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(PlainPageData.TYP)
        item.pollSeconds = self.connectionMode.getPollSeconds()
        item.stream = self.connectionMode.getStream()
        item.title = self.title
        item.widget = self.widget.inner().toJsonItem()
        return item
    }
}

class PlainPageController: UIViewController, PageController {
    var data: PlainPageData?
    let helper = SuperviewHelper()

    func isModal() -> Bool {
        false
    }

    func allowBackSwipe() -> Bool {
        true
    }

    func update(
            _ session: ApplinSession,
            _ widgetCache: WidgetCache,
            _ newData: PlainPageData
    ) {
        if newData == self.data {
            return
        }
        self.data = newData
        self.title = newData.title
        self.view.backgroundColor = .systemBackground
        self.helper.removeSubviewsAndConstraints(self.view)
        let subView = newData.widget.inner().getView(session, widgetCache)
        self.view.addSubview(subView)
        self.helper.setConstraints([
            subView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            subView.bottomAnchor.constraint(lessThanOrEqualTo: self.view.safeAreaLayoutGuide.bottomAnchor),
            subView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
            subView.trailingAnchor.constraint(lessThanOrEqualTo: self.view.safeAreaLayoutGuide.trailingAnchor),
        ])
        widgetCache.flip()
    }
}
