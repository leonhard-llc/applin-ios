import Foundation
import SwiftUI
import NiftyMarkdownFormatter

struct MaggieAlert: View {
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
    
    var body: some View {
        EmptyView().alert(self.title, isPresented: self.$isPresented) {
            ForEach(0..<self.widgets.count) {
                n in self.widgets[n]
            }
        }
    }
}

struct MaggieConfirmation: View {
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
    
    var body: some View {
        EmptyView().confirmationDialog(self.title, isPresented: self.$isPresented) {
            ForEach(0..<self.widgets.count) {
                n in self.widgets[n]
            }
        }
    }
}

enum MarkdownViewState {
    case loading(Task<Void, Never>?)
    case error(String)
    case ok(String)
}

struct MaggieMarkdownPage: View {
    static let TYP = "markdown-page"
    let title: String
    let url: URL
    @State var state: MarkdownViewState = .loading(nil)
    
    init(title: String, url: URL) {
        self.title = title
        self.url = url
    }
    
    init(_ item: JsonItem) throws {
        self.title = try item.takeTitle()
        self.url = try item.takeUrl()
    }
    
    func setError(_ msg: String) {
        print(msg)
        self.state = .error(msg)
    }
    
    func load() async {
        do {
            let urlSession = URLSession(configuration:URLSessionConfiguration.ephemeral)
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
    
    var body: some View {
        switch self.state {
        case .loading:
            return AnyView(
                VStack() {
                    Spacer()
                    ProgressView("Loading")
                    Spacer()
                    Button("Refresh") {}.disabled(true)
                }
                    .navigationTitle(self.title)
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
                }
                    .navigationTitle(self.title))
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
                }.navigationTitle(self.title))
        }
    }
}

struct MaggieNavPage: View {
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
    
    var body: some View {
        var view: AnyView = AnyView(self.widget.navigationTitle(self.title))
        if let start = self.start {
            view = AnyView(view.toolbar() {
                ToolbarItemGroup(placement: .navigationBarLeading) { start }
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

struct MaggiePlainPage: View {
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
    
    var body: some View {
        if let title = self.title {
            return AnyView(self.widget.navigationTitle(title))
        } else {
            return AnyView(self.widget.navigationBarHidden(true))
        }
    }
}

// TODO: Add "leading-widgets", "trailing-widgets", and "typ":"back-button".
//let start: (String, [MaggieAction])?
//switch (self.startText, self.startActions) {
//case let (.none, .some(actions)) where !actions.isEmpty:
//    throw MaggieError.deserializeError("object has 'start-actions' without 'start-text'")
//case (.none, _):
//    start = nil
//case (.some(""), _):
//    throw MaggieError.deserializeError("empty 'start-text'")
//case let (.some(text), opt_actions):
//    let actions = try (opt_actions ?? []).map({ s in try maggieAction(s) })
//    start = (text, actions)
//}
//let end: (String, [MaggieAction])?
//switch (self.endText, self.endActions) {
//case let (.none, .some(actions)) where !actions.isEmpty:
//    throw MaggieError.deserializeError("object has 'end-actions' without 'end-text'")
//case (.none, _):
//    end = nil
//case (.some(""), _):
//    throw MaggieError.deserializeError("empty 'end-text'")
//case let (.some(text), opt_actions):
//    let actions = try (opt_actions ?? []).map({ s in try maggieAction(s) })
//    end = (text, actions)
//}

enum MaggiePage: View {
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
    
    var body: AnyView {
        switch self {
        case let .Alert(inner):
            return AnyView(inner)
        case let .Confirmation(inner):
            return AnyView(inner)
        case let .MarkdownPage(inner):
            return AnyView(inner)
        case let .NavPage(inner):
            return AnyView(inner)
        case let .PlainPage(inner):
            return AnyView(inner)
        }
    }
}
