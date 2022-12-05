import Foundation

// TODO: Put all of these inside a Util class.

func createDir(_ path: String) async throws {
    let task = Task {
        do {
            if FileManager.default.fileExists(atPath: path) {
                return
            }
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
        } catch {
            throw ApplinError.appError("error creating directory '\(path)': \(error)")
        }
    }
    try await task.value
}

func decodeBundleJsonFile<T: Decodable>(_ filename: String) async throws -> T {
    let data: Data = try await readBundleFile(filename: filename)
    do {
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    } catch {
        throw ApplinError.appError("error parsing JSON \(filename) as \(T.self): \(error)")
    }
}

func decodeJson<T: Decodable>(_ data: Data) throws -> T {
    let decoder = JSONDecoder()
    return try decoder.decode(T.self, from: data)
}

func encodeJson<T: Encodable>(_ item: T) throws -> Data {
    let encoder = JSONEncoder()
    return try encoder.encode(item)
}

func deleteFile(path: String) async throws {
    let task = Task {
        do {
            // Apple's docs don't say what happens when the file doesn't exist.
            // https://developer.apple.com/documentation/foundation/filemanager/1408573-removeitem
            // Here's what I get from iOS 15 in Simulator:
            // Error Domain=NSCocoaErrorDomain Code=4 "'cache.json.tmp' couldn't be removed."
            // UserInfo={
            //   NSUserStringVariant=(Remove),
            //   NSFilePath=/Users/user/Library/Developer/CoreSimulator/Devices/61ED91D5-4782-4D6C-B943-74774C383CEC/data/
            //     Containers/Data/Application/CDF87840-5B50-4217-A2AC-5CC345A52A9B/Documents/cache.json.tmp,
            //   NSUnderlyingError=0x600000d541e0 {Error Domain=NSPOSIXErrorDomain Code=2 "No such file or directory"}
            // }
            // Apple docs also don't list the constant values.  And the editor won't show the values.
            // I printed out the value of kCFNotFound, which printed as -1.  But that value is not found in the error.
            // So I give up making this method idempotent.
            if !FileManager.default.fileExists(atPath: path) {
                return
            }
            try FileManager.default.removeItem(atPath: path)
        } catch {
            throw ApplinError.appError("error deleting file '\(path)': \(error)")
        }
    }
    try await task.value
}

func fileExists(path: String) async -> Bool {
    let task: Task<Bool, Never> = Task {
        FileManager.default.fileExists(atPath: path)
    }
    return await task.value
}

func getCacheDirPath() -> String {
    let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
    return urls[0].path
}

func getDataDirPath() -> String {
    let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
    return urls[0].path
}

func getTempDirPath() -> String {
    FileManager.default.temporaryDirectory.path
}

func moveFile(atPath: String, toPath: String) async throws {
    let task = Task {
        do {
            try FileManager.default.moveItem(atPath: atPath, toPath: toPath)
        } catch {
            throw ApplinError.appError("error moving file '\(atPath)' to '\(toPath)': \(error)")
        }
    }
    try await task.value
}

func readBundleFile(filename: String) async throws -> Data {
    let task: Task<Data, Error> = Task {
        guard let file = Bundle.main.url(forResource: filename, withExtension: nil)
        else {
            throw ApplinError.appError("bundle file not found: \(filename)")
        }
        do {
            return try Data(contentsOf: file)
        } catch {
            throw ApplinError.appError("error reading bundle file \(filename): \(error)")
        }
    }
    return try await task.value
}

func readFile(path: String) async throws -> Data {
    let task: Task<Data, Error> = Task {
        do {
            return try Data(contentsOf: URL(fileURLWithPath: path))
        } catch {
            throw ApplinError.appError("error reading file '\(path)': \(error)")
        }
    }
    return try await task.value
}

func sleep(ms: Int) async {
    do {
        try await Task.sleep(nanoseconds: UInt64(ms) * 1_000_000)
    } catch {
    }
}

func writeFile(data: Data, path: String) async throws {
    let task = Task {
        do {
            try data.write(to: URL(fileURLWithPath: path))
        } catch {
            throw ApplinError.appError("error writing file '\(path)': \(error)")
        }
    }
    try await task.value
}

extension HTTPURLResponse {
    func contentTypeBase() -> String? {
        if let mimeType = self.mimeType {
            return mimeType
                    .split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false)[0]
                    .lowercased()
        } else {
            return nil
        }
    }
}

extension Array {
    func get(_ index: Int) -> Element? {
        if index < self.count {
            return self[index]
        } else {
            return nil
        }
    }
}

// Lets us throw strings as exceptions.
extension String: Error {
}

// class Weak<T: AnyObject> {
//    weak var value: T?
//
//    init(_ value: T) {
//        self.value = value
//    }
// }

struct Stopwatch {
    let start: Date

    init() {
        self.start = Date.now
    }

    func waitUntil(seconds: Double) async {
        let elapsed = self.start.distance(to: Date.now)
        if elapsed < 1.0 {
            let secondsToWait = 1.0 - elapsed
            let nanoSecondsToWait = secondsToWait * 1_000_000_000
            do {
                try await Task.sleep(nanoseconds: UInt64(nanoSecondsToWait))
            } catch {
            }
        }
    }
}
