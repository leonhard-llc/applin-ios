import Foundation
import SwiftUI

struct MaggieBackButton: Equatable, View {
    static func == (lhs: MaggieBackButton, rhs: MaggieBackButton) -> Bool {
        return lhs.actions == rhs.actions
    }
    
    static let TYP = "back-button"
    let actions: [MaggieAction]
    weak var session: MaggieSession?
    
    init(_ item: JsonItem, _ session: MaggieSession) throws {
        self.actions = try item.takeOptActions() ?? []
        self.session = session
    }
    
    func toJsonItem() -> JsonItem {
        let item = JsonItem(MaggieBackButton.TYP)
        item.actions = self.actions.map({action in action.toString()})
        return item
    }
    
    var body: some View {
        Button(
            "Back",
            action: { self.session?.doActions(self.actions) }
        ).disabled(self.actions.isEmpty)
    }
}

struct MaggieButton: Equatable, View {
    static func == (lhs: MaggieButton, rhs: MaggieButton) -> Bool {
        return lhs.text == rhs.text
        && lhs.isDefault == rhs.isDefault
        && lhs.isDestructive == rhs.isDestructive
        && lhs.actions == rhs.actions
    }
    
    static let TYP = "button"
    let text: String
    let isDefault: Bool
    let isDestructive: Bool
    let actions: [MaggieAction]
    weak var session: MaggieSession?
    
    init(_ item: JsonItem, _ session: MaggieSession) throws {
        self.text = try item.takeText()
        self.isDefault = item.takeOptIsDefault() ?? false
        self.isDestructive = item.takeOptIsDestructive() ?? false
        self.actions = try item.takeOptActions() ?? []
        self.session = session
    }
    
    func toJsonItem() -> JsonItem {
        let item = JsonItem(MaggieButton.TYP)
        item.text = self.text
        item.isDefault = self.isDefault
        item.isDestructive = self.isDestructive
        item.actions = self.actions.map({action in action.toString()})
        return item
    }
    
    var body: some View {
        Button(
            self.text,
            role: self.isDestructive ? .destructive : nil,
            action: { () in
                print("Button(\(self.text)) action")
                self.session?.doActions(self.actions)
            }
        )
            .disabled(self.actions.isEmpty)
            .buttonStyle(.bordered)
    }
}

struct MaggieColumn: Equatable, View {
    static let TYP = "column"
    let widgets: [MaggieWidget]
    let alignment: HorizontalAlignment
    let spacing: CGFloat
    
    init(_ item: JsonItem, _ session: MaggieSession) throws {
        self.widgets = try item.takeOptWidgets(session) ?? []
        self.alignment = item.takeOptHorizontalAlignment() ?? .leading
        self.spacing = item.takeOptSpacing() ?? 4.0
    }
    
    func toJsonItem() -> JsonItem {
        let item = JsonItem(MaggieColumn.TYP)
        item.widgets = self.widgets.map({widgets in widgets.toJsonItem()})
        item.setHorizontalAlignment(self.alignment)
        return item
    }
    
    var body: some View {
        VStack(alignment: self.alignment, spacing: self.spacing) {
            ForEach(0..<self.widgets.count) {
                n in self.widgets[n]
            }
        }
        .border(Color.green)
        .padding(1.0)
    }
}

struct MaggieEmpty: Equatable, View {
    static let TYP = "empty"
    
    var body: EmptyView {
        EmptyView()
    }
}

struct MaggieErrorDetails: Equatable, View {
    static let TYP = "error-details"
    let error: String
    
    init(_ session: MaggieSession) {
        self.error = session.error ?? "no error"
    }
    
    var body: some View {
        Text(self.error)
    }
}

struct MaggieExpand: Equatable, View {
    static let TYP = "expand"
    let widget: MaggieWidget
    let minWidth: CGFloat?
    let maxWidth: CGFloat?
    let minHeight: CGFloat?
    let maxHeight: CGFloat?
    let alignment: Alignment
    
    init(_ widget: MaggieWidget) {
        self.widget = widget
        self.minWidth = nil
        self.maxWidth = nil
        self.minHeight = nil
        self.maxHeight = nil
        self.alignment = .center
    }
    
