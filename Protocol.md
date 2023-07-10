#  Applin Protocol

Applin clients and servers communicate with [JSON](https://en.wikipedia.org/wiki/JSON) and 
[HTTP](https://en.wikipedia.org/wiki/HTTP).
It incorporates the core concepts of [REST](https://en.wikipedia.org/wiki/Representational_state_transfer).

## Pages and URLs
Every Applin app is accessible at a particular base [URL](https://en.wikipedia.org/wiki/URL)
with the form `https://NETADDR/PATH`.
The URL must not contain query or fragment components.

Every Applin app page has a URL.  All page URLs are relative to the base URL.

When an Applin app starts up, it displays the "home page" which is at relative URL `/`.
An Applin app displays Applin pages only from the base URL.
To display content from another server, you can use a Markdown page.

For example, if your app's base URL is `https://applin.example.com:1234/travel1`
then the relative URL `/foo` corresponds to the absolute URL `https://applin.example.com:1234/travel1/foo`.

## Server Role
Every Applin server is an HTTP server that handles requests for app pages.

- `GET` returning an [Etag](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/ETag) header
- `GET` with [If-None-Match](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-None-Match) header
  and `Cache-Control: no-cache` header.
  - `200 Ok` with the updated page
  - `304 Not Modified` when the page has not been updated
- Handle `POST` requests with content type `application/vnd.applin-request`
- Return pages with content type `application/vnd.applin-page`
- Handle requests with the [Cache-Control request header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control#request_directives)
  - `no-cache` to get the latest version of the page
- Return pages with [Cache-Control response header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control#response_directives)
  and all of these directives
  - `max-age=SECONDS` to allow caching
  - `stale-if-error=SECONDS` to allow pages to display when the server is unreachable (very important for mobile)
  - `private`
- [Cookies](https://developer.mozilla.org/en-US/docs/Web/HTTP/Cookies)

## Page Responses
The `application/vnd.applin-page` content-type is a JSON object encoded in a UTF-8 string.
It defines a single page in an Applin app.

## Client Role
Every Applin client is a program that makes requests to a particular Applin server, stores responses, 
and provides functions interacting with pages and navigating between pages.

## Preloaded Pages
Some widgets can perform actions.  The `push` action takes a relative URL.
When the user activates the widget, the client adds that page to the top of the page stack, displaying the page.
If the page is cached, then the client uses the cached version, otherwise it makes a network request for the page.

The `push-preloaded` action works the same as `push`, but the client immediately fetches the page
and keeps it up-to-date according to the caching policy.
For example, if the page response includes an `Expires: 60` header, then the client will download
the page again after about 60 seconds.
The client sends the `If-None-Match` header to avoid downloading unchanged pages.

## Polling
The client may request some pages earlier than the expiration time to re-load multiple pages at the same time.
This can make the app use less battery power.

## Foreground and Background Requests
When the client requests a page that it will immediately show to the user, we call this a "foreground request".
The user is waiting for the request to complete.  We want the server to respond as quickly as possible.

When the client requests a page because of a `push-preloaded` action, we call this a "background request".
When the server is overloaded, we want it to prioritize processing foreground requests before background requests.
The client includes the `X-applin-background: 1` header to tell the server that the request is a background request.
