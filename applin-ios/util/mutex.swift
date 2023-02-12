import Foundation

class Guard<T> {
    private let nsLock: NSLock
    public var value: T

    init(_ lock: NSLock, _ value: T) {
        self.nsLock = lock
        self.value = value
    }

    deinit {
        self.nsLock.unlock()
    }
}

class Mutex<T> {
    private let nsLock = NSLock()
    private var value: T

    init(value: T) {
        self.value = value
    }

    public func lock() -> Guard<T> {
        self.nsLock.lock()
        return Guard(self.nsLock, self.value)
    }
}
