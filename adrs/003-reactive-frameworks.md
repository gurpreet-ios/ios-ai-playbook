# ADR 003: Structured Concurrency over Reactive Frameworks

## Status
Accepted

## Context
The Swift ecosystem has cycled through several asynchronous programming models: delegate callbacks, closure-based completion handlers, RxSwift, and Combine. Reactive streams are powerful, but they carry a steep learning curve, poor debuggability (stack traces die at the subscription boundary), and — critically for this playbook — they are a hallucination magnet: LLMs trained on a decade of RxSwift/Combine tutorials will happily generate `flatMapLatest` chains in a codebase that has none.

Swift's structured concurrency (`async/await`, `AsyncSequence`, `Task`, actors) is now the language-native model, is enforced by the Swift 6 compiler, and produces linear, readable code that AI generates far more reliably.

## Decision
All new asynchronous code uses **structured concurrency**. RxSwift is banned in new code. Combine is permitted only where a platform API still requires it (e.g., bridging a legacy publisher); wrap it at the boundary and expose an `AsyncSequence` or `async` function to the rest of the app.

## Consequences
**Positive:**
- Linear control flow — errors propagate with `throws`, cancellation with `Task` — dramatically easier to review.
- Swift 6 strict concurrency proves data-race safety at compile time; reactive graphs get no such proof.
- **AI Compatibility:** one idiom to enforce. A single constraint line ("use async/await; no Combine/RxSwift") eliminates an entire category of drift.

**Negative:**
- Multi-value streams (search-as-you-type debouncing, socket feeds) need `AsyncSequence`/`AsyncStream`, which is less battle-tested than Combine operators.
- Legacy modules built on publishers require bridging shims until migrated.

## AI Anchor Usage
Inject this ADR whenever the AI proposes or touches asynchronous code. If a generation includes `import Combine` or `import RxSwift`, reply: *"Read `adrs/003-reactive-frameworks.md` and rewrite to comply."*
