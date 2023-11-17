import Foundation

class ApplinLock {
    private let locked = AtomicBool(false)
    private let nsLock = NSLock()

    // This function exists to avoid the warning (and error):
    // "Instance method 'lock' is unavailable from asynchronous contexts; Use async-safe scoped locking instead; this is an error in Swift 6"
    // https://forums.swift.org/t/what-does-use-async-safe-scoped-locking-instead-even-mean/61029/15
    private func lock_nsLock() {
        self.nsLock.lock()
    }

    private func lock_nsLock(before: Date) -> Bool {
        self.nsLock.lock(before: before)
    }

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
                    // Task is cancelled.  Try to acquire the lock as fast as possible, without spinning.
                    self.lock_nsLock()
                    break
                }
            } else if self.lock_nsLock(before: Date.now + TimeInterval(0.050)) {
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
