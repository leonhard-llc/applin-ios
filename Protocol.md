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

Request types:
- `GET` for a page the client has not previously requested
  - Request headers
    - `Accept: application/vnd.applin-response`
      See [Accept on MDN](https://developer.mozilla.org/docs/Web/HTTP/Headers/Accept).
- `GET` to refresh a page that has no variables
  - Request headers
    - `If-None-Match: ETAGVALUE` with the previously received eTag header value.
      See [If-None-Match on MDN](https://developer.mozilla.org/docs/Web/HTTP/Headers/If-None-Match).
    - `Accept: application/vnd.applin-response`
- `POST` to refresh a page that has variables.
  - Request headers
    - `If-None-Match: ETAGVALUE`
    - `Accept: application/vnd.applin-response`
    - `Content-Type: application/vnd.applin-request` request header
  - Request body is a JSON object with the current page's variables.
- `POST` for a `rpc` action on a button.
  - Request headers
    - `Content-Type: application/vnd.applin-request` request header
  - Request body is a JSON object with the current page's variables.
- `GET` for page content (images, etc.)

If a server response has no
[Cache-Control](https://developer.mozilla.org/docs/Web/HTTP/Headers/Cache-Control) header,
the client adds `Cache-Control: max-age=0 stale-while-revalidate=9999999999`.

## Server Role
Every Applin server is an HTTP server that handles requests.
- Requests for pages, when request has the `Accept: application/vnd.applin-response` header
  - When the client is requesting the page for the first time (no `If-None-Match` header)
    or the page has changed (the page's `ETag` doesn't match the `If-None-Match` value)
    - Response headers
      - `Content-Type: application/vnd.applin-response`
      - `ETag: VALUE` with the hash of the response body.
        See [ETag on MDN](https://developer.mozilla.org/docs/Web/HTTP/Headers/ETag).
    - Response code: `200 OK`
    - Response body is a JSON object with the format described below.
  - When the page is unchanged (`ETag` matches `If-None-Match`)
    - Response codes
      - `304 Not Modified` for a `GET`
      - `412 Precondition Failed` for a `POST`
  - Do not return 4xx errors for bad user input.  Instead, display problems on the page.
- Form POST (without `Accept: application/vnd.applin-response`)
  - Response code: `200 OK`
  - No response body
- The request is missing a required variable, or a variable has the wrong type
  - Response code: `400 Bad Request`
  - Response headers: `Content-Type: text/plain`
  - Response body: a message for the user
- User entered data that is unacceptable
  - Response code: `422 Unprocessable Content`
  - Response headers: `Content-Type: text/plain`
  - Response body: a message for the user
- User is not logged in (session cookie missing or invalid) or does not have permission to view the page
  - Response code: `403 Forbidden`
  - Response headers: `Content-Type: text/plain`
  - Response body: a message for the user
- Server failed to process the request
  - Response code: `500 Internal Server Error`
  - Response headers: `Content-Type: text/plain`
  - Response body: a message for the user
- Server is overloaded
  - Response code: `503 Service Unavailable`
  - No response body 
  - The client will retry with backoff.

Applin clients receive and send cookies like web browsers.
Servers can set and receive cookies for session tokens.
See [Cookies on MDN](https://developer.mozilla.org/docs/Web/HTTP/Cookies).

## Applin Request Format
The `application/vnd.applin-request` content-type is a
[JSON](https://developer.mozilla.org/en-US/docs/Learn/JavaScript/Objects/JSON) object encoded in a UTF-8 string.
It contains key-value pairs for all variables defined on the page.

## Applin Response Format
The `application/vnd.applin-response` content-type is a JSON object encoded in a UTF-8 string.
It may include these keys:
- `page` is an Applin page specification
- TODO: Add a way for the server to set or unset variables.
- TODO: Add a way for the server to tell the client to perform some actions.
  Decide what to do with any remaining unperformed actions from the page.
- TODO: Add a way for the server to tell the client to delete pages from the cache.

## Prefetch Pages
Some app pages need to be always available, even when the device is not connected to the network or the server is down.
And some pages are slow to generate.
An Applin app can mark certain pages for pre-fetching.
Then the client will silently fetch these pages and keep them up-to-date in the cache.
When the user navigates to the page, it displays immediately.

To allow the user to navigate to another page, the page must contain a widget with a `push` action.
When the user activates the widget, the client adds that page to the top of the page stack, displaying the page.
If the page is cached, the client uses the cached version, otherwise it fetches the page from the server.

To mark a page for pre-fetching, the app uses the `push-prefetch` action instead of `push`.

Prefetching is configured on the link from one page to another.
The client prefetches a page if the page is linked from a page on the stack or from another prefetched page.

If the server sends a `Cache-Control: max-age=N` response header with the page,
then the client will re-fetch the page after `N` seconds.
The client ignores any `Cache-Control: stale-while-revalidate=N` value.
It keeps the cached page as long as it is marked for prefetching.

## TODO: Foreground and Background Requests
When the client requests a page that it will immediately show to the user, we call this a "foreground request".
The user is waiting for the request to complete.  We want the server to respond as quickly as possible.

When the client requests a page or content to display to the user, or to update the currently-visible page,
we call this a "foreground" request.  All other requests are "background" requests.
When the server is overloaded, we want it to prioritize processing foreground requests before background requests.
The client includes the `X-applin-priority: foreground` or `X-applin-priority: background` header to tell the server.
