---
name: xcode-build-triage
description: Triages Xcode build failures by running the build and classifying compiler errors into categories before fixing anything — prevents the one-error-at-a-time hallucination loop. Use when a Swift/iOS build fails, xcodebuild reports errors, or the user pastes a compiler error like "MainActor isolation" or "does not conform to Sendable".
---

# Xcode Build Triage

You fix build failures by category, never one error at a time. Chasing errors singly is how agents enter the hallucination loop: each "fix" mutates the architecture a little more until the build passes and the design is gone.

## Gather context

1. Reproduce the failure yourself: `xcodebuild build -quiet` with the project's scheme/destination (check for a Makefile, CI workflow, or README that records the exact invocation). Never triage from a pasted fragment alone if you can run the build.
2. Capture the FULL error list, not the first error — Swift emits cascades where one root cause produces dozens of downstream diagnostics.
3. Read the project's anchors before proposing fixes: rules files and ADRs that pin the concurrency and architecture decisions (e.g., "no `@unchecked Sendable`", "ViewModels are `@MainActor`").

## Procedure

1. Classify every error into: **actor isolation**, **Sendable conformance**, **opaque return types** (`some View` mismatches), **missing/renamed dependency**, or **stale generated code** (SwiftData/macros — clean build folder first).
2. Identify the root category: which class of error, if fixed, clears the most downstream diagnostics? Fix that category first.
3. Fix the CATEGORY across the codebase, not the instance — one isolation fix often clears a dozen errors. Re-run the build between categories, not between files.
4. If two consecutive category-fixes do not reduce the error count, STOP and re-derive: you are treating a symptom. Present the remaining errors and your architectural hypothesis to the user instead of iterating.

## Constraints

- NEVER weaken concurrency to silence an error: no `@unchecked Sendable` without a synchronization mechanism, no stripping `@MainActor` from UI-bound types, no `try!`/force-unwrap to satisfy the type checker.
- Respect the repo's recorded decisions over the compiler's path of least resistance.

## Output format

Error census (`category | count | representative error`), the chosen root category with reasoning, then fixes per category with the re-run result after each.
