import Foundation

class AtomicInt64 {
    private let nsLock = NSLock()
    private var value: Int64 = 0

    public func load() -> Int64 {
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
