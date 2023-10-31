import Foundation

public class StaticPageKeys {
    /// Applin pushes this page when the app has an error.
    /// Include an ErrorDetails widget to display the message.
    public static let APPLIN_CLIENT_ERROR = "/applin_app_error"
    /// Applin pushes this page when it starts and fails to load a previously visible page.
    public static let APPLIN_PAGE_NOT_LOADED = "/applin_page_not_loaded"
    /// Applin pushes this page when it fails to make an HTTP request to the server.
    public static let APPLIN_NETWORK_ERROR = "/applin_network_error"
    /// Applin pushes this page when the server returns a non-200 response.
    public static let APPLIN_SERVER_ERROR = "/applin_server_error"
    /// Applin pushes this page when it fails to load the state file.
    /// Show the user a Connect button.
    public static let APPLIN_STATE_LOAD_ERROR = "/applin_state_load_error"
    /// Applin pushes this page when the server returns a user error message.
    /// Include an ErrorDetails widget to display the message.
    public static let APPLIN_USER_ERROR = "/applin_user_error"
    /// The default error pages have an "Error Details" button that pushes this page.
    public static let ERROR_DETAILS = "/error_details"
    /// The default error pages have a "Server Status" button that pushes this page.
    public static let SERVER_STATUS = "/server_status"
    /// The default error pages have a "Support" button that pushes this page.
    public static let SUPPORT = "/support"
}

public class StaticPages {
    public static func applinClientError(_ config: ApplinConfig, _ pageKey: String) -> ToPageSpec {
        NavPageSpec(
                pageKey: pageKey,
                // TODO: Include error code in title.
                title: "Error",
                ephemeral: true,
                ScrollSpec(pull_to_refresh: false, FormSpec([
                    ErrorTextSpec("Error in app.  Please try again, quit and reopen the app. or update the app."),
                    FormButtonSpec(text: "Update App", [.launchUrl(config.appstoreUrl())]),
                    FormButtonSpec(text: "Error Details", [.push(StaticPageKeys.ERROR_DETAILS)]),
                    FormButtonSpec(text: "Support", [.push(StaticPageKeys.SUPPORT)]),
                ]))
        )
    }

    public static func applinNetworkError(_ config: ApplinConfig, _ pageKey: String) -> ToPageSpec {
        NavPageSpec(
                pageKey: pageKey,
                title: "Connection Problem",
                ephemeral: true,
                ScrollSpec(pull_to_refresh: false, FormSpec([
                    ErrorTextSpec("Could not contact server.  Check your connection and try again."),
                    FormButtonSpec(text: "Error Details", [.push(StaticPageKeys.ERROR_DETAILS)]),
                    FormButtonSpec(text: "Server Status", [.push(StaticPageKeys.SERVER_STATUS)]),
                    FormButtonSpec(text: "Support", [.push(StaticPageKeys.SUPPORT)]),
                    FormButtonSpec(text: "Update App", [.launchUrl(config.appstoreUrl())]),
                ]))
        )
    }

    public static func applinServerError(_ config: ApplinConfig, _ pageKey: String) -> ToPageSpec {
        NavPageSpec(
                pageKey: pageKey,
                title: "Error",
                ephemeral: true,
                ScrollSpec(pull_to_refresh: false, FormSpec([
                    ErrorTextSpec("Problem talking to server.  Please try again or update the app."),
                    FormButtonSpec(text: "Error Details", [.push(StaticPageKeys.ERROR_DETAILS)]),
                    FormButtonSpec(text: "Server Status", [.push(StaticPageKeys.SERVER_STATUS)]),
                    FormButtonSpec(text: "Support", [.push(StaticPageKeys.SUPPORT)]),
                    FormButtonSpec(text: "Update App", [.launchUrl(config.appstoreUrl())]),
                ]))
        )
    }

    public static func applinStateLoadError(_ config: ApplinConfig, _ pageKey: String) -> ToPageSpec {
        NavPageSpec(
                pageKey: pageKey,
                title: "Connect to Load App",
                ephemeral: true,
                FormSpec([
                    FormButtonSpec(text: "Connect", [.poll]),
                ])
        )
    }

    public static func applinUserError(_ config: ApplinConfig, _ pageKey: String) -> ToPageSpec {
        NavPageSpec(
                pageKey: pageKey,
                title: "Problem",
                ephemeral: true,
                ScrollSpec(pull_to_refresh: false, FormSpec([
                    ErrorTextSpec("${INTERACTIVE_ERROR_DETAILS}"),
                ]))
        )
    }

    public static func errorDetails(_ config: ApplinConfig, _ pageKey: String) -> ToPageSpec {
        NavPageSpec(pageKey: pageKey, title: "Error Details", ephemeral: true,
                ScrollSpec(pull_to_refresh: false,
                        LastErrorTextSpec()
                ))
    }

    public static func pageNotLoaded(_ config: ApplinConfig, _ pageKey: String) -> ToPageSpec {
        NavPageSpec(
                pageKey: pageKey,
                title: "Page Not Loaded",
                connectionMode: .pollSeconds(30),
                ColumnSpec([FormButtonSpec(text: "Load Page", [.poll])])
        )
    }

    public static func pageNotFound(_ config: ApplinConfig, _ pageKey: String) -> ToPageSpec {
        NavPageSpec(
                pageKey: pageKey,
                title: "Not Found",
                ephemeral: true,
                ColumnSpec([TextSpec("Page not found.")])
        )
    }

    public static func serverStatus(_ config: ApplinConfig, _ pageKey: String) -> ToPageSpec {
        NavPageSpec(pageKey: pageKey, title: "Server Status", ScrollSpec(
                // TODO: Replace this with a markdown page that loads the status markdown URL.
                TextSpec("Not implemented")
        ))
    }

    public static func support(_ config: ApplinConfig, _ pageKey: String) -> ToPageSpec {
        var buttons: [FormButtonSpec] = []
        // TODO: Support including error code in urls.
        if let url = config.supportChatUrl {
            buttons.append(FormButtonSpec(text: "Support Chat", [.launchUrl(url)]))
        }
        if let email = config.supportEmailAddress {
            let url = URL(string: "mailto:\(email)")!
            buttons.append(FormButtonSpec(text: "Email Support", [.launchUrl(url)]))
        }
        if let tel = config.supportSmsTel {
            let url = URL(string: "sms:\(tel)")!
            buttons.append(FormButtonSpec(text: "Text Support", [.launchUrl(url)]))
        }
        return NavPageSpec(pageKey: pageKey, title: "Support",
                ScrollSpec(pull_to_refresh: false,
                        FormSpec(buttons)
                )
        )
    }
}
