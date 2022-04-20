import Foundation
import SwiftUI
import NiftyMarkdownFormatter

func backButton(_ session: MaggieSession) -> some View {
    return Button(action: { session.pop() }) {
        HStack(spacing: 4) {
            Image(systemName: "chevron.backward")
                .font(Font.body.weight(.semibold))
            Text("Back")
        }
    }.padding(Edge.Set.leading, -8.0)
}

struct MaggieAlert: Equatable {
    static func == (lhs: MaggieAlert, rhs: MaggieAlert) -> Bool {
        return lhs.title == rhs.title
        && lhs.widgets == rhs.widgets
    }
    
    static let TYP = "alert"
    let title: String
    let widgets: [MaggieWidget]
    @State var isPresented = true
    
    init(title: String, _ widgets: [MaggieWidget]) {
        self.title = title
        self.widgets = widgets
    }
    
    init(_ item: JsonItem, _ session: MaggieSession) throws {
        self.title = try item.takeTitle()
        self.widgets = try item.takeWidgets(session)
    }
    
    public func toView() -> AnyView {
        return AnyView(
            EmptyView().alert(self.title, isPresented: self.$isPresented) {
                ForEach(0..<self.widgets.count) {
                    n in self.widgets[n]
                }
            }
        )
    }
}

struct MaggieConfirmation: Equatable {
    static func == (lhs: MaggieConfirmation, rhs: MaggieConfirmation) -> Bool {
        return lhs.title == rhs.title
        && lhs.widgets == rhs.widgets
    }
    
    static let TYP = "confirmation"
    let title: String
    let widgets: [MaggieWidget]
    @State var isPresented = true
    
    init(title: String, _ widgets: [MaggieWidget]) {
        self.title = title
        self.widgets = widgets
    }
    
    init(_ item: JsonItem, _ session: MaggieSession) throws {
        self.title = try item.takeTitle()
        self.widgets = try item.takeWidgets(session)
    }
    
    public func toView() -> AnyView {
        return AnyView(
            EmptyView().confirmationDialog(self.title, isPresented: self.$isPresented) {
                ForEach(0..<self.widgets.count) {
                    n in self.widgets[n]
                }
            }
        )
    }
}

enum MarkdownViewState {
    case loading(Task<Void, Never>?)
    case error(String)
    case ok(String)
}

struct MaggieMarkdownPage: Equatable {
    static func == (lhs: MaggieMarkdownPage, rhs: MaggieMarkdownPage) -> Bool {
        return lhs.title == rhs.title
        && lhs.url == rhs.url
        && lhs.cache == rhs.cache
    }
    
    static let TYP = "markdown-page"
    let title: String
    let url: URL
    let cache: Bool?
    @State var state: MarkdownViewState = .loading(nil)
    
    init(title: String, url: URL, cache: Bool? = nil) {
        self.title = title
        self.url = url
        self.cache = cache
    }
    
    init(_ item: JsonItem) throws {
        self.title = try item.takeTitle()
        self.url = try item.takeUrl()
        self.cache = item.takeOptCache()
    }
    
    func setError(_ msg: String) {
        print(msg)
        self.state = .error(msg)
    }
    
    func load() async {
        do {
            let urlSession = (self.cache ?? false) ? URLSession.shared : URLSession(configuration:URLSessionConfiguration.ephemeral)
            let (data, urlResponse) = try await urlSession.data(from: self.url)
            let response = urlResponse as! HTTPURLResponse
            print("GET \(self.url) response: \(response), bodyLen=\(data.count)")
            if response.statusCode != 200 {
                let description = HTTPURLResponse.localizedString(
                    forStatusCode: response.statusCode)
                self.setError("\(response.statusCode) \(description)")
                return
            }
            let contentType = response.value(forHTTPHeaderField: "content-type")?.lowercased() ?? ""
            let base = contentType.split(
                separator: ";", maxSplits: 1, omittingEmptySubsequences: false)[0]
            if base != "text/markdown" {
                self.setError("Response is not text/markdown")
                return
            }
            if data.count > 1 * 1024 * 1024 {
                self.setError("Document is too big: \(data.count) bytes")
                return
            }
            guard let string = String(data: data, encoding: String.Encoding.utf8) else {
                self.setError("Response is not UTF-8")
                return
            }
            self.state = .ok(string)
        } catch {
            print("ERROR GET \(self.url) : \(error)")
            self.setError(error.localizedDescription)
        }
    }
    
    func startLoad() {
        switch self.state {
        case .loading(.none), .error, .ok:
            self.state = .loading(Task() { await self.load() })
        case .loading:
            break
        }
    }
    
    func stopLoad() {
        if case let .loading(.some(task)) = self.state {
            task.cancel()
            self.state = .loading(nil)
        }
    }
    
