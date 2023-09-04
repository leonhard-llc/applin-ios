import Foundation
import OSLog
import UIKit

public class NavigationController: UINavigationController, UIGestureRecognizerDelegate {
    private enum Entry: CustomStringConvertible {
        case loadingPage(LoadingPageController)
        case modal(AlertController)
        case navPage(NavPageController, WidgetCache)
        case plainPage(PlainPageController, WidgetCache)

        func controller() -> UIViewController {
            switch self {
            case let .loadingPage(ctl):
                return ctl
            case let .modal(ctl):
                return ctl
            case let .navPage(ctl, _):
                return ctl
            case let .plainPage(ctl, _):
                return ctl
            }
        }

        func allowBackSwipe() -> Bool {
            switch self {
            case .loadingPage:
                return true
            case let .modal(ctl):
                return ctl.allowBackSwipe()
            case let .navPage(ctl, _):
                return ctl.allowBackSwipe()
            case let .plainPage(ctl, _):
                return ctl.allowBackSwipe()
            }
        }

        public var description: String {
            switch self {
            case let .loadingPage(ctl):
                return "Entry.loadingPage{\(ctl)}"
            case let .modal(ctl):
                return "Entry.modal{\(ctl)}"
            case let .navPage(ctl, _):
                return "Entry.navPage{\(ctl)}"
            case let .plainPage(ctl, _):
                return "Entry.plainPage{\(ctl)}"
            }
        }
    }

    private class EntryCache: CustomStringConvertible {
        private var keyToEntries: [String: [Entry]] = [:]

        init(keysAndEntries: [(String, Entry)]) {
            for (key, entry) in keysAndEntries.reversed() {
                self.keyToEntries[key, default: []].append(entry)
            }
        }

        var description: String {
            "EntryCache\(self.keyToEntries)"
        }

        func removeEntry(_ key: String) -> Entry? {
            self.keyToEntries[key]?.popLast()
        }

        func isEmpty() -> Bool {
            self.keyToEntries.isEmpty
        }
    }

    static let logger = Logger(subsystem: "Applin", category: "NavigationController")

    private var lock = ApplinLock()
    private var entryCache = EntryCache(keysAndEntries: [])
    private var pageControllers: [UIViewController] = []
    private var top: Entry?
    private var working: UIViewController?

    init() {
        super.init(rootViewController: LoadingPageController())
        self.setNavigationBarHidden(true, animated: false)
        self.view.backgroundColor = .systemBackground
        self.interactivePopGestureRecognizer?.delegate = self
        // self.navigationBar.delegate = self // <-- This crashes
        // with "NSInternalInconsistencyException: Cannot manually set the delegate
        // on a UINavigationBar managed by a controller."
        // That means we cannot intercept navigationBar(:didPop:) or navigationBar(:shouldPop:).
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not implemented")
    }

    @MainActor
    private func dismissModal() async {
        if let ctl = self.presentedViewController {
            Self.logger.debug("dismissing \(ctl)")
            await ctl.dismissAsync(animated: !(ctl is WorkingView))
            Self.logger.debug("dismissed \(ctl)")
        }
    }

    @MainActor
    private func presentCorrectModal() async {
        if let ctl = self.working, ctl === self.presentedViewController {
            return
        }
        if let ctl = self.top?.controller(), ctl === self.presentedViewController {
            return
        }
        await self.dismissModal()
        if let ctl = self.working {
            Self.logger.debug("presenting working \(ctl)")
            await self.presentAsync(ctl, animated: false)
        } else if case let .modal(ctl, _widgetCache) = self.top {
            Self.logger.debug("presenting modal \(ctl)")
            await self.presentAsync(ctl, animated: true)
        }
    }

    @MainActor
    func setWorking(_ text: String?) async {
        await self.lock.lockAsync {
            Self.logger.debug("setWorking '\(String(describing: text))")
            if let text = text {
                self.working = WorkingView(text: text)
            } else {
                self.working = nil
            }
            await self.presentCorrectModal()
        }
    }

