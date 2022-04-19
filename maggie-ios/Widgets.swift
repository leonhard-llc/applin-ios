import Foundation
import SwiftUI

struct MaggieBackButton: Equatable, View {
    static let TYP = "back-button"
    let actions: [MaggieAction]?
    
    init(_ actions: [MaggieAction]? = nil) {
        self.actions = actions
    }
    
    init(_ item: JsonItem, _ session: MaggieSession) throws {
        self.actions = try item.takeOptActions(session)
    }
    
    var body: some View {
        Button(
            // TODO: Use previous page's title.
            "Back",
            action: {
                for action in self.actions ?? [] {
                    action.perform()
                }
            }
        ).disabled(self.actions?.isEmpty ?? false)
    }
}

struct MaggieButton: Equatable, View {
    static let TYP = "button"
    let text: String
    let isDefault: Bool
    let isDestructive: Bool
    let actions: [MaggieAction]
    
    init(
        text: String,
        isDefault: Bool,
        isDestructive: Bool,
        _ actions: [MaggieAction]
    ) {
        self.text = text
        self.isDefault = isDefault
        self.isDestructive = isDestructive
        self.actions = actions
    }
    
    init(_ item: JsonItem, _ session: MaggieSession) throws {
        self.text = try item.takeText()
        self.isDefault = item.takeOptIsDefault() ?? false
        self.isDestructive = item.takeOptIsDestructive() ?? false
        self.actions = try item.takeOptActions(session) ?? []
    }
    
