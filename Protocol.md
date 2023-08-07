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

## Client Role
Every Applin client is a program that makes requests to a particular Applin server,
receives page specifications from the server,
and provides functions for interacting with pages and navigating between pages.

## Server Role
Every Applin server is an HTTP server that handles requests for app pages:
- `GET` for a page the client has not previously requested
  - Response headers
    - `Content-Type: application/vnd.applin-response`
    - [Etag](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/ETag) with a hash of the response body
    - [Cache-Control](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control)
      with any of these directives:
      - `no-cache` to ask the client to refresh the page every time it is displayed.
        This disables preloading on the page.
      - `max-age=N` to ask the client to refresh the page every N seconds, when the page is on the stack or preloaded.
      - `stale-while-revalidate=N` to allow the client to display the cached page while it is refreshing the page.
        This lets the client display cached pages when the server is unreachable, very important for mobile.
      - `private` to prevent an intermediate cache from sharing this response with other clients.
      - When a response has no `Cache-Control` header, the client adds `Cache-Control: max-age=300,stale-if-error=600`.
  - Response body is a JSON object with format described below.
- `GET` to refresh a page that has no variables
  - Request headers
    - `Cache-Control: no-cache` to revalidate the response with the origin server, skipping intermediate caches
    - [If-None-Match](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-None-Match) request header,
      with the previously received eTag header value.
  - Server response
    - `200 OK` with the updated page
    - `304 Not Modified` when the page has not changed
- `POST` for an `rpc` action.
  - Request headers
    - `Content-Type: application/vnd.applin-request` request header
  - Request body is a JSON object with the current page's variables.
  - Response body
    - 4xx and 5xx responses may contain a `text/plain` body which is shown to the user
    - 2xx responses may contain an `application/vnd.applin-response` response or be empty.
      The client ignores any page update in the response.
- `POST` to refresh a page that has variables.
  - Request headers
    - `Content-Type: application/vnd.applin-request` request header
    - `Cache-Control: no-cache`
    - `If-None-Match: ETAGVALUE`
  - Request body is a JSON object with the current page's variables.
  - Server response
    - `200 OK` with the updated page
    - `412 Precondition Failed` when the page has not changed
    - Do not return 4xx errors for bad user input.  Instead, display problems on the page.
- [Cookies](https://developer.mozilla.org/en-US/docs/Web/HTTP/Cookies) - Applin clients receive and send cookies like
  web browsers.

## Applin Response Format
The `application/vnd.applin-response` content-type is a JSON object encoded in a UTF-8 string.
It may include these keys:
- `page` is an Applin page specification
- TODO: Add a way for the server to set or unset variables.
- TODO: Add a way for the server to tell the client to perform some actions.
  Decide what to do with any remaining unperformed actions from the page.
- TODO: Add a way for the server to tell the client to delete pages from the cache.

## Preloaded Pages
Some widgets can perform actions.  The `push` action takes a relative URL.
When the user presses a button with a `push` action,
the client adds that page to the top of the page stack, displaying the page.
If the page is cached, the client uses the cached version, otherwise it makes a GET request for the page.

The `push-preloaded` action works the same as `push`, but the client immediately fetches the page
and keeps it up-to-date according to the page's caching policy.
For example, if the page response includes an `Cache-control: max-age=60` header, then the client will download
the page again after about 60 seconds.
The client sends the `If-None-Match` header to avoid downloading unchanged pages.

## TODO: Polling
The client may request some pages earlier than the expiration time to re-load multiple pages at the same time.
This can make the app use less battery power.

## TODO: Foreground and Background Requests
When the client requests a page that it will immediately show to the user, we call this a "foreground request".
The user is waiting for the request to complete.  We want the server to respond as quickly as possible.

When the client requests a page because of a `push-preloaded` action, we call this a "background request".
When the server is overloaded, we want it to prioritize processing foreground requests before background requests.
The client includes the `X-applin-priority: foreground` or `X-applin-priority: background` header to tell the server.
