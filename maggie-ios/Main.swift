import SwiftUI

struct AppView: View {
    @EnvironmentObject var session: MaggieSession

    public func binding(_ key: String) -> Binding<Bool> {
        Binding(
                get: { self.session.isVisible(key) },
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
        var optPrevView: (String, AnyView)?
        var optPrevModal: (String, MaggieModal)?
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
                var prevBinding = Binding(get: { false }, set: { _ in })
                var prevView = AnyView(EmptyView())
                if let (prevKey, prevAnyView) = optPrevView {
                    prevBinding = self.binding(prevKey)
                    prevView = prevAnyView
                } else if let (modalKey, modal) = optPrevModal {
                    optPrevModal = nil
                    switch modal.kind {
                    case .alert:
                        view = AnyView(
                                view.alert(modal.title, isPresented: self.binding(modalKey)) {
                                    ForEach(modal.widgets) { widget in
                                        widget
                                    }
                                }
                        )
                    case .info, .question:
                        view = AnyView(
                                view.confirmationDialog(modal.title, isPresented: self.binding(modalKey)) {
                                    ForEach(modal.widgets) { widget in
                                        widget
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
                                    destination: { prevView }
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
    let dataDirPath: String
    let cacheFileWriter: CacheFileWriter
    let connection: MaggieConnection = MaggieConnection()
    let session: MaggieSession
    let navigationController: NavigationController
    var window: UIWindow?

    override init() {
        // Note: This code runs during app prewarming.
        self.dataDirPath = getDataDirPath()
        self.cacheFileWriter = CacheFileWriter(dataDirPath: dataDirPath)
        self.navigationController = NavigationController()
        let url = URL(string: "http://127.0.0.1:8000/")!
        self.session = MaggieSession(self.cacheFileWriter, self.connection, self.navigationController, url)
        super.init()
    }

    func application(
            _ application: UIApplication,
            didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        print("launch")
        // https://betterprogramming.pub/creating-ios-apps-without-storyboards-42a63c50756f
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window!.rootViewController = self.navigationController
        self.window!.makeKeyAndVisible()
        Task(priority: .high) {
            do {
                await readDefaultData(self.session)
                try createDir(dataDirPath)
                await readCacheFile(dataDirPath: self.dataDirPath, self.session)
                self.connection.start(self.session)
            } catch {
                print("startup error: \(error)")
            }
        }
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        print("active")
        self.connection.start(self.session)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        print("background")
        self.connection.stop()
        self.cacheFileWriter.stop()
    }
}
