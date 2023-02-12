import Foundation

class Config: ConfigProto {
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
            // Applin pushes this modal when it fails to make an HTTP request to the server.
            "/applin-network-error-modal": ModalSpec(
                    pageKey: "/applin-network-error-modal",
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
            // Applin pushes this modal when the server returns a non-200 response.
            "/applin-rpc-error-modal": ModalSpec(
                    pageKey: "/applin-rpc-error-modal",
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
        ]
    }
}
