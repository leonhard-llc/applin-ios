// swiftlint:disable file_length
import Foundation

enum MaggieDimension: Equatable, Hashable {
    case value(Float32)
    case range(Float32?, Float32?)
}

enum MaggieDisposition: Equatable, Hashable {
    case fit
    case stretch
    case cover
}

enum MaggieHAlignment: Equatable, Hashable {
    case start
    case center
    case end

    func toAlignment() -> MaggieAlignment {
        switch self {
        case .start:
            return .centerStart
        case .center:
            return .center
        case .end:
            return .centerEnd
        }
    }
}

enum MaggieVAlignment: Equatable, Hashable {
    case top
    case center
    case bottom

    func toAlignment() -> MaggieAlignment {
        switch self {
        case .top:
            return .topCenter
        case .center:
            return .center
        case .bottom:
            return .bottomCenter
        }
    }
}

enum MaggieAlignment: Equatable, Hashable {
    case topStart
    case topCenter
    case topEnd
    case centerStart
    case center
    case centerEnd
    case bottomStart
    case bottomCenter
    case bottomEnd

    public func horizontal() -> MaggieHAlignment {
        switch self {
        case .topStart, .centerStart, .bottomStart:
            return .start
        case .topCenter, .center, .bottomCenter:
            return .center
        case .topEnd, .centerEnd, .bottomEnd:
            return .end
        }
    }

    public func vertical() -> MaggieVAlignment {
        switch self {
        case .topStart, .topCenter, .topEnd:
            return .top
        case .centerStart, .center, .centerEnd:
            return .center
        case .bottomStart, .bottomCenter, .bottomEnd:
            return .bottom
        }
    }
}

// swiftlint:disable type_body_length
class JsonItem: Codable {
    var typ: String
    var actions: [String]?
    var align: String?
    var cache: Bool?
    // TODO: Split this into separate horizontal and vertical fields.
    var disposition: String?
    var end: JsonItem?
    var height: Float32?
    var isCancel: Bool?
    var isDefault: Bool?
    var isDestructive: Bool?
    var maxHeight: Float32?
    var maxWidth: Float32?
    var minHeight: Float32?
    var minWidth: Float32?
    var photoUrl: String?
    var spacing: Float32?
    var start: JsonItem?
    var text: String?
    var title: String?
    var url: String?
    var widget: JsonItem?
    var widgets: [JsonItem]?
    var width: Float32?

    enum CodingKeys: String, CodingKey {
        case typ
        case actions
        case align
        case cache
        case disposition
        case end
        case height
        case isCancel = "is-cancel"
        case isDefault = "is-default"
        case isDestructive = "is-destructive"
        case maxHeight = "max-height"
        case maxWidth = "max-width"
        case minHeight = "min-height"
        case minWidth = "min-width"
        case photoUrl = "photo-url"
        case spacing
        case start
        case text
        case title
        case url
        case widget
        case widgets
        case width
    }

    init(_ typ: String) {
        self.typ = typ
    }

    func optActions() throws -> [MaggieAction]? {
        try self.actions?.map({ string in try MaggieAction(string) })
    }

    // swiftlint:disable cyclomatic_complexity
    func optAlign() -> MaggieAlignment? {
        switch self.align {
        case "top-start":
            return .topStart
        case "top-center":
            return .topCenter
        case "top-end":
            return .topEnd
        case "center-start":
            return .centerStart
        case "center":
            return .center
        case "center-end":
            return .centerEnd
        case "bottom-start":
            return .bottomStart
        case "bottom-center":
            return .bottomCenter
        case "bottom-end":
            return .bottomEnd
        case nil:
            return nil
        default:
            print("bad \(self.typ).align: \(self.align ?? "")")
            return nil
        }
    }

    func optAlign() -> MaggieHAlignment? {
        switch self.align {
        case "start":
            return .start
        case "center":
            return .center
        case "end":
            return .end
        case nil:
            return nil
        default:
            print("bad \(self.typ).align: \(self.align ?? "")")
            return nil
        }
    }

    func optAlign() -> MaggieVAlignment? {
        switch self.align {
        case "top":
            return .top
        case "center":
            return .center
        case "bottom":
            return .bottom
        case nil:
            return nil
        default:
            print("bad \(self.typ).align: \(self.align ?? "")")
            return nil
        }
    }

    func setAlign(_ value: MaggieAlignment) {
        switch value {
        case .topStart:
            self.align = "top-start"
        case .topCenter:
            self.align = "top-center"
        case .topEnd:
            self.align = "top-end"
        case .centerStart:
            self.align = "center-start"
        case .center:
            self.align = "center"
        case .centerEnd:
            self.align = "center-end"
        case .bottomStart:
            self.align = "bottom-start"
        case .bottomCenter:
            self.align = "bottom-center"
        case .bottomEnd:
            self.align = "bottom-end"
        }
    }

    func setAlign(_ value: MaggieHAlignment?) {
        switch value {
        case .none:
            self.align = nil
        case .some(.start):
            self.align = "start"
        case .some(.center):
            self.align = "center"
        case .some(.end):
            self.align = "end"
        }
    }

