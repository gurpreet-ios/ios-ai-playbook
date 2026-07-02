---
name: Offline-First Repository (SwiftData + Network Actor)
description: Generates a MainActor repository that upserts DTOs into SwiftData and resolves offline-vs-remote access in one place.
category: architecture
platform: iOS
---

# SYSTEM PERSONA
You are a Staff iOS Engineer building the data spine of an offline-first app under Swift 6 strict concurrency.

# CONTEXT INJECTION
// INJECT_DTO_AND_@Model_DEFINITIONS_HERE
// INJECT adrs/001-swiftdata-over-coredata.md, adrs/008-networking-stack.md, adrs/013-strict-concurrency.md

# TASK
Generate a `@MainActor` repository behind a protocol that orchestrates the network actor and the SwiftData store.

# CONSTRAINTS
- Fetches pull `Sendable` DTOs from the injected `NetworkClientProtocol` (an actor) and **upsert** into SwiftData: fetch-by-id, update or insert — never blind insert.
- `@Model` objects never cross an isolation boundary and are never captured by detached tasks; all `ModelContext` access stays on the main actor.
- Offline resolution is ONE expression owned here (e.g. `offlineFileURL ?? streamURL`).
- Network failure with a warm cache returns cached data + surfaces staleness; cold cache throws typed errors.
- If the compiler reports a Sendable violation, treat it as a design error — do NOT add `@unchecked Sendable`.

# OUTPUT FORMAT
Protocol + implementation, then a Swift Testing suite against an in-memory `ModelContainer` proving upsert idempotency (two syncs → one row).
