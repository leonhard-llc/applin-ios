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
        let before = Date.now
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
            throw ApplinError.networkError("error talking to server at \(req.url!.absoluteString) elapsed_sec=\(before.distance(to: Date.now)): \(error)")
        }
        Self.logger.info("HTTP response \(method) \(String(reflecting: req.url!.relativeString)) status=\(resp.statusCode) bodyLen=\(data.count) contentType='\(resp.value(forHTTPHeaderField: "content-type"))' elapsed_sec=\(before.distance(to: Date.now))")
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
                let string = String(data: data, encoding: .utf8)?.prefixString(len: 1000).emptyToNil() ??
                        "server returned: \(resp.statusCode) \(HTTPURLResponse.localizedString(forStatusCode: resp.statusCode))"
                throw ApplinError.userError(string)
            case 400...499:
                let string = String(data: data, encoding: .utf8)?.prefixString(len: 1000).emptyToNil() ??
                        "server returned: \(resp.statusCode) \(HTTPURLResponse.localizedString(forStatusCode: resp.statusCode))"
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
            _ url: URL,
            varNamesAndValues: [(String, Var)],
            interactive: Bool
    ) async throws -> PageUpdate? {
        var urlRequest = URLRequest(
                url: url,
                cachePolicy: .reloadIgnoringLocalAndRemoteCacheData
        )
        urlRequest.httpMethod = method.toString()
        if method == .POST {
            var jsonBody: [String: JSON] = [:]
            for (name, value) in varNamesAndValues {
                func split(_ name: String, sep: Character) throws -> (String, String) {
                    let parts = name.split(maxSplits: 2, whereSeparator: { c in c == sep })
                    guard let part0 = parts.get(0),
                          let part1 = parts.get(1)
                    else {
                        throw ApplinError.appError("invalid var_name: \(String(reflecting: name))")
                    }
                    return (String(part0), String(part1))
                }

                func nameConflict(varNamesAndValues: [(String, Var)]) throws {
                    throw ApplinError.appError("multiple vars resolve to name \(String(reflecting: name)): \(String(reflecting: varNamesAndValues.map({ (name, _) in name })))")
                }

                if name.contains("%") {
                    // var_name "ids%123" -> {"ids":["123"]}
                    let (arrayName, arrayValue) = try split(name, sep: "%")
                    switch jsonBody[arrayName] {
                    case var .array(array):
                        array.append(JSON.string(arrayValue))
                        jsonBody[arrayName] = .array(array)
                    case nil:
                        jsonBody[arrayName] = .array([JSON.string(arrayValue)])
                    default:
                        try nameConflict(varNamesAndValues: varNamesAndValues)
                    }
                } else if name.contains("#") {
                    // var_name="ids#123" value=true -> {"ids":{"123":true}}
                    let (objName, key) = try split(name, sep: "#")
                    switch jsonBody[objName] {
                    case var .object(obj):
                        obj[key] = value.toJson()
                        jsonBody[objName] = .object(obj)
                    case nil:
                        jsonBody[objName] = .object([key: value.toJson()])
                    default:
                        try nameConflict(varNamesAndValues: varNamesAndValues)
                    }
                } else {
                    // var_name="id" value="123" -> {"id":"123"}
                    if jsonBody[name] != nil {
                        try nameConflict(varNamesAndValues: varNamesAndValues)
                    }
                    jsonBody[name] = value.toJson()
                }
            }
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

    func poll(pageKey: String, varNamesAndValues: [(String, Var)], interactive: Bool) async throws -> PageUpdate {
        let relativeUrl = try self.config.relativeUrl(url: pageKey)
        let method: CallMethod = varNamesAndValues.isEmpty ? .GET : .POST
        let optUpdate = try await self.call(
                method,
                relativeUrl,
                varNamesAndValues: varNamesAndValues,
                interactive: interactive
        )
        guard let update = optUpdate else {
            throw ApplinError.serverError("server returned empty result for page '\(pageKey)")
        }
        return update
    }

    func upload(url: URL, uploadBody: UploadBody) async throws {
        var urlRequest = URLRequest(
                url: url,
                cachePolicy: .reloadIgnoringLocalAndRemoteCacheData
        )
        urlRequest.httpMethod = "PUT"
        urlRequest.httpBody = uploadBody.data
        urlRequest.addValue(uploadBody.contentType, forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("100-continue", forHTTPHeaderField: "Expect")
        urlRequest.timeoutInterval = 3600
        let _ = try await self.doRequest(urlRequest, interactive: true)
    }
}