    func setAlign(_ value: MaggieVAlignment?) {
        switch value {
        case .none:
            self.align = nil
        case .some(.top):
            self.align = "top"
        case .some(.center):
            self.align = "center"
        case .some(.bottom):
            self.align = "bottom"
        }
    }

    func setDisposition(_ value: MaggieDisposition) {
        switch value {
        case .cover:
            self.disposition = "cover"
        case .fit:
            self.disposition = "fit"
        case .stretch:
            self.disposition = "stretch"
        }
    }

    func optDisposition() -> MaggieDisposition? {
        switch self.disposition {
        case "cover":
            return .cover
        case "fit":
            return .fit
        case "stretch":
            return .stretch
        case nil:
            return nil
        default:
            print("bad \(self.typ).disposition: \(self.disposition ?? "")")
            return nil
        }
    }

    func optEnd(_ session: MaggieSession) throws -> MaggieWidget? {
        if let value = self.end {
            return try MaggieWidget(value, session)
        }
        return nil
    }

    func getMinMaxHeight() -> (Float32?, Float32?) {
        var optMin: Float32?
        if let min = self.minHeight {
            if min == 0.0 {
            } else if min > 0.0 && min < .infinity {
                optMin = min
            } else {
                print("bad \(self.typ).min-height: \(min)")
            }
        }
        var optMax: Float32?
        if let max = self.maxHeight {
            if max == .infinity {
            } else if max >= (optMin ?? 0.0) && max < .infinity {
                optMax = max
            } else {
                print("bad \(self.typ).max-height: \(max)")
            }
        }
        return (optMin, optMax)
    }

    func getHeight() -> MaggieDimension {
        if let value = self.height {
            if self.minHeight != nil {
                print("\(self.typ).height found, ignoring min-height")
            }
            if self.maxHeight != nil {
                print("\(self.typ).height found, ignoring max-height")
            }
            return .value(value)
        }
        let (optMin, optMax) = self.getMinMaxHeight()
        return .range(optMin, optMax)
    }

    func setHeight(_ dimension: MaggieDimension) {
        switch dimension {
        case let .value(value):
            self.height = value
        case let .range(optMin, optMax):
            self.minHeight = optMin
            self.maxHeight = optMax
        }
    }

    func getMinMaxWidth() -> (Float32?, Float32?) {
        var optMin: Float32?
        if let min = self.minWidth {
            if min == 0.0 {
            } else if min > 0.0 && min < .infinity {
                optMin = min
            } else {
                print("bad \(self.typ).min-width: \(min)")
            }
        }
        var optMax: Float32?
        if let max = self.maxWidth {
            if max == .infinity {
            } else if max >= (optMin ?? 0.0) && max < .infinity {
                optMax = max
            } else {
                print("bad \(self.typ).max-width: \(max)")
            }
        }
        return (optMin, optMax)
    }

    func getWidth() -> MaggieDimension {
        if let value = self.width {
            if self.minWidth != nil {
                print("\(self.typ).width found, ignoring min-width")
            }
            if self.maxWidth != nil {
                print("\(self.typ).width found, ignoring max-width")
            }
            return .value(value)
        }
        let (optMin, optMax) = self.getMinMaxWidth()
        return .range(optMin, optMax)
    }

    func setWidth(_ dimension: MaggieDimension) {
        switch dimension {
        case let .value(value):
            self.width = value
        case let .range(optMin, optMax):
            self.minWidth = optMin
            self.maxWidth = optMax
        }
    }

    func optPhotoUrl(_ session: MaggieSession?) throws -> URL? {
        if let value = self.photoUrl {
            if let url = URL(string: value, relativeTo: session?.url) {
                return url
            }
            throw MaggieError.deserializeError("bad \(self.typ).photo-url: \(value)")
        }
        return nil
    }

    func optStart(_ session: MaggieSession) throws -> MaggieWidget? {
        if let value = self.start {
            return try MaggieWidget(value, session)
        }
        return nil
    }

    func requireText() throws -> String {
        if let value = self.text {
            return value
        }
        throw MaggieError.deserializeError("missing \(self.typ).text")
    }

    func requireTitle() throws -> String {
        if let value = self.title {
            return value
        }
        throw MaggieError.deserializeError("missing \(self.typ).title")
    }

    func requireUrl(_ session: MaggieSession?) throws -> URL {
        if let value = self.url {
            if let url = URL(string: value, relativeTo: session?.url) {
                return url
            }
            throw MaggieError.deserializeError("bad \(self.typ).url: \(value)")
        }
        throw MaggieError.deserializeError("missing \(self.typ).url")
    }

    func requireWidget(_ session: MaggieSession) throws -> MaggieWidget {
        if let value = self.widget {
            return try MaggieWidget(value, session)
        }
        throw MaggieError.deserializeError("missing \(self.typ).widget")
    }

    func optWidgets(_ session: MaggieSession) throws -> [MaggieWidget]? {
        try self.widgets?.map({ value in try MaggieWidget(value, session) })
    }

    func requireWidgets(_ session: MaggieSession) throws -> [MaggieWidget] {
        if let values = self.widgets {
            return try values.map({ value in try MaggieWidget(value, session) })
        }
        throw MaggieError.deserializeError("missing \(self.typ).widgets")
    }
}
