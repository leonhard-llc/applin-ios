import Foundation
import UIKit

protocol ModalDelegate: AnyObject {
    func modalDismissed()
}

class AlertController: UIAlertController {
    weak var delegate: ModalDelegate?
    var animated = false

    func allowBackSwipe() -> Bool {
        false
    }

    func setAnimated(_ animated: Bool) {
        self.animated = animated
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !self.animated {
            UIView.setAnimationsEnabled(false)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.setAnimationsEnabled(true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if !self.animated {
            UIView.setAnimationsEnabled(false)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIView.setAnimationsEnabled(true)
        self.delegate?.modalDismissed()
    }

    // TODONT: Don't add a constructor.
    //         Our constructor cannot call the "convenience" constructor which is
    //         the only known way to properly initialize the class.
    // let preferredStyleOverride: UIAlertController.Style
    // // https://stackoverflow.com/a/45895513
    // override var preferredStyle: UIAlertController.Style {
    //     return self.preferredStyleOverride
    // }
    // init(title: String?, message: String?, preferredStyle: UIAlertController.Style) {
    //     self.preferredStyleOverride = preferredStyle
    //     // After calling this constructor, the class will throw
    //     // "Unable to simultaneously satisfy constraints" errors and display
    //     // the dialog with maximum height.  Strangely, displaying a second
    //     // dialog causes the one underneath to display properly.
    //     super.init(nibName: nil, bundle: nil)
    //     self.title = title
    //     self.message = message
    // }

    // TODONT: Don't try to intercept `dismiss` calls because it doesn't work.
    //         UIViewController does not call this when a button is tapped.
    // override func dismiss(animated flag: Bool, completion: (() -> ())?) {
    //     print("dismiss")
    //     super.dismiss(animated: flag, completion: completion)
    // }
}

class NavigationController: UINavigationController, ModalDelegate, UIGestureRecognizerDelegate {
    private enum Entry {
        case modal(AlertController)
        case navPage(NavPageController, WidgetCache)
        case plainPage(PlainPageController, WidgetCache)

        func controller() -> UIViewController {
            switch self {
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
            case let .modal(ctl):
                return ctl.allowBackSwipe()
            case let .navPage(ctl, _):
                return ctl.allowBackSwipe()
            case let .plainPage(ctl, _):
                return ctl.allowBackSwipe()
            }
        }
    }

    private class EntryCache {
        private var keyToEntries: [String: [Entry]] = [:]

        init(keysAndEntries: [(String, Entry)]) {
            for (key, entry) in keysAndEntries.reversed() {
                keyToEntries[key, default: []].append(entry)
            }
        }

        func removeEntry(_ key: String) -> Entry? {
            self.keyToEntries[key]?.popLast()
        }

        func isEmpty() -> Bool {
            self.keyToEntries.isEmpty
        }
    }

    private var taskLock = ApplinLock()
    private var entryCache = EntryCache(keysAndEntries: [])
    private var pageControllers: [UIViewController] = []
    private var top: Entry?
    private var working: UIViewController?

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

    private func presentModal(_ ctl: UIViewController) {
        if ctl === self.presentedViewController {
            return
        }
        if let presented = self.presentedViewController {
            presented.dismiss(animated: false) {
                self.present(ctl, animated: false)
            }
        } else {
            self.present(ctl, animated: false)
        }
    }

    private func presentCorrectModal() {
        if let ctl = self.working {
            self.presentModal(ctl)
        } else if case let .modal(ctl) = self.top {
            self.presentModal(ctl)
        } else {
            self.presentedViewController?.dismiss(animated: false)
        }
    }

    @MainActor
    func setWorking(_ text: String?) async {
        print("setWorking '\(text ?? "nil")'")
        if let text = text {
            self.working = WorkingView(text: text)
        } else {
            self.working = nil
        }
        self.presentCorrectModal()
    }

    func update(_ session: ApplinSession, _ state: ApplinState) {
        let newPages = state.getStackPages()
        print("NavigationController update")
        print("DEBUG newPages \(newPages)")
        precondition(!newPages.isEmpty)
        // TODO: Prevent multiple instances of this task from racing.
        Task { @MainActor [newPages] in
            await self.taskLock.lockAsync {
                let appJustStarted = self.entryCache.isEmpty()
                var newEntries: [(String, Entry)] = []
                for (key, pageSpec) in newPages {
                    switch pageSpec {
                    case let .modal(modalSpec):
                        if case let .modal(ctl) = self.entryCache.removeEntry(key) {
                            newEntries.append((key, .modal(ctl)))
                        } else {
                            let ctl = modalSpec.toAlert(session)
                            ctl.delegate = self
                            ctl.setAnimated(false)
                            newEntries.append((key, .modal(ctl)))
                        }
                    case .navPage:
                        if case let .navPage(ctl, widgetCache) = self.entryCache.removeEntry(key) {
                            ctl.update(session, widgetCache, state, pageSpec, hasPrevPage: !newEntries.isEmpty)
                            newEntries.append((key, .navPage(ctl, widgetCache)))
                        } else {
                            let widgetCache = WidgetCache()
                            let ctl = NavPageController(self, session, widgetCache)
                            ctl.update(session, widgetCache, state, pageSpec, hasPrevPage: !newEntries.isEmpty)
                            newEntries.append((key, .navPage(ctl, widgetCache)))
                        }
                    case .plainPage:
                        if case let .plainPage(ctl, widgetCache) = self.entryCache.removeEntry(key) {
                            ctl.update(session, widgetCache, state, pageSpec, hasPrevPage: !newEntries.isEmpty)
                            newEntries.append((key, .plainPage(ctl, widgetCache)))
                        } else {
                            let widgetCache = WidgetCache()
                            let ctl = PlainPageController()
                            ctl.update(session, widgetCache, state, pageSpec, hasPrevPage: !newEntries.isEmpty)
                            newEntries.append((key, .plainPage(ctl, widgetCache)))
                        }
                    }
                }
                self.entryCache = EntryCache(keysAndEntries: newEntries)
                let newTop = newEntries.last!.1
                let changedTop = self.top?.controller() !== newTop.controller()
                self.top = newTop
                let newPageControllers: [UIViewController] = newEntries.compactMap({ (_key, entry) in
                    switch entry {
                    case let .navPage(ctl, _):
                        return ctl
                    case let .plainPage(ctl, _):
                        return ctl
                    case .modal:
                        return nil
                    }
                })
                if self.pageControllers != newPageControllers {
                    // Dismiss any presented view to prevent error
                    // "setViewControllers:animated: called on <applin_ios.NavigationController>
                    // while an existing transition or presentation is occurring;
                    // the navigation stack will not be updated."
                    await self.presentedViewController?.dismissAsync(animated: false)
                    print("setViewControllers")
                    let animated = changedTop && !appJustStarted
                    self.setViewControllers(newPageControllers, animated: animated)
                    self.pageControllers = newPageControllers
                } else if changedTop {
                    await self.presentedViewController?.dismissAsync(animated: false)
                    self.presentCorrectModal()
                }
            }
        }
    }

    public func topViewController() -> UIViewController? {
        self.top?.controller()
    }

    // Implements ModalDelegate ----

    internal func modalDismissed() {
        self.presentCorrectModal()
    }

    // Implements UIGestureRecognizerDelegate ----

    internal func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let result = self.top?.allowBackSwipe() ?? false
        print("allowBackSwipe \(result)")
        return result
    }
}
