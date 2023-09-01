// swiftlint:disable file_length

import Foundation
import OSLog
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

enum ApplinHAlignment: CustomStringConvertible, Equatable, Hashable {
    case start
    case center
    case end

    func toAlignment() -> ApplinAlignment {
        switch self {
        case .start:
            return .center_start
        case .center:
            return .center
        case .end:
            return .center_end
        }
    }

    var description: String {
        switch self {
        case .start:
            return "start"
        case .center:
            return "center"
        case .end:
            return "end"
        }
    }
}

enum ApplinVAlignment: CustomStringConvertible, Equatable, Hashable {
    case top
    case center
    case bottom

    func toAlignment() -> ApplinAlignment {
        switch self {
        case .top:
            return .top_center
        case .center:
            return .center
        case .bottom:
            return .bottom_center
        }
    }

    var description: String {
        switch self {
        case .top:
            return "top"
        case .center:
            return "center"
        case .bottom:
            return "bottom"
        }
    }
}

enum ApplinAlignment: CustomStringConvertible, Equatable, Hashable {
    case top_start
    case top_center
    case top_end
    case center_start
    case center
    case center_end
    case bottom_start
    case bottom_center
    case bottom_end

    public func horizontal() -> ApplinHAlignment {
        switch self {
        case .top_start, .center_start, .bottom_start:
            return .start
        case .top_center, .center, .bottom_center:
            return .center
        case .top_end, .center_end, .bottom_end:
            return .end
        }
    }

    public func vertical() -> ApplinVAlignment {
        switch self {
        case .top_start, .top_center, .top_end:
            return .top
        case .center_start, .center, .center_end:
            return .center
        case .bottom_start, .bottom_center, .bottom_end:
            return .bottom
        }
    }

    var description: String {
        switch self {
        case .top_start:
            return "top_start"
        case .top_center:
            return "top_center"
        case .top_end:
            return "top_end"
        case .center_start:
            return "center_start"
        case .center:
            return "center"
        case .center_end:
            return "center_end"
        case .bottom_start:
            return "bottom_start"
        case .bottom_center:
            return "bottom_center"
        case .bottom_end:
            return "bottom_end"
        }
    }
}

class JsonItem: Codable {
    static let logger = Logger(subsystem: "Applin", category: "JsonItem")

    var typ: String
    var actions: [String]?
    var align: String?
    var allow: String?
    var aspect_ratio: Double?
    var auto_capitalize: String?
    var badge_text: String?
    var cache: Bool?
    var check_rpc: String?
    // TODO: Split this into separate horizontal and vertical fields.
    var disposition: String?
    var end: JsonItem?
    var error: String?
    var height: Float32?
    var id: String?
    var initial_bool: Bool?
    var initial_string: String?
    var is_cancel: Bool?
    var is_default: Bool?
    var is_destructive: Bool?
    var label: String?
    var max_chars: UInt32?
    var max_height: Float32?
    var max_lines: UInt32?
    var max_width: Float32?
    var min_chars: UInt32?
    var min_height: Float32?
    var min_width: Float32?
    var photo_url: String?
    var poll_seconds: UInt32?
    var row_groups: [[[JsonItem?]]]?
    var rpc: String?
    var spacing: Float32?
    var start: JsonItem?
    var stream: Bool?
    var sub_text: String?
    var text: String?
    var title: String?
    var url: String?
    var var_name: String?
    var widget: JsonItem?
    var widgets: [JsonItem]?
    var width: Float32?

    init(_ typ: String) {
        self.typ = typ
    }

    func optActions() throws -> [ActionSpec]? {
        try self.actions?.map({ string in try ActionSpec(string) })
    }

    func optAlign() -> ApplinAlignment? {
        switch self.align {
        case "top_start":
            return .top_start
        case "top_center":
            return .top_center
        case "top_end":
            return .top_end
        case "center_start":
            return .center_start
        case "center":
            return .center
        case "center_end":
            return .center_end
        case "bottom_start":
            return .bottom_start
        case "bottom_center":
            return .bottom_center
        case "bottom_end":
            return .bottom_end
        case nil:
            return nil
        default:
            Self.logger.warning("bad \(self.typ).align: \(String(describing: self.align))")
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
            Self.logger.warning("bad \(self.typ).align: \(String(describing: self.align))")
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
            Self.logger.warning("bad \(self.typ).align: \(String(describing: self.align))")
            return nil
        }
    }

