import Foundation

func stateFilePath(_ config: ApplinConfig) -> String {
    config.dataDirPath + "/state.json"
}

struct StateFileContents: Codable {
    var boolVars: [String: Bool]?
    var stringVars: [String: String]?
    var pages: [String: JsonItem]?
    var stack: [String]?
}

func loadStateFile(_ config: ApplinConfig) async throws -> ApplinState? {
    let path = stateFilePath(config)
    // Swift's standard library provides no documented way to tell if a file read error is due to file not found.
    // So we check for file existence separately.
    if !(await fileExists(path: path)) {
        return nil
    }
    let bytes: Data
    do {
        bytes = try Data(contentsOf: URL(fileURLWithPath: path))
    } catch {
        throw "error reading state file '\(path)': \(error)"
    }
    //print("state file contents: ")
    //FileHandle.standardOutput.write(bytes)
    //print("")
    let contents: StateFileContents
    do {
        contents = try decodeJson(bytes)
    } catch {
        throw "error decoding state file '\(path)': \(error)"
    }
    var state = ApplinState()
    for (name, value) in contents.boolVars ?? [:] {
        state.vars[name] = .boolean(value)
    }
    for (name, value) in contents.stringVars ?? [:] {
        state.vars[name] = .string(value)
    }
    for (key, item) in contents.pages ?? [:] {
        do {
            state.pages[key] = try PageSpec(config, pageKey: key, item)
        } catch {
            throw "error decoding state file '\(path)': error in page '\(key)': \(error)"
        }
    }
    state.stack = contents.stack ?? ["/"]
    return state
}

class StateFileWriter {
    private let config: ApplinConfig
    private var lock = NSLock()
    private weak var session: ApplinSession?
    private var task: Task<(), Never>?

    public init(_ config: ApplinConfig, _ session: ApplinSession?) {
        print("StateFileWriter")
        self.config = config
        self.session = session
    }

    deinit {
        self.task?.cancel()
    }

    func update(_ state: ApplinState) {
        self.lock.lock()
        defer {
            self.lock.unlock()
        }
        if self.task?.isCancelled != false {
            let lastWrittenId: UInt64 = state.fileUpdateId
            self.task = Task(priority: .low) {
                await self.writer(lastWrittenId)
            }
        }
    }

    private func writer(_ lastWrittenId: UInt64) async {
        print("StateFileWriter starting")
        var lastWrittenId: UInt64 = 0
        while !Task.isCancelled {
            await sleep(ms: 1_000)
            let contents: StateFileContents
            let contentsId: UInt64
            do {
                guard let mutexGuard = self.session?.mutex.readOnlyLock() else {
                    break
                }
                if mutexGuard.readOnlyState.fileUpdateId == lastWrittenId {
                    continue
                }
                contentsId = mutexGuard.readOnlyState.fileUpdateId
                let boolVars: [String: Bool] = mutexGuard.readOnlyState.vars.compactMapValues({ v in
                    if case let .boolean(value) = v {
                        return value
                    } else {
                        return nil
                    }
                })
                let stringVars: [String: String] = mutexGuard.readOnlyState.vars.compactMapValues({ v in
                    if case let .string(value) = v {
                        return value
                    } else {
                        return nil
                    }
                })
                let pages = mutexGuard.readOnlyState.pages.mapValues({ page in page.toJsonItem() })
                let stack = mutexGuard.readOnlyState.stack
                contents = StateFileContents(boolVars: boolVars, stringVars: stringVars, pages: pages, stack: stack)
            }
            do {
                let bytes = try encodeJson(contents)
                // TODO: Keep hash of file contents and don't write if file contents won't change.
                try await createDir(self.config.dataDirPath)
                let path = stateFilePath(config)
                let tmpPath = path + ".tmp"
                try await deleteFile(path: tmpPath)
                try await writeFile(data: bytes, path: tmpPath)
                // Swift has no atomic file replace function.
                try await deleteFile(path: path)
                try await moveFile(atPath: tmpPath, toPath: path)
                lastWrittenId = contentsId
            } catch {
                print("ERROR StateFileWriter: \(error)")
                self.session?.mutex.lock().state.connectionError = .appError(
                        "Error saving data to device.  Is your storage full?  Details: \(error)")
                if Task.isCancelled {
                    break
                } else {
                    await sleep(ms: 60_000)
                }
            }
        }
        print("StateStore.writeLoop stopping")
    }
}
