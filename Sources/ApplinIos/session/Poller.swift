import Foundation
import OSLog

class Poller {
    static let logger = Logger(subsystem: "Applin", category: "Poller")

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
            while !Task.isCancelled {
                await sleep(ms: 1_000)
                if Task.isCancelled {
                    break
                }
                do {
                    try await self.updatePolledPages()
                } catch {
                    Self.logger.error("error updating, will retry: \(error)")
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
                let optUpdate = try await serverCaller?.call(path: key, varNamesAndValues: varNamesAndValues)
                if let update = optUpdate {
                    let _ = await pageStack.tryUpdate(pageKey: key, token, update.spec)
                } else {
                    Self.logger.error("got no response body for '\(key)")
                }
            }
        })
    }
}
