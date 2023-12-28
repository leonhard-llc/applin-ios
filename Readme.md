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
- v0.27.0 - Add `logout` action.
- v0.26.0 - Fix "cancelled" errors when using `poll_delay_ms` field.
- v0.25.0
    - Add `poll_delay_ms` field to checkbox and textfield.
    - Add checkbox `actions` field and remove `rpc` field.
    - Improve debug logging of network requests and responses.
- v0.24.0
    - Add `on_user_error_poll` action.
    - Remove `nothing` action.