    init(_ item: JsonItem, _ session: MaggieSession) throws {
        self.widget = try item.takeWidget(session)
        self.minWidth = item.takeOptMinWidth()
        self.maxWidth = item.takeOptMaxWidth()
        self.minHeight = item.takeOptMinHeight()
        self.maxHeight = item.takeOptMaxHeight()
        self.alignment = item.takeOptAlignment() ?? .center
    }
    
    func toJsonItem() -> JsonItem {
        let item = JsonItem(MaggieExpand.TYP)
        item.widget = self.widget.toJsonItem()
        item.minWidth = self.minWidth != nil ? Double(self.minWidth!) : nil
        item.maxWidth = self.maxWidth != nil ? Double(self.maxWidth!) : nil
        item.minHeight = self.minHeight != nil ? Double(self.minHeight!) : nil
        item.maxHeight = self.maxHeight != nil ? Double(self.maxHeight!) : nil
        item.setAlignment(self.alignment)
        return item
    }
    
    var body: some View {
        self.widget
            .frame(
                minWidth: self.minWidth,
                maxWidth: self.maxWidth ?? .infinity,
                minHeight: self.minHeight,
                maxHeight: self.maxHeight ?? .infinity,
                alignment: self.alignment
            )
            .border(Color.red)
            .padding(1.0)
    }
}

struct MaggieHorizontalScroll: Equatable, View {
    static let TYP = "horizontal-scroll"
    let widget: MaggieWidget
    
    init(_ item: JsonItem, _ session: MaggieSession) throws {
        self.widget = try item.takeWidget(session)
    }
    
    func toJsonItem() -> JsonItem {
        let item = JsonItem(MaggieHorizontalScroll.TYP)
        item.widget = self.widget.toJsonItem()
        return item
    }
    
    var body: some View {
        ScrollView(Axis.Set.horizontal) {
            self.widget
        }
    }
}

struct MaggieImage: Equatable, View {
    static let TYP = "image"
    let url: URL
    let width: CGFloat?
    let height: CGFloat?
    let disposition: MaggieDisposition
    
    init(_ item: JsonItem) throws {
        self.url = try item.takeUrl()
        self.width = try item.takeOptWidth()
        self.height = try item.takeOptHeight()
        self.disposition = item.takeOptDisposition() ?? .fit
    }
    
    func toJsonItem() -> JsonItem {
        let item = JsonItem(MaggieImage.TYP)
        item.url = self.url
        item.width = self.width != nil ? Double(self.width!) : nil
        item.height = self.height != nil ? Double(self.height!) : nil
        item.setDisposition(self.disposition)
        return item
    }
    
    var body: some View {
        switch self.disposition {
        case .cover:
            return AnyView(
                AsyncImage(url: self.url) { image in
                    image.resizable()
                } placeholder: {
                    ProgressView()
                }
                    .scaledToFill()
                    .frame(width: self.width, height: self.height)
                    .clipped()
                    .border(Color.black)
                    .padding(1.0))
        case .fit:
            return AnyView(
                AsyncImage(url: self.url) { image in
                    image
                        .resizable()
                } placeholder: {
                    ProgressView()
                }
                    .scaledToFit()
                    .frame(width: self.width, height: self.height)
                    .border(Color.black)
                    .padding(1.0))
        case .stretch:
            return AnyView(
                AsyncImage(url: self.url) { image in
                    image.resizable()
                } placeholder: {
                    ProgressView()
                }
                    .frame(width: self.width, height: self.height)
                    .border(Color.black)
                    .padding(1.0))
        }
    }
}

struct MaggieRow: Equatable, View {
    static let TYP = "row"
    let widgets: [MaggieWidget]
    let alignment: VerticalAlignment
    let spacing: CGFloat?
    
    init(_ item: JsonItem, _ session: MaggieSession) throws {
        self.widgets = try item.takeOptWidgets(session) ?? []
        self.alignment = item.takeOptVerticalAlignment() ?? .top
        self.spacing = item.takeOptSpacing()
    }
    
    func toJsonItem() -> JsonItem {
        let item = JsonItem(MaggieRow.TYP)
        item.widgets = self.widgets.map({widgets in widgets.toJsonItem()})
        item.setVerticalAlignment(self.alignment)
        item.spacing = self.spacing?.toDouble()
        return item
    }
    
