# 05 — Repositories Layer Prompt

> Companion prompt for `TripRepository.swift` and `DriverRepository.swift`.
> Feed the **System** and **User** sections below to an AI coding agent to
> reproduce this layer from scratch.

---

## System Role

```
You are a Senior iOS Engineer writing production-quality Swift 6 code for
an Uber clone sample app.

CRITICAL RULES:
1. Target iOS 17+ and Swift 6 strict concurrency.
2. Use @Observable (NOT ObservableObject / @Published / Combine).
3. Use SwiftData with @Model (NOT CoreData).
4. Use async/await and actor for concurrency (NOT GCD / DispatchQueue).
5. Mark all ViewModels and repository implementations that touch SwiftData
   with @MainActor.
6. All views must be SwiftUI — but the Repositories layer must NEVER import
   SwiftUI.
7. Use protocol-based dependency injection throughout.
8. Keep files focused — one type per file.
```

---

## User Prompt

```
Write the REPOSITORIES layer for the Uber clone.

Base path:
  Sources/Repositories/

These files reference types from other layers — use these exact names that
exist in the same Swift module:

  Models  : Trip, TripStatus, Driver, Rider, LocationUpdate,
            TripRequestDTO, TripResponseDTO, FareEstimateDTO
  Services: NetworkClient, Endpoint, HTTPMethod

### File 1 — TripRepository.swift

Create:
- `TripRepositoryProtocol` (Sendable) with methods:
    • requestTrip(pickupLat:pickupLng:dropoffLat:dropoffLng:) async throws -> TripResponseDTO
    • cancelTrip(tripId: UUID) async throws
    • getActiveTrip() async throws -> Trip?
    • getFareEstimate(pickupLat:pickupLng:dropoffLat:dropoffLng:) async throws -> FareEstimateDTO
- `TripRepository` class conforming to the protocol:
    • Inject `NetworkClient` via init.
    • Mark with `@MainActor` (it updates SwiftData).
    • Use the `Endpoint` struct to construct each API call.
    • For `cancelTrip`, fire a PUT to `/api/v1/trips/{id}/cancel`.
    • For `getActiveTrip`, return `nil` when the server responds 404.
    • For `getFareEstimate`, pass coordinates as query items on a GET.

### File 2 — DriverRepository.swift

Create:
- `DriverRepositoryProtocol` (Sendable) with methods:
    • getNearbyDrivers(latitude:longitude:radiusKm:) async throws -> [Driver]
    • getDriver(id: UUID) async throws -> Driver
    • trackDriver(id: UUID) -> AsyncStream<LocationUpdate>
- `DriverRepository` class conforming to the protocol:
    • Inject `NetworkClient` AND `WebSocketManager` via init.
    • `getNearbyDrivers` builds a GET endpoint with query items.
    • `getDriver` builds a GET endpoint with the driver ID in the path.
    • `trackDriver` delegates to `WebSocketManager.locationUpdates(forChannel:)`,
      wrapping in an `AsyncStream` that filters updates by `driverId`.
- `WebSocketManager` protocol (Sendable) with:
    • `locationUpdates(forChannel:) -> AsyncStream<LocationUpdate>`

### Architectural Constraints

1. **Repository Pattern** — every data operation is defined in a protocol.
   The concrete class implements the protocol and owns the networking detail.
2. **ViewModels must NEVER import `NetworkClient` directly.** They depend
   only on repository protocols, received via initialiser injection.
3. **All data access is abstracted behind the protocol** — swap the concrete
   class for a mock in previews and tests without touching ViewModel code.
4. **No UI imports** — the Repositories layer must not import SwiftUI or
   reference any View type.
```

---

## Review Checklist

Before merging, verify each item:

| # | Check | Pass? |
|---|-------|-------|
| 1 | Every public data method is declared on a **protocol** first | ☐ |
| 2 | Concrete classes conform to their protocol | ☐ |
| 3 | Dependencies are injected through `init` (no singletons, no service locators) | ☐ |
| 4 | `@MainActor` is applied to classes that mutate SwiftData models | ☐ |
| 5 | All protocols are marked `Sendable` (Swift 6 requirement) | ☐ |
| 6 | Neither file imports `SwiftUI` | ☐ |
| 7 | No ViewModel references appear anywhere in the layer | ☐ |
| 8 | `AsyncStream` usage includes `onTermination` to cancel the backing `Task` | ☐ |
| 9 | `NetworkError` cases cover 404 → `nil` conversion in `getActiveTrip` | ☐ |
| 10 | Files compile in the flat `Sources/` target with no Xcode project | ☐ |

---

## How to Regenerate

```bash
# From the repo root, the package should compile with:
swift build
```

If the Models or Services layers are not yet written, the Repositories layer
will show expected "cannot find type" errors — that is correct; it is
designed to compile once all layers are present in the same target.
