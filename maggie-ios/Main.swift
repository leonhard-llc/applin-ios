import SwiftUI

struct AppView: View {
    @EnvironmentObject var session: MaggieSession
        
    public func binding(_ key: String) -> Binding<Bool> {
        return Binding(
            get: {self.session.isVisible(key)},
            set: { show in
                print("binding key=\(key) show=\(show)")
                if !show {
                    let (lastKey, lastPage) = self.session.getStack().last!
                    if lastKey == key && !lastPage.isModal {
                        self.session.pop()
                    } else if lastKey == key {
                        self.session.redraw()
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
        // Start task after app is launched.
        // This avoids starting it during prewarming.
        Task(priority: .high) {
            await self.session.startupTask()
        }
        return true
    }
}
