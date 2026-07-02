# ADR 011: Swift Testing First, Behavior-Contract Tests, the Deletion Standard

## Status
Accepted

## Context
AI writes both our code and most of our tests, which creates the tautology risk: suites that mirror stubs, echo implementations, and stay green while features break (Chapter 26). A testing ADR must therefore fix not just the framework but the *standard of evidence*.

## Decision
- **Framework:** Swift Testing (`@Test`, `#expect`, `#require`, `@Suite`) for all new tests; XCTest remains only for UI automation (`XCUITest`), performance metrics, and untouched legacy suites.
- **Ownership:** humans own test *names and assertions* (the behavior contract); AI generates ceremony (mocks/spies per `prompts/testing/generate-mock.md`, fixtures, bodies).
- **The deletion standard:** a test is acceptable only if a named line of production code, when deleted or inverted, makes it fail. Generated suites pass through `prompts/testing/tautology-audit.md` before merge.
- **Regression rule:** every production bug closes with a test that failed on the pre-fix code (proof: the failure output in the PR).
- **Async:** no `Task.sleep` synchronization — test-controlled continuations, `confirmation`, or bounded yields.

## Consequences
**Positive:**
- Green means something; the suite grows where reality bit us (bug-derived tests are never tautological).
- Swift Testing's concurrency-native API removes the `expectation` dance the AI hallucinates worst.

**Negative:**
- The audit adds a review step per generated suite (~2 minutes; cheapest insurance in the stack).
- Two frameworks coexist during the XCTest long tail.

## AI Anchor Usage
Inject when asking for tests or reviewing them. Anchor phrases: *"Swift Testing only; hardcoded expected values; for each test, name the production line that would make it fail; do not modify tests to make implementations pass."*
