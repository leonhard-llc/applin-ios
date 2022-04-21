import Foundation
import SwiftUI

enum MaggieDisposition {
    case fit
    case stretch
    case cover
}

class JsonItem: Codable {
    var typ: String
    var actions: [String]?
    var alignment: String?
    var cache: Bool?
    var disposition: String?
    var end: JsonItem?
    var height: Double?
    var isDefault: Bool?
    var isDestructive: Bool?
    var maxHeight: Double?
    var maxWidth: Double?
    var minHeight: Double?
    var minWidth: Double?
    var spacing: Double?
    var start: JsonItem?
    var text: String?
    var title: String?
    var url: URL?
    var widget: JsonItem?
    var widgets: [JsonItem]?
    var width: Double?
    
    enum CodingKeys: String, CodingKey {
        case typ
        case actions
        case alignment
        case cache
        case disposition
        case end
        case height
        case isDefault = "is-default"
        case isDestructive = "is-destructive"
        case maxHeight = "max-height"
        case maxWidth = "max-width"
        case minHeight = "min-height"
        case minWidth = "min-width"
        case spacing
        case start
        case text
        case title
        case url
        case widget
        case widgets
        case width
    }

    func takeOptActions() throws -> [MaggieAction]? {
        if let values = self.actions {
            self.actions = nil
            return try values.map({ string in try MaggieAction(string) })
        }
        return nil
    }
        
    func takeOptAlignment() -> Alignment? {
        if let value = self.alignment {
            self.alignment = nil
            switch value {
            case "top-start":
                return .topLeading
            case "top-center":
                return .top
            case "top-end":
                return .topTrailing
            case "center-start":
                return .leading
            case "center":
                return .center
            case "center-end":
                return .trailing
            case "bottom-start":
                return .bottomLeading
            case "bottom-center":
                return .bottom
            case "bottom-end":
                return .bottomTrailing
            default:
                print("WARNING: widget '\(self.typ)' has unknown 'alignment' value: \(value)")
                return nil
            }
        }
        return nil
    }
    
    func takeOptHorizontalAlignment() -> HorizontalAlignment? {
        if let value = self.alignment {
            self.alignment = nil
            switch value {
            case "start":
                return .leading
            case "center":
                return .center
            case "end":
                return .trailing
            default:
                print("WARNING: widget '\(self.typ)' has unknown 'alignment' value: \(value)")
                return nil
            }
        }
        return nil
    }
    
    func takeOptVerticalAlignment() -> VerticalAlignment? {
        if let value = self.alignment {
            self.alignment = nil
            switch value {
            case "top":
                return .top
            case "center":
                return .center
            case "bottom":
                return .bottom
            default:
                print("WARNING: widget '\(self.typ)' has unknown 'alignment' value: \(value)")
                return nil
            }
        }
        return nil
    }
    
    func takeOptCache() -> Bool? {
        if let value = self.cache {
            self.cache = nil
            return value
        }
        return nil
    }

    func takeOptDisposition() -> MaggieDisposition? {
        if let value = self.disposition {
            self.disposition = nil
            switch value {
            case "cover":
                return .cover
            case "fit":
                return .fit
            case "stretch":
                return .stretch
            default:
                print("WARNING: widget '\(self.typ)' has unknown 'disposition' value: \(value)")
                return nil
            }
        }
        return nil
    }

    func takeOptEnd(_ session: MaggieSession) throws -> MaggieWidget? {
        if let value = self.end {
            self.end = nil
            return try MaggieWidget(value, session)
        }
        return nil
    }
    
    func takeOptHeight() throws -> CGFloat? {
        if let value = self.height {
            self.height = nil
            return CGFloat(value)
        }
        return nil
    }

    func takeHeight() throws -> CGFloat {
        if let value = self.height {
            self.height = nil
            return CGFloat(value)
        }
        throw MaggieError.deserializeError("missing 'height'")
    }

    func takeOptIsDefault() -> Bool? {
        if let value = self.isDefault {
            self.isDefault = nil
            return value
        }
        return nil
    }
    
    func takeOptIsDestructive() -> Bool? {
        if let value = self.isDestructive {
            self.isDestructive = nil
            return value
        }
        return nil
    }
    
    func takeOptMaxHeight() -> CGFloat? {
        if let value = self.maxHeight {
            self.maxHeight = nil
            return CGFloat(value)
        }
        return nil
    }
    
    func takeOptMaxWidth() -> CGFloat? {
        if let value = self.maxWidth {
            self.maxWidth = nil
            return CGFloat(value)
        }
        return nil
    }
    
    func takeOptMinHeight() -> CGFloat? {
        if let value = self.minHeight {
            self.minHeight = nil
            return CGFloat(value)
        }
        return nil
    }
    
    func takeOptMinWidth() -> CGFloat? {
        if let value = self.minWidth {
            self.minWidth = nil
            return CGFloat(value)
        }
        return nil
    }
    
    func takeOptSpacing() -> CGFloat? {
        if let value = self.spacing {
            self.spacing = nil
            return CGFloat(value)
        }
        return nil
    }

    func takeOptStart(_ session: MaggieSession) throws -> MaggieWidget? {
        if let value = self.start {
            self.start = nil
            return try MaggieWidget(value, session)
        }
        return nil
    }
    
    func takeText() throws -> String {
        if let value = self.text {
            self.text = nil
            return value
        }
        throw MaggieError.deserializeError("missing 'text'")
    }
    
    func takeOptTitle() throws -> String? {
        if let value = self.title {
            self.title = nil
            return value
        }
        return nil
    }
    
    func takeTitle() throws -> String {
        if let value = self.title {
            self.title = nil
            return value
        }
        throw MaggieError.deserializeError("missing 'title'")
    }
    
    func takeUrl() throws -> URL {
        if let value = self.url {
            self.url = nil
            return value
        }
        throw MaggieError.deserializeError("missing 'url'")
    }
    
    func takeWidget(_ session: MaggieSession) throws -> MaggieWidget {
        if let value = self.widget {
            self.widget = nil
            return try MaggieWidget(value, session)
        }
        throw MaggieError.deserializeError("missing 'widget'")
    }
    
    func takeOptWidgets(_ session: MaggieSession) throws -> [MaggieWidget]? {
        if let values = self.widgets {
            self.widgets = nil
            return try values.map { value in try MaggieWidget(value, session) }
        }
        return nil
    }
    
    func takeWidgets(_ session: MaggieSession) throws -> [MaggieWidget] {
        if let values = self.widgets {
            self.widgets = nil
            return try values.map { value in try MaggieWidget(value, session) }
        }
        throw MaggieError.deserializeError("missing 'widgets'")
    }
    
    func takeOptWidth() throws -> CGFloat? {
        if let value = self.width {
            self.width = nil
            return CGFloat(value)
        }
        return nil
    }

    func takeWidth() throws -> CGFloat {
        if let value = self.width {
            self.width = nil
            return CGFloat(value)
        }
        throw MaggieError.deserializeError("missing 'width'")
    }
    
    // TODO: Warn about unused values.
}
