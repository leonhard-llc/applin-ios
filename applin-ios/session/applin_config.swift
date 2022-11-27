import Foundation

struct ApplinConfig {
    let url: URL

    init(url: URL) {
        print("ApplinConfig url=\(url)")
        precondition(url.scheme == "http" || url.scheme == "https")
        self.url = url
    }
}
