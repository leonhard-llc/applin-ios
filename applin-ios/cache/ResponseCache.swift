import Foundation
import OSLog

struct ResponseInfo: Codable {
    let absoluteUrl: String
    let eTag: String
    let deleteTime: UInt64
    let refreshTime: UInt64
}

class CachedResponse {
    let infoFilePath: String
    let dataFilePath: String
    let absoluteUrl: String
    let eTag: String
    let deleteTime: UInt64
    let refreshTime: UInt64

    init(
            infoFilePath: String,
            dataFilePath: String,
            absoluteUrl: String,
            eTag: String,
            deleteTime: UInt64,
            refreshTime: UInt64
    ) {
        self.infoFilePath = infoFilePath
        self.dataFilePath = dataFilePath
        self.absoluteUrl = absoluteUrl
        self.eTag = eTag
        self.deleteTime = deleteTime
        self.refreshTime = refreshTime
    }
}

class ResponseCache {
    private static let FILENAME_PREFIX = "ResponseCache."
    private static let INFO_SUFFIX = ".info"
    private static let DATA_SUFFIX = ".data"
    private static let logger = Logger(subsystem: "Applin", category: "ResponseCache")

    private static func removeFile(path: String) throws {
        do {
            try FileManager.default.removeItem(atPath: path)
            Self.logger.info("removed file: \(path)")
        } catch {
            throw "error removing file '\(path)': \(error)"
        }
    }

    private static func writeFile(path: String, _ data: Data) throws {
        do {
            try data.write(to: URL(fileURLWithPath: path))
            Self.logger.info("wrote \(data.count) bytes to file: \(path)")
        } catch {
            throw "error writing \(data.count) bytes to file '\(path)': \(error)"
        }
    }

    private let config: ApplinConfig
    private let dirPath: String
    private var urlToResponse: [String: CachedResponse]

    init(_ config: ApplinConfig, dirPath: String) throws {
        self.config = config
        self.dirPath = dirPath
        Self.logger.info("dataDirPath=\(self.dirPath)")
        let cacheFiles: Set<String>
        do {
            cacheFiles = Set(try FileManager.default
                    .contentsOfDirectory(atPath: self.dirPath)
                    .filter({ path in path.components(separatedBy: "/").last?.starts(with: Self.FILENAME_PREFIX) ?? false })
            )
        } catch {
            throw "error listing directory '\(self.dirPath)': \(error)"
        }
        let filePairs: [(String, String)] = cacheFiles.compactMap({ path in
            if !path.hasSuffix(Self.INFO_SUFFIX) {
                return nil
            }
            let dataPath = path.removeSuffix(Self.INFO_SUFFIX) + Self.DATA_SUFFIX
            if !cacheFiles.contains(dataPath) {
                return nil
            }
            return (path, dataPath)
        })
        let responses: [CachedResponse] = filePairs.compactMap({ (infoPath, dataPath) in
            let bytes: Data
            do {
                bytes = try Data(contentsOf: URL(fileURLWithPath: infoPath))
            } catch {
                Self.logger.error("error reading info file '\(infoPath)': \(error)")
                return nil
            }
            let content: ResponseInfo
            do {
                content = try decodeJson(bytes)
            } catch {
                Self.logger.error("error decoding info file '\(infoPath)': \(error)")
                return nil
            }
            // TODO: Delete files while app is running, not just during startup.
            if content.deleteTime < Date.now.secondsSinceEpoch() {
                return nil
            }
            return CachedResponse(
                    infoFilePath: infoPath,
                    dataFilePath: dataPath,
                    absoluteUrl: content.absoluteUrl,
                    eTag: content.eTag,
                    deleteTime: content.deleteTime,
                    refreshTime: content.refreshTime
            )
        })
        let pathsToKeep = Set(responses.flatMap({ r in [r.infoFilePath, r.dataFilePath] }))
        for path in cacheFiles {
            if !pathsToKeep.contains(path) {
                do {
                    try Self.removeFile(path: path)
                } catch {
                    Self.logger.error("\(error)")
                }
            }
        }
        self.urlToResponse = Dictionary(uniqueKeysWithValues: responses.map({ r in (r.absoluteUrl, r) }))
    }

    func remove(url: String) {
        if let cachedResponse = self.urlToResponse.removeValue(forKey: url) {
            do {
                try Self.removeFile(path: cachedResponse.infoFilePath)
                try Self.removeFile(path: cachedResponse.dataFilePath)
            } catch {
                Self.logger.error("\(error)")
            }
        }
    }

    func add(_ info: ResponseInfo, _ data: Data) {
        do {
            self.remove(url: info.absoluteUrl)
            let randomInt = UInt64.random(in: 1...UInt64.max)
            let randomCode = String(randomInt, radix: 16, uppercase: true)
            let pathPrefix = "\(self.dirPath)/\(Self.FILENAME_PREFIX)\(randomCode)"
            let infoFilePath = "\(pathPrefix)\(Self.INFO_SUFFIX)"
            let dataFilePath = "\(pathPrefix)\(Self.DATA_SUFFIX)"
            let bytes: Data
            bytes = try encodeJson(info)
            try Self.writeFile(path: infoFilePath, bytes)
            try Self.writeFile(path: dataFilePath, data)
            let cachedResponse = CachedResponse(
                    infoFilePath: infoFilePath,
                    dataFilePath: dataFilePath,
                    absoluteUrl: info.absoluteUrl,
                    eTag: info.eTag,
                    deleteTime: info.deleteTime,
                    refreshTime: info.refreshTime
            )
            self.urlToResponse[info.absoluteUrl] = cachedResponse
        } catch {
            Self.logger.error("\(error)")
        }
    }

    func get(url: String) -> ResponseInfo? {
        if let cachedResponse = self.urlToResponse[url] {
            if cachedResponse.deleteTime < Date.now.secondsSinceEpoch() {
                return nil
            }
            return ResponseInfo(
                    absoluteUrl: cachedResponse.absoluteUrl,
                    eTag: cachedResponse.eTag,
                    deleteTime: cachedResponse.deleteTime,
                    refreshTime: cachedResponse.refreshTime
            )
        } else {
            return nil
        }
    }

    func getSpec(pageKey: String) async -> PageSpec? {
        let url = self.config.url.appendingPathComponent(pageKey).absoluteString
        guard let cachedResponse = self.urlToResponse[url] else {
            return nil
        }
        if cachedResponse.deleteTime < Date.now.secondsSinceEpoch() {
            return nil
        }
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: cachedResponse.dataFilePath))
            let jsonItem: JsonItem = try decodeJson(data)
            return try PageSpec(self.config, pageKey: pageKey, jsonItem)
        } catch {
            Self.logger.error("error reading spec from file '\(cachedResponse.dataFilePath)': \(error)")
            return nil
        }
    }

    func urls() -> [String] {
        Array(self.urlToResponse.keys)
    }
}
