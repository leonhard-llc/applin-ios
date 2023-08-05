import Foundation
import Swifter

let server = HttpServer()
var count = 0

func nextCount() -> Int {
    count = count + 1
    return count
}

server["/"] = { (req: HttpRequest) -> HttpResponse in
    .ok(HttpResponseBody.json([
        "typ": "plain-page",
        "widget": [
            "typ": "column",
            "widgets": [
                ["typ": "text", "text": "Hello World!", ],
                ["typ": "text", "text": "Count: \(nextCount())", ],
                ["typ": "button", "text": "Poll", "actions": ["poll"]],
            ]
        ],
    ]))
}
try server.start(8000, forceIPv4: true)
sleep(365 * 24 * 3600)
