import Foundation
import OSLog

class Poller {
    static let logger = Logger(subsystem: "Applin", category: "Poller")
    static let retryMillis = RetryMillis(millis: [1_000, 5_000, 10_000, 30_000])

    private let taskLock = ApplinLock()
    private let config: ApplinConfig
    private let wallClock: WallClock
    private weak var pageStack: PageStack?
    private weak var serverCaller: ServerCaller?
    private var task: Task<(), Never>?

    public init(
            _ config: ApplinConfig,
            _ pageStack: PageStack?,
            _ serverCaller: ServerCaller?,
            _ wallClock: WallClock
    ) {
        self.config = config
        self.pageStack = pageStack
        self.serverCaller = serverCaller
        self.wallClock = wallClock
    }

    deinit {
        self.task?.cancel()
    }

    func start() {
        self.task?.cancel()
        self.task = Task(priority: .low) {
            Self.logger.info("starting")
            var attempt = 0
            while !Task.isCancelled {
                let sleepMs = Self.retryMillis.get(attemptNum: attempt)
                await sleep(ms: sleepMs)
                if Task.isCancelled {
                    break
                }
                do {
                    try await self.updatePolledPages()
                    attempt = 0
                } catch {
                    // TODO: Show "Connection problem" warning.
                    Self.logger.error("error updating, will retry: \(error)")
                    attempt += 1
                }
            }
            Self.logger.info("stopping")
        }
    }

    func stop() {
        self.task?.cancel()
    }

    func updatePolledPages() async throws {
        try await self.taskLock.lockAsyncThrows({
            guard let pageStack = self.pageStack else {
                return
            }
            let stackPages: [(String, PageSpec, Instant)] = pageStack.stackPages().reversed()
            for (key, spec, updated) in stackPages {
                guard case let .pollSeconds(intervalSeconds) = spec.connectionMode else {
                    continue
                }
                let staleTime = updated.secondsSinceEpoch + UInt64(intervalSeconds)
                if self.wallClock.now().secondsSinceEpoch < staleTime {
                    continue
                }
                if self.config.staticPages[key] != nil {
                    continue
                }
                let varNamesAndValues = pageStack.varNamesAndValues(pageKey: key)
                let token = pageStack.token()
                let optUpdate = try await serverCaller?.poll(
                        path: key,
                        varNamesAndValues: varNamesAndValues,
                        interactive: false
                )
                if let update = optUpdate {
                    let _ = await pageStack.tryUpdate(pageKey: key, token, update.spec)
                } else {
                    Self.logger.error("got no response body for '\(key)")
                }
            }
        })
    }
}
