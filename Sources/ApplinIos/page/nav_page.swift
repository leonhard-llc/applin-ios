import Foundation
import OSLog
import UIKit

public enum StartEnum: Equatable {
    case backButton(BackButtonSpec)
    case defaultBackButton
    case empty
}

public struct NavPageSpec: Equatable {
    static let TYP = "nav_page"
    let connectionMode: ConnectionMode
    let end: Spec?
    let ephemeral: Bool?
    let start: StartEnum
    let title: String
    let widget: Spec

    init(_ config: ApplinConfig, _ item: JsonItem) throws {
        self.connectionMode = ConnectionMode(item.stream, item.poll_seconds)
        self.end = try item.optEnd(config)
        self.ephemeral = item.ephemeral
        switch try item.optStart(config)?.value {
        case let .backButton(inner):
            self.start = .backButton(inner)
        case .none:
            self.start = .defaultBackButton
        case .empty:
            self.start = .empty
        case let .some(other):
            throw ApplinError.appError("bad \(item.typ).start: \(other)")
        }
        self.title = try item.requireTitle()
        self.widget = try item.requireWidget(config)
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(NavPageSpec.TYP)
        item.end = self.end?.toJsonItem()
        item.ephemeral = self.ephemeral
        item.poll_seconds = self.connectionMode.getPollSeconds()
        item.stream = self.connectionMode.getStream()
        item.title = self.title
        switch self.start {
        case let .backButton(inner):
            item.start = inner.toJsonItem()
        case .defaultBackButton:
            break
        case .empty:
            item.start = EmptySpec().toJsonItem()
        }
        item.widget = self.widget.toJsonItem()
        return item
    }

    public init(
            pageKey: String,
            title: String,
            start: StartEnum = .defaultBackButton,
            end: Spec? = nil,
            connectionMode: ConnectionMode = .disconnect,
            ephemeral: Bool? = nil,
            _ widget: ToSpec
    ) {
        self.connectionMode = connectionMode
        self.end = end
        self.start = start
        self.title = title
        self.ephemeral = ephemeral
        self.widget = widget.toSpec()
    }

    func toSpec() -> PageSpec {
        .navPage(self)
    }

    func vars() -> [(String, Var)] {
        self.widget.vars()
    }

    func visitActions(_ f: (ActionSpec) -> ()) {
        self.end?.visitActions(f)
        self.widget.visitActions(f)
    }
}

class NavPageController: UIViewController, UINavigationBarDelegate, PageController {
    static let logger = Logger(subsystem: "Applin", category: "NavPageController")

    weak var navController: NavigationController?
    let ctx: PageContext
    var helper: SingleViewContainerHelper!
    var spec: NavPageSpec?
    var navBar: UINavigationBar
    var optOriginalBackButton: UIBarButtonItem?

    init(_ navController: NavigationController?, _ ctx: PageContext) {
        Self.logger.debug("NavPageController.init")
        self.navController = navController
        self.ctx = ctx
        // PlainPageController cannot do self.navigationItem.navBarHidden = true,
        // because Apple didn't add support for that.
        // Instead, we must show/hide UINavigationController's navbar whenever the top
        // page changes between NavPage and PlainPage.
        // This works, but whenever we pop a NavPage with a PlainPage underneath,
        // the PlainPage shows a navbar for a second while the animation is running, then it disappears.
        // This is looks bad.  So we hide the UINavigationController's navbar
        // and give each NavPage its own navbar.
        self.navBar = UINavigationBar()
        self.navBar.translatesAutoresizingMaskIntoConstraints = false
        super.init(nibName: nil, bundle: nil)
        self.navBar.delegate = self
        self.view.backgroundColor = .systemBackground
        self.view.addSubview(self.navBar)
        self.helper = SingleViewContainerHelper(superView: self.view)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not implemented")
    }

