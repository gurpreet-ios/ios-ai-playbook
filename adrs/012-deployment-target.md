# ADR 012: Deployment Target = Current Major − 1, Reviewed Each September

## Status
Accepted

## Context
Every chapter's patterns lean on recent APIs: `@Observable` and SwiftData (iOS 17), Swift Testing, Foundation Models and Liquid Glass (iOS 26). Meanwhile LLMs cannot see build settings — they generate against whatever API level their training data favors, so an *undocumented* target produces silent `#available` guesswork and phantom-API review noise (Ch 14). The target must be a written fact the AI is always told.

## Decision
The minimum deployment target is **the previous major iOS version** (N−1), re-evaluated every September against adoption data and the feature cost of holding back. Newer-OS features (e.g. iOS 26 on-device models when the target is 25) ship behind `if #available` with a **designed fallback** — the capability-check rule of Chapter 34, not a blank screen. Raising the target is a one-line PR referencing this ADR plus the adoption snapshot; lowering it requires a rewrite of this ADR and is expected never to happen.

## Consequences
**Positive:**
- N−1 keeps the modern stack (Observation/SwiftData baseline) unblocked while covering the large majority of active devices.
- A written target turns availability from vibes into a checkable constraint in every prompt and review.

**Negative:**
- Bleeding-edge features carry dual-path cost for one year (fallback + flag), and older-device users churn to a frozen feature set at N−2.

## AI Anchor Usage
Inject into any prompt generating platform-API code (and keep the current target in the rules file). Anchor phrase: *"Target is iOS <N−1>. Do not use newer APIs without `if #available` plus a designed fallback; do not add availability guards for APIs older than the target."*
