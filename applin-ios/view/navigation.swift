import Foundation
import UIKit

private struct Entry {
    let key: String
    let data: PageData
    let controller: PageController
    let cache: WidgetCache?

    init(_ key: String, _ data: PageData, _ controller: PageController, _ cache: WidgetCache?) {
        self.key = key
        self.data = data
        self.controller = controller
        self.cache = cache
    }
}

class NavigationController: UINavigationController, UIGestureRecognizerDelegate {
    private var entries: [Entry] = []

    init() {
        super.init(rootViewController: LoadingPage())
        self.setNavigationBarHidden(true, animated: false)
        self.view.backgroundColor = .systemBackground
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
        let result = !(self.entries.last?.controller.allowBackSwipe() ?? false)
        print("allowBackSwipe \(result)")
        return result
    }

    private func removeEntry(_ key: String) -> Entry? {
        if let n = self.entries.firstIndex(where: { entry in entry.key == key }) {
            return self.entries.remove(at: n)
        } else {
            return nil
        }
    }

    func setStackPages(_ session: ApplinSession, _ newPages: [(String, PageData)]) {
        print("setStackPages")
        let appJustStarted = self.entries.isEmpty
        let topEntry: Entry? = self.entries.last
        precondition(!newPages.isEmpty)
        var newEntries: [Entry] = []
        let lastPageIndex = newPages.count - 1
        for (n, (key, pageData)) in newPages.enumerated() {
            let hasPrevPage = !newEntries.isEmpty
            switch pageData {
            case let .modal(data):
                let entry = self.removeEntry(key)
                let ctl = entry?.controller as? ModalPageController ?? ModalPageController()
                ctl.update(session, data, isTop: n == lastPageIndex)
                newEntries.append(Entry(key, pageData, ctl, nil))
            case let .navPage(data):
                let entry = self.removeEntry(key)
                let ctl = entry?.controller as? NavPageController ?? NavPageController(self, session)
                let cache = entry?.cache ?? WidgetCache()
                ctl.update(session, cache, data, hasPrevPage: hasPrevPage)
                newEntries.append(Entry(key, pageData, ctl, cache))
            case let .plainPage(data):
                let entry = self.removeEntry(key)
                let ctl = entry?.controller as? PlainPageController ?? PlainPageController()
                let cache = entry?.cache ?? WidgetCache()
                ctl.update(session, cache, data)
                newEntries.append(Entry(key, pageData, ctl, cache))
            }
        }
        let topIsModal = topEntry?.controller.isModal() ?? false
        let topPopped = self.entries.contains(where: { entry in entry.controller === topEntry?.controller })
        self.entries = newEntries
        let newTopEntry = self.entries.last
        let changedTopPage = topEntry?.controller !== newTopEntry?.controller
        if topIsModal && !changedTopPage {
            // Prevent warning "setViewControllers:animated: called on
            // <applin_ios.NavigationController> while an existing transition
            // or presentation is occurring; the navigation stack will not be
            // updated."
            print("skipping calling setViewControllers() because a modal is visible")
        } else {
            let newTopIsModal = newTopEntry?.controller.isModal() ?? false
            let animated = (changedTopPage && !newTopIsModal) && !(topIsModal && topPopped) && !appJustStarted
            self.setViewControllers(
                    self.entries.compactMap({ entry in entry.controller }),
                    animated: animated
            )
        }
    }

    public func topPageController() -> PageController? {
        self.entries.last?.controller
    }
}
