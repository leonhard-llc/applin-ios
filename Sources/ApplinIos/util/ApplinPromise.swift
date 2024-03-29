import Foundation

class ApplinPromise<T> {
    private enum PromiseResult {
        case no
        case yes(T)
    }

    private let applinLock = ApplinLock()
    private let resultLock = NSLock()
    private var result: PromiseResult = .no

    init() {
        self.applinLock.unsafeLock()
    }

    // This function exists to avoid the warning (and error):
    // "Instance method 'lock' is unavailable from asynchronous contexts; Use async-safe scoped locking instead; this is an error in Swift 6"
    // https://forums.swift.org/t/what-does-use-async-safe-scoped-locking-instead-even-mean/61029/15
    private func lock_resultLock() {
        self.resultLock.lock()
    }

    func complete(value: T) {
        if !self.tryComplete(value: value) {
            preconditionFailure("promise is already completed")
        }
    }

    func tryComplete(value: T) -> Bool {
        self.resultLock.lock()
        guard case .no = self.result else {
            self.resultLock.unlock()
            return false
        }
        self.result = .yes(value)
        self.resultLock.unlock()

        self.applinLock.unsafeUnlock()
        return true
    }

    func value() async -> T {
        await self.applinLock.lockAsync({
            self.lock_resultLock()
            defer {
                self.resultLock.unlock()
            }
            switch self.result {
            case .no:
                preconditionFailure()
            case let .yes(value):
                return value
            }
        })
    }
}
