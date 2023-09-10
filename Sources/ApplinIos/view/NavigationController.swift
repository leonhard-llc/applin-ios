import Foundation
import OSLog
import UIKit

public class NavigationController: UINavigationController, UIGestureRecognizerDelegate {
    private enum Entry: CustomStringConvertible {
        case loadingPage(LoadingPageController)
        case navPage(NavPageController, WidgetCache)
        case plainPage(PlainPageController, WidgetCache)

        func controller() -> UIViewController {
            switch self {
            case let .loadingPage(ctl):
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
            case let .navPage(ctl, _):
                return "Entry.navPage{\(ctl)}"
            case let .plainPage(ctl, _):
                return "Entry.plainPage{\(ctl)}"
            }
        }
    }

    static let logger = Logger(subsystem: "Applin", category: "NavigationController")

    private var lock = ApplinLock()
    private var entries: [(String, Entry)] = []
    private var pageControllers: [UIViewController] = []
    private var top: Entry?
    private var optWorking: WorkingView?
    private var appJustStarted = true

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
    private func updateViewControllers() {
        var newControllers: [UIViewController] = self.entries.map({ (_key, value) in value.controller() })
        if let working = self.optWorking {
            newControllers.append(working)
        }
        if self.pageControllers != newControllers {
            Self.logger.debug("setViewControllers \(newControllers)")
            let oldTopController = self.top?.controller()
            self.top = self.entries.last?.1
            let changedTop = self.top?.controller() !== oldTopController
            let animated = changedTop && !self.appJustStarted
            self.appJustStarted = false
            self.setViewControllers(newControllers, animated: animated)
            self.pageControllers = newControllers
        }
    }

    @MainActor
    func setWorking(_ text: String?) async {
        await self.lock.lockAsync {
            Self.logger.debug("setWorking '\(String(describing: text))")
            if let text = text {
                self.optWorking = WorkingView(text: text)
            } else {
                self.optWorking = nil
            }
            self.updateViewControllers()
        }
    }

    @MainActor
    func update(_ pageStack: PageStack, _ varSet: VarSet, newPages: [(String, PageSpec)]) async {
        precondition(!newPages.isEmpty)
        await self.lock.lockAsync {
            //for (key, pageSpec) in self.entries {
            //    Self.logger.trace("old page '\(key)' = \(pageSpec)")
            //}
            //for (key, pageSpec) in newPages {
            //    Self.logger.trace("new page '\(key)' = \(pageSpec)")
            //}
            Self.logger.debug("old page keys: \(self.entries.map({ $0.0 }))")
            Self.logger.debug("new page keys: \(newPages.map({ $0.0 }))")
            var keyToEntry: [String: Entry] = self.entries.toDictionary()
            self.entries = []
            for (key, pageSpec) in newPages {
                let hasPrevPage = !self.entries.isEmpty
                switch pageSpec {
                case .loadingPage:
                    if case let .loadingPage(ctl) = keyToEntry.removeValue(forKey: key) {
                        self.entries.append((key, .loadingPage(ctl)))
                    } else {
                        self.entries.append((key, .loadingPage(LoadingPageController())))
                    }
                case .navPage:
                    if case let .navPage(ctl, widgetCache) = keyToEntry.removeValue(forKey: key) {
                        let ctx = PageContext(widgetCache, hasPrevPage: hasPrevPage, pageKey: key, pageStack, varSet)
                        ctl.update(ctx, pageSpec)
                        self.entries.append((key, .navPage(ctl, widgetCache)))
                    } else {
                        let widgetCache = WidgetCache()
                        let ctx = PageContext(widgetCache, hasPrevPage: hasPrevPage, pageKey: key, pageStack, varSet)
                        let ctl = NavPageController(self, ctx)
                        ctl.update(ctx, pageSpec)
                        self.entries.append((key, .navPage(ctl, widgetCache)))
                    }
                case .plainPage:
                    if case let .plainPage(ctl, widgetCache) = keyToEntry.removeValue(forKey: key) {
                        let ctx = PageContext(widgetCache, hasPrevPage: hasPrevPage, pageKey: key, pageStack, varSet)
                        ctl.update(ctx, pageSpec)
                        self.entries.append((key, .plainPage(ctl, widgetCache)))
                    } else {
                        let widgetCache = WidgetCache()
                        let ctx = PageContext(widgetCache, hasPrevPage: hasPrevPage, pageKey: key, pageStack, varSet)
                        let ctl = PlainPageController()
                        ctl.update(ctx, pageSpec)
                        self.entries.append((key, .plainPage(ctl, widgetCache)))
                    }
                }
            }
            self.updateViewControllers()
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
