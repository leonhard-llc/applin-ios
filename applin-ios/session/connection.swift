import Foundation

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

enum ConnectionMode: Equatable, Comparable {
    case stream
    case pollSeconds(UInt32)
    case disconnect

    init(_ stream: Bool?, _ pollSeconds: UInt32?) {
        if stream == true {
            self = .stream
            return
        }
        switch pollSeconds {
        case .none:
            self = .disconnect
        case let .some(seconds) where seconds == 0:
            print("WARNING: Ignoring pollSeconds=0")
            self = .disconnect
        case let .some(seconds):
            self = .pollSeconds(seconds)
        }
    }

    func getStream() -> Bool? {
        switch self {
        case .stream:
            return true
        default:
            return nil
        }
    }

    func getPollSeconds() -> UInt32? {
        switch self {
        case .stream, .disconnect:
            return nil
        case let .pollSeconds(seconds):
            return seconds
        }
    }
}

enum ConnectionState {
    case disconnected, connecting, connectError, serverError, connected
}

class ApplinConnection {
    let config: ApplinConfig
    var paused: Bool = true
    var state: ConnectionState = .disconnected
    private var connectTask: Task<(), Never>?
    private var pollTask: Task<(), Never>?
    private var pollSeconds: UInt32 = 1
    private var running: Bool = false

    init(_ config: ApplinConfig) {
        self.config = config
    }

    private func connectOnce(_ session: ApplinSession) async throws {
        print("ApplinConnection connect")
        let config = URLSessionConfiguration.default
        config.urlCache = nil
        config.timeoutIntervalForRequest = 60.0 /* seconds to wait for next chunk */
        config.timeoutIntervalForResource = 60 * 60.0 /* seconds, max connection duration */
        // When config.waitsForConnectivity=true, it waits a long time between connect attempts.
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        let urlSession = URLSession(configuration: config)
        defer {
            urlSession.invalidateAndCancel()
        }
        // URLSession.bytes does not call the URLSessionTaskDelegate on error.
        // So we cannot use a delegate to suppress network error log spam.
        // Probably the only way to do it is to re-implement bytes() using AsyncStream:
        // https://developer.apple.com/documentation/swift/asyncstream
        // If we're going to spend that code, then let's make it good.
        // Let's make an URLSession extension with an asyncEventStream() method that returns
        // whole Server-Sent Events.
        let url = self.config.url.appendingPathComponent("stream")
        let (asyncBytes, response) = try await urlSession.bytes(from: url)
        let httpResponse = response as! HTTPURLResponse
        if httpResponse.statusCode != 200 {
            self.state = .serverError
            if httpResponse.contentTypeBase() == "text/plain" {
                let string = try await asyncBytes.lines.reduce(into: "", { result, item in result += item })
                print("ApplinConnection server error: "
                        + "\(httpResponse.statusCode) "
                        + "\(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)) \"\(string)\"")
            } else {
                print("ApplinConnection server error: "
                        + "\(httpResponse.statusCode) "
                        + "\(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)), "
                        + "len=\(response.expectedContentLength) \(httpResponse.mimeType ?? "")")
            }
            return
        }
        if httpResponse.contentTypeBase() != "text/event-stream" {
            self.state = .serverError
            print("ApplinConnection server sent unexpected content-type: \"\(httpResponse.mimeType ?? "")\"")
            return
        }
        self.state = .connected
        defer {
            self.state = .connectError
        }
        print("ApplinConnection reading")
        for try await line in asyncBytes.lines {
            if Task.isCancelled {
                return
            }
            // https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events
            print("ApplinConnection read \(line)")
            let parts = line.split(separator: ":", maxSplits: 1)
            if parts.count != 2 || parts[1].isEmpty {
                throw ApplinError.networkError("server sent line with unexpected format: \"\(line)\"")
            }
            if parts[0] != "data" {
                print("ApplinConnection ignoring non-data line from server: \"\(line)\"")
                continue
            }
            let data = parts[1].data(using: .utf8)!
            try session.applyUpdate(data)
        }
        print("ApplinConnection disconnected")
    }

    private func connect(_ session: ApplinSession) async {
        print("ApplinConnection connect")
        while self.running {
            await sleep(ms: 1_000)
        }
        defer {
            self.running = false
        }
        self.running = true
        while !Task.isCancelled {
            do {
                try await self.connectOnce(session)
            } catch let error as NSError where error.code == -1004 /* Could not connect to the server */ {
                self.state = .connectError
            } catch {
                // TODO: Show error to user on startup.
                self.state = .connectError
                print("ApplinConnection error: \(error)")
            }
            await sleep(ms: 5_000)
        }
        print("ApplinConnection stop connect")
    }

    private func startConnect(_ session: ApplinSession) {
        if self.paused || self.connectTask != nil {
            return
        }
        self.connectTask = Task(priority: .medium) {
            await self.connect(session)
        }
    }

    private func stopConnect() {
        self.connectTask?.cancel()
        self.connectTask = nil
    }

    private func poll(_ session: ApplinSession) async {
        print("ApplinConnection poll")
        while self.running {
            await sleep(ms: 1_000)
        }
        defer {
            self.running = false
        }
        self.running = true
        let periodic = Periodic()
        while !Task.isCancelled {
            do {
                if periodic.checkNow(TimeInterval(self.pollSeconds)) {
                    try await session.rpc(pageKey: nil, path: "/", method: "GET")
                } else {
                    await sleep(ms: 1000)
                }
            } catch let error as NSError where error.code == -1004 /* Could not connect to the server */ {
                self.state = .connectError
                await sleep(ms: 5_000)
            } catch {
                print("ApplinConnection error: \(error)")
                self.state = .connectError
                await sleep(ms: 5_000)
            }
        }
        print("ApplinConnection stop poll")
    }

    private func startPoll(_ session: ApplinSession) {
        if self.paused || self.pollTask != nil {
            return
        }
        self.pollTask = Task(priority: .medium) {
            await self.poll(session)
        }
    }

    private func stopPoll() {
        self.pollTask?.cancel()
        self.pollTask = nil
    }

    func setMode(_ session: ApplinSession, _ mode: ConnectionMode) {
        print("mode=\(mode)")
        if self.paused {
            return
        }
        switch mode {
        case .disconnect:
            self.stopConnect()
            self.stopPoll()
        case let .pollSeconds(seconds):
            self.pollSeconds = seconds
            self.stopConnect()
            self.startPoll(session)
        case .stream:
            self.stopPoll()
            self.startConnect(session)
        }
    }

    func pause() {
        print("pause")
        self.paused = true
        self.stopConnect()
        self.stopPoll()
    }

    func unpause(_ session: ApplinSession, _ mode: ConnectionMode) {
        print("unpause mode=\(mode)")
        self.paused = false
        self.setMode(session, mode)
    }
}
