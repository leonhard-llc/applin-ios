import Foundation
import UIKit

private struct ModalNode {
    let key: String
    let data: ModalData
    let controller: UIAlertController

    init(_ key: String, _ data: ModalData, _ controller: UIAlertController) {
        self.key = key
        self.data = data
        self.controller = controller
    }
}

private struct PageNode {
    let key: String
    let data: PageData
    let controller: PageController
    let cache: WidgetCache
    var modals: [ModalNode] = []

    init(_ key: String, _ data: PageData, _ controller: PageController, _ cache: WidgetCache) {
        self.key = key
        self.data = data
        self.controller = controller
        self.cache = cache
    }
}

private enum Controller {
    case modal(String, ModalData, UIAlertController)
    case page(String, PageController, WidgetCache)

    func key() -> String {
        switch self {
        case let .modal(key, _, _):
            return key
        case let .page(key, _, _):
            return key
        }
    }

    func isModal() -> Bool {
        switch self {
        case .modal:
            return true
        case .page:
            return false
        }
    }

    func asPageController() -> PageController? {
        switch self {
        case .modal:
            return nil
        case let .page(_, pageController, _):
            return pageController
        }
    }
}

class NavigationController: UINavigationController, UIGestureRecognizerDelegate {
    private var controllers: [Controller] = []

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
        let result = !(self.controllers.last?.isModal() ?? true)
        print("allowBackSwipe \(result)")
        return result
    }

    public func topPageController() -> PageController? {
        self.controllers.compactMap({ controller in controller.asPageController() }).last
    }

    private func removeController(_ key: String) -> Controller? {
        if let n = self.controllers.firstIndex(where: { entry in entry.key() == key }) {
            return self.controllers.remove(at: n)
        } else {
            return nil
        }
    }

    private func removeModalController(_ key: String) -> (ModalData?, UIAlertController?) {
        if case let .modal(_, data, ctl) = self.removeController(key) {
            return (data, ctl)
        }
        return (nil, nil)
    }

    private func removePageController(_ key: String) -> (PageController?, WidgetCache?) {
        if case let .page(_, ctl, cache) = self.removeController(key) {
            return (ctl, cache)
        }
        return (nil, nil)
    }

    func setStackPages(_ session: ApplinSession, _ newPages: [(String, PageData)]) {
        print("setStackPages")
        let appJustStarted = self.controllers.isEmpty
        let topPageController: PageController? = self.topPageController()
        precondition(!newPages.isEmpty)
        var nodes: [PageNode] = []
        for (key, pageData) in newPages {
            let hasPrevPage = !nodes.isEmpty
            switch pageData {
            case let .modal(data):
                var (oldData, oldCtl) = self.removeModalController(key)
                if oldData != data {
                    oldCtl = nil
                }
                let modalNode = ModalNode.init(key, data, oldCtl ?? data.makeController(session))
                if nodes.isEmpty {
                    let blankData = PlainPageData.blank()
                    let blankController = PlainPageController()
                    let cache = WidgetCache()
                    blankController.update(session, cache, blankData)
                    nodes.append(PageNode.init(
                            "applin-empty-page-for-root-modal", .plainPage(blankData), blankController, cache))
                }
                let lastIndex = nodes.lastIndex(where: { _ in true })!
                nodes[lastIndex].modals.append(modalNode)
            case let .navPage(data):
                let (optOldCtl, optOldCache) = self.removePageController(key)
                let cache = optOldCache ?? WidgetCache()
                let pageController: PageController;
                if let oldCtl = optOldCtl as? NavPageController {
                    oldCtl.update(session, cache, data, hasPrevPage: hasPrevPage)
                    pageController = oldCtl
                } else {
                    let ctl = NavPageController(self, session)
                    ctl.update(session, cache, data, hasPrevPage: hasPrevPage)
                    pageController = ctl
                }
                nodes.append(PageNode.init(key, pageData, pageController, cache))
            case let .plainPage(data):
                let (optOldCtl, optOldCache) = self.removePageController(key)
                let cache = optOldCache ?? WidgetCache()
                let pageController: PageController;
                if let oldCtl = optOldCtl as? PlainPageController {
                    oldCtl.update(session, cache, data)
                    pageController = oldCtl
                } else {
                    let ctl = PlainPageController()
                    ctl.update(session, cache, data)
                    pageController = ctl
                }
                nodes.append(PageNode.init(key, pageData, pageController, cache))
            }
        }
        var newControllers: [Controller] = []
        for node in nodes {
            var prevViewController: UIViewController = node.controller
            newControllers.append(.page(node.key, node.controller, node.cache))
            for modal in node.modals {
                if prevViewController.presentedViewController !== modal.controller {
                    modal.controller.dismiss(animated: false)
                    // TODO: Fix crash when presenting same modal twice.
                    // 2022-06-25 21:43:42.747611-0700 applin-ios[12718:253743] *** Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: 'Application tried to present modally a view controller <UIAlertController: 0x7fdf88828200> that is already being presented by <UIAlertController: 0x7fdf8580f800>.'
                    prevViewController.present(modal.controller, animated: true)
                }
                prevViewController = modal.controller
                newControllers.append(.modal(modal.key, modal.data, modal.controller))
            }
            if let presentedViewController = prevViewController.presentedViewController {
                presentedViewController.dismiss(animated: true)
            }
        }
        let newTopPageController: PageController? =
                newControllers.compactMap({ controller in controller.asPageController() }).last
        let changedTopPage = topPageController !== newTopPageController
        self.controllers = newControllers
        self.setViewControllers(
                newControllers.compactMap({ controller in controller.asPageController() }),
                // TODO: Prevent warning "setViewControllers:animated: called on <applin_ios.NavigationController>
                //       while an existing transition or presentation is occurring;
                //       the navigation stack will not be updated."
                animated: changedTopPage && !appJustStarted
        )
    }
}
