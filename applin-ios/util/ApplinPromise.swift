import Foundation

class ApplinPromise<T> {
    private enum PromiseResult<T> {
        case no
        case yes(T)
    }

    private let applinLock = ApplinLock()
    private let resultLock = NSLock()
    private var result: PromiseResult<T> = .no

    init() {
        self.applinLock.unsafeLock()
    }

    func complete(value: T) {
        self.resultLock.lock()
        switch self.result {
        case .no:
            break
        case .yes(_):
            preconditionFailure()
        }
        self.result = .yes(value)
        self.resultLock.unlock()

        self.applinLock.unsafeUnlock()
    }

    func value() async -> T {
        await self.applinLock.lockAsync({
            self.resultLock.lock()
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
