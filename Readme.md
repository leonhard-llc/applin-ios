#  Applin iOS Client
Copy this iOS app and customize it to connect to your
[`applin-rs`](https://github.com/mleonhard/applin-rs) server.

To use:
1. Clone this repo.
   - [Do not make a GitHub fork](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/what-happens-to-forks-when-a-repository-is-deleted-or-changes-visibility).
2. Replace the AppIcon
3. Edit [`CustomConfig.swift`](applin-ios/CustomConfig.swift).
   - Enter your server's prod URL
   - Customize the pages that your app shows before it connects to the server the first time.
4. Replace [`logo.png`](applin-ios/CustomConfig.swift) if your initial screen uses it.
5. Use XCode or other tools to build and test your app

## License
You may use Applin to build and test your app without a license.
To release or distribute your app, you must obtain a valid license.
See https://www.applin.dev/ .

When Applin for iOS is built in `Release` mode, it:
- When the license key is missing or invalid, Applin shows an error dialog to the user.  The user cannot use the app.
- When the license key is more than 1 month past its expiration date, Applin shows a warning dialog to the user.
  The user can dismiss the dialog and use the app.
- Reports its app ID and license key to Leonhard LLC.  Approximately 1% of app installs per month will do this.
You may not disable or interfere with these functions.

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
    - [X] custom back button actions
    - [ ] Use name of previous page, not "Back"
    - [ ] Swipe to go back with custom back button
    - [X] `stream` bool
    - [X] `poll-seconds`
  - [X] `plain-page`
  - `alert-modal`, `drawer-modal`
    - [X] `title`
    - [X] `text`
    - [X] `widgets` (only `modal-button` are allowed)
  - `media-page`
    - [ ] `title`
    - [ ] `url`
    - [ ] `cache` boolean
- Widgets
  - [X] Preserve widget data across page updates
  - [ ] Preserve widget data across app launches
    - <https://developer.apple.com/documentation/uikit/view_controllers/preserving_your_app_s_ui_across_launches>
  - `back-button`
    - [X] `actions`
    - [ ] Use name of previous page, not "Back"
  - `button`
    - [X] `text`
    - [X] `actions`
    - [ ] `actions-ios`
  - `column`
    - [X] `align`: `start`, `center`, `end`
    - [X] `spacing`
    - [X] `widgets`
  - [X] `empty`
  - [X] `error-details`
  - `form`
    - [X] `widgets`
  - `form-button`
    - [X] `text`
    - [X] `actions`
    - [ ] `actions-ios`
  - `form-checkbox`
    - [X] `initial-bool`
    - [X] `rpc`
    - [X] `text`
    - [X] `var`
  - `form-detail`
    - [X] `actions`
    - [X] `photo-url`
      - [ ] animated loading placeholder
      - [ ] retry
    - [X] `sub-text`
    - [X] `text`
  - `form-error`
    - [X] `text`
  - `form-section`
    - [X] `text`
    - [X] `widgets`
  - `form-textfield`
    - [ ] `allow`: `ascii`, `email`, `numbers`, `tel`
    - [ ] `auto-capitalize`: `names`, `sentences`
    - [ ] `check-rpc`
    - [X] `initial-string`
    - [ ] `label`
    - [ ] `max-chars`
    - [ ] `max-lines`
    - [ ] `min-chars`
    - [X] `var`
    - [ ] clear button
  - [ ] `expand` with `min-height`, `min-width`, `max-height`, `max-width`, `widget`
  - [ ] `expand.alignment`: `top-start`, `top-center`, `top-end`, `center-start`, `center`, `center-end`, `bottom-start`, `bottom-center`, `bottom-end`
  - [ ] `date-picker`
  - [ ] `date-time-picker`
  - `horizontal-scroll`
    - [ ] `widget`
  - `image`
    - [ ] `icon`
    - [ ] `url`
    - [ ] `alpha` 0-1.0
    - [ ] `color`: #rrggbb
    - [ ] dimensions
    - [ ] `disposition`: `cover`, `fit`, `stretch`
    - [ ] animated loading placeholder
    - [ ] retry
    - [ ] zoom
    - [ ] cache
  - [ ] `media`
    - [ ] `url`
    - [ ] `cache` bool
  - `modal-button`
    - [X] `text`
    - [X] `actions`
    - [ ] `actions-ios`
    - [X] `is-cancel`
    - [X] `is-default`
    - [X] `is-destructive`
  - `single-option`
    - [ ] `style`
      - [ ] `radio`
      - [ ] `wheel`
      - [ ] `menu`
    - [ ] `initial-id`
    - [ ] `label`
    - [ ] `options` list of `option`
    - [ ] `var`
  - `option`
    - [ ] `label`
    - [ ] `id` string
  - `row`
    - [ ] `align`: `top`, `center`, `bottom`
    - [ ] `spacing`
    - [ ] `widgets`
    - [ ] `wrap` bool
  - `scroll`
    - [X] `widget`
  - `table`
    - [ ] headers: `[string]`
    - [ ] cells: `[[widget]]`
  - `text`
    - [X] `text`
    - [ ] `text` should not show markdown-formatting
    - [ ] `scale` float
    - [ ] `overflow`: `wrap`, `ellipsis`
  - `date-time-picker`
    - [ ] `granularity-seconds`
    - [ ] `min-epoch-seconds`
    - [ ] `max-epoch-seconds`
    - [ ] `epoch-seconds-var`
    - [ ] `timezone-var`
- Actions:
  - `copy-to-clipboard`
    - [X] implement
    - [ ] show confirmation popover
  - `hilight:WIDGET_ID`
    - [ ] show flashing highlight
    - [ ] scroll the widget into view
  - [ ] `launch-url:URL`
  - [ ] `logout`
    - <https://developer.apple.com/documentation/foundation/urlsession/1411479-reset>
  - [X] `pop`
  - [X] `push:PAGE_KEY`
  - [ ] `reload-media` action
  - `rpc:/PATH`
    - [X] call server
    - [X] send cookies, receive & save cookies
    - [ ] send page stack to server
    - [X] send page variables to server in JSON request body
    - [ ] Ephemeral client data, to allow an RPC to include data from multiple pages
    - [ ] Option to automatically perform RPC when data changes, after a delay
    - [ ] Prevent overlapping RPCs or actions
    - [X] Show "working" modal to prevent race between user changing widgets and server changing UI in RPC response
    - [X] response can update pages
    - [ ] response can update stack
    - [ ] show network error dialog
    - [X] show server error dialog
    - [ ] show user error dialog
  - `pick-photo` action
    - [ ] `upload-url`
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
  - [ ] `take-photo` action
- Style
  - Pick one:
    - Each widget gets values from the style subsystem
    - Each widget has normal attributes for style.
      - Styles are a kind of JSON overlay which replace attributes.  This is like class inheritance.
      - Implement styles entirely on the server.
        This could make tests more verbose.
        This would simplify debugging. <--- This one.
  - [ ] `default-style` key
  - [ ] `style` attribute on pages and widgets
  - [ ] `style` widget
  - Text:
    - [ ] size
    - [ ] font
    - [ ] weight
    - [ ] color
    - [ ] effects
    - [ ] auto-size, with min & max
    - [ ] auto-size group
  - Box
    - [ ] width, height, min & max & preferred
    - [ ] padding
    - [ ] margin
    - Border
      - [ ] color
      - [ ] width
      - [ ] corner radius
      - [ ] pattern
    - Shadow
    - Background
      - [ ] color
      - [ ] pattern
      - [ ] gradient
    - Background image
      - [ ] disposition
      - [ ] origin
      - [ ] opacity
      - [ ] effects
  - Navigation bar
    - [ ] title text style
    - [ ] button text style
  - Markdown
  - Other widget-specific settings
- Connect to server
  - [X] Receive page updates
  - [ ] Receive page stack updates
  - [ ] Receive actions to execute immediately
  - [ ] Always apply diffs from connection and RPCs in correct order.
  - [ ] Avoid downloading all pages on new connection, use cached data
  - [X] Connect only when app is active.  Disconnect when in background, after a delay.
  - [X] Let pages specify "don't connect", "connect automatically" or "poll this RPC on this interval".
  - [ ] Add pull to refresh <https://stackoverflow.com/questions/26071528/refreshcontrol-with-programatic-uitableview-without-uitableviewcontroller>
- Save data
  - [X] pages
  - [X] Write pages after 10s delay, to reduce power usage
  - [X] stack
  - [X] cookies
- Notifications
  - [ ] action to request notifications
  - [ ] subscribe to notifications
  - [ ] Tap a notification to open the target page
  - [ ] Display received notifications while using app
- Logging
  - [ ] Replace `print` calls with proper logging: <https://developer.apple.com/documentation/os/logging>
  - [ ] gzip
  - [ ] log crashes
  - [ ] log JSON
  - [ ] encrypt with public key
  - [ ] max file size bytes
  - [ ] max file interval seconds
  - [ ] upload url
- Test coverage: ??
- Integration tests
- [X] Load `default.json` on startup
- Respond to memory pressure warnings
  <https://developer.apple.com/documentation/uikit/app_and_environment/managing_your_app_s_life_cycle/responding_to_memory_warnings>
  - [ ] Release non-visible images
  - [ ] Write cache since app may get terminated
- [ ] Download media in background task
  - <https://www.avanderlee.com/swift/urlsession-common-pitfalls-with-background-download-upload-tasks/>
- [ ] Reduce memory usage of pages that are not visible.
- [ ] Warn when two widgets use the same 'id'.
