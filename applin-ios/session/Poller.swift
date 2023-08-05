import Foundation
import OSLog

class Poller {
    static let logger = Logger(subsystem: "Applin", category: "Poller")

    private let taskLock = ApplinLock()
    private let config: ApplinConfig
    private weak var cache: ResponseCache?
    private weak var pageStack: PageStack?
    private weak var serverCaller: ServerCaller?
    private var task: Task<(), Never>?

    public init(_ config: ApplinConfig, _ cache: ResponseCache?, _ pageStack: PageStack?, _ serverCaller: ServerCaller?) {
        self.config = config
        self.cache = cache
        self.pageStack = pageStack
        self.serverCaller = serverCaller
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
                    try await self.updatePreloadPages()
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

    func updatePreloadPages() async throws {
        try await self.taskLock.lockAsyncThrows({
            guard let cache = self.cache, let pageStack = self.pageStack else {
                return
            }
            let keys = pageStack.preloadPageKeys().reversed()
            for key in keys {
                if self.config.staticPages[key] != nil {
                    continue
                }
                let url = self.config.url.appendingPathComponent(key).absoluteString
                if let responseInfo = cache.get(url: url) {
                    if Date.now.secondsSinceEpoch() < responseInfo.refreshTime {
                        continue
                    }
                }
                let varNamesAndValues = pageStack.varNamesAndValues(pageKey: key)
                let token = pageStack.token()
                let optUpdate = try await serverCaller?.call(path: key, varNamesAndValues: varNamesAndValues)
                if let update = optUpdate {
                    let updated = await pageStack.tryUpdate(pageKey: key, token, spec: update.spec)
                    if updated, let responseInfo = update.responseInfo {
                        // TODO: Solve race between actions and poller when writing to cache.
                        cache.add(responseInfo, update.data)
                    }
                } else {
                    Self.logger.error("got no response body for '\(key)")
                }
            }
        })
    }
}
