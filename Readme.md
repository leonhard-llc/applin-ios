#  Maggie iOS Client
Copy this iOS app and customize it to connect to your
[`maggie-rs`](https://github.com/mleonhard/maggie-rs) server.

To use:
1. Clone this repo.
   - [Do not make a GitHub fork](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/what-happens-to-forks-when-a-repository-is-deleted-or-changes-visibility).
2. Add an icon
3. Add your server's URL to `Main.swift`
4. Edit `default.json`.  The app uses pages in that file until it connects to the server the first time.
   - Put your app's ID in the "Update" button action URL.
   - Optional: Add `/maggie-server-status` and `/maggie-contact-support-modal` pages.
     The default error modal has "Status" and "Contact Support" buttons which open those pages.
5. Use standard processes to build and test your app

## Development Progress

This project is not yet usable.  It is not production-ready.

- [X] Load `default.json` on startup
- [ ] Widgets:
  - [ ] `back-button` with `actions`
  - [ ] `button` with `actions`, `actions-android`, `actions-ios`, `text`, `is-default`, `is-destructive`
  - [ ] `button-cell`
  - [ ] `checkbox`
  - [ ] `checkbox-cell`
  - [ ] `column` with `spacing`, `widgets`
  - [ ] `column.alignment`: `top`, `center`, `bottom`
  - [ ] `detail-cell`
  - [ ] `empty`
  - [ ] `error-cell`
  - [ ] `error-details`
  - [ ] `expand` with `min-height`, `min-width`, `max-height`, `max-width`, `widget`
  - [ ] `expand.alignment`: `top-start`, `top-center`, `top-end`, `center-start`, `center`, `center-end`, `bottom-start`, `bottom-center`, `bottom-end`
  - [ ] `date-picker`
  - [ ] `date-time-picker`
  - [ ] `horizontal-scroll` with `widget`
  - [ ] `icon` with `id`, `height`, `width`, `alignment`
  - [ ] `image` with `url`, `height`, `width`
  - [ ] `image.disposition`: `cover`, `fit`, `stretch`
  - [ ] `image` zoom
  - [ ] `image` retry load failure
  - [ ] `image-picker` camera
  - [ ] `image-picker` photo
  - [ ] `image-picker` upload
  - [ ] `image-picker` crop, resize, and rotate
  - [ ] `markdown`
  - [ ] `picker`
  - [ ] `radio-button`
  - [ ] `row` with `spacing`, `widgets`
  - [ ] `row.alignment`: `start`, `center`, `end`
  - [ ] `row` item sizing: unconstrained, fixed-width, max-width, min-width
  - [ ] `row` spacing: Make `Spacer` fixed size, and use `Wide` & `Tall` for expanded spacing.
  - [ ] `row` wrapping
  - [ ] `scroll` with `widget`
  - [ ] `spacer`
  - [ ] `table`
  - [ ] `tall` with `alignment`, `min-height`, `max-height`, `widget`
  - [ ] `text`
  - [ ] `text` should not show markdown-formatting
  - [ ] `text-cell`
  - [ ] `time-picker`
  - [ ] `wide` with `alignment`, `min-width`, `max-width`, `widget`
- [ ] Actions:
  - [ ] `copy-to-clipboard`
  - [ ] `copy-to-clipboard` to show confirmation popover
  - [ ] `hilight:WIDGET_ID`
  - [ ] `launch-url:URL`
  - [ ] `logout`
    - <https://developer.apple.com/documentation/foundation/urlsession/1411479-reset>
  - [ ] `pop`
  - [ ] `push:PAGE_KEY`
  - [ ] `rpc:/PATH`
  - [ ] `rpc:/PATH?ARGS`
  - [ ] Prevent overlapping RPCs or actions
  - [ ] `rpc` to include page stack
  - [ ] `rpc` to include page variables
  - [ ] `rpc` response can update page stack
- [ ] Style
  - [ ] `style` key
  - [ ] Text style: size, font-family, font, weight
  - [ ] Text preset styles: title, heading, text, emphasis
  - [ ] Text auto-size, with min & max
  - [ ] Text auto-size group
  - [ ] Border width, corner radius, color, pattern
  - [ ] Background color, pattern
  - [ ] Background image, disposition, origin, opacity
  - [ ] Margin
  - [ ] Padding
  - [ ] `style` widget
  - [ ] `style` attribute on pages and widgets
- [ ] Ephemeral client data, to allow an RPC to consume data from multiple pages
- [ ] Monotonic state counter, to keep client in sync with server
- [ ] Cache stack
- [ ] Cache pages
- [ ] Reduce power used for caching.  Append diffs, write after a delay, or something else.  Writing after 10s delay.
- [ ] Disconnect to save power, when in background, after a delay
- [ ] Subscribe to notifications
- [ ] Open notification to target page
- [ ] Display received notifications while using app
- [ ] Upload logs
- [ ] Log crashes
- [ ] Test coverage
- [ ] Integration tests
- [ ] Swipe to go back with custom back button
- [ ] Preserve content entered in text fields and other widget state:
  <https://developer.apple.com/documentation/uikit/view_controllers/preserving_your_app_s_ui_across_launches>
- Respond to memory pressure warnings
  <https://developer.apple.com/documentation/uikit/app_and_environment/managing_your_app_s_life_cycle/responding_to_memory_warnings>
  - Release non-visible images
  - Write cache since app may get terminated
- [ ] Download media in background task
  - <https://www.avanderlee.com/swift/urlsession-common-pitfalls-with-background-download-upload-tasks/>
- [ ] Reduce memory usage of pages that are not visible.
