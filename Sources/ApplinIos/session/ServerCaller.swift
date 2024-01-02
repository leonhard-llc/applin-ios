import Foundation
import OSLog

class PageUpdate {
    let data: Data
    let spec: PageSpec

    init(_ data: Data, _ spec: PageSpec) {
        self.data = data
        self.spec = spec
    }
}

class UploadBody {
    let data: Data
    let contentType: String

    init(_ data: Data, contentType: String) {
        self.data = data
        self.contentType = contentType
    }
}

class ServerCaller {
    static let logger = Logger(subsystem: "Applin", category: "ServerCaller")

    private let config: ApplinConfig
    private let urlSession: URLSession
    private weak var pageStack: PageStack?
    private weak var varSet: VarSet?

    public init(_ config: ApplinConfig, _ pageStack: PageStack?, _ varSet: VarSet?) {
        self.config = config
        let urlSessionConfig = URLSessionConfiguration.default
        urlSessionConfig.timeoutIntervalForRequest = 10.0 /* seconds */
        urlSessionConfig.timeoutIntervalForResource = 60.0 /* seconds */
        urlSessionConfig.urlCache = nil
        urlSessionConfig.httpCookieAcceptPolicy = .always
        urlSessionConfig.httpShouldSetCookies = true
        self.urlSession = URLSession(configuration: urlSessionConfig)
        self.pageStack = pageStack
        self.varSet = varSet
    }

    deinit {
        self.urlSession.invalidateAndCancel()
    }

    private func doRequest(_ req: URLRequest, interactive: Bool) async throws -> (HTTPURLResponse, Data) {
        let method = req.httpMethod ?? ""
        Self.logger.info("HTTP request \(method) \(String(reflecting: req.url!.relativeString))")
        Self.logger.dbg("HTTP request_headers \(method) \(String(reflecting: req.url!.relativeString)) \(String(reflecting: req.allHTTPHeaderFields ?? [:]))")
        if let body = req.httpBody {
            Self.logger.dbg("HTTP request_body \(method) \(String(reflecting: req.url!.relativeString)) body=\(String(reflecting: String(data: body, encoding: .utf8)))")
        }
        let data: Data
        let resp: HTTPURLResponse
        do {
            let (urlData, urlResponse) = try await self.urlSession.data(for: req)
            data = urlData
            resp = urlResponse as! HTTPURLResponse
        } catch {
            throw ApplinError.networkError("error talking to server at \(req.url!.absoluteString) : \(error)")
        }
        Self.logger.info("HTTP response \(method) \(String(reflecting: req.url!.relativeString)) status=\(resp.statusCode) bodyLen=\(data.count) contentType='\(resp.value(forHTTPHeaderField: "content-type"))'")
        Self.logger.dbg("HTTP response_headers \(method) \(String(reflecting: req.url!.relativeString)) \(resp.allHeaderFields.map({ k, v in "\(String(reflecting: String(describing: k))):\(String(reflecting: String(describing: v)))" }).joined(separator: " "))")
        if !data.isEmpty {
            Self.logger.dbg("HTTP response_body \(method) \(String(reflecting: req.url!.relativeString)) body=\(String(reflecting: (String(data: data, encoding: .utf8)!)))")
        }
        //Self.logger.dbg("HTTPCookieStorage.shared.cookies is \(String(reflecting: HTTPCookieStorage.shared.cookies))")
        do {
            switch resp.statusCode {
            case 200...299:
                return (resp, data)
            case 403, 422:
                let string = String(String(data: data, encoding: .utf8)?.prefix(1000) ?? "")
                throw ApplinError.userError(string)
            case 400...499:
                let string = String(String(data: data, encoding: .utf8)?.prefix(1000) ?? "")
                throw ApplinError.appError(string)
            case 503:
                throw ApplinError.serverError("Server overloaded. Please try again.")
            case 500...599:
                throw ApplinError.serverError("server returned error for \(req.url!.relativeString) : \(resp.statusCode) "
                        + "\(HTTPURLResponse.localizedString(forStatusCode: resp.statusCode))")
            default:
                throw ApplinError.serverError("server returned unexpected response for \(req.url!.relativeString) : \(resp.statusCode) "
                        + "\(HTTPURLResponse.localizedString(forStatusCode: resp.statusCode))")
            }
        } catch let e as ApplinError {
            if interactive {
                self.varSet?.setInteractiveError(e)
                self.varSet?.setConnectionError(e)
            }
            throw e
        }
    }

    public enum CallMethod {
        case GET
        case POST

        func toString() -> String {
            switch self {
            case .GET:
                return "GET"
            case .POST:
                return "POST"
            }
        }
    }

    func call(
            _ method: CallMethod,
            url: String,
            varNamesAndValues: [(String, Var)],
            interactive: Bool
    ) async throws -> PageUpdate? {
        let relativeUrl = try self.config.relativeUrl(url: url)
        var urlRequest = URLRequest(
                url: relativeUrl,
                cachePolicy: .reloadIgnoringLocalAndRemoteCacheData
        )
        urlRequest.httpMethod = method.toString()
        if method == .POST {
            let vars: [(String, JSON)] = varNamesAndValues.map({ (name, value) in (name, value.toJson()) })
            let jsonBody: [String: JSON] = vars.toDictionary()
            let body = try encodeJson(jsonBody)
            urlRequest.httpBody = body
            urlRequest.addValue("application/json", forHTTPHeaderField: "content-type")
        }
        // NOTE: Rpc POST requests must include the `accept` header so Rails backends can bypass the built-in CSRF checks.
        // TODO: Test that rpc requests include the `Accept` header.
        urlRequest.addValue("application/vnd.applin_response", forHTTPHeaderField: "accept")
        let (httpResponse, data) = try await self.doRequest(urlRequest, interactive: interactive)
        let contentTypeBase = httpResponse.contentTypeBase()
        if data.isEmpty {
            return nil
        }
        do {
            if contentTypeBase != "application/vnd.applin_response" {
                throw "content-type is not 'application/vnd.applin_response': \(String(reflecting: contentTypeBase ?? ""))"
            }

            struct ApplinResponse: Codable {
                let page: JsonItem
            }

            let response: ApplinResponse = try decodeJson(data)
            let pageSpec: PageSpec = try PageSpec(self.config, response.page)
            return PageUpdate(data, pageSpec)
        } catch {
            throw ApplinError.serverError("error processing server response: \(error)")
        }
    }

    func poll(url: String, varNamesAndValues: [(String, Var)], interactive: Bool) async throws -> PageUpdate {
        let method: CallMethod = varNamesAndValues.isEmpty ? .GET : .POST
        let optUpdate = try await self.call(
                method,
                url: url,
                varNamesAndValues: varNamesAndValues,
                interactive: interactive
        )
        guard let update = optUpdate else {
            throw ApplinError.serverError("server returned empty result for page '\(url)")
        }
        return update
    }

    func upload(url: String, uploadBody: UploadBody) async throws {
        let url = try self.config.relativeUrl(url: url)
        var urlRequest = URLRequest(
                url: url,
                cachePolicy: .reloadIgnoringLocalAndRemoteCacheData
        )
        urlRequest.httpMethod = "PUT"
        urlRequest.httpBody = uploadBody.data
        urlRequest.addValue(uploadBody.contentType, forHTTPHeaderField: "Content-Type")
        let _ = try await self.doRequest(urlRequest, interactive: true)
    }
}
