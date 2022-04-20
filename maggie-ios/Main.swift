import SwiftUI
import UIKit

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

    static func shouldAnimate(old: [MaggiePage], new: [MaggiePage]) -> Bool {
        if old.isEmpty {
            return false
        }
        // TODO: Implement.
        return false
    }
    
    func setStackPages(_ session: MaggieSession, _ newPages: [(String, MaggiePage)]) {
        print("setStackPages")
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
        let animated = NavigationController.shouldAnimate(
            old: self.controllers.map({ (key, page, controller) in page}),
            new: newControllers.map({ (key, page, controller) in page})
        )
        self.controllers = newControllers
        self.setViewControllers(
            newControllers.map({(key, page, controller) in controller}),
            animated: animated
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
