import Foundation

class AtomicBool {
    private let nsLock = NSLock()
    private var value: Bool

    init(_ initialValue: Bool) {
        self.value = initialValue
    }

    public func load() -> Bool {
        self.nsLock.lock()
        defer {
            self.nsLock.unlock()
        }
        return self.value
    }

    public func store(_ newValue: Bool) {
        self.nsLock.lock()
        defer {
            self.nsLock.unlock()
        }
        self.value = newValue
    }
}
