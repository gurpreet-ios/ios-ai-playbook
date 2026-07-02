# ADR 006: Modularization by Layer-Then-Feature (SwiftPM)

## Status
Accepted

## Context
As codebases and AI generation volume grow, a single target means every prompt exposes the whole app as editable context, and every convenience import is legal. AI agents generating file-by-file optimize local convenience, which sums to import cycles and cross-layer coupling (see Chapter 10's cyclic-dependency failure).

## Decision
We modularize with **SwiftPM targets**: a leaf `Models` target (pure value types, zero dependencies), peer infrastructure targets (`Networking`, `Persistence`, and domain engines like `Audio`) that depend only on `Models` and never on each other, and an app/composition layer that owns repositories, ViewModels, and Views. Feature targets are split out of the app layer when a feature exceeds roughly ten files or two engineers. Everything is `internal` by default; each target exports a protocol surface.

## Consequences
**Positive:**
- **Cycles are build errors**, not archaeology — SwiftPM refuses `A -> B -> A` at resolution time.
- **Context bounding:** "fix X in `Networking`" hands the agent three files and a protocol, not the app. The module boundary is the context-window boundary (and the token-bill boundary, Ch 35).
- **Access control as a guardrail:** the AI physically cannot call what isn't `public`.

**Negative:**
- Orchestration needing two peers must live in a repository in the composition layer — occasionally verbose.
- Manifest churn on new targets; DTO/domain mapping boilerplate at boundaries (AI-generated, reviewed once).

## AI Anchor Usage
Inject when asking an agent to create new targets, move files between layers, or add dependencies to `Package.swift`. Anchor phrase: *"Peers depend only on `Models` — if you want a peer-to-peer import, stop and surface it as a design question instead."*
