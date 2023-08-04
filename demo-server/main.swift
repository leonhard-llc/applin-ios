import Foundation
import Swifter

let server = HttpServer()
server["/hello"] = {
    .ok(.htmlBody("You asked for \($0)"))
}
try server.start(8000, forceIPv4: true)
sleep(365 * 24 * 3600)
