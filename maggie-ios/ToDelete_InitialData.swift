import Foundation
// https://developer.apple.com/documentation/foundation/nsdictionary
// Write it like JSON, but use "[]" instead of "{}".
// Use NSNull for null.
let SUPPORT_EMAIL = "cozydate@leonhardllc.com"
let SUPPORT_TEL = "14157693520"
let INITIAL_DATA: NSDictionary = [
    "/":["Hello"],
    "/status":[
        ["typ":"title-bar","text":"Status"],
        ["typ":"markdown","url":"https://cozydatestatus.com/index.md"],
        ["typ":"button","text":"Reload","actions":["refresh"]],
    ],
    "copied-to-clipboard-modal":[[
        "typ":"alert-modal",
        "title":"Copied",
        "content":[
            ["typ":"button","text":"OK","actions":["pop"],"default":true],
        ],
    ]],
    "contact-support-modal":[[
        "typ":"alert-modal",
        "title":"Contact Support",
        "content":[
            "We want to hear your compliments & complaints and answer your questions.",
            [
                "typ":"button",
                "text":"Text \(SUPPORT_TEL)",
                // "The 'sms' URI scheme https://datatracker.ietf.org/doc/html/rfc5724
                "actions":["launch-url:sms:\(SUPPORT_TEL)?body=%5BRpcError%5D%0AHi%20App%20Support%20Team%2C%0A"],
            ],
            [
                "typ":"button",
                "text":"Email \(SUPPORT_EMAIL)",
                // "The 'mailto' URI Scheme" https://datatracker.ietf.org/doc/html/rfc6068
                "actions":["launch-url:mailto:\(SUPPORT_EMAIL)?subject=RpcError&body=Hi%20App%20Support%20Team%2C%0A"],
            ],
            [
                "typ":"button",
                "text":"Copy \(SUPPORT_EMAIL)",
                "actions":["copy-to-clipboard:\(SUPPORT_EMAIL)","push:copied-to-clipboard-modal"],
            ],
            ["typ":"button","text":"OK","actions":["pop"],"default":true],
        ],
    ]],
    "/error-details":[
        ["typ":"title-bar","text":"Error Details"],
        ["typ":"error-details"],
    ],
    "network-error-modal":[[
        "typ":"alert-modal",
        "title":"Connection Problem",
        "content":[
            "Could not contact server.  Check your connection and try again.",
            ["typ":"button","text":"Details","actions":["push:/error-details"]],
            ["typ":"button","text":"Status","actions":["push:/status"]],
            ["typ":"button","text":"OK","actions":["pop"],"default":true],
        ],
    ]],
    "rpc-error-modal":[[
        "typ":"alert-modal",
        "title":"Error",
        "content":[
            "Problem talking to server.  Please try again or update the app.",
            ["typ":"button","text":"Details","actions":["push:/error-details"]],
            ["typ":"button","text":"Status","actions":["push:/status"]],
            ["typ":"button","text":"Contact Support","actions":["push:contact-support-modal"]],
            [
                "typ":"button",
                "text":"Update",
                "actions-ios":["launch-url:itms-apps://itunes.apple.com/app/id1064216828"],
                "actions-android":["launch-url:http://play.google.com/store/apps/details?id=com.leonhardllc.datingapp.prod"],
            ],
            ["typ":"button","text":"OK","actions":["pop"],"default":true],
        ],
    ]],
]