    @MainActor
    func update(_ pageStack: PageStack, _ varSet: VarSet, newPages: [(String, PageSpec)]) async {
        Self.logger.debug("newPages \(newPages)")
        precondition(!newPages.isEmpty)
        await self.lock.lockAsync {
            let appJustStarted = self.entryCache.isEmpty()
            var newEntries: [(String, Entry)] = []
            for (key, pageSpec) in newPages {
                let hasPrevPage = !newEntries.isEmpty
                switch pageSpec {
                case .loadingPage:
                    if case let .loadingPage(ctl) = self.entryCache.removeEntry(key) {
                        newEntries.append((key, .loadingPage(ctl)))
                    } else {
                        newEntries.append((key, .loadingPage(LoadingPageController())))
                    }
                case let .modal(modalSpec):
                    if case let .modal(ctl, widgetCache) = self.entryCache.removeEntry(key) {
                        newEntries.append((key, .modal(ctl, widgetCache)))
                    } else {
                        let widgetCache = WidgetCache()
                        let ctx = PageContext(widgetCache, hasPrevPage: false, pageKey: key, pageStack, varSet)
                        let ctl = modalSpec.toAlert(ctx)
                        ctl.setAnimated(true)
                        newEntries.append((key, .modal(ctl, widgetCache)))
                    }
                case .navPage:
                    if case let .navPage(ctl, widgetCache) = self.entryCache.removeEntry(key) {
                        let ctx = PageContext(widgetCache, hasPrevPage: hasPrevPage, pageKey: key, pageStack, varSet)
                        ctl.update(ctx, pageSpec)
                        newEntries.append((key, .navPage(ctl, widgetCache)))
                    } else {
                        let widgetCache = WidgetCache()
                        let ctx = PageContext(widgetCache, hasPrevPage: hasPrevPage, pageKey: key, pageStack, varSet)
                        let ctl = NavPageController(self, ctx)
                        ctl.update(ctx, pageSpec)
                        newEntries.append((key, .navPage(ctl, widgetCache)))
                    }
                case .plainPage:
                    if case let .plainPage(ctl, widgetCache) = self.entryCache.removeEntry(key) {
                        let ctx = PageContext(widgetCache, hasPrevPage: hasPrevPage, pageKey: key, pageStack, varSet)
                        ctl.update(ctx, pageSpec)
                        newEntries.append((key, .plainPage(ctl, widgetCache)))
                    } else {
                        let widgetCache = WidgetCache()
                        let ctx = PageContext(widgetCache, hasPrevPage: hasPrevPage, pageKey: key, pageStack, varSet)
                        let ctl = PlainPageController()
                        ctl.update(ctx, pageSpec)
                        newEntries.append((key, .plainPage(ctl, widgetCache)))
                    }
                }
            }
            self.entryCache = EntryCache(keysAndEntries: newEntries)
            Self.logger.debug("entryCache \(self.entryCache)")
            let newTop = newEntries.last!.1
            let changedTop = self.top?.controller() !== newTop.controller()
            self.top = newTop
            var newPageControllers: [UIViewController] = newEntries.compactMap({ (_key, entry) in
                switch entry {
                case let .loadingPage(ctl):
                    return ctl
                case .modal:
                    return nil
                case let .navPage(ctl, _):
                    return ctl
                case let .plainPage(ctl, _):
                    return ctl
                }
            })
            if self.pageControllers != newPageControllers {
                // Dismiss any presented view to prevent error
                // "setViewControllers:animated: called on <applin_ios.NavigationController>
                // while an existing transition or presentation is occurring;
                // the navigation stack will not be updated."
                await self.dismissModal()
                Self.logger.debug("setViewControllers")
                let animated = changedTop && !appJustStarted
                if newPageControllers.isEmpty {
                    // When home page fails to load, allow popping Error Details page.
                    newPageControllers = [LoadingPageController()]
                }
                self.setViewControllers(newPageControllers, animated: animated)
                self.pageControllers = newPageControllers
            }
            await self.presentCorrectModal()
        }
    }

    public func topViewController() -> UIViewController? {
        self.top?.controller()
    }

    override public var description: String {
        "NavigationController{\(self.address)}"
    }

    // Implements UIGestureRecognizerDelegate ----

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let result = self.top?.allowBackSwipe() ?? false
        Self.logger.debug("allowBackSwipe \(result)")
        return result
    }
}
