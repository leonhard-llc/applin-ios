import Foundation
import OSLog

class ResponseInfo {
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
    struct InfoFileContent: Codable {
        let absoluteUrl: String
        let eTag: String
        let deleteTime: UInt64
        let refreshTime: UInt64
    }

    static let FILENAME_PREFIX = "ResponseCache."
    static let INFO_SUFFIX = ".info"
    static let DATA_SUFFIX = ".data"
    static let logger = Logger(subsystem: "Applin", category: "ResponseCache")
    let dirPath: String
    var urlToInfo: [String: ResponseInfo]

    init(dirPath: String) throws {
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
        let infos: [ResponseInfo] = filePairs.compactMap({ (infoPath, dataPath) in
            let bytes: Data
            do {
                bytes = try Data(contentsOf: URL(fileURLWithPath: infoPath))
            } catch {
                Self.logger.error("error reading info file '\(infoPath)': \(error)")
                return nil
            }
            let content: InfoFileContent
            do {
                content = try decodeJson(bytes)
            } catch {
                Self.logger.error("error decoding info file '\(infoPath)': \(error)")
                return nil
            }
            return ResponseInfo(
                    infoFilePath: infoPath,
                    dataFilePath: dataPath,
                    absoluteUrl: content.absoluteUrl,
                    eTag: content.eTag,
                    deleteTime: content.deleteTime,
                    refreshTime: content.refreshTime
            )
        })
        let pathsToKeep = Set(infos.flatMap({ info in [info.infoFilePath, info.dataFilePath] }))
        for path in cacheFiles {
            if !pathsToKeep.contains(path) {
                do {
                    try FileManager.default.removeItem(atPath: path)
                    Self.logger.info("removed file: \(path)")
                } catch {
                    Self.logger.error("error removing file '\(path)': \(error)")
                }
            }
        }
        self.urlToInfo = Dictionary(uniqueKeysWithValues: infos.map({ info in (info.absoluteUrl, info) }))
    }
}