    func back() {
        Self.logger.info("back")
        if self.navController?.topViewController() !== self {
            return
        }
        guard let spec = self.spec else {
            return
        }
        switch spec.start {
        case let .backButton(inner):
            Self.logger.debug("back inner.tap()")
            inner.tap(self.ctx)
        case .defaultBackButton:
            Task {
                let _ = await self.ctx.pageStack?.doActions(pageKey: self.ctx.pageKey, [.pop])
            }
        case .empty:
            break
        }
    }

    // Implement UINavigationBarDelegate --------------

    /// Called when the user taps the Back button.
    func navigationBar(_ navigationBar: UINavigationBar, shouldPop item: UINavigationItem) -> Bool {
        Self.logger.debug("title=\(String(describing: self.title)) navigationBar shouldPop=\(item)")
        self.back()
        return false  // UINavigationBar should not remove NavigationItem objects.
    }

    /// Called when the user taps the Back button,
    /// or long-presses the Back button and taps Back from the popup menu.
    func navigationBar(_ navigationBar: UINavigationBar, didPop item: UINavigationItem) {
        Self.logger.debug("title=\(String(describing: self.title)) navigationBar didPop=\(item)")
        self.back()
    }

    /// Called when the view gets covered by another view (isMovingFromParent=false) or
    /// when the view is removed from the view (isMovingFromParent=true).
    override func viewDidDisappear(_ animated: Bool) {
        // NOTE: UIKit on iOS 15 does not set self.isBeingDismissed=true like the docs claim.
        Self.logger.debug("title=\(String(describing: self.title)) viewDidDisappear isMovingFromParent=\(self.isMovingFromParent)")
        if self.isMovingFromParent {
            self.back()
        }
        super.viewDidDisappear(animated)
    }

    // Implement PageController -----------------

    func allowBackSwipe() -> Bool {
        switch self.spec?.start {
        case .none:
            return false
        case .backButton:
            return false
        case .defaultBackButton:
            return true
        case .empty:
            return false
        }
    }

    func klass() -> AnyClass {
        NavPageController.self
    }

    func update(_ ctx: PageContext, _ newPageSpec: PageSpec) {
        guard let cache = ctx.cache else {
            return
        }
        guard case let .navPage(navPageSpec) = newPageSpec else {
            // This should never happen.
            fatalError("update called with non-navPage spec: \(newPageSpec)")
        }
        self.spec = navPageSpec
        self.title = navPageSpec.title

        if let originalBackButton = self.optOriginalBackButton {
            self.navBar.backItem?.backBarButtonItem = originalBackButton
            self.optOriginalBackButton = nil
        }
        self.navigationItem.hidesBackButton = false
        switch navPageSpec.start {
        case let .backButton(inner):
            if inner.actions.isEmpty {
                self.navBar.items = [UINavigationItem(title: "Back"), self.navigationItem]
                let backButton = UIBarButtonItem(title: "Back")
                backButton.isEnabled = false
                self.optOriginalBackButton = self.navBar.backItem?.backBarButtonItem
                self.navBar.backItem?.backBarButtonItem = backButton
            } else {
                self.navBar.items = [UINavigationItem(title: "Back"), self.navigationItem]
            }
        case .defaultBackButton:
            if ctx.hasPrevPage {
                self.navBar.items = [UINavigationItem(title: "Back"), self.navigationItem]
            } else {
                self.navBar.items = [self.navigationItem]
            }
        case .empty:
            self.navigationItem.hidesBackButton = true
            self.navBar.items = [self.navigationItem]
        }
        let widget = cache.updateAll(ctx, navPageSpec.widget)
        let subView = widget.getView()
        subView.translatesAutoresizingMaskIntoConstraints = false
        self.helper.update(subView) {
            [
                self.navBar.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
                self.navBar.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
                self.navBar.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
                subView.topAnchor.constraint(equalTo: self.navBar.safeAreaLayoutGuide.bottomAnchor),
                subView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
                subView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
                subView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
            ]
        }
    }

    override var description: String {
        "NavPageController{title=\(self.title ?? "")}"
    }
}
