# 06 — ViewModels Layer Prompt

> **Layer:** ViewModels
> **Target:** iOS 17+ · Swift 6 · SwiftUI · Strict Concurrency

---

## System Role

You are a Senior iOS Engineer writing production-quality Swift 6 code for an
Uber clone sample app. All ViewModels live under `Sources/ViewModels/`.

---

## Prompt

```text
Generate the ViewModels layer for the Uber clone Swift Package.

### Hard Constraints

1. **Swift 6 Strict Concurrency** — the package uses `swift-tools-version: 6.0`.
2. **`@MainActor @Observable final class`** — every ViewModel MUST be annotated
   with both `@MainActor` and `@Observable`. Do NOT use `ObservableObject`,
   `@Published`, or Combine.
3. **Protocol-Based Dependency Injection** — ViewModels accept repository and
   service protocols via `init`. Never instantiate concrete implementations
   inside a ViewModel.
4. **No Foundation networking** — ViewModels must NEVER import `Foundation`
   networking types (URLSession, URLRequest, etc.). All network/IO goes through
   the injected repository protocols.
5. **Views are stateless renderers** — all mutable state lives in the ViewModel.
   Views read ViewModel properties and call ViewModel methods; they own zero
   business state.
6. **Task Cancellation** — any long-running or streaming work must be stored in
   a `Task?` property. Provide a `stopTracking()` (or equivalent) method that
   calls `task?.cancel(); task = nil`. Check `Task.isCancelled` inside loops.
7. **`async/await` only** — do not use GCD, DispatchQueue, or Combine
   publishers.
8. **One type per file.**

### Types from Other Layers (use these exact names)

| Layer        | Types                                                                                       |
|--------------|---------------------------------------------------------------------------------------------|
| Models       | `Trip`, `TripStatus`, `Driver`, `LocationUpdate`, `FareEstimateDTO`, `TripResponseDTO`      |
| Repositories | `TripRepositoryProtocol`, `DriverRepositoryProtocol`                                        |
| Services     | `LocationService`                                                                           |

### Files to Generate

#### 1. `RideRequestViewModel.swift`

@MainActor @Observable class:
- Injected deps: `TripRepositoryProtocol`, `LocationService`
- Properties:
  - `pickupAddress: String`
  - `dropoffAddress: String`
  - `pickupCoordinate: CLLocationCoordinate2D?`
  - `dropoffCoordinate: CLLocationCoordinate2D?`
  - `fareEstimate: FareEstimateDTO?`
  - `isLoading: Bool`
  - `errorMessage: String?`
  - `currentUserLocation: CLLocationCoordinate2D?`
- Methods:
  - `fetchCurrentLocation() async` — gets location from LocationService
  - `estimateFare() async` — calls tripRepository, guards for coordinates
  - `requestRide() async throws -> TripResponseDTO` — submits the ride

#### 2. `ActiveTripViewModel.swift`

@MainActor @Observable class:
- Injected deps: `TripRepositoryProtocol`, `DriverRepositoryProtocol`
- Properties:
  - `trip: Trip?`
  - `driverLocation: CLLocationCoordinate2D?`
  - `driverHeading: Double`
  - `estimatedArrival: String`
  - `tripStatus: TripStatus`
  - `showCancelConfirmation: Bool`
- Private: `trackingTask: Task<Void, Never>?`
- Methods:
  - `startTrackingDriver(driverId: UUID) async` — streams driver location;
    cancels any previous task first
  - `cancelTrip() async` — cancels via repository, calls `stopTracking()`
  - `loadActiveTrip() async` — fetches active trip, auto-starts tracking
  - `stopTracking()` — cancels and nils `trackingTask`

#### 3. `DriverMapViewModel.swift`

@MainActor @Observable class:
- Injected deps: `DriverRepositoryProtocol`, `LocationService`
- Properties:
  - `nearbyDrivers: [Driver]`
  - `mapRegion: MKCoordinateRegion`
  - `selectedDriver: Driver?`
  - `isLoadingDrivers: Bool`
- Methods:
  - `loadNearbyDrivers() async` — uses LocationService for current position,
    then queries DriverRepository
  - `centerOnUser() async` — re-centers map, preserves zoom
  - `selectDriver(_ driver: Driver)` — sets selection

### Import Rules

- `import SwiftUI` — for `@Observable`
- `import MapKit` — for `CLLocationCoordinate2D`, `MKCoordinateRegion`
- Do NOT import Foundation networking (URLSession, URLRequest, etc.)
```

---

## Review Checklist

Before merging, verify every ViewModel against this checklist:

| #  | Check                                                        | Pass? |
|----|--------------------------------------------------------------|-------|
| 1  | Class is annotated `@MainActor @Observable final class`      | ☐     |
| 2  | Dependencies are protocol types injected via `init`          | ☐     |
| 3  | No concrete repository/service instantiation inside the VM   | ☐     |
| 4  | No `import Foundation` networking (`URLSession` etc.)         | ☐     |
| 5  | All mutable state lives in the ViewModel, not the View       | ☐     |
| 6  | Long-running tasks stored in `Task?` with `stopTracking()`   | ☐     |
| 7  | `Task.isCancelled` checked inside async loops                | ☐     |
| 8  | `[weak self]` used in `Task { }` closures to avoid cycles    | ☐     |
| 9  | `CancellationError` caught and silenced (not surfaced to UI) | ☐     |
| 10 | No `DispatchQueue`, no `DispatchGroup`, no Combine publishers | ☐     |
| 11 | One type per file                                            | ☐     |
| 12 | Companion `_prompts/*.prompt.md` file exists                 | ☐     |
