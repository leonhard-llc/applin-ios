import Foundation
import OSLog

class PageUpdate {
    let data: Data
    let responseInfo: ResponseInfo?
    let spec: PageSpec

    init(_ data: Data, _ responseInfo: ResponseInfo?, _ spec: PageSpec) {
        self.data = data
        self.responseInfo = responseInfo
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

    private struct UserError: Codable {
        var message: String
    }

    private let config: ApplinConfig
    private let urlSession: URLSession
    private weak var cache: ResponseCache?
    private weak var pageStack: PageStack?
    private weak var varSet: VarSet?

    public init(_ config: ApplinConfig, _ cache: ResponseCache?, _ pageStack: PageStack?, _ varSet: VarSet?) {
        self.config = config
        let urlSessionConfig = URLSessionConfiguration.default
        urlSessionConfig.timeoutIntervalForRequest = 10.0 /* seconds */
        urlSessionConfig.timeoutIntervalForResource = 60.0 /* seconds */
        urlSessionConfig.urlCache = nil
        urlSessionConfig.httpCookieAcceptPolicy = .always
        urlSessionConfig.httpShouldSetCookies = true
        self.urlSession = URLSession(configuration: urlSessionConfig)
        self.cache = cache
        self.pageStack = pageStack
        self.varSet = varSet
    }

    deinit {
        self.urlSession.invalidateAndCancel()
    }

    private func doRequest(path: String, _ urlRequest: URLRequest) async throws -> (HTTPURLResponse, Data) {
        let data: Data
        let httpResponse: HTTPURLResponse
        do {
            let (urlData, urlResponse) = try await self.urlSession.data(for: urlRequest)
            data = urlData
            httpResponse = urlResponse as! HTTPURLResponse
        } catch {
            throw ApplinError.networkError("error talking to server at \(urlRequest.url?.absoluteString ?? "") : \(error)")
        }
        if !(200...299).contains(httpResponse.statusCode) {
            if httpResponse.contentTypeBase() == "application/json", let userError: UserError = try? decodeJson(data) {
                throw ApplinError.userError(userError.message)
            } else if httpResponse.contentTypeBase() == "text/plain", let string = String(data: data, encoding: .utf8) {
                throw ApplinError.serverError("server returned error for \(path) : \(httpResponse.statusCode) "
                        + "\(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)) \"\(string)\"")
            } else {
                throw ApplinError.serverError("server returned error for \(path) : \(httpResponse.statusCode) "
                        + "\(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)), "
                        + "len=\(data.count) \(httpResponse.mimeType ?? "")")
            }
        }
        return (httpResponse, data)
    }

    func call(path: String, varNamesAndValues: [(String, Var)]) async throws -> PageUpdate? {
        let url = self.config.url.appendingPathComponent(path.removePrefix("/"))
        var urlRequest = URLRequest(
                url: url,
                cachePolicy: .reloadIgnoringLocalAndRemoteCacheData
        )
        if varNamesAndValues.isEmpty {
            urlRequest.httpMethod = "GET"
            Self.logger.info("GET \(String(describing: path))")
        } else {
            urlRequest.httpMethod = "POST"
            let vars: [(String, JSON)] = varNamesAndValues.map({ (name, value) in (name, value.toJson()) })
            let jsonBody: [String: JSON] = Dictionary(uniqueKeysWithValues: vars)
            let body = try encodeJson(jsonBody)
            urlRequest.httpBody = body
            urlRequest.addValue("application/json", forHTTPHeaderField: "content-type")
            Self.logger.info("POST \(String(describing: path))")
            Self.logger.debug("POST \(String(describing: path)) request body=\(String(describing: body))")
        }
        let (httpResponse, data) = try await self.doRequest(path: path, urlRequest)
        let contentTypeBase = httpResponse.contentTypeBase()
        Self.logger.info("\(urlRequest.httpMethod!) \(String(describing: path)) response status=\(httpResponse.statusCode) bodyLen=\(data.count) bodyType='\(contentTypeBase ?? "")'")
        if data.isEmpty {
            return nil
        }
        Self.logger.debug("\(urlRequest.httpMethod!) \(String(describing: path)) response status=\(httpResponse.statusCode) body=\(String(describing: data))")
        do {
            if contentTypeBase != "application/json" {
                throw "content-type is not 'application/json': \(String(describing: contentTypeBase ?? ""))"
            }
            let eTag = try httpResponse.eTagHeader()
            let date = try httpResponse.dateHeader()
            let optMaxAgeSeconds = httpResponse.maxAgeHeader()
            let optStaleIfErrorSeconds = httpResponse.staleIfErrorHeader()
            let jsonItem: JsonItem = try decodeJson(data)
            let pageSpec: PageSpec = try PageSpec(self.config, pageKey: path, jsonItem)
            let responseInfo: ResponseInfo?
            if let maxAgeSeconds = optMaxAgeSeconds {
                responseInfo = ResponseInfo(
                        absoluteUrl: url.absoluteString,
                        eTag: eTag,
                        deleteTime: date.secondsSinceEpoch() + maxAgeSeconds,
                        refreshTime: date.secondsSinceEpoch() + (optStaleIfErrorSeconds ?? maxAgeSeconds)
                )
            } else {
                responseInfo = nil
            }
            return PageUpdate(data, responseInfo, pageSpec)
        } catch {
            throw ApplinError.serverError("error processing server response: \(error)")
        }
    }

    func upload(path: String, uploadBody: UploadBody) async throws {
        let url = self.config.url.appendingPathComponent(path.removePrefix("/"))
        var urlRequest = URLRequest(
                url: url,
                cachePolicy: .reloadIgnoringLocalAndRemoteCacheData
        )
        urlRequest.httpMethod = "PUT"
        urlRequest.httpBody = uploadBody.data
        urlRequest.addValue(uploadBody.contentType, forHTTPHeaderField: "Content-Type")
        Self.logger.info("PUT \(String(describing: path)) request bodyLen=\(uploadBody.data.count) contentType='\(uploadBody.contentType)'")
        let (httpResponse, data) = try await self.doRequest(path: path, urlRequest)
        let contentTypeBase = httpResponse.contentTypeBase()
        Self.logger.info("PUT \(String(describing: path)) response status=\(httpResponse.statusCode) bodyLen=\(data.count) contentType='\(contentTypeBase ?? "")'")
        Self.logger.debug("PUT \(String(describing: path)) response status=\(httpResponse.statusCode) body=\(String(describing: data))")
    }
}
