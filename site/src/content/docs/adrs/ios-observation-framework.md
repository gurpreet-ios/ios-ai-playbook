---
title: "ADR 002: Observation Framework over Combine"
---

## Status
Accepted

## Context
For the past several years, state management in SwiftUI was driven by the Combine framework (`ObservableObject`, `@Published`, `@StateObject`). While powerful, it often resulted in over-rendering, as a change to *any* `@Published` property would invalidate the entire view holding the object, even if the view didn't read that specific property.

## Decision
We will exclusively use the Swift 5.9+ `@Observable` macro (the Observation framework) for all new state management and ViewModels.

## Consequences
**Positive:**
- **Performance:** `@Observable` tracks property access at the property level, meaning views only re-render if the specific property they read changes.
- **Simplicity:** Removes the need for `@Published` and simplifies dependency injection (can use standard `@State` instead of `@StateObject`).
- **AI Compatibility:** The macro drastically reduces boilerplate, making AI code generation faster and less prone to property wrapper mismatches.

**Negative:**
- **Combine Interoperability:** If a legacy module still relies heavily on Combine publishers, bridging them to Observation requires manual `withObservationTracking` or custom async sequences.

## AI Anchor Usage
Inject this ADR into the system prompt when asking the AI to build SwiftUI Views or ViewModels to prevent it from generating legacy `ObservableObject` code.