    public func toView(_ session: MaggieSession, hasPrevPage: Bool) -> AnyView {
        var view: AnyView
        switch self.state {
        case .loading:
            view = AnyView(
                VStack() {
                    Spacer()
                    ProgressView("Loading")
                    Spacer()
                    Button("Refresh") {}.disabled(true)
                }
                    .onAppear(perform: self.startLoad)
                    .onDisappear(perform: self.stopLoad)
            )
        case let .error(msg):
            return AnyView(
                VStack() {
                    Spacer()
                    Image(systemName: "xmark.octagon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100)
                    Text("ERROR")
                    Text(msg).padding()
                    Spacer()
                    Button("Refresh") { self.startLoad() }
                })
        case let .ok(markdown):
            return AnyView(
                VStack() {
                    ScrollView(showsIndicators: true) {
                        FormattedMarkdown(
                            markdown: markdown,
                            alignment: .leading,
                            spacing: 7.0
                        )
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                    Button("Refresh") { self.startLoad() }
                })
        }
        if hasPrevPage {
            return AnyView(
                view
                    .navigationTitle(self.title)
                    .navigationBarBackButtonHidden(true)
                    .toolbar() {
                        ToolbarItemGroup(placement: .navigationBarLeading) {
                            backButton(session)
                        }
                    }
            )
        } else {
            return AnyView(
                view
                    .navigationTitle(self.title)
                    .navigationBarBackButtonHidden(true)
            )
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
        self.title = try item.takeTitle()
        self.start = try item.takeOptStart(session)
        self.end = try item.takeOptEnd(session)
        self.widget = try item.takeWidget(session)
    }
    
    //public func allowBackSwipe() -> Bool {
    //    return self.start == nil
    //}
    
    public func toView(_ session: MaggieSession, hasPrevPage: Bool) -> AnyView {
        var view: AnyView = AnyView(
            self.widget
                .navigationTitle(self.title)
                .navigationBarBackButtonHidden(true)
        )
        if let start = self.start {
            view = AnyView(view.toolbar() {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    start
                        .padding(Edge.Set.leading, -8.0)
                }
            })
        } else if hasPrevPage {
            view = AnyView(view.toolbar() {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    backButton(session)
                }
            })
        }
        if let end = self.end {
            view = AnyView(view.toolbar() {
                ToolbarItemGroup(placement: .navigationBarTrailing) { end }
            })
        }
        return view
    }
}

struct MaggiePlainPage: Equatable {
    static let TYP = "plain-page"
    let title: String?
    let widget: MaggieWidget
    
    init(title: String?, _ widget: MaggieWidget) {
        self.title = title
        self.widget = widget
    }
    
    init(_ item: JsonItem, _ session: MaggieSession) throws {
        self.title = try item.takeOptTitle()
        self.widget = try item.takeWidget(session)
    }
    
    public func toView() -> AnyView {
        return AnyView(self.widget.navigationBarHidden(true))
    }
}

enum MaggiePage: Equatable {
    case Alert(MaggieAlert)
    case Confirmation(MaggieConfirmation)
    case MarkdownPage(MaggieMarkdownPage)
    case NavPage(MaggieNavPage)
    case PlainPage(MaggiePlainPage)
    
    init(_ item: JsonItem, _ session: MaggieSession) throws {
        switch item.typ {
        case MaggieAlert.TYP:
            self = try .Alert(MaggieAlert(item, session))
        case MaggieConfirmation.TYP:
            self = try .Confirmation(MaggieConfirmation(item, session))
        case MaggieMarkdownPage.TYP:
            self = try .MarkdownPage(MaggieMarkdownPage(item))
        case MaggieNavPage.TYP:
            self = try .NavPage(MaggieNavPage(item, session))
        case MaggiePlainPage.TYP:
            self = try .PlainPage(MaggiePlainPage(item, session))
        default:
            throw MaggieError.deserializeError("unexpected page 'typ' value: \(item.typ)")
        }
    }
    
    var isPage: Bool {
        get {
            switch self {
            case .Alert(_), .Confirmation(_):
                return false
            case .MarkdownPage(_), .NavPage(_), .PlainPage(_):
                return true
            }
        }
    }
    
    var title: String? {
        get {
            switch self {
            case let .Alert(inner):
                return inner.title
            case let .Confirmation(inner):
                return inner.title
            case let .MarkdownPage(inner):
                return inner.title
            case let .NavPage(inner):
                return inner.title
            case .PlainPage(_):
                return nil
            }
        }
    }
    
    public func toView(_ session: MaggieSession, hasPrevPage: Bool) -> AnyView {
        switch self {
        case let .Alert(inner):
            return inner.toView()
        case let .Confirmation(inner):
            return inner.toView()
        case let .MarkdownPage(inner):
            return inner.toView(session, hasPrevPage: hasPrevPage)
        case let .NavPage(inner):
            return inner.toView(session, hasPrevPage: hasPrevPage)
        case let .PlainPage(inner):
            return inner.toView()
        }
    }
    
    //public func allowBackSwipe() -> Bool {
    //    switch self {
    //    case .Alert(_), .Confirmation(_), .MarkdownPage(_):
    //        return true
    //    case let .NavPage(inner):
    //        return inner.allowBackSwipe()
    //    case .PlainPage(_):
    //        return false
    //    }
    //}
}
