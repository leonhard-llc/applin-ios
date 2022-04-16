import Foundation

struct MaggieAlert {
    static let TYP = "alert"
    let title: String
    let widgets: [MaggieWidget]
    
    init(title: String, widgets: [MaggieWidget]) {
        self.title = title
        self.widgets = widgets
    }
}

struct MaggieButton {
    static let TYP = "button"
    let text: String
    let isDefault: Bool
    let actions: [MaggieAction]
    
    init(text: String, isDefault: Bool, actions: [MaggieAction]) {
        self.text = text
        self.isDefault = isDefault
        self.actions = actions
    }
}

struct MaggieCenter {
    static let TYP = "center"
    let widget: MaggieWidget
    
    init(widget: MaggieWidget) {
        self.widget = widget
    }
}

struct MaggieColumn {
    static let TYP = "column"
    let widgets: [MaggieWidget]
    
    init(widgets: [MaggieWidget]) {
        self.widgets = widgets
    }
}

struct MaggieErrorDetails {
    static let TYP = "error-details"
}

struct MaggieExpand {
    static let TYP = "expand"
    let widget: MaggieWidget
    
    init(widget: MaggieWidget) {
        self.widget = widget
    }
}

struct MaggieMarkdownView {
    static let TYP = "markdown-view"
    let url: URL
    
    init(url: URL) {
        self.url = url
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

struct MaggieText {
    static let TYP = "text"
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
}

struct MaggieTitleBar {
    static let TYP = "title-bar"
    let text: String
    let start: (String, [MaggieAction])?
    let end: (String, [MaggieAction])?
    
    init(text: String, start: (String, [MaggieAction])?, end: (String, [MaggieAction])?) {
        self.text = text
        self.start = start
        self.end = end
    }
}

enum MaggieWidget {
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
    case Text(MaggieText)
    case TitleBar(MaggieTitleBar)
}

func getTitleBarText(_ widget: MaggieWidget) -> String? {
    switch widget {
    case let .Alert(alert):
        return alert.title
    case .Button(_):
        return nil
    case let .Center(center):
        return getTitleBarText(center.widget)
    case let .Column(col):
        for widget in col.widgets {
            if let title = getTitleBarText(widget) {
                return title
            }
        }
        return nil
    case .ErrorDetails(_):
        return nil
    case let .Expand(expand):
        return getTitleBarText(expand.widget)
    case .MarkdownView(_):
        return nil
    case let .Row(row):
        for widget in row.widgets {
            if let title = getTitleBarText(widget) {
                return title
            }
        }
        return nil
    case let .Scroll(scroll):
        return getTitleBarText(scroll.widget)
    case let .HorizontalScroll(hScroll):
        return getTitleBarText(hScroll.widget)
    case .Text(_):
        return nil
    case let .TitleBar(bar):
        return bar.text
    }
}

enum MaggieAction {
    case CopyToClipboard(String)
    case LaunchUrl(URL)
    case Push(String)
    case Rpc(String)
    case Pop
    case Refresh
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
        case MaggieText.TYP:
            return .Text(MaggieText(try self.requireText()))
        case MaggieTitleBar.TYP:
            let start: (String, [MaggieAction])?
            switch (self.startText, self.startActions) {
            case let (.none, .some(actions)) where !actions.isEmpty:
                throw MaggieError.deserializeError("object has 'start-actions' without 'start-text'")
            case (.none, _):
                start = nil
            case (.some(""), _):
                throw MaggieError.deserializeError("empty 'start-text'")
            case let (.some(text), opt_actions):
                let actions = try (opt_actions ?? []).map({ s in try maggieAction(s) })
                start = (text, actions)
            }
            let end: (String, [MaggieAction])?
            switch (self.endText, self.endActions) {
            case let (.none, .some(actions)) where !actions.isEmpty:
                throw MaggieError.deserializeError("object has 'end-actions' without 'end-text'")
            case (.none, _):
                end = nil
            case (.some(""), _):
                throw MaggieError.deserializeError("empty 'end-text'")
            case let (.some(text), opt_actions):
                let actions = try (opt_actions ?? []).map({ s in try maggieAction(s) })
                end = (text, actions)
            }
            return .TitleBar(MaggieTitleBar(
                text: try self.requireText(),
                start: start,
                end: end
            ))
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
            return .Page(MaggiePage(
                widget: try self.requireWidget()))
        default:
            throw MaggieError.deserializeError("unexpected stack-item 'typ' value: \(self.typ)")
        }
    }}

enum MaggiePane {
    case Drawer(MaggieDrawer)
    case Modal(MaggieModal)
    case Page(MaggiePage)
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

struct MaggiePage {
    static let TYP = "page"
    let widget: MaggieWidget
    init(widget: MaggieWidget) {
        self.widget = widget
    }
}
