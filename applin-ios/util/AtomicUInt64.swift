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

    public func increment() {
        self.nsLock.lock()
        defer {
            self.nsLock.unlock()
        }
        self.value += 1
    }
}
