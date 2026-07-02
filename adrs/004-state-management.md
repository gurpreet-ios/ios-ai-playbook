# ADR 004: State Management

## Status
Accepted

## Context
Left unconstrained, AI-generated SwiftUI features scatter state everywhere: singletons holding mutable globals, `UserDefaults` used as a message bus, `@State` structs duplicated across sibling views, and environment objects mutated from background threads. Each generation invents a new pattern, and the app's behavior becomes untestable and irreproducible.

## Decision
State follows a strict ownership hierarchy:

1. **Feature state lives in one `@Observable` ViewModel per feature** (see ADR 002), annotated `@MainActor`. Views read it; only the ViewModel mutates it.
2. **Ephemeral view-local state** (a disclosure toggle, a text field draft) may use `@State` inside the view — nothing else may.
3. **Shared app state** (session, current user) lives in a single `@Observable` app-state object injected via `@Environment` — never a singleton reached by global name.
4. **Persistence is not state management.** `UserDefaults` and SwiftData are storage; reading them in a view body or using them to pass messages between features is forbidden.
5. **Data flows down, actions flow up.** Child views receive values or `@Binding`s and call methods; they never reach sideways into another feature's ViewModel.

## Consequences
**Positive:**
- Every piece of state has exactly one owner, so bugs are reproducible and previews/tests can inject state trivially.
- Reviews get mechanical: any `.shared` singleton, non-`@MainActor` mutation, or `UserDefaults` read in a `body` is an automatic flag.

**Negative:**
- Cross-feature communication needs explicit plumbing (delegate closures, shared app-state object) instead of a convenient global — more wiring up front.

## AI Anchor Usage
Inject this ADR when scaffolding any feature. It is the anchor to cite when reviewing drift: *"You drifted from our architecture. Review `adrs/004-state-management.md` and rewrite this file to comply."*
