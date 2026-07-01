# Prompt 04 — NetworkClient

## Layer
`Services/`

## Prompt

> Write a Swift 6 `actor` called `NetworkClient` for an iOS 17+ Uber clone app
> that provides a generic REST API client using `URLSession`.
>
> **Key requirements:**
>
> 1. **Actor isolation** — Must be an `actor` for safe concurrent request handling.
>
> 2. **Generic request method:**
>    ```swift
>    func request<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T
>    ```
>    This single method handles all REST calls, returning decoded responses.
>
> 3. **Endpoint struct** — Define a `Sendable` struct with:
>    - `path: String`
>    - `method: HTTPMethod` (default `.get`)
>    - `body: (any Encodable & Sendable)?` (default `nil`)
>    - `queryItems: [URLQueryItem]?` (default `nil`)
>
> 4. **HTTPMethod enum** — Raw `String` values: `"GET"`, `"POST"`, `"PUT"`, `"DELETE"`.
>    Must conform to `Sendable`.
>
> 5. **APIError enum** — Four cases, all `Sendable`:
>    - `.invalidURL` — The constructed URL was malformed
>    - `.decodingFailed(Error)` — JSON decoding failed
>    - `.httpError(statusCode: Int, data: Data)` — Non-2xx response
>    - `.networkError(Error)` — Transport/connectivity failure
>    Conform to `LocalizedError` with descriptive messages.
>
> 6. **Request building:**
>    - Append `endpoint.path` to the configurable `baseURL`.
>    - Apply `queryItems` via `URLComponents`.
>    - Set `Content-Type: application/json` and `Accept: application/json` headers.
>    - Encode the body using `JSONEncoder` via an `AnyEncodable` type-erased wrapper.
>
> 7. **Response validation:**
>    - Only HTTP 200-299 is considered success.
>    - Non-success throws `.httpError(statusCode:data:)`.
>    - Decoding failure throws `.decodingFailed(Error)`.
>    - Transport errors throw `.networkError(Error)`.
>
> 8. **Initialization** — Accept `baseURL: URL`, optional `session: URLSession`,
>    optional `encoder: JSONEncoder`, optional `decoder: JSONDecoder`.
>
> Import only `Foundation`.

## Constraints

| # | Constraint | Rationale |
|---|-----------|-----------|
| 1 | Must be an `actor` | Safe concurrent access; no shared mutable state races |
| 2 | Generic `<T: Decodable & Sendable>` return | Type-safe decoding without manual casting |
| 3 | `Endpoint` must be `Sendable` | Crosses actor isolation boundaries |
| 4 | `AnyEncodable` wrapper for body encoding | `any Encodable` can't be encoded directly |
| 5 | Only 200-299 is success | Standard HTTP success range |
| 6 | Separate error cases for decode vs. HTTP vs. network | Callers need different recovery strategies for each |
| 7 | `URLSession` injection via init | Enables unit testing with mock sessions |
| 8 | No Alamofire / Moya / third-party | Project mandate: Foundation only |
| 9 | `LocalizedError` conformance on `APIError` | Better debugging and user-facing messages |
| 10 | `@unchecked Sendable` on `AnyEncodable` | The closure captures an `Encodable`, safe by construction |

## Review Checklist

- [ ] File compiles under Swift 6 strict concurrency with no warnings
- [ ] `NetworkClient` is declared as `actor`
- [ ] `request<T>()` method signature matches spec exactly
- [ ] `Endpoint` struct has all four fields with correct defaults
- [ ] `HTTPMethod` enum has `get`, `post`, `put`, `delete` with raw strings
- [ ] `APIError` has all four cases
- [ ] `APIError` conforms to `LocalizedError` with descriptions
- [ ] URL is built with `URLComponents` + `queryItems`
- [ ] `Content-Type` and `Accept` headers are set to `application/json`
- [ ] Body encoding uses `AnyEncodable` wrapper
- [ ] HTTP status validation: only 200-299 passes
- [ ] Decoder and encoder are injectable via init
- [ ] `baseURL` is a `let` property on the actor
- [ ] No Combine, no Alamofire, no third-party imports
- [ ] Only imports `Foundation`
