import Foundation

class Mutex<T> {
    class Guard<T> {
        private let mutex: Mutex<T>
        public var value: T

        init(_ mutex: Mutex<T>) {
            self.mutex = mutex
            self.mutex.nsLock.lock()
            self.value = self.mutex.value
        }

        deinit {
            self.mutex.value = self.value
            self.mutex.nsLock.unlock()
        }
    }

    private let nsLock = NSLock()
    private var value: T

    init(value: T) {
        self.value = value
    }

    func lock() -> Guard<T> {
        Guard(self)
    }
}
