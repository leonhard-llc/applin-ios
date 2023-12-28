import Foundation
import OSLog

enum Var {
    case bool(Bool)
    case string(String)
    // case Int(Int64)
    // case Float(Double)
    // case EpochSeconds(UInt64)

    func toJson() -> JSON {
        switch self {
        case let .bool(value):
            return .boolean(value)
        case let .string(value):
            return .string(value)
        }
    }
}

class VarSet {
    static let logger = Logger(subsystem: "Applin", category: "VarSet")
    private var lock = NSLock()
    private var vars: [String: Var] = [:]
    private var connectionError: ApplinError?
    private var interactiveError: ApplinError?

    init(_ bools: [String: Bool], _ strings: [String: String]) {
        for (name, value) in bools {
            self.set(name, .bool(value))
        }
        for (name, value) in strings {
            self.set(name, .string(value))
        }
    }

    func bool(_ name: String) -> Bool? {
        self.lock.lock()
        defer {
            self.lock.unlock()
        }
        switch self.vars[name] {
        case .none:
            return nil
        case let .some(.bool(value)):
            return value
        case let .some(other):
            Self.logger.error("tried to read variable \(String(describing: name)) as bool but it is: \(String(describing: other))")
            return nil
        }
    }

    func bools() -> [String: Bool] {
        self.lock.lock()
        defer {
            self.lock.unlock()
        }
        return self.vars.compactMap2({ (key, value) in
            switch value {
            case let .bool(b):
                return b
            default:
                return nil
            }
        })
    }

    func get(_ name: String) -> Var? {
        self.lock.lock()
        defer {
            self.lock.unlock()
        }
        return self.vars[name]
    }

    func getConnectionError() -> ApplinError? {
        self.lock.lock()
        defer {
            self.lock.unlock()
        }
        return self.connectionError
    }

    func getInteractiveError() -> ApplinError? {
        self.lock.lock()
        defer {
            self.lock.unlock()
        }
        return self.interactiveError
    }

    func setConnectionError(_ value: ApplinError?) {
        self.lock.lock()
        defer {
            self.lock.unlock()
        }
        self.connectionError = value
    }

    func setInteractiveError(_ value: ApplinError?) {
        self.lock.lock()
        defer {
            self.lock.unlock()
        }
        self.interactiveError = value
    }

    func setBool(_ name: String, _ optValue: Bool?) {
        if let value = optValue {
            self.set(name, .bool(value))
        } else {
            self.set(name, nil)
        }
    }

    func setString(_ name: String, _ optValue: String?) {
        if let value = optValue {
            self.set(name, .string(value))
        } else {
            self.set(name, nil)
        }
    }

    func set(_ name: String, _ optValue: Var?) {
        self.lock.lock()
        defer {
            self.lock.unlock()
        }
        Self.logger.info("setVar \(String(describing: name))=\(String(describing: optValue))")
        guard let value = optValue else {
            self.vars.removeValue(forKey: name)
            return
        }
        let oldValue = self.vars.updateValue(value, forKey: name)
        switch (oldValue, value) {
        case (.bool, .bool): break
        case (.string, .string): break
        default:
            Self.logger.error("setVar changed var type: \(String(describing: name)): \(String(describing: oldValue)) -> \(String(describing: optValue))")
        }
    }

    func string(_ name: String) -> String? {
        self.lock.lock()
        defer {
            self.lock.unlock()
        }
        switch self.vars[name] {
        case .none:
            return nil
        case let .some(.string(value)):
            return value
        case let .some(other):
            Self.logger.error("tried to read variable \(String(describing: name)) as string but it is: \(String(describing: other))")
            return nil
        }
    }

    func strings() -> [String: String] {
        self.lock.lock()
        defer {
            self.lock.unlock()
        }
        return self.vars.compactMap2({ (key, value) in
            switch value {
            case let .string(s):
                return s
            default:
                return nil
            }
        })
    }

    func removeAll() {
        self.lock.lock()
        defer {
            self.lock.unlock()
        }
        self.vars.removeAll()
        self.connectionError = nil
        self.interactiveError = nil
    }
}
