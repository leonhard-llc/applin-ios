import Foundation

class ApplinMutex<T> {
    private let applinLock = ApplinLock()
    private var value: T

    init(value: T) {
        self.value = value
    }

    func lock<R>(_ f: (inout T) -> R) -> R {
        self.applinLock.lock({ f(&self.value) })
    }

    func lockReadOnly<R>(_ f: (T) -> R) -> R {
        self.applinLock.lock({ f(self.value) })
    }

    func lockThrows<R>(_ f: (inout T) throws -> R) throws -> R {
        try self.applinLock.lockThrows({ try f(&self.value) })
    }

    func lockReadOnlyThrows<R>(_ f: (T) throws -> R) throws -> R {
        try self.applinLock.lockThrows({ try f(self.value) })
    }

    func lockAsync<R>(_ f: (inout T) async -> R) async -> R {
        await self.applinLock.lockAsync({ await f(&self.value) })
    }

    func lockAsyncReadOnly<R>(_ f: (T) async -> R) async -> R {
        await self.applinLock.lockAsync({ await f(self.value) })
    }

    func lockAsyncThrows<R>(_ f: (inout T) async throws -> R) async throws -> R {
        try await self.applinLock.lockAsyncThrows({ try await f(&self.value) })
    }

    func lockAsyncThrowsReadOnly<R>(_ f: (T) async throws -> R) async throws -> R {
        try await self.applinLock.lockAsyncThrows({ try await f(self.value) })
    }
}
