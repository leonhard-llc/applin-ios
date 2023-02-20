import Foundation
import UIKit

protocol ModalDelegate: AnyObject {
    func modalDismissed()
}

class AlertController: UIAlertController {
    weak var delegate: ModalDelegate?
    var animated = false

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
    private struct Entry {
        let key: String
        let pageSpec: PageSpec
        let controller: PageController
        let cache: WidgetCache

        init(_ key: String, _ pageSpec: PageSpec, _ controller: PageController, _ cache: WidgetCache) {
            self.key = key
            self.pageSpec = pageSpec
            self.controller = controller
            self.cache = cache
        }
    }

    private var entries: [Entry] = []
    private var modals: [UIViewController] = []
    private var working: UIViewController?
    private var taskLock = ApplinLock()
    private var lastServerUpdateId: UInt64 = 0

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

    private func presentCorrectModal() {
        if let modal = self.working ?? self.modals.last {
            if self.presentedViewController === modal {
                return
            } else {
                if let presented = self.presentedViewController {
                    presented.dismiss(animated: false) {
                        self.presentCorrectModal()
                    }
                } else {
                    self.present(modal, animated: false)
                }
            }
        } else {
            self.presentedViewController?.dismiss(animated: false)
        }
    }

    private func removeEntry(_ key: String) -> Entry? {
        if let n = self.entries.firstIndex(where: { entry in entry.key == key }) {
            return self.entries.remove(at: n)
        } else {
            return nil
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
        // TODO: Don't keep reference to `state`.
        let serverUpdateId: UInt64 = state.serverUpdateId
        let newPages = state.getStackPages()
        print("newPages \(newPages)")
        Task { @MainActor [serverUpdateId, newPages] in
            await self.taskLock.lockAsync() {
                //if self.lastServerUpdateId >= serverUpdateId {
                //    print("NavigationController ignored update")
                //    return
                //}
                print("NavigationController update")
                self.lastServerUpdateId = serverUpdateId
                let appJustStarted = self.entries.isEmpty
                let topEntry: Entry? = self.entries.last
                precondition(!newPages.isEmpty)
                var newEntries: [Entry] = []
                var newModals: [UIViewController] = []
                // TODO: Solve flash on poll when modal is visible.
                for (key, pageSpec) in newPages {
                    let hasPrevPage = !newEntries.isEmpty
                    if case let .modal(modalSpec) = pageSpec {
                        let alert = modalSpec.toAlert(session)
                        alert.delegate = self
                        alert.setAnimated(false)
                        newModals.append(alert)
                    } else {
                        newModals = []
                        var ctl: PageController
                        var cache: WidgetCache
                        if let entry = self.removeEntry(key) {
                            cache = entry.cache
                            if entry.controller.klass() == pageSpec.controllerClass() {
                                ctl = entry.controller
                            } else {
                                ctl = pageSpec.newController(self, session, entry.cache)
                            }
                        } else {
                            cache = WidgetCache()
                            ctl = pageSpec.newController(self, session, cache)
                        }
                        print("setStackPages update \(key)")
                        ctl.update(session, cache, state, pageSpec, hasPrevPage: hasPrevPage)
                        newEntries.append(Entry(key, pageSpec, ctl, cache))
                    }
                }
                self.modals = [] // So modalDismissed delegate func will not present any modals.
                // Dismiss any presented view to prevent error
                // "setViewControllers:animated: called on <applin_ios.NavigationController>
                // while an existing transition or presentation is occurring;
                // the navigation stack will not be updated."
                await self.presentedViewController?.dismissAsync(animated: false)
                self.modals = newModals
                self.entries = newEntries
                let newTopEntry = self.entries.last
                let changedTopPage = topEntry?.controller !== newTopEntry?.controller
                let animated = changedTopPage && !appJustStarted
                let newViewControllers = self.entries.compactMap({ entry in entry.controller })
                if self.viewControllers != newViewControllers {
                    print("setViewControllers")
                    self.setViewControllers(newViewControllers, animated: animated)
                }
                self.presentCorrectModal()
            }
        }
    }

    public func topPageController() -> PageController? {
        self.entries.last?.controller
    }

    // Implements ModalDelegate ----

    internal func modalDismissed() {
        self.presentCorrectModal()
    }

    // Implements UIGestureRecognizerDelegate ----

    internal func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let result = self.entries.last?.controller.allowBackSwipe() ?? false
        print("allowBackSwipe \(result)")
        return result
    }
}
