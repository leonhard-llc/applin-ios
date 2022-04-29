#  Maggie iOS Client
Copy this iOS app and customize it to connect to your
[`maggie-rs`](https://github.com/mleonhard/maggie-rs) server.

To use:
1. Clone this repo.
  - [Do not make a GitHub fork](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/what-happens-to-forks-when-a-repository-is-deleted-or-changes-visibility).
1. Add initial pages to `initial.json`.  The app displays `"/"` on startup.
1. Add your server's URL to `Main.swift`
1. Add an icon
1. Use standard processes to build and test your app

## Development Progress

This project is not yet usable.  It is not production-ready.

- [X] Load `default.json` on startup
- [X] Load customizable `initial.json` on startup, with useful error logging
- [ ] Widgets:
  - [X] `back-button` with `actions`
  - [X] `button` with `actions`, `actions-android`, `actions-ios`, `text`, `is-default`, `is-destructive`
  - [ ] `button-cell`
  - [ ] `checkbox`
  - [ ] `checkbox-cell`
  - [X] `column` with `spacing`, `widgets`
  - [X] `column.alignment`: `top`, `center`, `bottom`
  - [ ] `detail-cell`
  - [X] `empty`
  - [ ] `error-cell`
  - [X] `error-details`
  - [X] `expand` with `min-height`, `min-width`, `max-height`, `max-width`, `widget`
  - [X] `expand.alignment`: `top-start`, `top-center`, `top-end`, `center-start`, `center`, `center-end`, `bottom-start`, `bottom-center`, `bottom-end`
  - [ ] `date-picker`
  - [ ] `date-time-picker`
  - [X] `horizontal-scroll` with `widget`
  - [ ] `icon` with `id`, `height`, `width`, `alignment`
  - [X] `image` with `url`, `height`, `width`
  - [X] `image.disposition`: `cover`, `fit`, `stretch`
  - [ ] `image` zoom
  - [ ] `image` retry load failure
  - [ ] `image-picker` camera
  - [ ] `image-picker` photo
  - [ ] `image-picker` upload
  - [ ] `image-picker` crop, resize, and rotate
  - [ ] `markdown`
  - [ ] `picker`
  - [ ] `radio-button`
  - [X] `row` with `spacing`, `widgets`
  - [X] `row.alignment`: `start`, `center`, `end`
  - [ ] `row` item sizing: unconstrained, fixed-width, max-width, min-width
  - [ ] `row` spacing: Make `Spacer` fixed size, and use `Wide` & `Tall` for expanded spacing.
  - [ ] `row` wrapping
  - [X] `scroll` with `widget`
  - [X] `spacer`
  - [ ] `table`
  - [X] `tall` with `alignment`, `min-height`, `max-height`, `widget`
  - [X] `text`
  - [ ] `text` should not show markdown-formatting
  - [ ] `text-cell`
  - [ ] `time-picker`
  - [X] `wide` with `alignment`, `min-width`, `max-width`, `widget`
- [ ] Actions:
  - [X] `copy-to-clipboard`
  - [ ] `copy-to-clipboard` to show confirmation popover
  - [ ] `hilight:WIDGET_ID`
  - [ ] `launch-url:URL`
  - [ ] `logout`
  - [X] `pop`
  - [X] `push:PAGE_KEY`
  - [X] `rpc:/PATH`
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
- [X] Cache stack
- [X] Cache pages
- [X] Reduce power used for caching.  Append diffs, write after a delay, or something else.  Writing after 10s delay.
- [ ] Disconnect to save power, when in background, after a delay
- [ ] Subscribe to notifications
- [ ] Open notification to target page
- [ ] Display received notifications while using app
- [ ] Upload logs
- [ ] Log crashes
- [ ] Test coverage
- [ ] Integration tests
- [ ] Swipe to go back
