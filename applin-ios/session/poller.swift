import Foundation

class Poller {
    class Periodic {
        var last: Date = .distantPast

        func checkNow(_ interval: TimeInterval) -> Bool {
            let now = Date.now
            let nextPollTime = last.addingTimeInterval(interval)
            if nextPollTime < now {
                last = max(nextPollTime, now.addingTimeInterval(-interval))
                return true
            } else {
                return false
            }
        }
    }

    static private func poll(_ weakRpcCaller: Weak<RpcCaller>, _ weakSession: Weak<ApplinSession>, seconds: UInt32) async {
        print("Poller.poll")
        await sleep(ms: 1_000)
        let periodic = Periodic()
        while !Task.isCancelled {
            while !Task.isCancelled {
                if periodic.checkNow(TimeInterval(seconds)) {
                    break
                }
                await sleep(ms: 1000)
            }
            while !Task.isCancelled {
                guard let rpcCaller = weakRpcCaller.value, let session = weakSession.value else {
                    return
                }
                do {
                    try await rpcCaller.rpc(optPageKey: nil, path: "/", method: "GET")
                    break
                } catch let e as ApplinError {
                    print("Poller.poll error: \(e)")
                    session.mutex.lock().state.connectionError = e
                } catch let e {
                    print("Poller.poll unexpected error: \(e)")
                    session.mutex.lock().state.connectionError = .appError("\(e)")
                }
                await sleep(ms: Int.random(in: 2_500...7_500))
            }
        }
        print("Poller.poll stopped")
    }

    private let config: ApplinConfig
    private var lock = NSLock()
    private weak var rpcCaller: RpcCaller?
    private weak var session: ApplinSession?
    private var seconds: UInt32 = 0
    private var task: Task<(), Never>?

    init(_ config: ApplinConfig, _ rpcCaller: RpcCaller?, _ session: ApplinSession?) {
        self.config = config
        self.rpcCaller = rpcCaller
        self.session = session
    }

    deinit {
        self.task?.cancel()
    }

    func update(_ state: ApplinState) {
        self.lock.lock()
        defer {
            self.lock.unlock()
        }
        if state.paused {
            self.seconds = 0
            self.task?.cancel()
            self.task = nil
            return
        }
        switch state.getConnectionMode() {
        case let .pollSeconds(s) where s == self.seconds:
            break
        case let .pollSeconds(s):
            self.seconds = s
            self.task?.cancel()
            let weakRpcCaller = Weak(self.rpcCaller)
            let weakSession = Weak(self.session)
            self.task = Task(priority: .low) { [weakRpcCaller, weakSession, s] in
                await Self.poll(weakRpcCaller, weakSession, seconds: s)
            }
        default:
            self.seconds = 0
            self.task?.cancel()
            self.task = nil
        }
    }
}
