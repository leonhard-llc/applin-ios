import Foundation
import SwiftUI

import NiftyMarkdownFormatter

struct MaggieAlert {
    static let TYP = "alert"
    let title: String
    let widgets: [MaggieWidget]
    
    init(title: String, widgets: [MaggieWidget]) {
        self.title = title
        self.widgets = widgets
    }
}

struct MaggieButton: View {
    static let TYP = "button"
    let text: String
    let isDefault: Bool
    let actions: [MaggieAction]
    
    init(text: String, isDefault: Bool, actions: [MaggieAction]) {
        self.text = text
        self.isDefault = isDefault
        self.actions = actions
    }
    
    var body: some View {
        Button(self.text) {
            for action in self.actions {
                action.perform()
            }
        }
    }
}

struct MaggieCenter: View {
    static let TYP = "center"
    let widget: MaggieWidget
    
    init(widget: MaggieWidget) {
        self.widget = widget
    }
    
    var body: some View {
        VStack(alignment: .center) { self.widget }
    }
}

struct MaggieColumn: View {
    static let TYP = "column"
    let widgets: [MaggieWidget]
    
    init(widgets: [MaggieWidget]) {
        self.widgets = widgets
    }
    
    var body: some View {
        VStack() {
            ForEach(0..<self.widgets.count) {
                n in self.widgets[n]
            }
        }
    }
}

struct MaggieErrorDetails {
    static let TYP = "error-details"
}

struct MaggieExpand: View {
    static let TYP = "expand"
    let widget: MaggieWidget
    
    init(widget: MaggieWidget) {
        self.widget = widget
    }
    
    var body: some View {
        self.widget.frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .leading
        )
    }
}

enum MarkdownViewState {
    case loading(Task<Void, Never>?)
    case error(String)
    case ok(String)
}

struct MaggieMarkdownView: View {
    static let TYP = "markdown-view"
    let url: URL
    @State var state: MarkdownViewState = .loading(nil)
    
    init(url: URL) {
        self.url = url
    }
    
    func setError(_ msg: String) {
        print(msg)
        self.state = .error(msg)
    }
    
    func load() async {
        do {
            let (data, urlResponse) = try await URLSession.shared.data(from: self.url)
            let response = urlResponse as! HTTPURLResponse
            print("GET \(self.url) -> \(response), bodyLen=\(data.count)")
            if response.statusCode != 200 {
                let description = HTTPURLResponse.localizedString(
                    forStatusCode: response.statusCode)
                self.setError("ERROR: \(response.statusCode) \(description)")
                return
            }
            let contentType = response.value(forHTTPHeaderField: "content-type")?.lowercased() ?? ""
            let base = contentType.split(
                separator: ";", maxSplits: 1, omittingEmptySubsequences: false)[0]
            if base != "text/markdown" {
                self.setError("ERROR: Response is not text/markdown")
                return
            }
            if data.count > 1 * 1024 * 1024 {
                self.setError("ERROR: Document is too big: \(data.count) bytes")
                return
            }
            guard let string = String(data: data, encoding: String.Encoding.utf8) else {
                self.setError("ERROR: Response is not UTF-8")
                return
            }
            self.state = .ok(string)
        } catch {
            self.setError("ERROR: \(error)")
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
        get {
            switch self.state {
            case .loading:
                return AnyView(
                    ProgressView("Loading")
                        .onAppear(perform: self.startLoad)
                        .onDisappear(perform: self.stopLoad))
            case let .error(msg):
                return AnyView(Text(msg))
            case let .ok(markdown):
                return AnyView(FormattedMarkdown(
                    markdown: markdown, alignment: .leading, spacing: 7.0))
            }
        }
    }
}

struct MaggieRow {
    static let TYP = "row"
    let widgets: [MaggieWidget]
    
    init(widgets: [MaggieWidget]) {
        self.widgets = widgets
    }
}

struct MaggieScroll {
    static let TYP = "scroll"
    let widget: MaggieWidget
    
