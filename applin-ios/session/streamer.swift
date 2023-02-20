import Foundation

class Streamer {
    private let urlSession: URLSession
    private let config: ApplinConfig
    private var lock = NSLock()
    private weak var session: ApplinSession?
    private var task: Task<(), Never>?

    init(_ config: ApplinConfig, _ session: ApplinSession?) {
        let urlSessionConfig = URLSessionConfiguration.default
        urlSessionConfig.urlCache = nil
        urlSessionConfig.timeoutIntervalForRequest = 60.0 /* seconds to wait for next chunk */
        urlSessionConfig.timeoutIntervalForResource = 60 * 60.0 /* seconds, max connection duration */
        // When config.waitsForConnectivity=true, it waits a long time between connect attempts.
        urlSessionConfig.httpCookieAcceptPolicy = .always
        urlSessionConfig.httpShouldSetCookies = true
        self.urlSession = URLSession(configuration: urlSessionConfig)
        self.config = config
        self.session = session
    }

    deinit {
        self.task?.cancel()
        self.urlSession.invalidateAndCancel()
    }

    func update(_ state: ApplinState) {
        self.lock.lock()
        defer {
            self.lock.unlock()
        }
        if state.paused {
            self.task?.cancel()
            self.task = nil
            return
        }
        if state.getConnectionMode() == .stream && self.task == nil {
            self.task = Task {
                await self.stream()
            }
        }
    }

    private func connectOnce() async throws {
        print("Streamer connecting")
        // TODO: Stop spamming the log for every connection failure.
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
            let status = "\(httpResponse.statusCode) \(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))"
            if httpResponse.contentTypeBase() == "text/plain" {
                let body = try await asyncBytes.lines.reduce(into: "", { result, item in result += item })
                throw ApplinError.serverError(
                        "server returned \(status): \(String(describing: body))")
            } else {
                throw ApplinError.serverError(
                        "server returned \(status), len=\(response.expectedContentLength) \(httpResponse.mimeType ?? "")")
            }
        }
        if httpResponse.contentTypeBase() != "text/event-stream" {
            throw ApplinError.serverError(
                    "server sent unexpected content-type: \"\(httpResponse.mimeType ?? "")\"")
        }
        print("Streamer connected")
        do {
            for try await line in asyncBytes.lines {
                if Task.isCancelled {
                    return
                }
                // https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events
                print("Streamer read \(line)")
                let parts = line.split(separator: ":", maxSplits: 1)
                if parts.count != 2 || parts[1].isEmpty {
                    throw ApplinError.serverError("server sent line with unexpected format: \"\(line)\"")
                }
                if parts[0] != "data" {
                    print("Streamer ignoring non-data line from server: \"\(line)\"")
                    continue
                }
                let data = parts[1].data(using: .utf8)!
                try self.session?.applyUpdate(data)
            }
        } catch let e as NSError where e.code == -1004 /* Could not connect to the server */ {
            throw ApplinError.networkError("\(e)")
        } catch let e as ApplinError {
            throw e
        } catch let e {
            throw ApplinError.serverError("\(e)")
        }
        print("Streamer disconnected")
    }

    private func stream() async {
        print("Streamer starting")
        while !Task.isCancelled {
            do {
                try await self.connectOnce()
            } catch let e as ApplinError {
                print("Streamer error: \(e)")
                self.session?.mutex.lock().state.connectionError = e
            } catch let e {
                print("Streamer unexpected error: \(e)")
                self.session?.mutex.lock().state.connectionError = .appError("\(e)")
            }
            if !Task.isCancelled {
                await sleep(ms: Int.random(in: 2_500...7_500))
            }
        }
        print("Streamer stopped")
    }
}
