import Foundation
import OSLog

class ForegroundPoller {
    static let logger = Logger(subsystem: "Applin", category: "ForegroundPoller")

    weak var weakPageStack: PageStack?
    private let tasksLock = ApplinLock()
    private var waitingTasks: [Task<(), Never>] = []
    private var pollTask: Task<(), Never>?
    private let pollTaskLock = ApplinLock()

    deinit {
        self.stop()
    }

    private func poll() async {
        await self.pollTaskLock.lockAsync({
            if Task.isCancelled {
                return
            }
            guard let pageStack = self.weakPageStack else {
                return
            }
            guard let pageKey = pageStack.topPageKey() else {
                return
            }
            Self.logger.dbg("poll")
            // TODO: Retry failed polls.
            let _ = await pageStack.doActions(pageKey: pageKey, [.poll], showWorking: false)
        })
    }

    private func waitAndPoll(delayMillis: UInt32) async {
        await sleep(ms: Int(delayMillis))
        await self.pollTaskLock.lockAsync({
            await self.tasksLock.lockAsync({
                if Task.isCancelled {
                    return
                }
                for t in self.waitingTasks {
                    t.cancel()
                }
                self.waitingTasks.removeAll()
                self.pollTask?.cancel()
                self.pollTask = Task {
                    await self.poll()
                }
            })
        })
    }

    func schedulePoll(delayMillis: UInt32) {
        let waitingTask = Task {
            await self.waitAndPoll(delayMillis: delayMillis)
        }
        self.tasksLock.lock({
            waitingTasks.append(waitingTask)
        })
    }

    func stop() {
        self.tasksLock.lock({
            for t in self.waitingTasks {
                t.cancel()
            }
            self.waitingTasks.removeAll()
            self.pollTask?.cancel()
            self.pollTask = nil
        })
    }
}
