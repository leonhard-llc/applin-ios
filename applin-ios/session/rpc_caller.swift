import Foundation

class UploadBody {
    let data: Data
    let contentType: String

    init(_ data: Data, contentType: String) {
        self.data = data
        self.contentType = contentType
    }
}

class RpcCaller {
    private struct UserError: Codable {
        var message: String
    }

    private let config: ApplinConfig
    private weak var session: ApplinSession?
    private let interactiveRpcLock = ApplinLock()
    private let rpcLock = ApplinLock()
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

    func rpc(optPageKey: String?, path: String, method: String, uploadBody: UploadBody? = nil) async throws {
        print("rpc \(path)")
        try await self.rpcLock.lockAsyncThrows {
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
                guard let vars: [String: Var] = session.mutex.lockReadOnly({ state in state.pageVars(pageKey: pageKey) }) else {
                    print("WARN cancelling rpc for missing page '\(pageKey)'")
                    return
                }
                let jsonBody: [String: JSON] = vars.mapValues({ v in v.toJson() })
                urlRequest.httpBody = try! encodeJson(jsonBody)
                urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
                if let bodyString = String(data: urlRequest.httpBody!, encoding: .utf8) {
                    print("DEBUG request body: \(bodyString)")
                }
            } else if let uploadBody = uploadBody {
                urlRequest.httpBody = uploadBody.data
                urlRequest.addValue(uploadBody.contentType, forHTTPHeaderField: "Content-Type")
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
                if httpResponse.contentTypeBase() == "application/json", let userError: UserError = try? decodeJson(data) {
                    throw ApplinError.userError(userError.message)
                } else if httpResponse.contentTypeBase() == "text/plain", let string = String(data: data, encoding: .utf8) {
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
    }

    func withWorking<R>(_ f: () async -> R) async -> R {
        await self.session?.nav?.setWorking("Working")
        let result = await f()
        await self.session?.nav?.setWorking(nil)
        return result
    }

    func interactiveRpc(optPageKey: String?, path: String, method: String, uploadBody: UploadBody? = nil) async -> Bool {
        await self.interactiveRpcLock.lockAsync {
            await self.withWorking {
                guard let session = self.session else {
                    return false
                }
                let stopwatch = Stopwatch()
                do {
                    try await self.rpc(optPageKey: optPageKey, path: path, method: method, uploadBody: uploadBody)
                    await stopwatch.waitUntil(seconds: 1.0)
                    return true
                } catch let e as ApplinError {
                    print("RpcCaller.interactiveRpc error: \(e)")
                    session.mutex.lock { state in
                        state.interactiveError = e
                        switch e {
                        case .appError:
                            state.stack.append(APPLIN_APP_ERROR_PAGE_KEY)
                        case .networkError:
                            state.stack.append(APPLIN_NETWORK_ERROR_PAGE_KEY)
                        case .serverError:
                            state.stack.append(APPLIN_RPC_ERROR_PAGE_KEY)
                        case .userError:
                            state.stack.append(APPLIN_USER_ERROR_PAGE_KEY)
                        }
                    }
                } catch let e {
                    print("RpcCaller.interactiveRpc unexpected error: \(e)")
                    session.mutex.lock { state in
                        state.interactiveError = .appError("\(e)")
                        state.stack.append(APPLIN_APP_ERROR_PAGE_KEY)
                    }
                }
                await stopwatch.waitUntil(seconds: 1.0)
                return false
            }
        }
    }
}
