import Foundation

class StateStore {
    struct FileContents: Codable {
        var boolVars: [String: Bool]?
        var stringVars: [String: String]?
        var pages: [String: JsonItem]?
        var stack: [String]?
    }

    static let FILE_NAME = "state.json"

    private let config: ApplinConfig
    @BackgroundActor private var waitTask: Task<Void, Error>?
    @BackgroundActor private var writeTask: Task<Void, Error>?

    public init(_ config: ApplinConfig) {
        print("StateStore")
        self.config = config
    }

    private func readDefaultJson() async throws -> FileContents {
        let bytes = try await readBundleFile(filename: "default.json")
        do {
            return try decodeJson(bytes)
        } catch {
            throw ApplinError.deserializeError("error decoding bundle file 'default.json': \(error)")
        }
    }

    private func readStateFile(_ path: String) async -> FileContents? {
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
            print("StateStore: \(error)")
            return nil
        }
        //print("state file contents: ")
        //FileHandle.standardOutput.write(bytes)
        //print("")
        do {
            return try decodeJson(bytes)
        } catch {
            print("StateStore: error decoding state file '\(path)': \(error)")
            return nil
        }
    }

    func read() async throws -> ApplinState {
        print("StateStore.read")
        let defaultState = try await readDefaultJson()
        let stateFilePath = self.config.dataDirPath + "/" + StateStore.FILE_NAME
        let savedState = await readStateFile(stateFilePath) ?? FileContents()
        var vars: [String: Var] = [:]
        for (name, value) in defaultState.boolVars ?? [:] {
            vars[name] = .boolean(value)
        }
        for (name, value) in defaultState.stringVars ?? [:] {
            vars[name] = .string(value)
        }
        for (name, value) in savedState.boolVars ?? [:] {
            vars[name] = .boolean(value)
        }
        for (name, value) in savedState.stringVars ?? [:] {
            vars[name] = .string(value)
        }
        var pages: [String: PageSpec] = [:]
        for (key, item) in defaultState.pages ?? [:] {
            do {
                pages[key] = try PageSpec(config, pageKey: key, item)
            } catch {
                throw "StateStore: error in 'default.json' page '\(key)': \(error)"
            }
        }
        for (key, item) in savedState.pages ?? [:] {
            do {
                pages[key] = try PageSpec(config, pageKey: key, item)
            } catch {
                print("StateStore: error in stored page '\(key)': \(error)")
            }
        }
        let stack = savedState.stack ?? defaultState.stack ?? ["/"]
        return ApplinState(pages: pages, stack: stack, vars: vars)
    }

    func writeOnce(_ session: ApplinSession) async throws {
        print("StateStore.writeOnce")
        let boolVars: [String: Bool] = session.state.vars.compactMapValues({ v in
            if case let .boolean(value) = v {
                return value
            } else {
                return nil
            }
        })
        let stringVars: [String: String] = session.state.vars.compactMapValues({ v in
            if case let .string(value) = v {
                return value
            } else {
                return nil
            }
        })
        let pages = session.state.pages.mapValues({ page in page.toJsonItem() })
        let stack = session.state.stack
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
                print("StateStore.writeLoop: \(error)")
                // TODO: Update session error.
                await sleep(ms: 60_000)
            }
        }
        print("StateStore.writeLoop task cancelled")
    }

    @BackgroundActor private func waitThenWrite(_ session: ApplinSession) async {
        print("StateStore.waitThenWrite")
        defer {
            self.waitTask = nil
        }
        let waitDeadline = Date() + 10.0 /* seconds */
        while !Task.isCancelled && self.writeTask != nil {
            await sleep(ms: 1_000)
        }
        print("StateStore.waitThenWrite writeTask is available")
        while !Task.isCancelled && Date() < waitDeadline {
            await sleep(ms: 1_000)
        }
        if Task.isCancelled {
            print("StateStore.waitThenWrite task cancelled")
            return
        }
        self.writeTask = Task(priority: .low) { @BackgroundActor in
            await self.writeLoop(session)
        }
    }

    // TODO: Take ApplinState as argument, not session, and cancel any pending waiter.

    nonisolated public func scheduleWrite(_ session: ApplinSession) {
        print("StateStore.scheduleWrite")
        Task(priority: .low) { @BackgroundActor in
            if self.waitTask != nil {
                print("StateStore.scheduleWrite another task is already waiting")
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
