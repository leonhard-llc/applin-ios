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
            session.pages[key] = try PageSpec(session, pageKey: key, item)
        } catch {
            print("error loading cached key '\(key)': \(error)")
        }
    }
    session.setStack(contents.stack ?? [])
}

class CacheFileWriter {
    static let cacheFileName = "cache.json"

    private let dataDirPath: String
    @BackgroundActor private var waitTask: Task<Void, Error>?
    @BackgroundActor private var writeTask: Task<Void, Error>?

    public init(dataDirPath: String) {
        self.dataDirPath = dataDirPath
        // print("CacheFileWriter \(dataDirPath)")
    }

    func wroteOnce(_ session: ApplinSession) async throws {
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

    @BackgroundActor private func writeLoop(_ session: ApplinSession) async {
        // TODO: Move the defer into the calling Task closure once https://github.com/apple/swift/issues/58921 is fixed.
        defer {
            self.writeTask = nil
        }
        while !Task.isCancelled {
            do {
                try await self.wroteOnce(session)
                return
            } catch {
                print("CacheFileWriter error writing: \(error)")
                // TODO: Update session error.
                await sleep(ms: 60_000)
            }
        }
        print("CacheFileWriter.writeLoop task cancelled")
    }

    @BackgroundActor private func waitThenWrite(_ session: ApplinSession) async {
        defer {
            self.waitTask = nil
        }
        let waitDeadline = Date() + 10.0 /* seconds */
        while !Task.isCancelled && self.writeTask != nil {
            await sleep(ms: 1_000)
        }
        while !Task.isCancelled && Date() < waitDeadline {
            await sleep(ms: 1_000)
        }
        if Task.isCancelled {
            print("CacheFileWriter.waitThenWrite task cancelled")
            return
        }
        self.writeTask = Task(priority: .low) { @BackgroundActor in
            await self.writeLoop(session)
        }
    }

    nonisolated public func scheduleWrite(_ session: ApplinSession) {
        Task(priority: .low) { @BackgroundActor in
            if self.waitTask != nil {
                return
            }
            self.waitTask = Task(priority: .low) { @BackgroundActor in
                await self.waitThenWrite(session)
            }
        }
    }

    nonisolated public func stop() {
        Task(priority: .low) { @BackgroundActor in
            self.waitTask?.cancel()
            self.writeTask?.cancel()
        }
    }
}
