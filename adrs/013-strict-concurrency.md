# ADR 013: Swift 6 Strict Concurrency Everywhere; Escape Hatches Are Waivers

## Status
Accepted

## Context
AI models trained on pre-Swift-6 code generate GCD idioms, detached tasks capturing mutable state, and `@unchecked Sendable` as an error-silencer. Strict concurrency converts that entire class of shipped races into build failures (Chapter 12) — but only if the escape hatches are governed, because the AI's cheapest path to green is deleting the diagnostic rather than the race.

## Decision
- **Swift 6 language mode with strict concurrency in every target, including tests** (per Ch 30 gate 1).
- **Isolation defaults:** UI/app modules adopt Swift 6.2 `.defaultIsolation(MainActor.self)`; infrastructure targets stay nonisolated-by-default with explicit `actor`s for shared mutable state. Each module's manifest choice is documented in its rules-file section, because the AI cannot see build settings and must be told which world it is in (Ch 12).
- **Escape hatches are waivers:** `@unchecked Sendable` and `nonisolated(unsafe)` require a code comment stating the invariant that makes them safe and a PR reviewer's explicit sign-off. AI-added waivers are review-blocking by default (the `data-race.md` playbook standard).
- **Model confinement:** SwiftData `@Model` types stay `@MainActor`-confined; DTOs cross boundaries (ADR 001/008). `@ModelActor` is adopted only when profiling shows main-thread write pressure.

## Consequences
**Positive:**
- Data races become compile errors; TSan (Ch 30 gate 5) polices only the waiver zones.
- Prompting simplifies to a stable rule set the agent can follow mechanically.

**Negative:**
- Interop with non-Sendable frameworks (KVO, delegates) needs deliberate bridging patterns; occasional annotation friction on legacy files.

## AI Anchor Usage
Inject for any concurrent code, and whenever a Sendable diagnostic appears. Anchor phrase: *"Treat concurrency errors as design errors — restructure isolation; never add `@unchecked Sendable`/`nonisolated(unsafe)`. This module's default isolation is <MainActor | nonisolated>."*
