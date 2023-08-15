#  Applin&trade; iOS Client Library

## How to make a new iOS app with Applin
1. Open XCode and create a new iOS app.  Select SwiftUI.
1. Delete `ContentView.swift`
1. Add a `logo.png` file next to your main Swift file
1. Add `Package.swift`
   ```swift
   // swift-tools-version:4.0
   import PackageDescription
   
   let package = Package(
       name: "ApplinIos",
       products: [
           .library(name: "ApplinIos", targets: ["ApplinIos"]),
       ],
       dependencies: [
           .package(url: "https://github.com/mleonhard/applin-ios.git", from: "0.0.0"),
       ],
       targets: [
           .target(
               name: "ApplinIos",
               dependencies: ["ApplinIos"]),
           .testTarget(
               name: "ApplinIos",
               dependencies: ["ApplinIos"]),
       ]
   )
   ```
1. Replace the contents of your main Swift file with:
   ```swift
   import ApplinIos
   import OSLog
   import UIKit
   
   @main
   class Main: UIResponder, UIApplicationDelegate {
       static let logger = Logger(subsystem: "Example", category: "Main")
       let applinApp: ApplinApp
   
       override init() {
           // Note: This code runs during app prewarming.
           do {
               URLCache.shared = URLCache(memoryCapacity: 10 * 1024 * 1024, diskCapacity: 500 * 1024 * 1024, diskPath: nil)
               let config = try ApplinConfig(
                   // Required
                   appStoreAppId = 0,
                   licenseKey = nil, // ApplinLicenseKey("DSCZKrGaWAUymZXezLAA,https://app.example.com/"),
                   showPageOnFirstStartup = "/new-user",
                   staticPages = [
                       // Required
                       StaticPageKeys.APPLIN_CLIENT_ERROR: StaticPages.applinClientError,
                       StaticPageKeys.APPLIN_PAGE_NOT_LOADED: StaticPages.pageNotLoaded,
                       StaticPageKeys.APPLIN_NETWORK_ERROR: StaticPages.applinNetworkError,
                       StaticPageKeys.APPLIN_SERVER_ERROR: StaticPages.applinServerError,
                       StaticPageKeys.APPLIN_STATE_LOAD_ERROR: StaticPages.applinStateLoadError,
                       StaticPageKeys.APPLIN_USER_ERROR: StaticPages.applinUserError,
                       // Optional
                       StaticPageKeys.ERROR_DETAILS: StaticPages.errorDetails,
                       StaticPageKeys.SERVER_STATUS: StaticPages.serverStatus,
                       StaticPageKeys.SUPPORT: StaticPages.support,
                       "/new-user": StaticPages.legalForm,
                       StaticPageKeys.TERMS: StaticPages.terms,
                       StaticPageKeys.PRIVACY_POLICY: StaticPages.privacyPolicy,
                   ],
                   urlForDebugBuilds: URL = URL(string: "http://192.168.0.2:8000/")!,
                   urlForSimulatorBuilds: URL = URL(string: "http://127.0.0.1:8000/")!,
                   // Optional
                   statusPageUrl = URL("https://status.example.com/")!,
                   supportChatUrl = URL("https://www.example.com/support")!,
                   supportEmailAddress = "info@example.com",
                   supportSmsTel = "+10005551111"
               )
               self.applinApp = ApplinApp(config)
           } catch let e {
               Self.logger.fault("error starting app: \(e)")
               fatalError("error starting app: \(e)")
           }
           super.init()
       }
   
       // impl UIApplicationDelegate
   
       func application(
               _ application: UIApplication,
               didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
       ) -> Bool {
           self.applinApp.application(application, didFinishLaunchingWithOptions: launchOptions)
       }
   
       func applicationDidBecomeActive(_ application: UIApplication) {
           self.applinApp.applicationDidBecomeActive(application)
       }
   
       func applicationDidEnterBackground(_ application: UIApplication) {
           self.applinApp.applicationDidEnterBackground(application)
       }
   }
   ```

Use your new iOS app to connect to your applin server and develop your app.

## License
You may use Applin to build and test apps.
To release or distribute an app, you must obtain a valid license.
See https://www.applin.dev/ .

When you build in `Release` mode:
- Applin checks the license key.  If the key is missing or invalid, your app will not start.
- Applin reports its app ID and license key to Leonhard LLC.  Approximately 1% of app installs per month will do this.

