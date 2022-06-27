import Foundation

struct CacheFileContents: Codable {
    var pages: [String: JsonItem]?
    var stack: [String]?
}

func readCacheFile(dataDirPath: String, _ session: ApplinSession) async {
    let path = dataDirPath + "/" + CacheFileWriter.cacheFileName
    print("CacheFile read \(path)")
    let bytes: Data
    do {
        bytes = try await readFile(path: path)
    } catch {
        print("CacheFile error reading \(path): \(error)")
        return
    }
    let contents: CacheFileContents
    do {
        contents = try decodeJson(bytes)
    } catch {
        print("CacheFile error decoding \(path): \(error)")
        return
    }
    for (key, item) in contents.pages ?? [:] {
        do {
            session.pages[key] = try PageData(item, session)
        } catch {
            print("CacheFile error loading cached key '\(key)': \(error)")
        }
    }
    session.setStack(contents.stack ?? [])
}

class CacheFileWriter {
    static let cacheFileName = "cache.json"

    private let dataDirPath: String
    private var writeTime: Date = .distantPast
    private var writerWaiting: Bool = false
    private var writerRunning: Bool = false

    public init(dataDirPath: String) {
        self.dataDirPath = dataDirPath
        print("CacheFileWriter \(dataDirPath)")
    }

    func writeCacheFile(_ session: ApplinSession) async throws {
        print("CacheFileWriter write")
        var contents = CacheFileContents()
        contents.pages = session.pages.mapValues({ page in page.inner().toJsonItem() })
        contents.stack = session.stack
        let bytes = try encodeJson(contents)
        let path = dataDirPath + "/" + CacheFileWriter.cacheFileName
        let tmpPath = path + ".tmp"
        try await deleteFile(path: tmpPath)
        try await writeFile(data: bytes, path: tmpPath)
        // Swift has no atomic file replace function.
        try await deleteFile(path: path)
        try await moveFile(atPath: tmpPath, toPath: path)
    }

    public func scheduleWrite(_ session: ApplinSession) {
        if self.writerWaiting {
            return
        }
        self.writerWaiting = true
        Task(priority: .low) {
            self.writeTime = Date() + 10.0 /* seconds */
            while self.writerRunning || Date() < writeTime {
                await sleep(ms: 1_000)
            }
            self.writerRunning = true
            defer {
                self.writerRunning = false
            }
            self.writerWaiting = false
            while !Task.isCancelled {
                do {
                    try await self.writeCacheFile(session)
                    return
                } catch {
                    print("CacheFileWriter write error: \(error)")
                    await sleep(ms: 60_000)
                }
            }
        }
    }

    public func stop() {
        self.writeTime = .distantPast
    }
}
