import Foundation

import Foundation

class ApplinLock {
    private let locked = AtomicBool(false)
    private let nsLock = NSLock()

    func lock<T>(_ f: () -> T) -> T {
        self.nsLock.lock()
        defer {
            self.unlock()
        }
        let wasLocked = self.locked.store(true)
        assert(!wasLocked)
        return f()
    }

    func lockThrows<T>(_ f: () throws -> T) throws -> T {
        self.nsLock.lock()
        defer {
            self.unlock()
        }
        let wasLocked = self.locked.store(true)
        assert(!wasLocked)
        return try f()
    }

    func lockAsync<T>(_ f: () async -> T) async -> T {
        while true {
            if self.locked.load() {
                do {
                    try await Task.sleep(nanoseconds: 50_000_000)
                } catch {
                    self.nsLock.lock()
                    break
                }
            } else if self.nsLock.lock(before: Date.now + TimeInterval(0.050)) {
                break
            }
        }
        defer {
            self.unlock()
        }
        let wasLocked = self.locked.store(true)
        assert(!wasLocked)
        return await f()
    }

    func lockAsyncThrows<T>(_ f: () async throws -> T) async throws -> T {
        while true {
            if self.locked.load() {
                do {
                    try await Task.sleep(nanoseconds: 50_000_000)
                } catch {
                    self.nsLock.lock()
                    break
                }
            } else if self.nsLock.lock(before: Date.now + TimeInterval(0.050)) {
                break
            }
        }
        defer {
            self.unlock()
        }
        let wasLocked = self.locked.store(true)
        assert(!wasLocked)
        return try await f()
    }

    private func unlock() {
        let wasLocked = self.locked.store(false)
        self.nsLock.unlock()
        assert(wasLocked)
    }
}
