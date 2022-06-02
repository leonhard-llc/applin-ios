import Foundation
import UIKit

class NavPageController: UIViewController {
    weak var navController: NavigationController?
    weak var session: MaggieSession?
    var page: MaggieNavPage
    var subView: UIView = UIView()
    var constraints: [NSLayoutConstraint] = []

    init(_ navController: NavigationController, _ session: MaggieSession, _ page: MaggieNavPage) {
        self.navController = navController
        self.session = session
        self.page = page
        super.init(nibName: nil, bundle: nil)
        self.update()
    }

    required init?(coder: NSCoder) {
        fatalError("unimplemented")
    }

    override func viewDidDisappear(_ animated: Bool) {
        // NOTE: UIKit does not set self.isBeingDismissed to true like the docs say.
        print("NavPageController viewDidDisappear isMovingFromParent=\(self.isMovingFromParent)")
        if self.isMovingFromParent && self.navController?.topPageController()?.inner() === self {
            print("back")
            self.session?.pop()
        }
        super.viewDidDisappear(animated)
    }

    func setPage(_ page: MaggieNavPage) {
        if page == self.page {
            return
        }
        self.page = page
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
            self.constraints.append(
                    self.subView.topAnchor.constraint(
                            equalTo: self.view.safeAreaLayoutGuide.topAnchor))
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
    let start: MaggieWidget?
    let end: MaggieWidget?
    let widget: MaggieWidget

    init(
            title: String,
            widget: MaggieWidget,
            start: MaggieWidget? = nil,
            end: MaggieWidget? = nil
    ) {
        self.title = title
        self.start = start
        self.end = end
        self.widget = widget
    }

    init(_ item: JsonItem, _ session: MaggieSession) throws {
        self.title = try item.requireTitle()
        self.start = try item.optStart(session)
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
