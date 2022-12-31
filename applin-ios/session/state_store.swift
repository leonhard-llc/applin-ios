import Foundation

class StateStore {
    struct FileContents: Codable {
        var boolVars: [String: Bool]?
        var stringVars: [String: String]?
        var pages: [String: JsonItem]?
        var stack: [String]?

        func toApplinState(_ config: ApplinConfig, throwOnPageError: Bool) throws -> ApplinState {
            var vars: [String: Var] = [:]
            for (name, value) in self.boolVars ?? [:] {
                vars[name] = .boolean(value)
            }
            for (name, value) in self.stringVars ?? [:] {
                vars[name] = .string(value)
            }
            var pages: [String: PageSpec] = [:]
            for (key, item) in self.pages ?? [:] {
                do {
                    pages[key] = try PageSpec(config, pageKey: key, item)
                } catch {
                    if throwOnPageError {
                        throw "error in page '\(key)': \(error)"
                    } else {
                        print("WARNING: error in page '\(key)': \(error)")
                    }
                }
            }
            let stack = self.stack ?? ["/"]
            return ApplinState(pages: pages, stack: stack, vars: vars)
        }
    }

    static let FILE_NAME = "state.json"

    public static func loadDefaultJson(_ config: ApplinConfig) async throws -> ApplinState {
        let bytes = try await readBundleFile(filepath: "default.json")
        let contents: FileContents
        do {
            contents = try decodeJson(bytes)
        } catch {
            throw ApplinError.appError("error decoding 'default.json': \(error)")
        }
        do {
            return try contents.toApplinState(config, throwOnPageError: true)
        } catch {
            throw "error in 'default.json': \(error)"
        }
    }

    public static func loadSavedState(_ config: ApplinConfig) async -> ApplinState? {
        let path = config.dataDirPath + "/" + StateStore.FILE_NAME
        // Swift's standard library provides no documented way to tell if a file read error is due to file not found.
        // So we check for file existence separately.
        if !(await fileExists(path: path)) {
            print("StateStore: state file not found: \(path)")
            return nil
        }
        let bytes: Data
        do {
            bytes = try await readFile(path: path)
        } catch {
            print("ERROR: \(error)")
            return nil
        }
        //print("state file contents: ")
        //FileHandle.standardOutput.write(bytes)
        //print("")
        let contents: FileContents
        do {
            contents = try decodeJson(bytes)
        } catch {
            print("ERROR: error decoding state file '\(path)': \(error)")
            return nil
        }
        do {
            return try contents.toApplinState(config, throwOnPageError: false)
        } catch {
            print("unreachable")
            return nil
        }
    }

    private let config: ApplinConfig
    private let lock = NSLock()
    private var state: ApplinState
    private var writesAllowed = false
    private var writeLoopTask: Task<Void, Never>?
    private var optEarliestWriteTime: Date?

    public init(_ config: ApplinConfig, _ state: ApplinState) {
        print("StateStore")
        self.config = config
        self.state = state
    }

    public func allowWrites() {
        self.lock.lock()
        self.writesAllowed = true
        self.lock.unlock()
    }

    private func writeOnce(_ stateToWrite: ApplinState) async throws {
        print("StateStore.writeOnce")
        let boolVars: [String: Bool] = stateToWrite.vars.compactMapValues({ v in
            if case let .boolean(value) = v {
                return value
            } else {
                return nil
            }
        })
        let stringVars: [String: String] = stateToWrite.vars.compactMapValues({ v in
            if case let .string(value) = v {
                return value
            } else {
                return nil
            }
        })
        let pages = stateToWrite.pages.mapValues({ page in page.toJsonItem() })
        let stack = stateToWrite.stack
        let contents = FileContents(boolVars: boolVars, stringVars: stringVars, pages: pages, stack: stack)
        let bytes = try encodeJson(contents)
        // TODO: Keep hash of file contents and don't write if file contents won't change.
        try await createDir(self.config.dataDirPath)
        let path = self.config.dataDirPath + "/" + Self.FILE_NAME
        let tmpPath = path + ".tmp"
        try await deleteFile(path: tmpPath)
        try await writeFile(data: bytes, path: tmpPath)
        // Swift has no atomic file replace function.
        try await deleteFile(path: path)
        try await moveFile(atPath: tmpPath, toPath: path)
    }

    private func writeLoop() async {
        print("StateStore.writeLoop")
        // TODO: Move the defer into the calling Task closure once https://github.com/apple/swift/issues/58921 is fixed.
        defer {
            self.lock.lock()
            self.writeLoopTask = nil
            self.lock.unlock()
        }
        while !Task.isCancelled {
            while true {
                if Task.isCancelled {
                    print("StateStore.writeLoop cancelled")
                    break
                } else if let earliestWriteTime = self.optEarliestWriteTime, earliestWriteTime < Date() {
                    print("StateStore.writeLoop writing")
                    break
                } else {
                    await sleep(ms: 1_000)
                }
            }
            while true {
                self.lock.lock()
                let stateToWrite = self.state
                self.optEarliestWriteTime = nil
                let writesAllowed = self.writesAllowed
                self.lock.unlock()

                if !writesAllowed {
                    print("StateStore: writes not allowed")
                    if Task.isCancelled {
                        break
                    } else {
                        await sleep(ms: 1_000)
                        continue
                    }
                }
                do {
                    try await self.writeOnce(stateToWrite)
                    break
                } catch {
                    print("ERROR StateStore: \(error)")
                    // TODO: Update session error.
                    if Task.isCancelled {
                        await sleep(ms: 1_000)
                    } else {
                        await sleep(ms: 60_000)
                    }
                }
            }
        }
        print("StateStore.writeLoop stopping")
    }

    public func startWriterTask() {
        print("StateStore.startWriterTask")
        self.lock.lock()
        defer {
            self.lock.unlock()
        }
        if self.writeLoopTask == nil {
            self.writeLoopTask = Task(priority: .low) {
                await self.writeLoop()
            }
        }
    }

    public func stopWriterTask() {
        print("StateStore.stopWriterTask")
        self.lock.lock()
        defer {
            self.lock.unlock()
        }
        self.writeLoopTask?.cancel() // Makes sleep return immediately.
    }

    public func read<R>(_ f: (_: ApplinState) -> R) -> R {
        print("StateStore.read")
        self.lock.lock()
        defer {
            self.lock.unlock()
        }
        let result: R = f(self.state)

        return result
    }

    public func update<R>(_ f: (_: inout ApplinState) -> R) -> R {
        print("StateStore.update")
        self.lock.lock()
        defer {
            self.lock.unlock()
        }
        let result: R = f(&self.state)
        if self.writesAllowed {
            self.optEarliestWriteTime = self.optEarliestWriteTime ?? (Date() + 10.0 /* seconds */)
        }
        return result
    }
}
