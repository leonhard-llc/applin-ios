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

    init(_ session: ApplinSession, pageKey: String, _ item: JsonItem) throws {
        self.connectionMode = ConnectionMode(item.stream, item.pollSeconds)
        self.title = item.title
        self.widget = try item.requireWidget(session, pageKey: pageKey)
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(PlainPageData.TYP)
        item.pollSeconds = self.connectionMode.getPollSeconds()
        item.stream = self.connectionMode.getStream()
        item.title = self.title
        item.widget = self.widget.inner().toJsonItem()
        return item
    }

    func vars() -> [(String, Var)] {
        self.widget.inner().vars()
    }
}

class PlainPageController: UIViewController, PageController {
    var data: PlainPageData?
    var helper: SingleViewContainerHelper!

    init() {
        super.init(nibName: nil, bundle: nil)
        self.helper = SingleViewContainerHelper(superView: self.view)
    }

    required init?(coder: NSCoder) {
        fatalError("unimplemented")
    }

    func isModal() -> Bool {
        false
    }

    func allowBackSwipe() -> Bool {
        true
    }

    func update(
            _ session: ApplinSession,
            _ cache: WidgetCache,
            _ newData: PlainPageData
    ) {
        if newData == self.data {
            return
        }
        self.data = newData
        self.title = newData.title
        self.view.backgroundColor = .systemBackground
        let widget = cache.updateAll(session, newData.widget)
        let subView = widget.getView()
        self.helper.update(subView) {
            // subView.setNeedsDisplay()
            [
                subView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
                subView.bottomAnchor.constraint(lessThanOrEqualTo: self.view.safeAreaLayoutGuide.bottomAnchor),
                subView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
                subView.trailingAnchor.constraint(lessThanOrEqualTo: self.view.safeAreaLayoutGuide.trailingAnchor),
            ]
        }
    }
}
