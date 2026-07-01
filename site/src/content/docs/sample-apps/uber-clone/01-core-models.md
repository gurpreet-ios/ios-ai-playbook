---
title: "01 – Core Models Layer Prompt"
---

> Companion prompt document for the **Models/** layer of the Uber Clone sample app.
> This file records the **exact prompt** a Senior iOS Engineer would feed to an AI
> coding agent to produce every Swift file in this directory.

---

## System Role

```text
You are a Senior iOS Engineer writing production-quality Swift 6 code for an Uber
clone sample app.

CRITICAL RULES:
1. All code must target iOS 17+ and Swift 6 strict concurrency.
2. Use @Observable (NOT ObservableObject / @Published / Combine).
3. Use SwiftData with @Model (NOT CoreData).
4. Use async/await and actor for concurrency (NOT GCD / DispatchQueue).
5. Mark all ViewModels with @MainActor.
6. All views must be SwiftUI.
7. Code must be self-contained and compilable inside a Swift Package (no Xcode
   project needed).
8. Use protocol-based dependency injection throughout.
9. Keep files focused — one type per file.
```

---

## Prompt

```text
Write the MODELS layer for the Uber clone.

Base path: Sources/Models/

Create the following files:

### 1. Rider.swift
SwiftData `@Model` class with these stored properties:
- id: UUID (unique)
- name: String
- email: String
- phoneNumber: String
- rating: Double (default 5.0)
- savedAddresses: [SavedAddress] (embedded Codable array)

Also define a `SavedAddress` struct (Codable, Sendable, Hashable) with:
- label: String
- latitude: Double
- longitude: Double

Provide a memberwise initialiser with sensible defaults.

### 2. Driver.swift
SwiftData `@Model` class with:
- id: UUID (unique)
- name: String
- vehicleMake: String
- vehicleModel: String
- licensePlate: String
- rating: Double (default 5.0)
- isAvailable: Bool (default true)
- currentLatitude: Double (default 0.0)
- currentLongitude: Double (default 0.0)

Provide a memberwise initialiser with sensible defaults.

### 3. Trip.swift
SwiftData `@Model` class with:
- id: UUID (unique)
- riderId: UUID
- driverId: UUID? (nil until matched)
- status: TripStatus (default .requested)
- pickupLatitude: Double
- pickupLongitude: Double
- dropoffLatitude: Double
- dropoffLongitude: Double
- requestedAt: Date (default .now)
- completedAt: Date? (nil)
- fare: Double? (nil until finalised)

Define `TripStatus` as an enum that is `String, Codable, Sendable, CaseIterable`
with cases: requested, driverAssigned, driverArrived, inProgress, completed,
cancelled.

### 4. LocationUpdate.swift
A plain `struct` (NOT @Model) that is `Codable, Sendable, Hashable` with:
- driverId: UUID
- latitude: Double
- longitude: Double
- heading: Double
- speed: Double
- timestamp: Date

This represents ephemeral real-time telemetry — it is never persisted to
SwiftData.

### 5. APIModels.swift
Three DTO structs, all `Codable, Sendable, Hashable`:

**TripRequestDTO**
- pickupLatitude: Double
- pickupLongitude: Double
- dropoffLatitude: Double
- dropoffLongitude: Double

**TripResponseDTO**
- tripId: UUID
- estimatedFare: Double
- estimatedArrivalMinutes: Int

**FareEstimateDTO**
- baseFare: Double
- distanceFare: Double
- timeFare: Double
- totalFare: Double
- currency: String

### Code-style requirements
- Add `// MARK: -` section headers.
- Write concise doc-comments on every type and every property.
- Import only `Foundation` and `SwiftData` (where needed).
- Do NOT import UIKit or Combine.
- Every file should start with a brief file-header comment.
```

---

## Key Constraints Enforced

| # | Constraint | Why |
|---|-----------|-----|
| 1 | `@Model` on persistent entities only | `LocationUpdate` is ephemeral — storing it in SwiftData would bloat the DB. |
| 2 | `TripStatus` is `String`-backed | Ensures stable, human-readable persistence and JSON serialisation. |
| 3 | All structs are `Sendable` | Required by Swift 6 strict concurrency for cross-isolation transfer. |
| 4 | DTOs are separate from `@Model` types | Decouples the API contract from the persistence schema. |
| 5 | `@Attribute(.unique)` on every `id` | Prevents duplicate inserts and enables upsert semantics. |
| 6 | Coordinates as separate `Double` fields | Avoids custom transformable overhead; keeps queries simple. |
| 7 | No Combine / `ObservableObject` / `@Published` | Project mandates `@Observable` (Observation framework, iOS 17+). |
| 8 | No CoreData | Project mandates SwiftData exclusively. |

---

## What to Review in the Output

- [ ] **Compilation** – `swift build` succeeds with no warnings under `-strict-concurrency=complete`.
- [ ] **Sendable conformance** – All structs explicitly declare `Sendable`. `@Model` classes get implicit `Sendable` from the macro.
- [ ] **No Combine imports** – `grep -r "import Combine" Sources/Models/` returns nothing.
- [ ] **No UIKit imports** – `grep -r "import UIKit" Sources/Models/` returns nothing.
- [ ] **Unique IDs** – Every `@Model` class has `@Attribute(.unique) var id: UUID`.
- [ ] **Default values** – Initialisers provide sensible defaults (`rating: 5.0`, `status: .requested`, etc.).
- [ ] **Doc-comments** – Every public type and property has a `///` doc-comment.
- [ ] **One type per file** – Except `SavedAddress` (embedded helper in `Rider.swift`) and the DTO collection in `APIModels.swift`.
- [ ] **File headers** – Each file has a `// MARK: -` header identifying the file name and layer.
- [ ] **`TripStatus` is `CaseIterable`** – Useful for testing and UI pickers.
