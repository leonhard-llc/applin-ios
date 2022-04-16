import Foundation

func documentDirPath() -> String {
    let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return urls[0].path
}

func fileExists(path: String) async -> Bool {
    await (Task() {
        return FileManager.default.fileExists(atPath: path)
    }).value
}

func readFile(path: String) async throws -> Data {
    try await (Task() {
        return try Data(contentsOf: URL(fileURLWithPath: path))
    }).value
}

func readBundleFile(filename: String) async throws -> Data {
    try await (Task() {
        guard let file = Bundle.main.url(forResource: filename, withExtension: nil)
        else {
            throw MaggieError.deserializeError("bundle file not found: \(filename)")
        }
        do {
            return try Data(contentsOf: file)
        } catch {
            throw MaggieError.deserializeError("error reading bundle file \(filename): \(error)")
        }
    }).value
}

func sleep(ms: Int) async {
    do {
        try await Task.sleep(nanoseconds: UInt64(ms) * 1_000_000)
    } catch {}
}

func decodeBundleJsonFile<T: Decodable>(_ filename: String) async throws -> T {
    let data = try await readBundleFile(filename: filename)
    do {
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    } catch {
        throw MaggieError.deserializeError("error parsing JSON \(filename) as \(T.self): \(error)")
    }
}

func decodeJson<T: Decodable>(_ data: Data) async throws -> T {
    let decoder = JSONDecoder()
    return try decoder.decode(T.self, from: data)
}
