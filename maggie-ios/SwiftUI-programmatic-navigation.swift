import SwiftUI

func navLinkBinding(onTap: @escaping () -> Void) -> Binding<Bool> {
    return Binding(
        get: {() in false},
        set: { show in
            if show {
                print("navLinkBinding onTap")
                onTap()
            }
        }
    )
}

func content(_ app: App, _ id: String) -> AnyView {
    return AnyView(
        List {
            Text("Hello")
            NavigationLink(
                "Page1",
                isActive: navLinkBinding(onTap: {app.push(page1(app, id))}),
                destination: {EmptyView()}
            )
            NavigationLink(
                "Page2",
                isActive: navLinkBinding(onTap: {app.push(page2(app, id))}),
                destination: {EmptyView()}
            )
            NavigationLink(
                "Page3",
                isActive: navLinkBinding(onTap: {app.push(page3(app, id))}),
                destination: {EmptyView()}
            )
            NavigationLink(
                "Alert1",
                isActive: navLinkBinding(onTap: {app.push(alert1(app, id))}),
                destination: {EmptyView()}
            )
            NavigationLink(
                "Alert2",
                isActive: navLinkBinding(onTap: {app.push(alert2(app, id))}),
                destination: {EmptyView()}
            )
        }
    )
}

func homePage(_ app: App) -> Page {
    let id = "home"
    return .Normal(id, AnyView(
        content(app, id)
            .navigationTitle("Home")
    ))
}

func page1(_ app: App, _ parentId: String) -> Page {
    let id = "\(parentId)-page1"
    return .Normal(id, AnyView(
        content(app, id)
            .navigationTitle("Page1")
    ))
}

func page2(_ app: App, _ parentId: String) -> Page {
    let id = "\(parentId)-page2"
    return .Normal(id, AnyView(
        content(app, id)
            .navigationTitle("Page2")
    ))
}

func page3(_ app: App, _ parentId: String) -> Page {
    let id = "\(parentId)-page3"
    return .Normal(id, AnyView(
        content(app, id)
            .navigationTitle("Page3")
    ))
}

func alert1(_ app: App, _ parentId: String) -> Page {
    let id = "\(parentId)-alert1"
    return .Alert(id, "Alert1", AnyView(
        HStack {
            Text("Hello")
            Button("Page1") {app.push(page1(app, id))}
            Button("Page2") {app.push(page2(app, id))}
            Button("Page3") {app.push(page3(app, id))}
            Button("Alert1") {app.push(alert1(app, id))}
            Button("Alert2") {app.push(alert2(app, id))}
            Button("OK") { app.pop(id) }
        }
    ))
}

func alert2(_ app: App, _ parentId: String) -> Page {
    let id = "\(parentId)-alert2"
    return .Alert(id, "Alert2", AnyView(
        HStack {
            Text("Hello")
            Button("Page1") {app.push(page1(app, id))}
            Button("Page2") {app.push(page2(app, id))}
            Button("Page3") {app.push(page3(app, id))}
            Button("Alert1") {app.push(alert1(app, id))}
            Button("Alert2") {app.push(alert2(app, id))}
            Button("OK") { app.pop(id) }
        }
    ))
}

enum Page: Identifiable {
    case Normal(String, AnyView)
    case Alert(String, String, AnyView)

    var id: String {
        switch self {
        case let .Normal(id, _), let .Alert(id, _, _):
            return id
        }
    }
    
    public func isModal() -> Bool {
        switch self {
        case .Normal:
            return false
        case .Alert:
            return true
        }
    }
}

class App: ObservableObject {
    @Published
    var stack: [Page]
    
    public init() {
        self.stack = []
        self.stack.append(homePage(self))
    }
    
    public func stackString() -> String {
        return "\(self.stack.map({page in page.id}))"
    }
    
    public func push(_ target: Page) {
        print("push \(target.id)")
        self.stack.append(target)
        print("stack=\(self.stackString())")
    }
    
    public func pop(_ id: String) {
        print("pop(\(id)")
        for (index, page) in self.stack.enumerated().reversed() {
            if page.id == id {
                self.stack.remove(at: index)
                print("stack=\(self.stackString())")
                return
            }
        }
    }
    
    public func isVisible(_ id: String) -> Bool {
        for page in self.stack {
            if page.id == id {
                print("isVisible(\(id)) -> true")
                return true
            }
        }
        print("isVisible(\(id)) -> false")
        return false
    }
    
    public func binding(_ index: Int, _ id: String) -> Binding<Bool> {
        return Binding(
            get: {self.isVisible(id)},
            set: { show in
                if !show && !self.stack.last!.isModal() && self.stack.last!.id == id {
                    let page = self.stack.removeLast()
                    print("pop \(page.id)")
                    print("stack=\(self.stackString())")
                }
            }
        )
    }
    
    public func makeView() -> AnyView {
        print("App.body stack=\(self.stackString())")
        var optPrevView: (Int, String, AnyView)? = nil
        var optPrevModal: (Int, String, String, AnyView)? = nil
        for (index, page) in self.stack.enumerated().reversed() {
            switch page {
            case let .Alert(id, title, actions):
                if optPrevModal != nil {
                    continue
                }
                optPrevModal = (index, id, title, actions)
            case .Normal(let id, var view):
                var prevBinding = Binding(get: {false}, set: {show in})
                var prevView = AnyView(EmptyView())
                if let (prevIndex, prevId, prevAnyView) = optPrevView {
                    prevBinding = self.binding(prevIndex, prevId)
                    prevView = prevAnyView
                } else if let (modalIndex, modalId, modalTitle, modalActions) = optPrevModal {
                    optPrevModal = nil
                    view = AnyView(
                        view
                            .alert(
                                modalTitle,
                                isPresented: self.binding(modalIndex, modalId),
                                actions: {modalActions}
                        )
                    )
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
                optPrevView = (index, id, view)
            }
        }
        if let (_, _, prevAnyView) = optPrevView {
            return prevAnyView
        } else {
            return AnyView(Text("ERROR: root view is modal"))
        }
    }
}

struct AppView: View {
    @EnvironmentObject var app: App
    var body: some View {
        NavigationView {
            app.makeView()
        }.navigationViewStyle(.stack)
    }
}

@main
class AppDelegate2: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var app: App = App()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        print("application didFinishLaunchingWithOptions")
        // https://betterprogramming.pub/creating-ios-apps-without-storyboards-42a63c50756f
        let view = AppView().environmentObject(self.app)
        let controller = UIHostingController(rootView: view)
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window!.rootViewController = controller
        self.window!.makeKeyAndVisible()
        return true
    }
}
