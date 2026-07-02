# ADR 010: Initializer Injection from a Composition Root (No DI Framework, No Singletons)

## Status
Accepted

## Context
AI-generated code reaches for `static let shared` the moment two objects need the same dependency — hidden coupling that defeats testing and bypasses ownership (the Chapter 14 PR review caught exactly this). DI frameworks solve it with registration magic, but magic is precisely what an LLM hallucinates against: containers it half-remembers, resolution APIs from other frameworks.

## Decision
Dependencies are **injected through initializers as protocols**, wired in one **composition root** (the `App` struct + root view, e.g. `AppRootView` in the spine app). The root owns singleton-*lifetime* objects (the `ModelContainer`, engines, app-scoped ViewModels) as ordinary instances — singleton lifetime without singleton *access*. No `static let shared` in production code; no DI framework; `@Environment` is reserved for system values and view-layer concerns, never for repositories or engines (and never read in `init` — the Chapter 16 crash).

## Consequences
**Positive:**
- Every dependency is visible in the initializer signature — reviewable, mockable (Ch 26 spies), and explicit in prompts.
- The object graph is plain code the AI can read and extend; there is no registration state to hallucinate.
- App Intents and widgets can reuse the same seams (Ch 34's `@Dependency` registration wraps the same instances).

**Negative:**
- Long initializer chains in deep trees; mitigated by grouping (a `Dependencies` struct) when a root grows past ~6 parameters.
- Manual wiring is boilerplate — ideal AI work, but it lands in one high-review-value file.

## AI Anchor Usage
Inject when scaffolding features or reviewing construction code. Anchor phrases: *"No `.shared`, no service locators — add the dependency to the initializer as a protocol and wire it in the composition root. Flag any `@Environment` read inside an `init`."*
