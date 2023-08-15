import Foundation

enum JSON {
    indirect case array([JSON])
    case boolean(Bool)
    case double(Double)
    case integer(Int)
    case null
    indirect case object([String: JSON])
    case string(String)
}

extension JSON: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .array(let value):
            try container.encode(value)
        case .boolean(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .integer(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        case .object(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        }
    }
}

extension JSON: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode([JSON].self) {
            self = .array(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .boolean(value)
        } else if let value = try? container.decode(Int.self) {
            // NOTE: We must try to decode integer before double.
            self = .integer(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if
                let container = try? decoder.singleValueContainer(),
                container.decodeNil() {
            self = .null
        } else if let value = try? container.decode([String: JSON].self) {
            self = .object(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: container.codingPath, debugDescription: "error decoding as JSON"
            ))
        }
    }
}
