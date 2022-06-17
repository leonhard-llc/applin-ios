import Foundation
import UIKit

struct NavPageData: Equatable {
    static let TYP = "nav-page"
    let title: String
    let start: BackButtonData?
    let end: WidgetData?
    let widget: WidgetData

    init(
            title: String,
            widget: WidgetData,
            start: BackButtonData? = nil,
            end: WidgetData? = nil
    ) {
        self.title = title
        self.start = start
        self.end = end
        self.widget = widget
    }

    init(_ item: JsonItem, _ session: ApplinSession) throws {
        self.title = try item.requireTitle()
        switch try item.optStart(session) {
        case .none:
            self.start = nil
        case let .backButton(start):
            self.start = start
        case let .some(other):
            throw ApplinError.deserializeError("bad \(item.typ).start: \(other)")
        }
        self.end = try item.optEnd(session)
        self.widget = try item.requireWidget(session)
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(NavPageData.TYP)
        item.title = self.title
        item.start = self.start?.toJsonItem()
        item.end = self.end?.toJsonItem()
        item.widget = self.widget.toJsonItem()
        return item
    }
}

class NavPageController: UIViewController, UINavigationBarDelegate, PageController {
    weak var navController: NavigationController?
    weak var session: ApplinSession?
    var data: NavPageData?
    var hasPrevPage: Bool = false
    var navBar: UINavigationBar
    var subView: UIView?
    let helper = SuperviewHelper()

    init(_ navController: NavigationController, _ session: ApplinSession) {
        self.navController = navController
        self.session = session
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
        self.view.addSubview(self.navBar)
    }

    required init?(coder: NSCoder) {
        fatalError("unimplemented")
    }

    func back() {
        print("back")
        if self.navController?.topPageController() !== self {
            return
        }
        if let start = self.data?.start {
            self.session?.doActions(start.actions)
        } else {
            self.session?.pop()
        }
    }

    // Called when the user taps the Back button.
    func navigationBar(_ navigationBar: UINavigationBar, shouldPop item: UINavigationItem) -> Bool {
        print("navigationBar shouldPop=\(item)")
        self.back()
        return false  // UINavigationBar should not remove NavigationItem objects.
    }

    // Called when the user presses the Back button,
    // or long-presses the Back button and taps Back from the popup menu.
    func navigationBar(_ navigationBar: UINavigationBar, didPop item: UINavigationItem) {
        print("navigationBar didPop=\(item)")
        self.back()
    }

    // Called when the view gets covered by another view (isMovingFromParent=false) or
    // when the view is removed from the view (isMovingFromParent=true).
    override func viewDidDisappear(_ animated: Bool) {
        // NOTE: UIKit on iOS 15 does not set self.isBeingDismissed=true like the docs claim.
        print("NavPageController viewDidDisappear isMovingFromParent=\(self.isMovingFromParent)")
        if self.isMovingFromParent {
            self.back()
        }
        super.viewDidDisappear(animated)
    }

    func isModal() -> Bool {
        false
    }

    func allowBackSwipe() -> Bool {
        self.data?.start == nil
    }

    func update(
            _ session: ApplinSession,
            _ widgetCache: WidgetCache,
            _ newData: NavPageData,
            hasPrevPage: Bool
    ) {
        self.hasPrevPage = hasPrevPage
        if hasPrevPage {
            self.navBar.items = [UINavigationItem(title: "Back"), self.navigationItem]
        } else {
            self.navBar.items = [self.navigationItem]
        }
        if newData == self.data {
            return
        }
        self.data = newData
        self.title = newData.title
        self.view.backgroundColor = .systemBackground
        self.helper.deactivateConstraints()
        self.subView?.removeFromSuperview()
        let subView = newData.widget.getView(session, widgetCache)
        self.view.addSubview(subView)
        self.subView = subView
        self.helper.setConstraints([
            self.navBar.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            self.navBar.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
            self.navBar.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
            subView.topAnchor.constraint(equalTo: self.navBar.safeAreaLayoutGuide.bottomAnchor),
            subView.bottomAnchor.constraint(lessThanOrEqualTo: self.view.safeAreaLayoutGuide.bottomAnchor),
            subView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
            subView.trailingAnchor.constraint(lessThanOrEqualTo: self.view.safeAreaLayoutGuide.trailingAnchor),
        ])
        widgetCache.flip()
    }
}