You may not disable or interfere with these functions.

Licenses expire, but keys do not contain the expiration date.  An app with an expired license will work.
It is your responsibility to renew your license or disable your app before its license expires.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Development Progress

This project is still under development.

- Pages
  - `nav-page`
    - [X] `title`
    - [X] `widget`
    - [X] `start` widget
      - [X] `null` or missing means default back button
      - [X] `back-button` widget
      - [X] `empty` widget
    - [ ] `end` widget
  - [X] `plain-page`
    - [X] `widget`
  - `alert-modal`, `drawer-modal`
    - [X] `title`
    - [X] `text`
    - [X] `widgets`, must be `modal-button` widgets
  - `media-page`
    - [ ] `title`
    - [ ] `url`
    - [ ] Markdown
    - [ ] Video
    - [ ] Audio
    - [ ] Proto
- Widgets
  - [X] Preserve widget data across page updates
  - [X] Preserve widget data across app launches
    - <https://developer.apple.com/documentation/uikit/view_controllers/preserving_your_app_s_ui_across_launches>
  - `back-button`
    - [X] `actions`
    - [ ] Use name of previous page, not "Back"
    - [ ] Swipe to go back with custom back button
  - `button`
    - [X] `text`
    - [X] `actions`
  - `checkbox`
    - [X] `var`
    - [X] `initial-bool`
    - [X] `text`
    - [X] `rpc` to call when the user clicks
  - `column`
    - [X] `align`: `start`, `center`, `end`
    - [X] `spacing`
    - [X] `widgets`
  - [X] `empty`
  - [X] `error-text` is a label with a red error icon
  - `form` is a column that separates widgets with horizontal lines
    - [X] `widgets`
  - `form-button` is an iOS-style button that appears as blue text
    - [X] `text`
    - [X] `actions`
    - [X] `align`: `start`, `center`, `end`
  - `form-section` is a column with a header, separates widgets with horizontal lines
    - [X] `title`
    - [X] `widgets`
  - `grouped-row-table` is a table that can can group certain rows together
    - [X] `row-groups` is a triple-nested array of widgets
    - [X] `spacing`
  - `image`
    - [X] `url`
    - [X] `aspect-ratio` (prevents UI shifts when image loads)
    - [ ] `disposition`: `fit`, `cover`, `stretch`
    - [ ] `icon`
    - [ ] `alpha`
    - [ ] `color` (for monochrome images)
    - [ ] `preload` bool
    - [ ] `allow-zoom`
  - [X] `last-error-text`
  - [ ] `media`
    - [ ] `url`
    - [ ] `aspect-ratio`
    - [ ] `preload` bool
  - `modal-button`
    - [X] `text`
    - [X] `actions`
    - [X] `is-cancel`
    - [X] `is-default`
    - [X] `is-destructive`
  - `nav-button` shows an iOS style navigation button with a text label and a chevron
    - [X] `text`
    - [X] `sub-text`
    - [X] `actions`
    - [X] `photo-url`
      - [x] animated loading placeholder
      - [x] retry
      - [ ] tap to retry
  - `scroll`
    - [X] `widget`
  - `text` a text label
    - [X] `text`
    - [ ] `text` should not show markdown-formatting
    - [ ] `scale` float
    - [ ] `overflow`: `wrap`, `ellipsis`
    - [ ] `align`
  - `textfield`
    - [X] `label`
    - [X] `var`
    - [X] `initial-string`
    - [X] `error` label with error icon
    - `max-lines`
      - [X] 1 for single line, >1 for multi-line
      - [ ] constrain lines
    - `allow`: `all`, `ascii`, `email`, `numbers`, `tel`
      - [X] show correct keyboard type
      - [ ] constrain content
    - [X] `auto-capitalize`: `names`, `sentences`
    - [ ] `check-rpc`
    - [ ] `max-chars`
    - [ ] `min-chars`
    - [ ] `regex`
    - [ ] clear button
    - [ ] `rpc` to call when the user changes the text
  - [ ] `date-picker`
  - [ ] `date-time-picker`
    - [ ] `granularity-seconds`
    - [ ] `min-epoch-seconds`
    - [ ] `max-epoch-seconds`
    - [ ] `epoch-seconds-var`
    - [ ] `timezone-var`
  - `horizontal-scroll`
  - `single-option`
    - [ ] `style`
      - [ ] `radio`
      - [ ] `wheel`
      - [ ] `menu`
    - [ ] `initial-id`
    - [ ] `label`
    - [ ] `options` is `{'id': String, 'label': String}`
    - [ ] `var`
  - `row`
    - [ ] `align`: `top`, `center`, `bottom`
    - [ ] `spacing`
    - [ ] `widgets`
    - [ ] `wrap` bool
  - `table`
    - [ ] headers: `[string]`
    - [ ] cells: `[[widget]]`
