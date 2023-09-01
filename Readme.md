#  Applin&trade; iOS Client Library

<https://www.applin.dev/>

## How to make a new iOS app with Applin
1. Open XCode and create a new iOS app
   - Interface: `Storyboard`
   - Language: `Swift`
1. Delete
   - `AppDelegate`
   - `SceneDelegate`
   - `ViewController`
   - `Main`
   - `LaunchScreen`
1. Click menu View > Navigators > Project. 
   Select the app, which is the top-most item in the panel on the left.
   Click on the project, below `PROJECT`.
   Click the `General` tab
   - Change "Supported Destinations" to `iPhone` and `iPad`.
   - Change "Minimum Deployments" to iOS `15.0`.
1. Open `Info`, open keys
   `Information Property List` >
   `Application Scene Manifest` >
   `Scene Configuration` >
   `Application Session Role`
   and delete `Item 0 (Default Configuration)`
1. Add a `logo.png` file
1. Add package `https://github.com/leonhard-llc/applin-ios.git`
1. Add `ApplinIos` to app targets
1. Add a new `Main.swift` file with:
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
                   appStoreAppId: 0,
                   showPageOnFirstStartup: "/new_user",
                   staticPages: [
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
                       "/new_user": StaticPages.legalForm,
                       StaticPageKeys.TERMS: StaticPages.terms,
                       StaticPageKeys.PRIVACY_POLICY: StaticPages.privacyPolicy,
                   ],
                   urlForDebugBuilds: URL(string: "http://192.168.0.2:8000/")!,
                   urlForSimulatorBuilds: URL(string: "http://127.0.0.1:8000/")!,
                   licenseKey:  nil, // ApplinLicenseKey("DSZKrGaWAUymZXezLAA,https://app.example.com/"),
                   // Optional
                   statusPageUrl: URL(string: "https://status.example.com/")!,
                   supportChatUrl: URL(string: "https://www.example.com/support")!,
                   supportEmailAddress: "info@example.com",
                   supportSmsTel: "+10005551111"
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
