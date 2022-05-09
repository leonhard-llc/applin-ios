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

struct AppView: View {
    @EnvironmentObject var session: MaggieSession
        
    public func binding(_ key: String) -> Binding<Bool> {
        return Binding(
            get: {self.session.isVisible(key)},
            set: { show in
                if !show {
                    let (lastKey, lastPage) = self.session.getStack().last!
                    if lastKey == key && !lastPage.isModal {
                        self.session.pop()
                    }
                }
            }
        )
    }
    
    var body: some View {
        var optPrevView: (String, AnyView)? = nil
        var optPrevModal: (String, MaggieModal)? = nil
        var stack = self.session.getStack()
        precondition(!stack.isEmpty)
        if stack.first!.1.isModal {
            // Stack starts with a modal.  Show a blank page before it.
            stack.insert(("/", MaggiePage.blankPage()), at: 0)
        }
        for (index, (key, page)) in stack.enumerated().reversed() {
            if let modal = page.asModal {
                if optPrevModal != nil {
                    continue
                }
                optPrevModal = (key, modal)
            } else {
                var view = page.toView(self.session, hasPrevPage: index > 0)
                var prevBinding = Binding(get: {false}, set: {show in})
                var prevView = AnyView(EmptyView())
                if let (prevKey, prevAnyView) = optPrevView {
                    prevBinding = self.binding(prevKey)
                    prevView = prevAnyView
                } else if let (modalKey, modal) = optPrevModal {
                    optPrevModal = nil
                    switch modal.kind {
                    case .Alert:
                        view = AnyView(
                            view.alert(modal.title, isPresented: self.binding(modalKey)) {
                                ForEach(modal.widgets) {
                                    widget in widget
                                }
                            }
                        )
                    case .Info, .Question:
                        view = AnyView(
                            view.confirmationDialog(modal.title, isPresented: self.binding(modalKey)) {
                                ForEach(modal.widgets) {
                                    widget in widget
                                }
                            }
                        )
                    }
                }
                view = AnyView(
                    ZStack {
                        NavigationLink(
                            "Hidden",
                            isActive: prevBinding,
                            destination: {prevView}
                        )
                        .hidden()
                        view
                    }
                )
                optPrevView = (key, view)
            }
        }
        let (_, prevAnyView) = optPrevView!
        return NavigationView {
            prevAnyView
        }
        .navigationViewStyle(.stack)
    }
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    let session: MaggieSession
    var window: UIWindow?

    override init() {
        let url = URL(string: "http://127.0.0.1:8000/")!
        self.session = MaggieSession(url: url)
        super.init()
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        print("application didFinishLaunchingWithOptions")
        // https://betterprogramming.pub/creating-ios-apps-without-storyboards-42a63c50756f
        window = UIWindow(frame: UIScreen.main.bounds)
        let view = AppView().environmentObject(self.session)
        let controller = UIHostingController(rootView: view)
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window!.rootViewController = controller
        self.window!.makeKeyAndVisible()
        return true
    }
}
