# 02 – NetworkClient Prompt

> Companion prompt document for `Services/NetworkClient.swift`.

**Interview clock:** ~0:10 · **Time to type:** ~30 seconds

---

## What you say to the interviewer first

> "One generic GET client behind a protocol. It's an actor so the decoder and
> any future auth state are race-free by construction — that's the Swift 6 way
> of saying 'thread-safe' without a lock in sight."

---

## Prompt

```text
Create Services/NetworkClient.swift.

1. NetworkError enum (Error, LocalizedError): invalidURL,
   requestFailed(statusCode: Int), decodingFailed(underlying: Error).
   User-presentable errorDescription for each.

2. protocol NetworkClientProtocol: Sendable with one generic method:
   get<Response: Decodable & Sendable>(_:path:queryItems:) async throws
   -> Response

3. actor NetworkClient conforming to it. Init takes baseURL and a URLSession
   (default .shared). JSONDecoder with .convertFromSnakeCase, created once.
   The get method builds the URL with URLComponents (throw invalidURL on
   failure), awaits session.data(from:), validates 2xx (throw requestFailed
   with the real status code), decodes (wrap decoding errors in
   decodingFailed).

No completion handlers, no GCD, no force-unwraps.
```

---

## Key Constraints Enforced

| # | Constraint | Why |
|---|-----------|-----|
| 1 | `actor`, not `final class` + lock | Mutable client state (future auth token) is isolated by the compiler, not by discipline. |
| 2 | Generic `get` behind a protocol | Repositories stay stubbable in tests without a network. |
| 3 | Status-code validation before decoding | A 500 with an HTML body must surface as `requestFailed`, not a confusing decoding error. |
| 4 | Decoder built once in `init` | AI loves allocating a `JSONDecoder` per call; pointless churn. |
| 5 | `.convertFromSnakeCase` centralised | DTOs stay clean camelCase with zero `CodingKeys` boilerplate. |

---

## What to Review in the Output

- [ ] The decoder is a stored property, not created inside `get`.
- [ ] Non-HTTP responses don't crash — a safe fallback status code is used.
- [ ] `queryItems` is set to nil when empty (avoids a trailing `?` in the URL).
- [ ] Errors are the typed `NetworkError`, never a bare `URLError` rethrow for status failures.
- [ ] `grep -n "DispatchQueue" Sources/Services/NetworkClient.swift` returns nothing.