    var body: some View {
        Button(
            self.text,
            role: self.isDestructive ? .destructive : nil,
            action: {
                for action in self.actions {
                    action.perform()
                }
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

    init(
        _ widgets: [MaggieWidget],
        _ alignment: HorizontalAlignment,
        spacing: Double? = nil
    ) {
        self.widgets = widgets
        self.alignment = alignment
        self.spacing = CGFloat(spacing ?? 4.0)
    }
    
    init(_ item: JsonItem, _ session: MaggieSession) throws {
        self.widgets = try item.takeOptWidgets(session) ?? []
        self.alignment = item.takeOptHorizontalAlignment() ?? .leading
        self.spacing = item.takeOptSpacing() ?? 4.0
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
    static func == (lhs: MaggieErrorDetails, rhs: MaggieErrorDetails) -> Bool {
        true
    }
    
    @ObservedObject var session: MaggieSession
    static let TYP = "error-details"
    
    init(_ session: MaggieSession) {
        self.session = session
    }

    var body: some View {
        Text(session.error ?? "no error")
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
    
    init(
        _ widget: MaggieWidget,
        minWidth: CGFloat? = nil,
        maxWidth: CGFloat? = nil,
        minHeight: CGFloat? = nil,
        maxHeight: CGFloat? = nil,
        _ alignment: Alignment = .center
    ) {
        self.widget = widget
        self.minWidth = minWidth
        self.maxWidth = maxWidth
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.alignment = alignment
    }
    
    init(_ item: JsonItem, _ session: MaggieSession) throws {
        self.widget = try item.takeWidget(session)
        self.minWidth = item.takeOptMinWidth()
        self.maxWidth = item.takeOptMaxWidth()
        self.minHeight = item.takeOptMinHeight()
        self.maxHeight = item.takeOptMaxHeight()
        self.alignment = item.takeOptAlignment() ?? .center
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
    
    init(widget: MaggieWidget) {
        self.widget = widget
    }
    
    init(_ item: JsonItem, _ session: MaggieSession) throws {
        self.widget = try item.takeWidget(session)
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
    
    init(
        _ url: URL,
        width: CGFloat? = nil,
        height: CGFloat? = nil,
        disposition: MaggieDisposition = .fit
    ) {
        self.url = url
        self.width = width
        self.height = height
        self.disposition = disposition
    }
    
    init(_ item: JsonItem) throws {
        self.url = try item.takeUrl()
        self.width = try item.takeOptWidth()
        self.height = try item.takeOptHeight()
        self.disposition = item.takeOptDisposition() ?? .fit
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
    let spacing: CGFloat
    
    init(
        _ widgets: [MaggieWidget],
        _ alignment: VerticalAlignment,
        spacing: Double? = nil
    ) {
        self.widgets = widgets
        self.alignment = alignment
        self.spacing = CGFloat(spacing ?? 4.0)
    }
    
    init(_ item: JsonItem, _ session: MaggieSession) throws {
        self.widgets = try item.takeOptWidgets(session) ?? []
        self.alignment = item.takeOptVerticalAlignment() ?? .top
        self.spacing = item.takeOptSpacing() ?? 4.0
    }

    var body: some View {
        HStack(alignment: self.alignment, spacing: self.spacing) {
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
    
    init(widget: MaggieWidget) {
        self.widget = widget
    }
    
    init(_ item: JsonItem, _ session: MaggieSession) throws {
        self.widget = try item.takeWidget(session)
    }
    
    var body: some View {
        ScrollView(Axis.Set.vertical) {
            self.widget
        }
    }
}

struct MaggieSpacer: Equatable, View {
    static let TYP = "spacer"
    
    var body: AnyView {
        AnyView(Spacer()
                    .background(Color.teal)
        )
    }
}

struct MaggieTall: Equatable, View {
    static let TYP = "tall"
    let widget: MaggieWidget
    let minHeight: CGFloat
    let maxHeight: CGFloat
    let vAlignment: VerticalAlignment
    
    init(
        _ widget: MaggieWidget,
        minHeight: CGFloat,
        maxHeight: CGFloat,
        _ vAlignment: VerticalAlignment
    ) {
        self.widget = widget
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.vAlignment = vAlignment
    }
    
    init(_ item: JsonItem, _ session: MaggieSession) throws {
        self.widget = try item.takeWidget(session)
        self.minHeight = item.takeOptMinHeight() ?? 0.0
        self.maxHeight = item.takeOptMaxHeight() ?? .infinity
        self.vAlignment = item.takeOptVerticalAlignment() ?? .center
    }
    
    func alignment() -> Alignment {
        switch self.vAlignment {
        case .top:
            return .top
        case .center:
            return .center
        case .bottom:
            return .bottom
        default:
            preconditionFailure("unreachable")
        }
    }
    
    var body: some View {
        self.widget
            .frame(
                minHeight: self.minHeight,
                maxHeight: self.maxHeight,
                alignment: self.alignment()
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
    let minWidth: CGFloat
    let maxWidth: CGFloat
    let hAlignment: HorizontalAlignment
    
    init(
        _ widget: MaggieWidget,
        minWidth: CGFloat,
        maxWidth: CGFloat,
        _ alignment: HorizontalAlignment
    ) {
        self.widget = widget
        self.minWidth = minWidth
        self.maxWidth = maxWidth
        self.hAlignment = alignment
    }
    
    init(_ item: JsonItem, _ session: MaggieSession) throws {
        self.widget = try item.takeWidget(session)
        self.minWidth = item.takeOptMinWidth() ?? 0.0
        self.maxWidth = item.takeOptMaxWidth() ?? .infinity
        self.hAlignment = item.takeOptHorizontalAlignment() ?? .center
    }
    
    func alignment() -> Alignment {
        switch self.hAlignment {
        case .leading:
            return .leading
        case .center:
            return .center
        case .trailing:
            return .trailing
        default:
            preconditionFailure("unreachable")
        }
    }
    
    var body: some View {
        self.widget
            .frame(
                minWidth: self.minWidth,
                maxWidth: self.maxWidth,
                alignment: self.alignment()
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
        case let .Tall(inner):
            return AnyView(inner)
        case let .Text(inner):
            return AnyView(inner)
        case let .Wide(inner):
            return AnyView(inner)
        }
    }
}
