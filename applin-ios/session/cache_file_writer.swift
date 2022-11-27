import Foundation

// TODO: Rename file to state_file.swift.

struct CacheFileContents: Codable {
    var boolVars: [String: Bool]?
    var stringVars: [String: String]?
    var pages: [String: JsonItem]?
    var stack: [String]?
}

private func readDefaultJson() async throws -> CacheFileContents {
    let bytes: Data
    do {
        bytes = try await readBundleFile(filename: "default.json")
    } catch {
        throw "error reading 'default.json': \(error)"
    }
    do {
        return try decodeJson(bytes)
    } catch {
        throw "error decoding 'default.json': \(error)"
    }
}

private func readCacheFile(_ path: String) async -> CacheFileContents {
    // Swift's standard library provides no documented way to tell if a file read error is due to file not found.
    // So we check for file existence separately.
    if !(await fileExists(path: path)) {
        print("cache not found: \(path)")
        return CacheFileContents()
    }
    let bytes: Data
    do {
        bytes = try await readFile(path: path)
    } catch {
        print("error reading cache '\(path)': \(error)")
        return CacheFileContents()
    }
    //print("cache file contents: ")
    //FileHandle.standardOutput.write(bytes)
    //print("")
    do {
        return try decodeJson(bytes)
    } catch {
        print("error decoding cache '\(path)': \(error)")
        return CacheFileContents()
    }
}

func readCacheFile(_ config: ApplinConfig, dataDirPath: String) async throws -> ApplinState {
    print("readCacheFile")
    let defaultJson = try await readDefaultJson()
    let cacheFilePath = dataDirPath + "/" + CacheFileWriter.cacheFileName
    let cache = await readCacheFile(cacheFilePath)
    var vars: [String: Var] = [:]
    for (name, value) in defaultJson.boolVars ?? [:] {
        vars[name] = .boolean(value)
    }
    for (name, value) in defaultJson.stringVars ?? [:] {
        vars[name] = .string(value)
    }
    for (name, value) in cache.boolVars ?? [:] {
        vars[name] = .boolean(value)
    }
    for (name, value) in cache.stringVars ?? [:] {
        vars[name] = .string(value)
    }
    var pages: [String: PageSpec] = [:]
    for (key, item) in defaultJson.pages ?? [:] {
        do {
            pages[key] = try PageSpec(config, pageKey: key, item)
        } catch {
            throw "error in default page '\(key)': \(error)"
        }
    }
    for (key, item) in cache.pages ?? [:] {
        do {
            pages[key] = try PageSpec(config, pageKey: key, item)
        } catch {
            print("error loading cached key '\(key)': \(error)")
        }
    }
    let stack = cache.stack ?? defaultJson.stack ?? ["/"]
    return ApplinState(pages: pages, stack: stack, vars: vars)
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

    func writeOnce(_ session: ApplinSession) async throws {
        print("write cache")
        try createDir(self.dataDirPath)
        var contents = CacheFileContents()
        contents.boolVars = session.state.vars.compactMapValues({ v in
            if case let .boolean(value) = v {
                return value
            } else {
                return nil
            }
        })
        contents.stringVars = session.state.vars.compactMapValues({ v in
            if case let .string(value) = v {
                return value
            } else {
                return nil
            }
        })
        contents.pages = session.state.pages.mapValues({ page in page.toJsonItem() })
        contents.stack = session.state.stack
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
                try await self.writeOnce(session)
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

    // TODO: Take ApplinState as argument, not session, and cancel any pending waiter.

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
