import Foundation

import Foundation

class ApplinLock {
    private let locked = AtomicBool(false)
    private let nsLock = NSLock()

    func unsafeLock() {
        self.nsLock.lock()
        let wasLocked = self.locked.store(true)
        assert(!wasLocked)
    }

    func unsafeLockAsync() async {
        while true {
            if self.locked.load() {
                do {
                    // TODO: See if we can use `withCheckedContinuation` and eliminate the spin lock.
                    try await Task.sleep(nanoseconds: 50_000_000)
                } catch {
                    self.nsLock.lock()
                    break
                }
            } else if self.nsLock.lock(before: Date.now + TimeInterval(0.050)) {
                break
            }
        }
        let wasLocked = self.locked.store(true)
        assert(!wasLocked)
    }

    func unsafeUnlock() {
        let wasLocked = self.locked.store(false)
        self.nsLock.unlock()
        assert(wasLocked)
    }

    func lock<T>(_ f: () -> T) -> T {
        self.nsLock.lock()
        defer {
            self.unsafeUnlock()
        }
        let wasLocked = self.locked.store(true)
        assert(!wasLocked)
        return f()
    }

    func lockThrows<T>(_ f: () throws -> T) throws -> T {
        self.nsLock.lock()
        defer {
            self.unsafeUnlock()
        }
        let wasLocked = self.locked.store(true)
        assert(!wasLocked)
        return try f()
    }

    func lockAsync<T>(_ f: () async -> T) async -> T {
        await self.unsafeLockAsync()
        defer {
            self.unsafeUnlock()
        }
        return await f()
    }

    func lockAsyncThrows<T>(_ f: () async throws -> T) async throws -> T {
        await self.unsafeLockAsync()
        defer {
            self.unsafeUnlock()
        }
        return try await f()
    }
}
