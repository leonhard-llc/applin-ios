import Foundation
import UIKit

class NavPageController: UIViewController, UINavigationBarDelegate {
    weak var navController: NavigationController?
    weak var session: MaggieSession?
    var page: MaggieNavPage
    var navBar: UINavigationBar
    var hasPrev: Bool
    var subView: UIView = UIView()
    var constraints: [NSLayoutConstraint] = []

    init(
            _ navController: NavigationController,
            _ session: MaggieSession,
            _ page: MaggieNavPage,
            _ hasPrev: Bool
    ) {
        self.navController = navController
        self.session = session
        self.navBar = UINavigationBar()
        self.page = page
        self.hasPrev = hasPrev
        super.init(nibName: nil, bundle: nil)
        self.navBar.delegate = self
        self.update()
    }

    required init?(coder: NSCoder) {
        fatalError("unimplemented")
    }

    func back() {
        print("back")
        if self.navController?.topPageController()?.inner() !== self {
            return
        }
        if let start = self.page.start {
            self.session?.doActions(start.actions)
        } else {
            self.session?.pop()
        }
    }

    // Called when the user taps the Back button.
    func navigationBar(_ navigationBar: UINavigationBar, shouldPop item: UINavigationItem) -> Bool {
        print("navigationBar shouldPop=\(item)")
        self.back()
        return false
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

    func setPage(_ page: MaggieNavPage, _ hasPrev: Bool) {
        if page == self.page && self.hasPrev == hasPrev {
            return
        }
        self.page = page
        self.hasPrev = hasPrev
        self.update()
    }

    func update() {
        if let session = self.session {
            self.title = page.title
            self.view.backgroundColor = .systemBackground
            NSLayoutConstraint.deactivate(self.constraints)
            self.constraints.removeAll(keepingCapacity: true)
            self.subView.removeFromSuperview()
            self.subView = self.page.widget.makeView(session)
            self.view.addSubview(self.subView)
            // We do not use UINavigationController's navbar because when we pop a
            // NavPage with a PlainPage underneath, the PlainPage shows a navbar for
            // a second while the animation is running, then it disappears.
            // This is looks bad.  So we add our own navbar.
            self.navBar.translatesAutoresizingMaskIntoConstraints = false
            self.navBar.removeFromSuperview()
            self.navBar.items = [UINavigationItem(title: "Back"), self.navigationItem]
            self.navBar.isHidden = false
            self.view.addSubview(self.navBar)
            self.constraints.append(
                    self.navBar.topAnchor.constraint(
                            equalTo: self.view.safeAreaLayoutGuide.topAnchor))
            self.constraints.append(
                    self.navBar.leadingAnchor.constraint(
                            equalTo: self.view.safeAreaLayoutGuide.leadingAnchor))
            self.constraints.append(
                    self.navBar.trailingAnchor.constraint(
                            equalTo: self.view.safeAreaLayoutGuide.trailingAnchor))
            self.constraints.append(
                    self.subView.topAnchor.constraint(
                            equalTo: self.navBar.safeAreaLayoutGuide.bottomAnchor))
            self.constraints.append(
                    self.subView.bottomAnchor.constraint(
                            lessThanOrEqualTo: self.view.safeAreaLayoutGuide.bottomAnchor))
            self.constraints.append(
                    self.subView.leadingAnchor.constraint(
                            equalTo: self.view.safeAreaLayoutGuide.leadingAnchor))
            self.constraints.append(
                    self.subView.trailingAnchor.constraint(
                            lessThanOrEqualTo: self.view.safeAreaLayoutGuide.trailingAnchor))
            NSLayoutConstraint.activate(self.constraints)
        }
    }
}

struct MaggieNavPage: Equatable {
    static let TYP = "nav-page"
    let title: String
    let start: MaggieBackButton?
    let end: MaggieWidget?
    let widget: MaggieWidget

    init(
            title: String,
            widget: MaggieWidget,
            start: MaggieBackButton? = nil,
            end: MaggieWidget? = nil
    ) {
        self.title = title
        self.start = start
        self.end = end
        self.widget = widget
    }

    init(_ item: JsonItem, _ session: MaggieSession) throws {
        self.title = try item.requireTitle()
        switch try item.optStart(session) {
        case .none:
            self.start = nil
        case let .backButton(start):
            self.start = start
        case let .some(other):
            throw MaggieError.deserializeError("bad \(item.typ).start: \(other)")
        }
        self.end = try item.optEnd(session)
        self.widget = try item.requireWidget(session)
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(MaggieNavPage.TYP)
        item.title = self.title
        item.start = self.start?.toJsonItem()
        item.end = self.end?.toJsonItem()
        item.widget = self.widget.toJsonItem()
        return item
    }

    func allowBackSwipe() -> Bool {
        self.start == nil
    }

//    public func toView(_ session: MaggieSession, hasPrevPage: Bool) -> AnyView {
//        var view: AnyView = AnyView(
//                self.widget
//                        .navigationTitle(self.title)
//                        .navigationBarTitleDisplayMode(.inline)
//                        .navigationBarBackButtonHidden(true)
//        )
//        if let start = self.start {
//            view = AnyView(view.toolbar {
//                ToolbarItemGroup(placement: .navigationBarLeading) {
//                    start
//                }
//            })
//        } else if hasPrevPage {
//            view = AnyView(view.toolbar {
//                ToolbarItemGroup(placement: .navigationBarLeading) {
//                    MaggieBackButton([.pop], session)
//                }
//            })
//        }
//        if let end = self.end {
//            view = AnyView(view.toolbar {
//                ToolbarItemGroup(placement: .navigationBarTrailing) {
//                    end
//                }
//            })
//        }
//        return view
//    }
}