    var body: some View {
        HStack(alignment: self.alignment, spacing: self.spacing ?? 4.0) {
            ForEach(0..<self.widgets.count) {
                n in self.widgets[n]
            }
        }
        .border(Color.blue)
        .padding(1.0)
    }
}

struct MaggieScroll: Equatable, View {
    static let TYP = "scroll"
    let widget: MaggieWidget
    
    init(_ item: JsonItem, _ session: MaggieSession) throws {
        self.widget = try item.takeWidget(session)
    }
    
    func toJsonItem() -> JsonItem {
        let item = JsonItem(MaggieScroll.TYP)
        item.widget = self.widget.toJsonItem()
        return item
    }
    
    var body: some View {
        ScrollView(Axis.Set.vertical) {
            self.widget
        }
    }
}

struct MaggieSpacer: Equatable, View {
    static let TYP = "spacer"
    
    var body: some View {
        Spacer()
            .background(Color.teal)
    }
}

struct MaggieSpinner: Equatable, View {
    static let TYP = "spinner"
    
    var body: some View {
        ProgressView()
    }
}

struct MaggieTall: Equatable, View {
    static let TYP = "tall"
    let widget: MaggieWidget
    let minHeight: CGFloat?
    let maxHeight: CGFloat?
    let alignment: VerticalAlignment?
    
    init(_ item: JsonItem, _ session: MaggieSession) throws {
        self.widget = try item.takeWidget(session)
        self.minHeight = item.takeOptMinHeight()
        self.maxHeight = item.takeOptMaxHeight()
        self.alignment = item.takeOptVerticalAlignment()
    }
    
    func toJsonItem() -> JsonItem {
        let item = JsonItem(MaggieExpand.TYP)
        item.widget = self.widget.toJsonItem()
        item.minHeight = self.minHeight?.toDouble()
        item.maxHeight = self.maxHeight?.toDouble()
        item.setVerticalAlignment(self.alignment)
        return item
    }
    
    var body: some View {
        self.widget
            .frame(
                minHeight: self.minHeight ?? 0.0,
                maxHeight: self.maxHeight ?? .infinity,
                alignment: self.alignment?.toAlignment() ?? .center
            )
            .border(Color.brown)
            .padding(1.0)
    }
}

struct MaggieText: Equatable, View {
    static let TYP = "text"
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    init(_ item: JsonItem) throws {
        self.text = try item.takeText()
    }
    
    func toJsonItem() -> JsonItem {
        let item = JsonItem(MaggieText.TYP)
        item.text = self.text
        return item
    }
    
    var body: some View {
        Text(self.text)
            .padding(1.0)
            .border(Color.yellow)
            .padding(1.0)
    }
}

struct MaggieWide: Equatable, View {
    static let TYP = "wide"
    let widget: MaggieWidget
    let minWidth: CGFloat?
    let maxWidth: CGFloat?
    let alignment: HorizontalAlignment?
    
    init(_ item: JsonItem, _ session: MaggieSession) throws {
        self.widget = try item.takeWidget(session)
        self.minWidth = item.takeOptMinWidth()
        self.maxWidth = item.takeOptMaxWidth()
        self.alignment = item.takeOptHorizontalAlignment()
    }
    
    func toJsonItem() -> JsonItem {
        let item = JsonItem(MaggieWide.TYP)
        item.widget = self.widget.toJsonItem()
        item.minWidth = self.minWidth?.toDouble()
        item.maxWidth = self.maxWidth?.toDouble()
        item.setHorizontalAlignment(self.alignment)
        return item
    }
    
    var body: some View {
        self.widget
            .frame(
                minWidth: self.minWidth ?? 0.0,
                maxWidth: self.maxWidth ?? .infinity,
                alignment: self.alignment?.toAlignment() ?? .center
            )
            .border(Color.mint)
            .padding(1.0)
    }
}