    init(widget: MaggieWidget) {
        self.widget = widget
    }
}

struct MaggieHorizontalScroll {
    static let TYP = "horizontal-scroll"
    let widget: MaggieWidget
    
    init(widget: MaggieWidget) {
        self.widget = widget
    }
}

struct MaggieText: View {
    static let TYP = "text"
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        Text(self.text)
    }
}

struct MaggieSpacer: View {
    static let TYP = "spacer"
    
    var body: Spacer {
        Spacer()
    }
}

enum MaggieWidget: View {
    indirect case Alert(MaggieAlert)
    case Button(MaggieButton)
    indirect case Center(MaggieCenter)
    indirect case Column(MaggieColumn)
    case ErrorDetails(MaggieErrorDetails)
    indirect case Expand(MaggieExpand)
    case MarkdownView(MaggieMarkdownView)
    indirect case Row(MaggieRow)
    indirect case Scroll(MaggieScroll)
    indirect case HorizontalScroll(MaggieHorizontalScroll)
    indirect case Spacer(MaggieSpacer)
    case Text(MaggieText)
    
    var body: some View {
        switch self {
        case let .Button(inner):
            return AnyView(inner)
        case let .Center(inner):
            return AnyView(inner)
        case let .Column(inner):
            return AnyView(inner)
        case let .Expand(inner):
            return AnyView(inner)
        case let .MarkdownView(inner):
            return AnyView(inner)
        case let .Spacer(inner):
            return AnyView(inner)
        case let .Text(inner):
            return AnyView(inner)
        default:
            return AnyView(SwiftUI.Text("unimplemented"))
        }
    }
}

enum MaggieAction {
    case CopyToClipboard(String)
    case LaunchUrl(URL)
    case Push(String)
    case Rpc(String)
    case Pop
    case Refresh
    
    func perform() {
        print("unimplemented")
    }
}

func maggieAction(_ action: String) throws -> MaggieAction {
    switch action {
    case "":
        throw MaggieError.deserializeError("action is empty")
    case "pop":
        return .Pop
    case "refresh":
        return .Refresh
    default:
        break
    }
    let parts = action.split(separator: ":", maxSplits: 1)
    if parts.count != 2 || parts[1].isEmpty {
        throw MaggieError.deserializeError("invalid action: \(action)")
    }
    let part1 = String(parts[1])
    switch parts[0] {
    case "copy-to-clipboard":
        return .CopyToClipboard(part1)
    case "launch-url":
        if let url = URL(string: part1) {
            return .LaunchUrl(url)
        } else {
            throw MaggieError.deserializeError("failed parsing url: \(part1)")
        }
    case "push":
        return .Push(part1)
    case "rpc":
        return .Rpc(part1)
    default:
        throw MaggieError.deserializeError("unknown action: \(action)")
    }
}

class JsonWidget: Codable {
    let typ: String
    let title: String?
    let text: String?
    let startText: String?
    let endText: String?
    let isDefault: Bool?
    let actions: [String]?
    let startActions: [String]?
    let endActions: [String]?
    let url: URL?
    let widget: JsonWidget?
    let widgets: [JsonWidget]?
    
    func convertActions() throws -> [MaggieAction] {
        return try (self.actions ?? []).map({ string in try maggieAction(string) })
    }
    
    func requireText() throws -> String {
        if let text = self.text {
            return text
        } else {
            throw MaggieError.deserializeError("missing 'text'")
        }
    }
    
    func requireTitle() throws -> String {
        if let title = self.title {
            return title
        } else {
            throw MaggieError.deserializeError("missing 'title'")
        }
    }
    
    func requireUrl() throws -> URL {
        if let url = self.url {
            return url
        } else {
            throw MaggieError.deserializeError("missing 'url'")
        }
    }
    
    func requireWidget() throws -> MaggieWidget {
        if let widget = self.widget {
            return try widget.toWidget()
        } else {
            throw MaggieError.deserializeError("missing 'widget'")
        }
    }
    
