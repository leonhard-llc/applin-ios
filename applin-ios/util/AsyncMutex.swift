import Foundation

class AsyncMutex<T> {
    class Guard<T> {
        private let lockGuard: AsyncLock.Guard
        private let mutex: AsyncMutex<T>
        public var value: T

        init(_ lockGuard: AsyncLock.Guard, _ mutex: AsyncMutex<T>) {
            self.lockGuard = lockGuard
            self.mutex = mutex
            self.value = self.mutex.value
        }

        deinit {
            self.mutex.value = self.value
        }
    }

    private let asyncLock = AsyncLock()
    private var value: T

    init(value: T) {
        self.value = value
    }

    func lock() -> Guard<T> {
        Guard(self.asyncLock.lock(), self)
    }

    /// Throws `CancellationError` when the task is cancelled.
    func lockAsync() async throws -> Guard<T> {
        Guard(try await self.asyncLock.lockAsync(), self)
    }
}
