import Foundation

enum ConnectionState {
    case disconnected, connecting, connectError, serverError, connected
}

class ApplinConnection {
    var state: ConnectionState = .disconnected
    private var task: Task<(), Never>?
    private var running: Bool = false

    func connectOnce(_ session: ApplinSession) async throws {
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
        let url = session.url
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
            print("ApplinConnection server sent unexpected content-type: \" \(httpResponse.mimeType ?? "")\"")
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
            _ = session.applyUpdate(data)
        }
        print("ApplinConnection disconnected")
    }

    public func start(_ session: ApplinSession) {
        if self.task != nil {
            return
        }
        self.task = Task(priority: .medium) {
            print("ApplinConnection start")
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
            print("ApplinConnection stop")
        }
    }

    public func stop() {
        if let task = self.task {
            task.cancel()
            self.task = nil
        }
    }
}
