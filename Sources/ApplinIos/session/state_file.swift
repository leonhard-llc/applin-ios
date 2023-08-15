import Foundation
import OSLog

struct StateFileContents: Codable {
    var boolVars: [String: Bool]?
    var stringVars: [String: String]?
    var pageKeys: [String]?
}

/// This class has two jobs:
/// 1. Periodically save app state in case the phone crashes.
/// 2. Save state when the app is put in the background or closed.
class StateFileOwner {
    static let logger = Logger(subsystem: "Applin", category: "StateFileOwner")

    static func read(_ config: ApplinConfig) async -> StateFileContents? {
        let path = config.stateFilePath()
        // Swift's standard library provides no documented way to tell if a file read error is due to file not found.
        // So we check for file existence separately.
        if !(await fileExists(path: path)) {
            return nil
        }
        do {
            let bytes = try await readFile(path: path)
            let contents: StateFileContents = try decodeJson(bytes)
            return contents
        } catch {
            Self.logger.error("error reading state file '\(path)': \(error)")
            return nil
        }
    }

    private let fileBytesHash = AtomicUInt64(0)
    private let lock = ApplinLock()
    private let path: String
    private weak var weakVarSet: VarSet?
    private weak var weakPageStack: PageStack?
    private var periodicTask: Task<(), Never>?
    private var stopTask: Task<(), Never>?

    public init(_ config: ApplinConfig, _ varSet: VarSet?, _ pageStack: PageStack?) {
        self.path = config.stateFilePath()
        self.weakVarSet = varSet
        self.weakPageStack = pageStack
        Self.logger.info("path=\(String(describing: self.path))")
    }

    deinit {
        self.periodicTask?.cancel()
    }

    func start() {
        self.stopTask?.cancel()
        self.periodicTask?.cancel()
        self.periodicTask = Task(priority: .low) {
            Self.logger.info("periodic writer task starting")
            while !Task.isCancelled {
                await sleep(ms: 10_000)
                if Task.isCancelled {
                    break
                }
                do {
                    try await self.write()
                } catch {
                    Self.logger.error("error saving state, will retry: \(error)")
                }
            }
            Self.logger.info("periodic writer task stopping")
        }
    }

    func stop() {
        self.periodicTask?.cancel()
        self.stopTask?.cancel()
        self.stopTask = Task(priority: .high) {
            do {
                try await self.write()
            } catch {
                Self.logger.error("failed saving state before stop: \(error)")
            }
        }
    }

    func write() async throws {
        try await self.lock.lockAsyncThrows({
            var contents: StateFileContents = StateFileContents()
            if let varSet = self.weakVarSet {
                contents.boolVars = varSet.bools()
                contents.stringVars = varSet.strings()
            }
            if let pageStack = self.weakPageStack {
                contents.pageKeys = pageStack.stackPageKeys()
            }
            let bytes = try encodeJson(contents)
            let hash = UInt64(truncatingIfNeeded: bytes.hashValue)
            if self.fileBytesHash.load() == hash {
                Self.logger.debug("file contents unchanged, skipping writing file")
                return
            }
            let dirPath = (self.path as NSString).deletingLastPathComponent
            try await createDirAsync(dirPath)
            let tmpPath = self.path + ".tmp"
            try await deleteFile(path: tmpPath)
            try await writeFile(data: bytes, path: tmpPath)
            // Swift has no atomic file replace function.
            try await deleteFile(path: self.path)
            try await moveFile(atPath: tmpPath, toPath: self.path)
            self.fileBytesHash.store(hash)
            Self.logger.info("wrote file")
        })
    }
}