- Actions:
  - `copy-to-clipboard`
    - [X] implement
    - [ ] show confirmation popover
  - [X] `pop`
  - [X] `push:PAGE_KEY`
  - `rpc:/PATH`
    - [X] call server
    - [X] send cookies, receive & save cookies
    - [ ] send page stack to server
    - [X] send page variables to server in JSON request body
    - [X] Show "working" modal
    - [X] response can update pages
    - [ ] response can update stack
    - [X] show network error dialog
    - [X] show server error dialog
    - [X] show user error dialog
  - `choose-photo:URL` to choose a photo and upload it to the given URL
    - [X] Let user choose photo from library
    - [ ] Upload photo to URL, use HTTP PUT
    - [ ] `aspect-ratio` float, width / height
    - [ ] `max-bytes`
    - [ ] `max-height`
    - [ ] `max-width`
    - [ ] `min-height`
    - [ ] `min-width`
    - [ ] convert to JPEG
    - [ ] preserve metadata
    - [ ] zoom
    - [ ] rotate
  - [X] `poll` to refresh the page
  - [ ] `take-photo` action
  - [ ] `launch-url:URL`
  - [ ] `logout`
    - <https://developer.apple.com/documentation/foundation/urlsession/1411479-reset>
  - `hilight:WIDGET_ID`
    - [ ] show flashing highlight
    - [ ] scroll the widget into view
- [ ] style and layout
- Connect to server
  - [X] Receive page updates
  - [X] Cache pages
  - [X] Automatically cache and refresh all pages reachable via `push-preload` action from a visible page
  - [X] When a visible page expires and is re-fetched, do the fetch silently.
    If the user starts an interaction that could update the page (action list includes rpc or pop) then
    pause updates to the current page.  Discard any refresh updates that could possibly revert the page.
  - [ ] Add an interaction hold after the update, to reject interactions right after the update and show feedback.
  - [ ] Send eTag and If-None-Match headers
  - [ ] Refresh some pages a little early and in parallel to reduce battery usage.
        Avoid refreshing pages too early if their max age is already short.
  - [ ] Do a single batch fetch for non-foreground pages.  Build support for this into the server libraries.
  - [ ] Connect only when app is active.  Disconnect when in background, after a delay.
  - [ ] Let pages specify that they need a live connection to the server to receive updates
  - [ ] Add pull to refresh <https://stackoverflow.com/questions/26071528/refreshcontrol-with-programatic-uitableview-without-uitableviewcontroller>
- Save data
  - [X] stack
  - [X] user-entered data
  - [X] cookies - the iOS HTTP library saves these automatically
  - [X] Save data after 10s delay, to reduce power usage
  - [X] Save when app is being shut down
- Notifications
  - [ ] include list of pages to refresh
  - [ ] allow server to send header with list of pages to refresh
  - [ ] allow refreshing all app pages
  - [ ] action to request notifications
  - [ ] subscribe to notifications
  - [ ] Tap a notification to open the target page
  - [ ] Display received notifications while using app
  - [ ] Support testing apps with push notifications.  Use SSE.  Build support for this into the server libraries.
- Log properly, not using `print`.  See <https://developer.apple.com/documentation/os/logging>
- Test coverage: ??
- [X] Check license key on startup, require for Release builds
- Respond to memory pressure warnings
  <https://developer.apple.com/documentation/uikit/app_and_environment/managing_your_app_s_life_cycle/responding_to_memory_warnings>
  - [ ] Release non-visible images
  - [ ] Save data since app may get terminated
- [ ] Download media in background task
  - <https://www.avanderlee.com/swift/urlsession-common-pitfalls-with-background-download-upload-tasks/>
