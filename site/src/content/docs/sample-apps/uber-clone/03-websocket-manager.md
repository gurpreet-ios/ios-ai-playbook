---
title: "Prompt 03 — WebSocketManager"
---

## Layer
`Services/`

## Prompt

> Write a Swift 6 `actor` called `WebSocketManager` for an iOS 17+ Uber clone
> app that manages a persistent WebSocket connection for receiving real-time
> driver location updates.
>
> **Key requirements:**
>
> 1. **Actor isolation** — Must be an `actor` for thread-safe state management.
>
> 2. **URLSessionWebSocketTask** — Use Foundation's built-in WebSocket support.
>    No third-party libraries (Starscream, etc.).
>
> 3. **AsyncStream output** — Expose a `nonisolated let locationUpdates: AsyncStream<LocationUpdate>`
>    where `LocationUpdate` is a `Codable, Sendable` struct with fields:
>    `driverId: String`, `latitude: Double`, `longitude: Double`,
>    `heading: Double`, `timestamp: Date`.
>
> 4. **Public methods:**
>    - `connect(url: URL)` — Opens a WebSocket connection. If already connected,
>      disconnects first. Resets reconnect state.
>    - `disconnect()` — Cleanly closes with `.normalClosure`. Sets a flag to
>      prevent auto-reconnect.
>    - `send(_ message: Codable)` — Encodes the message as JSON text and sends.
>      Throws `WebSocketError.notConnected` if no active task.
>
> 5. **Auto-reconnect with exponential backoff:**
>    - Initial delay: 1 second
>    - Multiplier: 2×
>    - Maximum delay: 30 seconds
>    - Formula: `min(1 * 2^(attempt-1), 30)`
>    - Reconnect only on unexpected disconnects (not after `disconnect()`).
>    - Reset attempt counter on successful connection.
>
> 6. **Message handling** — Support both `.text` and `.data` message types.
>    Decode incoming messages as `LocationUpdate` using ISO 8601 date strategy.
>    Log decode failures but don't terminate the stream.
>
> 7. **Connection state** — Track state via `WebSocketConnectionState` enum:
>    `.disconnected`, `.connecting`, `.connected`, `.reconnecting(attempt: Int)`.
>
> 8. **Cleanup** — `deinit` finishes the continuation. `disconnect()` cancels
>    the task with `.normalClosure` and nils out the reference.
>
> 9. **Error types** — Define `WebSocketError` enum with
>    `.notConnected` and `.encodingFailed` cases.
>
> Import only `Foundation`.

## Constraints

| # | Constraint | Rationale |
|---|-----------|-----------|
| 1 | Must be an `actor` | Safe concurrent access to connection state |
| 2 | `URLSessionWebSocketTask` only | No third-party WebSocket libraries |
| 3 | Exponential backoff: 1s, 2s, 4s, 8s … max 30s | Prevents thundering herd on server recovery |
| 4 | `nonisolated` stream property | Consumers subscribe without `await` |
| 5 | Intentional disconnect flag | Prevents reconnect loop after manual `disconnect()` |
| 6 | `Task.sleep(for:)` for backoff delays | Cooperative cancellation via structured concurrency |
| 7 | `LocationUpdate` must be `Codable, Sendable` | Crosses actor boundaries safely |
| 8 | Handle both `.text` and `.data` WebSocket frames | Servers may send either format |
| 9 | `ISO8601` date decoding | Standard timestamp format for API interop |
| 10 | Must `finish()` continuation in `deinit` | Prevents consumers from hanging |

## Review Checklist

- [ ] File compiles under Swift 6 strict concurrency with no warnings
- [ ] `WebSocketManager` is declared as `actor`
- [ ] Uses `URLSessionWebSocketTask` (no Starscream, no SocketIO)
- [ ] `locationUpdates` is `nonisolated let AsyncStream<LocationUpdate>`
- [ ] `connect(url:)`, `disconnect()`, `send(_:)` are all present
- [ ] Exponential backoff: starts at 1s, doubles each attempt, caps at 30s
- [ ] Reconnect attempt counter resets on successful connection
- [ ] `disconnect()` sets intentional-disconnect flag to prevent auto-reconnect
- [ ] Both `.text` and `.data` message types are handled
- [ ] `LocationUpdate` is `Codable, Sendable, Equatable`
- [ ] `WebSocketConnectionState` enum covers all four states
- [ ] `WebSocketError` has `notConnected` and `encodingFailed` cases
- [ ] `deinit` finishes the continuation
- [ ] No Combine imports
- [ ] No `DispatchQueue` usage
- [ ] Only imports `Foundation`
