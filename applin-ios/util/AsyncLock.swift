import Foundation

import Foundation

class AsyncLock {
    class Guard {
        private let asyncLock: AsyncLock

        init(_ lock: AsyncLock) {
            self.asyncLock = lock
        }

        deinit {
            self.asyncLock.unlock()
        }
    }

    private let locked = AtomicBool(false)
    private let nsLock = NSLock()

    func lock() -> Guard {
        self.nsLock.lock()
        let wasLocked = self.locked.store(true)
        assert(!wasLocked)
        return Guard(self)
    }

    /// Throws `CancellationError` when the task is cancelled.
    func lockAsync() async throws -> Guard {
        while true {
            if self.locked.load() {
                try await Task.sleep(nanoseconds: 50_000_000)
            } else if self.nsLock.lock(before: Date.now + TimeInterval(0.050)) {
                let wasLocked = self.locked.store(true)
                assert(!wasLocked)
                return Guard(self)
            }
        }
    }

    private func unlock() {
        self.nsLock.unlock()
        let wasLocked = self.locked.store(false)
        assert(wasLocked)
    }
}
