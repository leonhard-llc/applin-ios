import Foundation
import UIKit

struct PlainPageSpec: Equatable {
    static let TYP = "plain-page"
    let connectionMode: ConnectionMode
    let title: String?
    let widget: Spec

    init(title: String?, _ widget: Spec) {
        self.connectionMode = .disconnect
        self.title = title
        self.widget = widget
    }

    init(_ session: ApplinSession?, pageKey: String, _ item: JsonItem) throws {
        self.connectionMode = ConnectionMode(item.stream, item.pollSeconds)
        self.title = item.title
        self.widget = try item.requireWidget(session, pageKey: pageKey)
    }

    func controllerClass() -> AnyClass {
        PlainPageController.self
    }

    func newController() -> PageController {
        PlainPageController()
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(PlainPageSpec.TYP)
        item.pollSeconds = self.connectionMode.getPollSeconds()
        item.stream = self.connectionMode.getStream()
        item.title = self.title
        item.widget = self.widget.toJsonItem()
        return item
    }

    func vars() -> [(String, Var)] {
        self.widget.vars()
    }
}

class PlainPageController: UIViewController, PageController {
    var spec: PlainPageSpec?
    var helper: SingleViewContainerHelper!

    init() {
        super.init(nibName: nil, bundle: nil)
        self.helper = SingleViewContainerHelper(superView: self.view)
    }

    required init?(coder: NSCoder) {
        fatalError("unimplemented")
    }

    // Implement PageController -----------------

    func allowBackSwipe() -> Bool {
        true
    }

    func klass() -> AnyClass {
        PlainPageController.self
    }

    func update(_ session: ApplinSession, _ cache: WidgetCache, _ newPageSpec: PageSpec, hasPrevPage: Bool) {
        guard case let .plainPage(plainPageSpec) = newPageSpec else {
            print("FATAL: PlainPageController.update() called with newPageSpec=\(newPageSpec)")
            abort()
        }
        if self.spec == plainPageSpec {
            return
        }
        self.title = plainPageSpec.title
        self.view.backgroundColor = .systemBackground
        let widget = cache.updateAll(session, plainPageSpec.widget)
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
