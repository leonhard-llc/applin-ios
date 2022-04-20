import SwiftUI
import UIKit

// Failed attempt to implement swipe-back.
// UINavigationController does not set isBeingDismissed=true.
// The view cannot easily find out if it was dismissed or just hidden.
// One way is to ask the navigation controller if it is the top view
// and assume that it was dismissed.
// If the view decides that it was dismissed,
// it must pop itself from the session's stack.
// This seems prone to race conditions and popping the wrong page.
//
// One alternative is to combine the session and nav controller.
// But then we lose the separation of concerns.
//
// Another alternative is to re-implement the swiping gesture and
// give the nav controller a proper "dismissTopPage()" method.
// That would still have to call session.pop().
// There's no escaping the spaghetti.
//
// The root cause of all of this is that UIKits's UINavigationController
// is not at all modular.  It is designed to be used in exactly one way.
// It has very few features to allow flexibility or customization.
// SwiftUI's NavigationView is even less flexible.
// Apple, you can do better.
//
//class PageController: UIHostingController<AnyView> {
//    weak var navController: NavigationController?
//    //weak var session: MaggieSession?
//    var page: MaggiePage
//
//    init(_ navController: NavigationController, _ session: MaggieSession, _ page: MaggiePage, hasPrevPage: Bool) {
//        self.navController = navController
//        self.page = page
//        let view = page.toView(session, hasPrevPage: hasPrevPage)
//        super.init(rootView: view)
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("unimplemented")
//    }
//
//    func setPage(_ session: MaggieSession, _ page: MaggiePage, hasPrevPage: Bool) {
//        self.page = page
//        let view = page.toView(session, hasPrevPage: hasPrevPage)
//        self.rootView = view
//    }
//
//    override func viewDidDisappear(_ animated: Bool) {
//        print("PageController viewDidDisappear isBeingDismissed=\(self.isBeingDismissed) isMovingFromParent=\(self.isMovingFromParent)")
//        super.viewDidDisappear(animated)
//        if self.isBeingDismissed || self.isMovingFromParent {
//            self.navController?.wasDismissed(self)
//        }
//    }
//}
//class NavigationController: UINavigationController, UIGestureRecognizerDelegate {
//    deinit {
//        self.interactivePopGestureRecognizer?.delegate = nil
//    }
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        self.interactivePopGestureRecognizer?.delegate = self
//    }
//
//    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
//        let result = self.controllers.last?.1.allowBackSwipe() ?? false
//        print("allowBackSwipe \(result)")
//        return result
//    }
//
//    public func wasDismissed(_ pageController: PageController) {
//        print("NavigationController a page was dismissed")
//        if self.controllers.last?.2 === pageController {
//            print("NavigationController top page was dismissed")
//            self.controllers.removeLast()
//            self.setViewControllers(
//                self.controllers.map({(key, page, controller) in controller}),
//                animated: false
//            )
//        } else {
//            print("NavigationController non-top page was dismissed")
//        }
//    }

class NavigationController: UINavigationController {
    var controllers: [(String, MaggiePage, UIHostingController<AnyView>)] = []

    init() {
        super.init(rootViewController: UIHostingController(
            rootView: VStack(alignment: .center) { ProgressView() }
        ))
    }
    
    required init?(coder: NSCoder) {
        fatalError("unimplemented")
    }
    
    func setStackPages(_ session: MaggieSession, _ newPages: [(String, MaggiePage)]) {
        print("setStackPages")
        let topPageController = self.controllers
            .reversed()
            .filter({(key, page, controller) in page.isPage})
            .map({(key, page, controller) in controller})
            .first
        precondition(!newPages.isEmpty)
        var newControllers: [(String, MaggiePage, UIHostingController<AnyView>)] = []
        var hasPrevPage = false
        for (newKey, newPage) in newPages {
            if let n = self.controllers
                .map({(key, page, controller) in key})
                .enumerated()
                .filter({(n, key) in key == newKey})
                .map({(n, key) in n})
                .first {
                let (key, page, controller) = self.controllers.remove(at: n)
                if newPage != page {
                    controller.rootView = newPage.toView(session, hasPrevPage: hasPrevPage)
                }
                newControllers.append((key, newPage, controller))
            } else {
                let view = newPage.toView(session, hasPrevPage: hasPrevPage)
                let controller = UIHostingController(rootView: view)
                newControllers.append((newKey, newPage, controller))
            }
            if newPage.isPage {
                hasPrevPage = true
            }
        }
        self.controllers = newControllers
        let newTopPageController = self.controllers
            .reversed()
            .filter({(key, page, controller) in page.isPage})
            .map({(key, page, controller) in controller})
            .first
        self.setViewControllers(
            newControllers.map({(key, page, controller) in controller}),
            animated: topPageController !== newTopPageController
        )
    }
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    let session: MaggieSession
    let navigationController: NavigationController
    var window: UIWindow?

    override init() {
        self.navigationController = NavigationController()
        self.session = MaggieSession(url: "http://localhost/", self.navigationController)
        super.init()
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        print("application didFinishLaunchingWithOptions")
        // https://betterprogramming.pub/creating-ios-apps-without-storyboards-42a63c50756f
        window = UIWindow(frame: UIScreen.main.bounds)
        window!.rootViewController = self.navigationController

        // Demo
        Task() {
            // Run this after a small delay to prevent
            // "Unbalanced calls to begin/end appearance transitions" warning
            try? await Task.sleep(nanoseconds: 1_000)
            window!.makeKeyAndVisible()
        }

        return true
    }
}