enum MaggieWidget: Equatable, View {
    case BackButton(MaggieBackButton)
    case Button(MaggieButton)
    indirect case Column(MaggieColumn)
    case Empty(MaggieEmpty)
    case ErrorDetails(MaggieErrorDetails)
    indirect case Expand(MaggieExpand)
    indirect case HorizontalScroll(MaggieHorizontalScroll)
    case Image(MaggieImage)
    indirect case Row(MaggieRow)
    indirect case Scroll(MaggieScroll)
    indirect case Spacer(MaggieSpacer)
    indirect case Spinner(MaggieSpinner)
    indirect case Tall(MaggieTall)
    case Text(MaggieText)
    indirect case Wide(MaggieWide)
    
    init(_ item: JsonItem, _ session: MaggieSession) throws {
        switch item.typ {
        case MaggieBackButton.TYP:
            self = try .BackButton(MaggieBackButton(item, session))
        case MaggieButton.TYP:
            self = try .Button(MaggieButton(item, session))
        case MaggieColumn.TYP:
            self = try .Column(MaggieColumn(item, session))
        case MaggieEmpty.TYP:
            self = .Empty(MaggieEmpty())
        case MaggieErrorDetails.TYP:
            self = .ErrorDetails(MaggieErrorDetails(session))
        case MaggieExpand.TYP:
            self = try .Expand(MaggieExpand(item, session))
        case MaggieHorizontalScroll.TYP:
            self = try .HorizontalScroll(MaggieHorizontalScroll(item, session))
        case MaggieImage.TYP:
            self = try .Image(MaggieImage(item))
        case MaggieRow.TYP:
            self = try .Row(MaggieRow(item, session))
        case MaggieScroll.TYP:
            self = try .Scroll(MaggieScroll(item, session))
        case MaggieSpacer.TYP:
            self = .Spacer(MaggieSpacer())
        case MaggieSpinner.TYP:
            self = .Spinner(MaggieSpinner())
        case MaggieTall.TYP:
            self = try .Tall(MaggieTall(item, session))
        case MaggieText.TYP:
            self = try .Text(MaggieText(item))
        case MaggieWide.TYP:
            self = try .Wide(MaggieWide(item, session))
        default:
            throw MaggieError.deserializeError("unexpected widget 'typ' value: \(item.typ)")
        }
    }
    
    func toJsonItem() -> JsonItem {
        switch self {
        case let .BackButton(widget):
            return widget.toJsonItem()
        case let .Button(widget):
            return widget.toJsonItem()
        case let .Column(widget):
            return widget.toJsonItem()
        case .Empty(_):
            return JsonItem(MaggieEmpty.TYP)
        case .ErrorDetails(_):
            return JsonItem(MaggieErrorDetails.TYP)
        case let .Expand(widget):
            return widget.toJsonItem()
        case let .HorizontalScroll(widget):
            return widget.toJsonItem()
        case let .Image(widget):
            return widget.toJsonItem()
        case let .Row(widget):
            return widget.toJsonItem()
        case let .Scroll(widget):
            return widget.toJsonItem()
        case .Spacer(_):
            return JsonItem(MaggieSpacer.TYP)
        case .Spinner(_):
            return JsonItem(MaggieSpinner.TYP)
        case let .Tall(widget):
            return widget.toJsonItem()
        case let .Text(widget):
            return widget.toJsonItem()
        case let .Wide(widget):
            return widget.toJsonItem()
        }
    }
    
    var body: some View {
        switch self {
        case let .BackButton(inner):
            return AnyView(inner)
        case let .Button(inner):
            return AnyView(inner)
        case let .Column(inner):
            return AnyView(inner)
        case let .Empty(inner):
            return AnyView(inner)
        case let .ErrorDetails(inner):
            return AnyView(inner)
        case let .Expand(inner):
            return AnyView(inner)
        case let .HorizontalScroll(inner):
            return AnyView(inner)
        case let .Image(inner):
            return AnyView(inner)
        case let .Row(inner):
            return AnyView(inner)
        case let .Scroll(inner):
            return AnyView(inner)
        case let .Spacer(inner):
            return AnyView(inner)
        case let .Spinner(inner):
            return AnyView(inner)
        case let .Tall(inner):
            return AnyView(inner)
        case let .Text(inner):
            return AnyView(inner)
        case let .Wide(inner):
            return AnyView(inner)
        }
    }
}

