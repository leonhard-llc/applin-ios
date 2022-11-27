import Foundation

func readDefaultData(_ config: ApplinConfig, _ session: ApplinSession) async {
    print("readDefaultData")
    let itemMap: [String: JsonItem]
    do {
        itemMap = try await decodeBundleJsonFile("default.json")
    } catch {
        print("readDefaultData error: \(error)")
        return
    }
    for (key, item) in itemMap {
        do {
            session.pages[key] = try PageSpec(config, pageKey: key, item)
        } catch {
            print("readDefaultData error loading default.json key '\(key)': \(error)")
        }
    }
}