    func convertWidgets() throws -> [MaggieWidget] {
        return try (self.widgets ?? []).map { jsonWidget in try jsonWidget.toWidget() }
    }
    
    func requireWidgets() throws -> [MaggieWidget] {
        if self.widgets == nil {
            throw MaggieError.deserializeError("missing 'widgets'")
        }
        return try self.convertWidgets()
    }
    
    public func toWidget() throws -> MaggieWidget {
        switch self.typ {
        case MaggieAlert.TYP:
            return .Alert(MaggieAlert(
                title: try self.requireTitle(),
                widgets: try self.requireWidgets()))
        case MaggieButton.TYP:
            return .Button(MaggieButton(
                text: try self.requireText(),
                isDefault: self.isDefault ?? false,
                actions: try self.convertActions()))
        case MaggieCenter.TYP:
            return .Center(MaggieCenter(widget: try self.requireWidget()))
        case MaggieColumn.TYP:
            return .Column(MaggieColumn(widgets: try self.convertWidgets()))
        case MaggieErrorDetails.TYP:
            return .ErrorDetails(MaggieErrorDetails())
        case MaggieExpand.TYP:
            return .Expand(MaggieExpand(widget: try self.requireWidget()))
        case MaggieMarkdownView.TYP:
            return .MarkdownView(MaggieMarkdownView(url: try self.requireUrl()))
        case MaggieRow.TYP:
            return .Row(MaggieRow(widgets: try self.convertWidgets()))
        case MaggieScroll.TYP:
            return .Scroll(MaggieScroll(widget: try self.requireWidget()))
        case MaggieHorizontalScroll.TYP:
            return .HorizontalScroll(MaggieHorizontalScroll(widget: try self.requireWidget()))
        case MaggieSpacer.TYP:
            return .Spacer(MaggieSpacer())
        case MaggieText.TYP:
            return .Text(MaggieText(try self.requireText()))
        default:
            throw MaggieError.deserializeError("unexpected widget 'typ' value: \(self.typ)")
        }
    }
    
    public func toPane() throws -> MaggiePane {
        switch self.typ {
        case MaggieDrawer.TYP:
            return .Drawer(MaggieDrawer(
                widget: try self.requireWidget()))
        case MaggieModal.TYP:
            return .Modal(MaggieModal(
                widget: try self.requireWidget()))
        case MaggiePage.TYP:
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
            return .Page(MaggiePage(
                title: self.title,
                widget: try self.requireWidget()
                //start: start,
                //end: end
            ))
        default:
            throw MaggieError.deserializeError("unexpected stack-item 'typ' value: \(self.typ)")
        }
    }
}

enum MaggiePane: View {
    case Drawer(MaggieDrawer)
    case Modal(MaggieModal)
    case Page(MaggiePage)
    
    var body: AnyView {
        switch self {
        case let .Drawer(drawer):
            return AnyView(VStack(alignment: .center) { Text("Drawer unimplemented") })
        case let .Modal(modal):
            return AnyView(VStack(alignment: .center) { Text("Modal unimplemented") })
        case let .Page(page):
            return AnyView(page)
        }
    }
}

struct MaggieDrawer {
    static let TYP = "drawer"
    let widget: MaggieWidget
    init(widget: MaggieWidget) {
        self.widget = widget
    }
}

struct MaggieModal {
    static let TYP = "modal"
    let widget: MaggieWidget
    init(widget: MaggieWidget) {
        self.widget = widget
    }
}

struct MaggiePage: View {
    static let TYP = "page"
    let title: String?
    let widget: MaggieWidget
    
    init(title: String? = nil, widget: MaggieWidget) {
        self.title = title
        self.widget = widget
    }
    
    var body: some View {
        if let title = self.title {
            return AnyView(self.widget.navigationTitle(title))
        } else {
            return AnyView(self.widget)
        }
    }
}
