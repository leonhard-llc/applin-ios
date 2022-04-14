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

func readBundleFile(filename: String) async -> Data {
    await (Task() {
        guard let file = Bundle.main.url(forResource: filename, withExtension: nil)
        else {
            fatalError("did not find bundle file: \(filename)")
        }
        do {
            return try Data(contentsOf: file)
        } catch {
            fatalError("error reading bundle file \(filename): \(error)")
        }
    }).value
}

func sleep(ms: Int) async {
    do {
        try await Task.sleep(nanoseconds: UInt64(ms) * 1_000_000)
    } catch {}
}

func decodeBundleJsonFile<T: Decodable>(_ filename: String) async -> T {
    let data = await readBundleFile(filename: filename)
    do {
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    } catch {
        fatalError("Couldn't parse \(filename) as \(T.self):\n\(error)")
    }
}

func decodeJson<T: Decodable>(_ data: Data) async throws -> T {
    let decoder = JSONDecoder()
    return try decoder.decode(T.self, from: data)
}
