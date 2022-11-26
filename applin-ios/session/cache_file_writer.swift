import Foundation

struct CacheFileContents: Codable {
    var boolVars: [String: Bool]?
    var stringVars: [String: String]?
    var pages: [String: JsonItem]?
    var stack: [String]?
}

func readCacheFile(dataDirPath: String, _ session: ApplinSession) async {
    print("readCacheFile")
    let path = dataDirPath + "/" + CacheFileWriter.cacheFileName
    if !(await fileExists(path: path)) {
        print("cache not found")
        return
    }
    let bytes: Data
    do {
        bytes = try await readFile(path: path)
    } catch {
        print("error reading cache: \(error)")
        return
    }
    //print("cache file contents: ")
    //FileHandle.standardOutput.write(bytes)
    //print("")
    let contents: CacheFileContents
    do {
        contents = try decodeJson(bytes)
    } catch {
        print("error decoding cache: \(error)")
        return
    }
    for (name, value) in contents.boolVars ?? [:] {
        session.vars[name] = .boolean(value)
    }
    for (name, value) in contents.stringVars ?? [:] {
        session.vars[name] = .string(value)
    }
    for (key, item) in contents.pages ?? [:] {
        do {
            session.pages[key] = try PageData(session, pageKey: key, item)
        } catch {
            print("error loading cached key '\(key)': \(error)")
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
        // print("CacheFileWriter \(dataDirPath)")
    }

    func writeCacheFile(_ session: ApplinSession) async throws {
        print("write cache")
        var contents = CacheFileContents()
        contents.boolVars = session.vars.compactMapValues({ v in
            if case let .boolean(value) = v {
                return value
            } else {
                return nil
            }
        })
        contents.stringVars = session.vars.compactMapValues({ v in
            if case let .string(value) = v {
                return value
            } else {
                return nil
            }
        })
        contents.pages = session.pages.mapValues({ page in page.toJsonItem() })
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
                    print("error writing cache: \(error)")
                    await sleep(ms: 60_000)
                }
            }
        }
    }

    public func stop() {
        self.writeTime = .distantPast
    }
}
