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
        "typ": "scroll", "widget": [
            "typ": "column", "widgets": [
                ["typ": "form-section", "widgets": [
                    ["typ": "text", "text": "Hello World!", ],
                    ["typ": "text", "text": "Count: \(String(repeating: "M", count: nextCount()))", ],
                    ["typ": "button", "text": "Poll", "actions": ["poll"]],
                ]],
                ["typ": "form-section", "title": "Single Group", "widgets": [
                    ["typ": "grouped-row-table", "spacing": 8, "row-groups": [[
                        [
                            ["typ": "text", "text": "A1", ],
                            ["typ": "text", "text": "B1", ],
                        ],
                        [
                            nil,
                            ["typ": "text", "text": "B2", ],
                            ["typ": "text", "text": "C2", ],
                        ],
                    ]]],
                ]],
                ["typ": "form-section", "title": "Multiple Groups", "widgets": [
                    ["typ": "grouped-row-table", "spacing": 8, "row-groups": [
                        [
                            [
                                nil,
                                ["typ": "text", "text": "B1", ],
                                ["typ": "text", "text": "C1", ],
                            ],
                            [
                                ["typ": "text", "text": "A2", ],
                                ["typ": "text", "text": "B2", ],
                                nil,
                            ],
                        ],
                        [
                            [
                                ["typ": "text", "text": "A3", ],
                                nil,
                                ["typ": "text", "text": "C3", ],
                            ],
                            [
                                ["typ": "text", "text": "A4", ],
                                ["typ": "text", "text": "B4", ],
                            ],
                        ],
                    ]],
                ]],
                ["typ": "form-section", "title": "With an empty column", "widgets": [
                    ["typ": "grouped-row-table", "spacing": 8, "row-groups": [[
                        [
                            ["typ": "text", "text": "A1", ],
                            nil,
                            ["typ": "text", "text": "C1", ],
                        ],
                        [
                            ["typ": "text", "text": "A2", ],
                            nil,
                            ["typ": "text", "text": "C2", ],
                        ],
                    ]]],
                ]],
                ["typ": "form-section", "title": "With an empty row", "widgets": [
                    ["typ": "grouped-row-table", "spacing": 8, "row-groups": [[
                        [
                            ["typ": "text", "text": "A", ],
                            ["typ": "text", "text": "B", ],
                        ],
                        [
                            nil,
                            nil,
                        ],
                        [
                            ["typ": "text", "text": "AAA", ],
                            ["typ": "text", "text": "BBB", ],
                        ],
                    ]]],
                ]],
                ["typ": "form-section", "title": "With empty groups", "widgets": [
                    ["typ": "grouped-row-table", "spacing": 8, "row-groups": [[
                        [],
                        [
                            ["typ": "text", "text": "A1", ],
                            ["typ": "text", "text": "B1", ],
                        ],
                        [
                            ["typ": "text", "text": "A2", ],
                            ["typ": "text", "text": "B2", ],
                        ],
                    ]]],
                ]],
                ["typ": "form-section", "title": "With an empty cell", "widgets": [
                    ["typ": "grouped-row-table", "spacing": 8, "row-groups": [[
                        [nil],
                    ]]],
                ]],
                ["typ": "form-section", "title": "With no cells", "widgets": [
                    ["typ": "grouped-row-table", "spacing": 8, "row-groups": [[
                        [],
                    ]]],
                ]],
                ["typ": "form-section", "title": "With no groups", "widgets": [
                    ["typ": "grouped-row-table", "spacing": 8, "row-groups": [[
                    ]]],
                ]],
                ["typ": "form-section", "title": "Row with a lot of words", "widgets": [
                    ["typ": "grouped-row-table", "spacing": 8, "row-groups": [[
                        [],
                        [
                            ["typ": "text", "text": "A1", ],
                            ["typ": "text", "text": "MMMM MMMM MMMM MMMM MMMM MMMM MMMM MMMM MMMM MMMM MMMM MMMM MMMM MMMM", ],
                        ],
                        [
                            ["typ": "text", "text": "A2", ],
                            ["typ": "text", "text": "B2", ],
                        ],
                    ]]],
                ]],
                ["typ": "form-section", "title": "Row with a long word", "widgets": [
                    ["typ": "grouped-row-table", "spacing": 8, "row-groups": [[
                        [],
                        [
                            ["typ": "text", "text": "A1", ],
                            ["typ": "text", "text": "MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM", ],
                        ],
                        [
                            ["typ": "text", "text": "A2", ],
                            ["typ": "text", "text": "B2", ],
                        ],
                    ]]],
                ]],
                ["typ": "form-section", "title": "Row with long words", "widgets": [
                    ["typ": "grouped-row-table", "spacing": 8, "row-groups": [[
                        [],
                        [
                            ["typ": "text", "text": "MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM", ],
                            ["typ": "text", "text": "MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM", ],
                        ],
                        [
                            ["typ": "text", "text": "A2", ],
                            ["typ": "text", "text": "MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM", ],
                        ],
                    ]]],
                ]],
            ]],
    ]]])
}
try server.start(8000, forceIPv4: true)
sleep(365 * 24 * 3600)
