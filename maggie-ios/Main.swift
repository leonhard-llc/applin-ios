import SwiftUI
import UIKit

class NavigationController: UINavigationController {
    init<Content: View>(rootView: Content) {
        super.init(
            rootViewController: UIHostingController(rootView: rootView)
        )
    }

    required init?(coder: NSCoder) {
        fatalError("unimplemented")
    }

    func pushView<Content: View>(_ content: Content, animated: Bool = true) {
        self.pushViewController(UIHostingController(rootView: content), animated: animated)
    }

    // Replaces all views, including the root.
    func setViews(_ views: [AnyView], animated: Bool = true) {
        print("setViews count=\(views.count)")
        self.setViewControllers(
            views.map({ view in UIHostingController(rootView: view)}),
            animated: animated
        )
    }
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    let navigationController: NavigationController
    let session: MaggieSession

    override init() {
        self.navigationController = NavigationController(
            rootView: VStack(alignment: .center) { ProgressView() }
        )
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
