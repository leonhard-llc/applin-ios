import Foundation

func default_data() -> NSDictionary {
    return [
        "/":[
            ["typ":"expand", "content":[
                ["typ":"center", "content":[
                    [
                        "typ":"text",
                        "text":"ERROR: InitialData.swift is missing a \"/\" entry.",
                    ],
                ]],
            ]],
        ],
        "/maggie-error-details":[
            ["typ":"title-bar","text":"Error Details"],
            ["typ":"error-details"],
        ],
        "/maggie-server-status":[
            ["typ":"title-bar","text":"Status"],
            ["typ":"expand", "content":[
                ["typ":"center", "content":[
                    [
                        "typ":"text",
                        "text":"ERROR: InitialData.swift is missing a \"/maggie-server-status\" entry.",
                    ],
                ]],
            ]],
        ],
        "maggie-contact-support-modal":[[
            "typ":"alert-modal",
            "title":"Contact Support",
            "content":[
                [
                    "typ":"text",
                    "text":"ERROR: InitialData.swift is missing a \"maggie-contact-support-modal\" entry.",
                ],
                ["typ":"button","text":"OK","actions":["pop"],"default":true],
            ],
        ]],
        "maggie-network-error-modal":[[
            "typ":"alert-modal",
            "title":"Connection Problem",
            "content":[
                [
                    "typ":"text",
                    "text":"Could not contact server.  Check your connection and try again.",
                ],
                ["typ":"button","text":"Details","actions":["push:/maggie-error-details"]],
                ["typ":"button","text":"Status","actions":["push:/maggie-server-status"]],
                ["typ":"button","text":"OK","actions":["pop"],"default":true],
            ],
        ]],
        "maggie-rpc-error-modal":[[
            "typ":"alert-modal",
            "title":"Error",
            "content":[
                [
                    "typ":"text",
                    "text":"Problem talking to server.  Please try again or update the app.",
                ],
                ["typ":"button","text":"Details","actions":["push:/maggie-error-details"]],
                ["typ":"button","text":"Status","actions":["push:/maggie-server-status"]],
                ["typ":"button","text":"Contact Support","actions":["push:maggie-contact-support-modal"]],
                ["typ":"button","text":"Update","actions":["push:maggie-update-button-not-customized-modal"]],
                ["typ":"button","text":"OK","actions":["pop"],"default":true],
            ],
        ]],
        "maggie-update-button-not-customized-modal":[[
            "typ":"alert-modal",
            "title":"Update",
            "content":[
                [
                    "typ":"text",
                    "text":"ERROR: InitialData.swift is missing a \"maggie-rpc-error-modal\" entry.",
                ],
                ["typ":"button","text":"OK","actions":["pop"],"default":true],
            ],
        ]],
    ]
}
