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
    - `Accept: application/vnd.applin-response`
- `POST` to refresh a page that has variables.
  - Request headers
    - `Accept: application/vnd.applin-response`
    - `Content-Type: application/vnd.applin-request` request header
  - Request body is a JSON object with the current page's variables.
- `POST` for a `rpc` action on a button.
  - Request headers
    - `Content-Type: application/vnd.applin-request` request header
  - Request body is a JSON object with the current page's variables.
- `GET` for page content (images, etc.)

## Server Role
Every Applin server is an HTTP server that handles requests.
- Requests for pages, when request has the `Accept: application/vnd.applin-response` header
  - Response headers
    - `Content-Type: application/vnd.applin-response`
    - Response code: `200 OK`
    - Response body is a JSON object with the format described below.
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
