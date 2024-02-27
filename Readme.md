# Applin&trade; iOS Client Library

How to use this library: https://www.applin.dev/docs/ios/

## License

You may use this software to build and test apps.
To use this software in a released or distributed app,
you must maintain a valid license for it.
See https://www.applin.dev/ .

When you build in `Release` mode:

- Applin checks the license key.
  If the key is missing or invalid, your app will not start.
- Applin reports its app ID and license key to Leonhard LLC.
  Approximately 1% of app installs per month will do this.

You may not disable or interfere with these functions.

Licenses expire, but keys do not contain the expiration date.
An app with an expired license will run.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Changes
- v0.37.0 - Update form_section to modern style.  Make form background dark and remove separators.
- v0.36.0 - Add `reset_var` action.
- v0.35.0 - Add `stop_actions` action.
- v0.34.0
    - `modal` action to stop action processing.
    - Support '%' and '#' in `var_name`.
    - Bugfixes
- v0.33.0 - Add support for the `validated: true` attribute on input widgets.
- v0.32.0 - Bugfixes.
- v0.31.0
    - Add `modal` action.
    - Change the wire format of action definitions from strings to JSON objects.
- v0.30.0
    - Add "Cancel" button to "Working" modal. Users can now cancel slow operations!
    - Support the `aspect_ratio=N` URL parameter for `choose_photo` and `take_photo` actions.
      Users can now rotate and crop their photos before upload!
    - Support URL parameters on upload URLs and page URLs.
    - Improve error reporting.
    - Fix a bug that caused some widgets to not appear.
- v0.29.0
    - Add `take_photo` action.
    - Fix bug in Logger.dbg.
- v0.28.0 - Add `selector` widget.
- v0.27.0 - Add `logout` action.
- v0.26.0 - Fix "cancelled" errors when using `poll_delay_ms` field.
- v0.25.0
    - Add `poll_delay_ms` field to checkbox and textfield.
    - Add checkbox `actions` field and remove `rpc` field.
    - Improve debug logging of network requests and responses.
- v0.24.0
    - Add `on_user_error_poll` action.
    - Remove `nothing` action.
