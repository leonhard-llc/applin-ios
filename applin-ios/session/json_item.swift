// swiftlint:disable file_length

import Foundation
import UIKit

enum ApplinAllow {
    case all
    case ascii
    case email
    case numbers
    case tel

    func keyboardType() -> UIKeyboardType {
        switch self {
        case .all:
            return .default
        case .ascii:
            return .default
        case .email:
            return .emailAddress
        case .numbers:
            return .numberPad
        case .tel:
            return .phonePad
        }
    }
}

enum ApplinAutoCapitalize {
    case names
    case sentences

    func textAutocapitalizationType() -> UITextAutocapitalizationType {
        switch self {
        case .names:
            return .words
        case .sentences:
            return .sentences
        }
    }
}

enum ApplinDimension: Equatable, Hashable {
    case value(Float32)
    case range(Float32?, Float32?)
}

enum ApplinDisposition: Equatable, Hashable {
    case fit
    case stretch
    case cover
}

enum ApplinHAlignment: Equatable, Hashable {
    case start
    case center
    case end

    func toAlignment() -> ApplinAlignment {
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

enum ApplinVAlignment: Equatable, Hashable {
    case top
    case center
    case bottom

    func toAlignment() -> ApplinAlignment {
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

enum ApplinAlignment: Equatable, Hashable {
    case topStart
    case topCenter
    case topEnd
    case centerStart
    case center
    case centerEnd
    case bottomStart
    case bottomCenter
    case bottomEnd

    public func horizontal() -> ApplinHAlignment {
        switch self {
        case .topStart, .centerStart, .bottomStart:
            return .start
        case .topCenter, .center, .bottomCenter:
            return .center
        case .topEnd, .centerEnd, .bottomEnd:
            return .end
        }
    }

    public func vertical() -> ApplinVAlignment {
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

class JsonItem: Codable {
    var typ: String
    var actions: [String]?
    var align: String?
    var allow: String?
    var aspectRatio: Double?
    var autoCapitalize: String?
    var badgeText: String?
    var cache: Bool?
    var checkRpc: String?
    // TODO: Split this into separate horizontal and vertical fields.
    var disposition: String?
    var end: JsonItem?
    var error: String?
    var height: Float32?
    var id: String?
    var initialBool: Bool?
    var initialString: String?
    var isCancel: Bool?
    var isDefault: Bool?
    var isDestructive: Bool?
    var label: String?
    var maxChars: UInt32?
    var maxHeight: Float32?
    var maxLines: UInt32?
    var maxWidth: Float32?
    var minChars: UInt32?
    var minHeight: Float32?
    var minWidth: Float32?
    var photoUrl: String?
    var pollSeconds: UInt32?
    var rowGroups: [[[JsonItem?]]]?
    var rpc: String?
    var spacing: Float32?
    var start: JsonItem?
    var stream: Bool?
    var subText: String?
    var text: String?
    var title: String?
    var url: String?
    var varName: String?
    var widget: JsonItem?
    var widgets: [JsonItem]?
    var width: Float32?

    enum CodingKeys: String, CodingKey {
        case typ
        case actions
        case align
        case allow
        case aspectRatio = "aspect-ratio"
        case autoCapitalize = "auto-capitalize"
        case badgeText = "badge-text"
        case cache
        case checkRpc = "check-rpc"
        case disposition
        case end
        case error
        case height
        case id
        case initialBool = "initial-bool"
        case initialString = "initial-string"
        case isCancel = "is-cancel"
        case isDefault = "is-default"
        case isDestructive = "is-destructive"
        case label
        case maxChars = "max-chars"
        case maxHeight = "max-height"
        case maxLines = "max-lines"
        case maxWidth = "max-width"
        case minChars = "min-chars"
        case minHeight = "min-height"
        case minWidth = "min-width"
        case photoUrl = "photo-url"
        case pollSeconds = "poll-seconds"
        case rowGroups = "row-groups"
        case rpc
        case spacing
        case start
        case stream
        case subText = "sub-text"
        case text
        case title
        case url
        case varName = "var"
        case widget
        case widgets
        case width
    }

    init(_ typ: String) {
        self.typ = typ
    }

    func optActions() throws -> [ActionSpec]? {
        try self.actions?.map({ string in try ActionSpec(string) })
    }

    func optAlign() -> ApplinAlignment? {
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

    func optAlign() -> ApplinHAlignment? {
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

    func optAlign() -> ApplinVAlignment? {
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

    func setAlign(_ value: ApplinAlignment) {
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

    func setAlign(_ value: ApplinHAlignment?) {
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

    func setAlign(_ value: ApplinVAlignment?) {
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

    func optAllow() -> ApplinAllow? {
        switch self.allow {
        case "all":
            return .all
        case "ascii":
            return .ascii
        case "email":
            return .email
        case "numbers":
            return .numbers
        case "tel":
            return .tel
        case nil:
            return nil
        default:
            print("bad \(self.typ).allow: \(self.allow ?? "")")
            return nil
        }
    }

    func setAllow(_ value: ApplinAllow?) {
        switch value {
        case .none:
            self.allow = nil
        case .some(.all):
            self.allow = "all"
        case .some(.ascii):
            self.allow = "ascii"
        case .some(.email):
            self.allow = "email"
        case .some(.numbers):
            self.allow = "numbers"
        case .some(.tel):
            self.allow = "tel"
        }
    }

    func requireAspectRatio() throws -> Double {
        if let value = self.aspectRatio {
            return value
        }
        throw ApplinError.appError("missing \(self.typ).aspect-ratio")
    }

    func optAutoCapitalize() -> ApplinAutoCapitalize? {
        switch self.autoCapitalize {
        case "names":
            return .names
        case "sentences":
            return .sentences
        case nil:
            return nil
        default:
            print("bad \(self.typ).auto-capitalize: \(self.autoCapitalize ?? "")")
            return nil
        }
    }

    func setAutoCapitalize(_ value: ApplinAutoCapitalize?) {
        switch value {
        case .none:
            self.autoCapitalize = nil
        case .some(.names):
            self.autoCapitalize = "names"
        case .some(.sentences):
            self.autoCapitalize = "sentences"
        }
    }

    func setDisposition(_ value: ApplinDisposition?) {
        switch value {
        case nil:
            break
        case .cover:
            self.disposition = "cover"
        case .fit:
            self.disposition = "fit"
        case .stretch:
            self.disposition = "stretch"
        }
    }

    func optDisposition() -> ApplinDisposition? {
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

    func optEnd(_ config: ApplinConfig, pageKey: String) throws -> Spec? {
        if let item = self.end {
            return try Spec(config, pageKey: pageKey, item)
        }
        return nil
    }

    func requireId() throws -> String {
        if let value = self.id {
            return value
        }
        throw ApplinError.appError("missing \(self.typ).id")
    }

    func requireLabel() throws -> String {
        if let value = self.label {
            return value
        }
        throw ApplinError.appError("missing \(self.typ).label")
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

    func getHeight() -> ApplinDimension {
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

    func setHeight(_ dimension: ApplinDimension) {
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

    func getWidth() -> ApplinDimension {
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

    func setWidth(_ dimension: ApplinDimension) {
        switch dimension {
        case let .value(value):
            self.width = value
        case let .range(optMin, optMax):
            self.minWidth = optMin
            self.maxWidth = optMax
        }
    }

    func optPhotoUrl(_ config: ApplinConfig) throws -> URL? {
        if let value = self.photoUrl {
            if let url = URL(string: value, relativeTo: config.url) {
                return url
            }
            throw ApplinError.appError("bad \(self.typ).photo-url: \(value)")
        }
        return nil
    }

    func optStart(_ config: ApplinConfig, pageKey: String) throws -> Spec? {
        if let item = self.start {
            return try Spec(config, pageKey: pageKey, item)
        }
        return nil
    }

    func requireText() throws -> String {
        if let value = self.text {
            return value
        }
        throw ApplinError.appError("missing \(self.typ).text")
    }

    func requireTitle() throws -> String {
        if let value = self.title {
            return value
        }
        throw ApplinError.appError("missing \(self.typ).title")
    }

    func requireUrl(_ config: ApplinConfig) throws -> URL {
        if let value = self.url {
            if let url = URL(string: value, relativeTo: config.url) {
                return url
            }
            throw ApplinError.appError("bad \(self.typ).url: \(value)")
        }
        throw ApplinError.appError("missing \(self.typ).url")
    }

    func requireWidget(_ config: ApplinConfig, pageKey: String) throws -> Spec {
        if let value = self.widget {
            return try Spec(config, pageKey: pageKey, value)
        }
        throw ApplinError.appError("missing \(self.typ).widget")
    }

    func optWidgets(_ config: ApplinConfig, pageKey: String) throws -> [Spec]? {
        try self.widgets?.map({ value in try Spec(config, pageKey: pageKey, value) })
    }

    func requireWidgets(_ config: ApplinConfig, pageKey: String) throws -> [Spec] {
        if let values = self.widgets {
            return try values.map({ value in try Spec(config, pageKey: pageKey, value) })
        }
        throw ApplinError.appError("missing \(self.typ).widgets")
    }

    func requireVar() throws -> String {
        if let value = self.varName {
            return value
        }
        throw ApplinError.appError("missing \(self.typ).var")
    }
}
