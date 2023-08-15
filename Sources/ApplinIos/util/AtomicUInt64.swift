import Foundation

class AtomicUInt64 {
    private let nsLock = NSLock()
    private var value: UInt64 = 0

    init(_ value: UInt64) {
        self.value = value
    }

    public func load() -> UInt64 {
        self.nsLock.lock()
        defer {
            self.nsLock.unlock()
        }
        return self.value
    }

    @discardableResult
    public func increment() -> UInt64 {
        self.nsLock.lock()
        defer {
            self.nsLock.unlock()
        }
        self.value += 1
        return self.value
    }

    @discardableResult
    func store(_ value: UInt64) -> UInt64 {
        self.nsLock.lock()
        defer {
            self.nsLock.unlock()
        }
        let oldValue = self.value
        self.value = value
        return oldValue
    }
}
