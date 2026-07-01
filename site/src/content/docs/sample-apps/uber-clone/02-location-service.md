---
title: "Prompt 02 — LocationService"
---

## Layer
`Services/`

## Prompt

> Write a Swift 6 `actor` called `LocationService` that wraps `CLLocationManager`
> from CoreLocation for an iOS 17+ Uber clone app.
>
> **Key requirements:**
>
> 1. **Actor isolation** — The service must be an `actor`, not a class.
>    Since actors cannot directly conform to `@objc` protocols, create a
>    nested `final class Delegate: NSObject, CLLocationManagerDelegate, Sendable`
>    that bridges callbacks into `AsyncStream` continuations.
>
> 2. **AsyncStream for locations** — Expose a `nonisolated let locations: AsyncStream<CLLocation>`
>    property so consumers can `for await location in service.locations`.
>    Build the stream using `AsyncStream.makeStream()`.
>
> 3. **AsyncStream for authorization** — Expose a second
>    `nonisolated let authorizationUpdates: AsyncStream<CLAuthorizationStatus>` so
>    the UI can react to permission changes.
>
> 4. **Public methods:**
>    - `requestPermission()` — calls `requestWhenInUseAuthorization()`
>    - `startTracking()` — checks current auth status; requests permission
>      if `.notDetermined`, starts updates if authorized, no-ops if denied.
>    - `stopTracking()` — stops location updates.
>
> 5. **Delegate bridging** — The `Delegate` class receives
>    `didUpdateLocations` and `locationManagerDidChangeAuthorization` callbacks
>    and yields values into the continuations.  On authorization change to
>    `.authorizedWhenInUse` or `.authorizedAlways`, auto-start updates.
>
> 6. **Cleanup** — `deinit` must call `finish()` on both continuations.
>
> 7. **Configuration** — `desiredAccuracy = kCLLocationAccuracyBest`,
>    `distanceFilter = 10`.
>
> Import `CoreLocation` and `Foundation`. No third-party dependencies.

## Constraints

| # | Constraint | Rationale |
|---|-----------|-----------|
| 1 | Must be an `actor` | Swift 6 strict concurrency; no data races |
| 2 | Delegate must be a nested `final class` conforming to `Sendable` | Actors can't conform to `@objc` protocols directly |
| 3 | Use `AsyncStream.makeStream()` | Modern continuation-based API, not the closure initializer |
| 4 | `nonisolated` stream properties | Allows consumers to access the stream without `await` |
| 5 | No Combine / `ObservableObject` / `@Published` | Project mandate: pure async/await |
| 6 | Handle `.notDetermined` in `startTracking()` | Prevents silent failure when permission hasn't been requested |
| 7 | Auto-start on authorization grant | Eliminates extra round-trip between granting and starting |
| 8 | Must `finish()` continuations in `deinit` | Prevents dangling consumers from hanging forever |

## Review Checklist

- [ ] File compiles under Swift 6 strict concurrency with no warnings
- [ ] `LocationService` is declared as `actor`
- [ ] `Delegate` is `final class`, conforms to `NSObject`, `CLLocationManagerDelegate`, `Sendable`
- [ ] `locations` and `authorizationUpdates` are `nonisolated let` of type `AsyncStream`
- [ ] `requestPermission()`, `startTracking()`, `stopTracking()` are all present
- [ ] `startTracking()` handles `.notDetermined`, `.authorized*`, and `.denied/.restricted`
- [ ] `locationManagerDidChangeAuthorization` auto-starts on authorized
- [ ] `deinit` finishes both continuations
- [ ] No Combine imports or publishers
- [ ] No `DispatchQueue` usage
- [ ] Only imports `CoreLocation` and `Foundation`
