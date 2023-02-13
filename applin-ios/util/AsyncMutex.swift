import Foundation

class AsyncMutex<T> {
    class Guard<T> {
        private let mutex: AsyncMutex<T>
        public var value: T

        init(_ mutex: AsyncMutex<T>, _ value: T) {
            self.mutex = mutex
            self.value = value
        }

        deinit {
            self.mutex.unlock(self.value)
        }
    }

    private let locked = AtomicBool(false)
    private let nsLock = NSLock()
    private var value: T

    init(value: T) {
        self.value = value
    }

    func lock() -> Guard<T> {
        self.nsLock.lock()
        let wasLocked = self.locked.store(true)
        assert(!wasLocked)
        return Guard(self, self.value)
    }

    /// Throws `CancellationError` when the task is cancelled.
    func lockAsync() async throws -> Guard<T> {
        while true {
            if self.locked.load() {
                try await Task.sleep(nanoseconds: 50_000_000)
            } else if self.nsLock.lock(before: Date.now + TimeInterval(0.050)) {
                let wasLocked = self.locked.store(true)
                assert(!wasLocked)
                return Guard(self, self.value)
            }
        }
    }

    private func unlock(_ value: T) {
        self.value = value
        self.nsLock.unlock()
        let wasLocked = self.locked.store(false)
        assert(wasLocked)
    }
}
