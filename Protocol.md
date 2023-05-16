#  Applin Protocol

Applin clients and servers communicate with [JSON](https://en.wikipedia.org/wiki/JSON) and 
[HTTP](https://en.wikipedia.org/wiki/HTTP).
It incorporates the core concepts of [REST](https://en.wikipedia.org/wiki/Representational_state_transfer).

## Base and Relative URLs
Every Applin app is accessible at a particular base [URL](https://en.wikipedia.org/wiki/URL)
with the form `https://NETADDR/PATH`.
The URL must not contain query or fragment components.

We can append a "relative URL" to the base URL to obtain an "absolute URL".

For example, if your app's base URL is `https://applin.example.com:1234/travel1/`
then the relative URL `/foo` corresponds to the absolute URL `https://applin.example.com:1234/travel1/foo`.

## Server Role
Every Applin server is an HTTP server that must handle requests for URLs that start with `https://app/` (the base URL).

1. Handle `GET` requests
2. Handle `POST` requests with content type `application/vnd.applin-request`
3. Return responses with content type `application/vnd.applin-page`
4. May return streaming responses with content type `text/event-stream`
   as defined in HTML5 [Server-sent events](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events).

## Page Responses
The `application/vnd.applin-page` content-type is JSON object encoded in a UTF-8 string.
It represents a single page in an Applin app.

HTTP responses can include headers to control
[caching](https://developer.mozilla.org/en-US/docs/Web/HTTP/Caching) and
[cookies](https://developer.mozilla.org/en-US/docs/Web/HTTP/Cookies).

HTTP responses can include the `Discard` header
with a space-separated list of relative URLs to discard from the cache.

Each `applin-page` response defines the widgets of a single page.

## Client Role
Every Applin client is a program that makes requests to a particular Applin server, stores responses,
and provides functions interacting with pages and navigating between pages.

## Preloaded Pages
Some widgets can perform actions.  The `push` action takes a relative URL.
When the user activates the widget, the client adds that page to the stack.
If the page is cached, then the server uses the cached version, otherwise it makes a network request for the page.

The `push-preloaded` action works the same as `push`, but the client will immediately
fetch the page keep it up-to-date according to the caching policy.
For example, if the page response includes an `Expires: 60` header, then the client will discard the cached version
after 60 seconds and re-request it.

## Polling
The client may request some pages earlier than the expiration time to re-load multiple pages at the same time.

## Streaming
The page response can include an "Expire-Stream: true".
Whenever this page is visible, the client will make a `GET` request to `/applin-stream` and stream the response.
The server must return the content type `text/event-stream`
as defined in HTML5 [Server-sent events](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events).
Each `data` message is a single page relative URL to discard from the cache.

The server can use the stream to make the client update the visible page immediately.

## Foreground and Background Requests
When the client requests a page that it will immediately show to the user, we call this a "foreground request".
The user is waiting for the request to complete.  We want the server to respond as quickly as possible.

When the client requests a page because of a `push-preloaded` action, we call this a "background request".
When the server is overloaded, we want it to prioritize processing foreground requests before background requests.
The client includes the `Applin-background: 1` header to tell the serve that the request is a background request.
