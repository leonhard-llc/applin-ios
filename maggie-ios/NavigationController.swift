import Foundation
import UIKit

class NavigationController: UINavigationController, UIGestureRecognizerDelegate {
    private var controllers: [(String, MaggiePage, PageController)] = []

    init() {
        super.init(rootViewController: LoadingPageController())
        self.isNavigationBarHidden = true
        self.interactivePopGestureRecognizer?.delegate = self
        // We cannot set the navbar delegate because it crashes with
        // "NSInternalInconsistencyException: Cannot manually set the delegate
        // on a UINavigationBar managed by a controller."
        // That means we cannot intercept navigationBar(:didPop:) or navigationBar(:shouldPop:).
        // self.navigationBar.delegate = self
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
        self.controllers.last?.2
    }

    func setStackPages(_ session: MaggieSession, _ newPages: [(String, MaggiePage)]) {
        print("setStackPages")
        let topPageController = self.controllers
                .reversed()
                .filter({ (_, page, _) in !page.isModal })
                .map({ (_, _, controller) in controller })
                .first
        precondition(!newPages.isEmpty)
        var newControllers: [(String, MaggiePage, PageController)] = []
        var hasPrevPage = false
        for (newKey, newPage) in newPages {
            if let n = self.controllers
                    .map({ (key, _, _) in key })
                    .enumerated()
                    .filter({ (_, key) in key == newKey })
                    .map({ (n, _) in n })
                    .first {
                var (key, page, controller) = self.controllers.remove(at: n)
                if newPage != page {
                    controller.setPage(self, session, newPage, hasPrevPage)
                }
                newControllers.append((key, newPage, controller))
            } else {
                let controller = PageController(self, session, newPage, hasPrevPage)
                newControllers.append((newKey, newPage, controller))
            }
            // if !newPage.isModal {
            //     hasPrevPage = true
            // }
            hasPrevPage = true
        }
        let newTopPageController = newControllers
                .reversed()
                .filter({ (_, page, _) in !page.isModal })
                .map({ (_, _, controller) in controller })
                .first!
        let changedTopPage = topPageController != newTopPageController
        let appJustStarted = self.controllers.isEmpty
        self.controllers = newControllers
        self.setViewControllers(
                newControllers.map({ (_, _, controller) in controller.inner() }),
                animated: changedTopPage && !appJustStarted
        )
    }
}
