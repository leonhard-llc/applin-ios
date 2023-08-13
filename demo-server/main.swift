import Foundation
import Swifter

let server = HttpServer()
var count = 0

func nextCount() -> Int {
    count = count + 1
    return count
}

// Lets us throw strings as exceptions.
extension String: Error {
}

func json(_ object: Any) -> HttpResponse {
    HttpResponse.raw(200, "OK", ["content-type": "application/json", "Cache-Control": "max-age=10"], { (writer: HttpResponseBodyWriter) in
        guard JSONSerialization.isValidJSONObject(object) else {
            throw "not a valid JSON object: \(String(describing: object))"
        }
        let data = try JSONSerialization.data(withJSONObject: object)
        try writer.write(data)
    })
}

server["/"] = { (req: HttpRequest) -> HttpResponse in
    json(["page": ["typ": "plain-page", "widget": [
        "typ": "column", "widgets": [
            ["typ": "text", "text": "Hello World!", ],
            ["typ": "text", "text": "Count: \(nextCount())", ],
            ["typ": "button", "text": "Poll", "actions": ["poll"]],
        ]
    ]]])
}
try server.start(8000, forceIPv4: true)
sleep(365 * 24 * 3600)
