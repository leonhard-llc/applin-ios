import Foundation

struct ApplinConfig {
    let dataDirPath: String
    let url: URL

    init(dataDirPath: String, url: URL) {
        print("ApplinConfig dataDirPath=\(dataDirPath) url=\(url)")
        self.dataDirPath = dataDirPath
        precondition(url.scheme == "http" || url.scheme == "https")
        self.url = url
    }
}
