import Foundation
import UIKit

class NavigationController: UINavigationController, UIGestureRecognizerDelegate {
    private var controllers: [(String, PageController, WidgetCache)] = []

    init() {
        super.init(rootViewController: LoadingPage())
        self.setNavigationBarHidden(true, animated: false)
        self.interactivePopGestureRecognizer?.delegate = self
        // self.navigationBar.delegate = self // <-- This crashes
        // with "NSInternalInconsistencyException: Cannot manually set the delegate
        // on a UINavigationBar managed by a controller."
        // That means we cannot intercept navigationBar(:didPop:) or navigationBar(:shouldPop:).
    }

    required init?(coder: NSCoder) {
        fatalError("unimplemented")
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let result = self.controllers.last?.1.allowBackSwipe() ?? false
        print("allowBackSwipe \(result)")
        return result
    }

    public func topPageController() -> PageController? {
        self.controllers.last?.1
    }

    func setStackPages(_ session: MaggieSession, _ newPages: [(String, PageData)]) {
        print("setStackPages")
        let appJustStarted = self.controllers.isEmpty
        let topPageController: PageController? =
                self.controllers.reversed().first(where: { (_, controller, _) in !controller.isModal() })?.1
        precondition(!newPages.isEmpty)
        var newControllers: [(String, PageController, WidgetCache)] = []
        var hasPrevPage = false
        for (newKey, newData) in newPages {
            var controller: PageController?
            var widgetCache: WidgetCache
            if let n = self.controllers.firstIndex(where: { (key, _, _) in key == newKey }) {
                print("reusing WidgetCache")
                (_, controller, widgetCache) = self.controllers.remove(at: n)
            } else {
                print("new WidgetCache")
                widgetCache = WidgetCache()
            }
            switch (newData, controller) {
            case (.modal, _):
                fatalError("unimplemented")
            case (.markdownPage, _):
                fatalError("unimplemented")
            case let (.navPage(data), controller as NavPageController):
                controller.update(session, widgetCache, data, hasPrevPage: hasPrevPage)
            case let (.navPage(data), _):
                let newController = NavPageController(self, session)
                newController.update(session, widgetCache, data, hasPrevPage: hasPrevPage)
                controller = newController
            case let (.plainPage(data), controller as PlainPageController):
                controller.update(self, session, widgetCache, data)
            case let (.plainPage(data), _):
                let newController = PlainPageController()
                newController.update(self, session, widgetCache, data)
                controller = newController
            }
            newControllers.append((newKey, controller!, widgetCache))
            // if !newPage.isModal {
            //     hasPrevPage = true
            // }
            hasPrevPage = true
        }
        let newTopPageController: PageController? =
                newControllers.reversed().first(where: { (_, controller, _) in !controller.isModal() })?.1
        let changedTopPage = topPageController !== newTopPageController
        self.controllers = newControllers
        self.setViewControllers(
                newControllers.map({ (_, controller, _) in controller }),
                animated: changedTopPage && !appJustStarted
        )
    }
}