    func setAlign(_ value: ApplinAlignment) {
        switch value {
        case .top_start:
            self.align = "top_start"
        case .top_center:
            self.align = "top_center"
        case .top_end:
            self.align = "top_end"
        case .center_start:
            self.align = "center_start"
        case .center:
            self.align = "center"
        case .center_end:
            self.align = "center_end"
        case .bottom_start:
            self.align = "bottom_start"
        case .bottom_center:
            self.align = "bottom_center"
        case .bottom_end:
            self.align = "bottom_end"
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
            Self.logger.warning("bad \(self.typ).allow: \(String(describing: self.allow))")
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
        guard let value = self.aspect_ratio else {
            throw ApplinError.appError("missing \(self.typ).aspect_ratio")
        }
        return value
    }

    func optAutoCapitalize() -> ApplinAutoCapitalize? {
        switch self.auto_capitalize {
        case "names":
            return .names
        case "sentences":
            return .sentences
        case nil:
            return nil
        default:
            Self.logger.warning("bad \(self.typ).auto_capitalize: \(String(describing: self.auto_capitalize))")
            return nil
        }
    }

    func setAutoCapitalize(_ value: ApplinAutoCapitalize?) {
        switch value {
        case .none:
            self.auto_capitalize = nil
        case .some(.names):
            self.auto_capitalize = "names"
        case .some(.sentences):
            self.auto_capitalize = "sentences"
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
            Self.logger.warning("bad \(self.typ).disposition: \(String(describing: self.disposition))")
            return nil
        }
    }

    func optEnd(_ config: ApplinConfig) throws -> Spec? {
        if let item = self.end {
            return try Spec(config, item)
        }
        return nil
    }

    func requireId() throws -> String {
        guard let value = self.id else {
            throw ApplinError.appError("missing \(self.typ).id")
        }
        return value
    }

    func requireLabel() throws -> String {
        guard let value = self.label else {
            throw ApplinError.appError("missing \(self.typ).label")
        }
        return value
    }

    func getMinMaxHeight() -> (Float32?, Float32?) {
        var optMin: Float32?
        if let min = self.min_height {
            if min == 0.0 {
            } else if min > 0.0 && min < .infinity {
                optMin = min
            } else {
                Self.logger.warning("bad \(self.typ).min_height: \(String(describing: min))")
            }
        }
        var optMax: Float32?
        if let max = self.max_height {
            if max == .infinity {
            } else if max >= (optMin ?? 0.0) && max < .infinity {
                optMax = max
            } else {
                Self.logger.warning("bad \(self.typ).max_height: \(String(describing: max))")
            }
        }
        return (optMin, optMax)
    }

    func getHeight() -> ApplinDimension {
        if let value = self.height {
            if self.min_height != nil {
                Self.logger.warning("\(self.typ).height found, ignoring min_height")
            }
            if self.max_height != nil {
                Self.logger.warning("\(self.typ).height found, ignoring max_height")
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
            self.min_height = optMin
            self.max_height = optMax
        }
    }

    func getMinMaxWidth() -> (Float32?, Float32?) {
        var optMin: Float32?
        if let min = self.min_width {
            if min == 0.0 {
            } else if min > 0.0 && min < .infinity {
                optMin = min
            } else {
                Self.logger.warning("bad \(self.typ).min_width: \(String(describing: min))")
            }
        }
        var optMax: Float32?
        if let max = self.max_width {
            if max == .infinity {
            } else if max >= (optMin ?? 0.0) && max < .infinity {
                optMax = max
            } else {
                Self.logger.warning("bad \(self.typ).max_width: \(String(describing: max))")
            }
        }
        return (optMin, optMax)
    }

    func getWidth() -> ApplinDimension {
        if let value = self.width {
            if self.min_width != nil {
                Self.logger.warning("\(self.typ).width found, ignoring min_width")
            }
            if self.max_width != nil {
                Self.logger.warning("\(self.typ).width found, ignoring max_width")
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
            self.min_width = optMin
            self.max_width = optMax
        }
    }

    func optPhotoUrl(_ config: ApplinConfig) throws -> URL? {
        if let value = self.photo_url {
            guard let url = URL(string: value, relativeTo: config.url) else {
                throw ApplinError.appError("bad \(self.typ).photo_url: \(value)")
            }
            return url
        }
        return nil
    }

    func optStart(_ config: ApplinConfig) throws -> Spec? {
        if let item = self.start {
            return try Spec(config, item)
        }
        return nil
    }

    func requireText() throws -> String {
        guard let value = self.text else {
            throw ApplinError.appError("missing \(self.typ).text")
        }
        return value
    }

    func requireTitle() throws -> String {
        guard let value = self.title else {
            throw ApplinError.appError("missing \(self.typ).title")
        }
        return value
    }

    func requireUrl(_ config: ApplinConfig) throws -> URL {
        guard let value = self.url else {
            throw ApplinError.appError("missing \(self.typ).url")
        }
        guard let url = URL(string: value, relativeTo: config.url) else {
            throw ApplinError.appError("bad \(self.typ).url: \(value)")
        }
        return url
    }

    func requireWidget(_ config: ApplinConfig) throws -> Spec {
        guard let value = self.widget else {
            throw ApplinError.appError("missing \(self.typ).widget")
        }
        return try Spec(config, value)
    }

    func optWidgets(_ config: ApplinConfig) throws -> [Spec]? {
        try self.widgets?.map({ value in try Spec(config, value) })
    }

    func requireWidgets(_ config: ApplinConfig, pageKey: String) throws -> [Spec] {
        guard let values = self.widgets else {
            throw ApplinError.appError("missing \(self.typ).widgets")
        }
        return try values.map({ value in try Spec(config, value) })
    }

    func requireVar() throws -> String {
        guard let value = self.var_name else {
            throw ApplinError.appError("missing \(self.typ).var")
        }
        return value
    }
}
