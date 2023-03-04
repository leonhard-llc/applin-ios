import Foundation

class CustomConfig: CustomConfigProto {
    static let APPSTORE_URL = URL(string: "itms-apps://itunes.apple.com/app/id00000000000")!

    func serverUrl() -> URL {
        URL(string: "http://127.0.0.1:8000/")!
    }

    /// The app displays the default pages when the `"session"` cookie is unset.
    func defaultPages(_ config: ApplinConfig) -> [String: PageSpec] {
        [
            "/": PlainPageSpec(title: "Age Form", ColumnSpec([
                ImageSpec(config, url: "asset:///logo.png", aspectRatio: 1.67, disposition: .fit),
                TextSpec("To use this app, you must agree to the Terms of Use and be at least 18 years old."),
                FormSpec([
                    NavButtonSpec(pageKey: "/", text: "Terms of Use", [.push("/terms")]),
                    NavButtonSpec(pageKey: "/", text: "Privacy Policy", [.push("/privacy")]),
                ]),
                FormButtonSpec(pageKey: "/", text: "I Agree and I am 18+ Years Old", [.poll]),
            ])).toSpec(),
            "/terms": NavPageSpec(pageKey: "/terms", title: "Terms of Use", ScrollSpec(TextSpec(
                    """
                    TODO: Replace with terms of use.
                    """
            ))).toSpec(),
            "/privacy": NavPageSpec(pageKey: "/privacy", title: "Privacy Policy", ScrollSpec(TextSpec(
                    """
                    TODO: Replace with privacy policy.
                    """
            ))).toSpec(),
            APPLIN_NETWORK_ERROR_PAGE_KEY: ModalSpec(
                    pageKey: APPLIN_NETWORK_ERROR_PAGE_KEY,
                    kind: .alert,
                    title: "Connection Problem",
                    text: "Could not contact server.  Check your connection and try again.",
                    [
                        ModalButtonSpec(text: "Error Details", [.push("/error-details")]),
                        ModalButtonSpec(text: "Server Status", [.push("/status")]),
                        ModalButtonSpec(text: "Support", [.push("/support")]),
                        ModalButtonSpec(text: "Update App", [.launchUrl(Self.APPSTORE_URL)]),
                        ModalButtonSpec(text: "OK", isDefault: true, [.pop]),
                    ]
            ).toSpec(),
            APPLIN_RPC_ERROR_PAGE_KEY: ModalSpec(
                    pageKey: APPLIN_RPC_ERROR_PAGE_KEY,
                    kind: .alert,
                    // TODO: Include error code in title.
                    title: "Error",
                    text: "Problem talking to server.  Please try again or update the app.",
                    [
                        ModalButtonSpec(text: "Error Details", [.push("/error-details")]),
                        ModalButtonSpec(text: "Server Status", [.push("/status")]),
                        ModalButtonSpec(text: "Support", [.push("/support")]),
                        ModalButtonSpec(text: "Update App", [.launchUrl(Self.APPSTORE_URL)]),
                        ModalButtonSpec(text: "OK", isDefault: true, [.pop]),
                    ]
            ).toSpec(),
            APPLIN_APP_ERROR_PAGE_KEY: ModalSpec(
                    pageKey: APPLIN_APP_ERROR_PAGE_KEY,
                    kind: .alert,
                    // TODO: Include error code in title.
                    title: "Error",
                    text: "Error in app.  Please try again, quit and reopen the app. or update the app.",
                    [
                        ModalButtonSpec(text: "Update App", [.launchUrl(Self.APPSTORE_URL)]),
                        ModalButtonSpec(text: "Error Details", [.push("/error-details")]),
                        ModalButtonSpec(text: "Support", [.push("/support")]),
                        ModalButtonSpec(text: "OK", isDefault: true, [.pop]),
                    ]
            ).toSpec(),
            "/error-details": NavPageSpec(pageKey: "/error-details", title: "Error Details", ScrollSpec(
                    LastErrorTextSpec()
            )).toSpec(),
            "/status": NavPageSpec(pageKey: "/status", title: "Server Status", ScrollSpec(
                    // TODO: Replace this with a markdown page that loads the status markdown URL.
                    TextSpec("Not implemented")
            )).toSpec(),
            "/support": ModalSpec(
                    pageKey: "/support",
                    kind: .drawer,
                    title: "Support",
                    text: "",
                    [
                        // TODO: Replace with your support channels.
                        // TODO: Support including error code in url.
                        ModalButtonSpec(text: "Support Chat", [.launchUrl(URL(string: "https://www.example.com/support")!)]),
                        ModalButtonSpec(text: "Email Support", [.launchUrl(URL(string: "mailto:support@example.com")!)]),
                        ModalButtonSpec(text: "Text Support", [.launchUrl(URL(string: "sms:000-000-0000")!)]),
                        ModalButtonSpec(text: "OK", isDefault: true, [.pop]),
                    ]
            ).toSpec(),
            APPLIN_STATE_LOAD_ERROR_PAGE_KEY: ModalSpec(
                    pageKey: APPLIN_STATE_LOAD_ERROR_PAGE_KEY,
                    kind: .alert,
                    title: "Connect to Load App",
                    [ModalButtonSpec(text: "Connect", isDefault: true, [.poll, .pop])]
            ).toSpec(),
            APPLIN_PAGE_NOT_FOUND_PAGE_KEY: NavPageSpec(
                    pageKey: APPLIN_PAGE_NOT_FOUND_PAGE_KEY,
                    title: "Not Found",
                    ColumnSpec([TextSpec("Page not found.")])
            ).toSpec(),
            APPLIN_USER_ERROR_PAGE_KEY: ModalSpec(
                    pageKey: APPLIN_USER_ERROR_PAGE_KEY,
                    kind: .alert,
                    title: "Problem",
                    text: "${INTERACTIVE_ERROR_DETAILS}",
                    [ModalButtonSpec(text: "OK", isDefault: true, [.pop])]
            ).toSpec(),
        ]
    }
}
