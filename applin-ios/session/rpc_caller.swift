import Foundation

class RpcCaller {
    private let config: ApplinConfig
    private weak var session: ApplinSession?
    private let interactiveRpcLock = AsyncLock()
    private let rpcLock = AsyncLock()
    private let urlSession: URLSession

    init(_ config: ApplinConfig, _ session: ApplinSession) {
        self.config = config
        self.session = session
        let urlSessionConfig = URLSessionConfiguration.default
        urlSessionConfig.timeoutIntervalForRequest = 10.0 /* seconds */
        urlSessionConfig.timeoutIntervalForResource = 60.0 /* seconds */
        urlSessionConfig.urlCache = nil
        urlSessionConfig.httpCookieAcceptPolicy = .always
        urlSessionConfig.httpShouldSetCookies = true
        self.urlSession = URLSession(configuration: urlSessionConfig)
    }

    deinit {
        self.urlSession.invalidateAndCancel()
    }

    func rpc(optPageKey: String?, path: String, method: String) async throws {
        print("rpc \(path)")
        let _guard = try await self.rpcLock.lockAsync()
        guard let session = self.session else {
            return
        }
        let url = self.config.url.appendingPathComponent(
                path.starts(with: "/") ? String(path.dropFirst()) : path)
        var urlRequest = URLRequest(
                url: url,
                cachePolicy: .reloadIgnoringLocalAndRemoteCacheData
        )
        urlRequest.httpMethod = method
        if let pageKey = optPageKey {
            urlRequest.addValue("application/json", forHTTPHeaderField: "content-type")
            guard let vars: [String: Var] = session.mutex.readOnlyLock().readOnlyState.pageVars(pageKey: pageKey) else {
                print("WARN cancelling rpc for missing page '\(pageKey)'")
                return
            }
            let jsonBody: [String: JSON] = vars.mapValues({ v in v.toJson() })
            urlRequest.httpBody = try! encodeJson(jsonBody)
            if let bodyString = String(data: urlRequest.httpBody!, encoding: .utf8) {
                print("DEBUG request body: \(bodyString)")
            }
        }
        let data: Data
        let httpResponse: HTTPURLResponse
        do {
            let (urlData, urlResponse) = try await self.urlSession.data(for: urlRequest)
            data = urlData
            httpResponse = urlResponse as! HTTPURLResponse
        } catch {
            throw ApplinError.networkError("rpc \(path) transport error: \(error)")
        }
        if !(200...299).contains(httpResponse.statusCode) {
            if httpResponse.contentTypeBase() == "text/plain", let string = String(data: data, encoding: .utf8) {
                throw ApplinError.serverError("rpc \(path) server error: \(httpResponse.statusCode) "
                        + "\(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)) \"\(string)\"")
            } else {
                throw ApplinError.serverError("rpc \(path) server error: \(httpResponse.statusCode) "
                        + "\(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)), "
                        + "len=\(data.count) \(httpResponse.mimeType ?? "")")
            }
        }
        let contentTypeBase = httpResponse.contentTypeBase()
        if let bodyString = String(data: data, encoding: .utf8) {
            print("DEBUG response body \(contentTypeBase ?? ""): \(bodyString)")
        }
        if contentTypeBase != "application/json" {
            throw ApplinError.serverError(
                    "rpc \(path) server response content-type is not 'application/json': '\(contentTypeBase ?? "")'")
        }
        try session.applyUpdate(data)
    }

    func interactiveRpc(optPageKey: String?, path: String, method: String) async -> Bool {
        let _guard: AsyncLock.Guard
        do {
            _guard = try await self.interactiveRpcLock.lockAsync()
        } catch {
            return false
        }
        guard let session = self.session else {
            return false
        }
        session.mutex.lock().state.working = "Working"
        defer {
            session.mutex.lock().state.working = nil
        }
        let stopwatch = Stopwatch()
        do {
            try await self.rpc(optPageKey: optPageKey, path: path, method: method)
            await stopwatch.waitUntil(seconds: 1.0)
            return true
        } catch let e as ApplinError {
            print("RpcCaller.interactiveRpc error: \(e)")
            let mutexGuard = session.mutex.lock()
            mutexGuard.state.interactiveError = e
            switch e {
            case .appError:
                mutexGuard.state.stack.append(APPLIN_APP_ERROR_PAGE_KEY)
            case .networkError:
                mutexGuard.state.stack.append(APPLIN_NETWORK_ERROR_PAGE_KEY)
            case .serverError:
                mutexGuard.state.stack.append(APPLIN_RPC_ERROR_PAGE_KEY)
            case .userError:
                mutexGuard.state.stack.append(APPLIN_USER_ERROR_PAGE_KEY)
            }
        } catch let e {
            print("RpcCaller.interactiveRpc unexpected error: \(e)")
            let mutexGuard = session.mutex.lock()
            mutexGuard.state.interactiveError = .appError("\(e)")
            mutexGuard.state.stack.append(APPLIN_APP_ERROR_PAGE_KEY)
        }
        await stopwatch.waitUntil(seconds: 1.0)
        return false
    }
}
