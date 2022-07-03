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

class NavigationController: UINavigationController, ModalDelegate, UIGestureRecognizerDelegate {
    private var entries: [Entry] = []
    private var modals: [UIViewController] = []
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

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let result = !(self.entries.last?.controller.allowBackSwipe() ?? false)
        print("allowBackSwipe \(result)")
        return result
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

    func modalDismissed() {
        self.presentCorrectModal()
    }

    private func removeEntry(_ key: String) -> Entry? {
        if let n = self.entries.firstIndex(where: { entry in entry.key == key }) {
            return self.entries.remove(at: n)
        } else {
            return nil
        }
    }

    func setWorking(_ text: String?) {
        print("setWorking '\(text ?? "nil")'")
        if let text = text {
            self.working = WorkingView(text: text)
        } else {
            self.working = nil
        }
        self.presentCorrectModal()
    }

    func setStackPages(_ session: ApplinSession, _ newPages: [(String, PageData)]) async {
        print("setStackPages")
        let appJustStarted = self.entries.isEmpty
        let topEntry: Entry? = self.entries.last
        precondition(!newPages.isEmpty)
        var newEntries: [Entry] = []
        var newModals: [UIViewController] = []
        for (key, pageData) in newPages {
            let hasPrevPage = !newEntries.isEmpty
            switch pageData {
            case let .modal(data):
                let alert = data.toAlert(session)
                alert.delegate = self
                alert.setAnimated(false)
                newModals.append(alert)
            case let .navPage(data):
                newModals = []
                let entry = self.removeEntry(key)
                let ctl = entry?.controller as? NavPageController ?? NavPageController(self, session)
                let cache = entry?.cache ?? WidgetCache()
                ctl.update(session, cache, data, hasPrevPage: hasPrevPage)
                newEntries.append(Entry(key, pageData, ctl, cache))
            case let .plainPage(data):
                newModals = []
                let entry = self.removeEntry(key)
                let ctl = entry?.controller as? PlainPageController ?? PlainPageController()
                let cache = entry?.cache ?? WidgetCache()
                ctl.update(session, cache, data)
                newEntries.append(Entry(key, pageData, ctl, cache))
            }
        }
        self.modals = [] // So modalDismissed delegate func will not present any modals.
        // Prevent error "setViewControllers:animated: called on
        // <applin_ios.NavigationController> while an existing transition
        // or presentation is occurring; the navigation stack will not be
        // updated."
        await self.presentedViewController?.dismissAsync(animated: false)
        self.modals = newModals
        self.entries = newEntries
        let newTopEntry = self.entries.last
        let changedTopPage = topEntry?.controller !== newTopEntry?.controller
        let animated = changedTopPage && !appJustStarted
        self.setViewControllers(
                self.entries.compactMap({ entry in entry.controller }),
                animated: animated
        )
        self.presentCorrectModal()
    }

    public func topPageController() -> PageController? {
        self.entries.last?.controller
    }
}
