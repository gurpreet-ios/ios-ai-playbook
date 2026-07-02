# Chapter 30: Verifying AI Output at Scale

> "When one engineer generates the code of five, review by reading stops working. The only thing that scales with generation is verification."

Chapters 14 and 26 gave you the review taxonomy and the test audit. This chapter assembles them — plus the layers no human review can perform at all — into a **verification stack**: an ordered series of machine gates that AI-generated Swift must pass before a human spends attention on it. The organizing principle: *every gate you automate upgrades your role from proofreader to editor.*

## The Verification Gap

An agent can produce a 2,000-line, 12-file feature in minutes. Reading it line-by-line takes hours and — as Chapter 14 showed — misses the systemic failures anyway. Meanwhile the failure modes of AI code are *skewed*: it compiles more often than junior-human code but is confidently wrong in ways that only manifest under concurrency, memory pressure, or a device you don't demo on. The response is not "review harder." It is to make the machine prove properties before review begins.

The iOS verification stack, cheapest gate first:

| # | Gate | Catches | Cost |
| :-- | :--- | :--- | :--- |
| 1 | Swift 6 strict-concurrency build | Phantom APIs, data races, isolation errors | Seconds |
| 2 | Swift Testing suite (+ tautology audit) | Behavior regressions, contract violations | Seconds–minutes |
| 3 | Snapshot tests | Unintended visual change, layout drift | Seconds |
| 4 | UI tests + `performAccessibilityAudit()` | Broken flows, a11y regressions | Minutes |
| 5 | Sanitizers (TSan/ASan) on the test suite | Races strict concurrency can't see, memory corruption | Minutes |
| 6 | Performance gates (hitch/launch/memory budgets) | The "works on the demo device" class | Minutes |

A PR that reaches your eyes has already passed all six. What's left for you is what only you can do: architecture, intent, and the ADR diff.

## Gate 1: The Compiler Is Your First Reviewer

The Swift 6 strict-concurrency build is the highest-value verification you own, because it converts an entire class of production crashes into build failures (Chapter 12's detached-task race). Two rules make it a real gate:

1. **Strict concurrency everywhere, including test targets.** AI-generated test ceremony is where `@unchecked Sendable` waivers breed.
2. **Warnings-as-errors for the AI's tells.** Unused variables, unreachable code, deprecated APIs — individually harmless, collectively the residue of iterative generation (Chapter 14's dead-code failure mode). `SWIFT_TREAT_WARNINGS_AS_ERRORS` turns the residue into a red build the agent must clean itself.

The agent loop (Chapter 20) makes this gate free: the agent runs `xcodebuild build` after every edit and fixes its own compile errors before you ever see the diff.

## Gate 2: Tests — With the Audit Applied

Chapter 26 in one line: AI-generated tests are only evidence after they survive the **deletion test** and the tautology audit (`prompts/testing/tautology-audit.md`). At scale, add the ratchet rule: **coverage may not decrease on a PR**. Not because a percentage means quality — it doesn't — but because generation volume without a ratchet reliably produces the opposite drift, and the ratchet is free to enforce in CI.

## Gate 3: Snapshot Tests — Diffing What You Can't Read

You cannot review rendering by reading SwiftUI. A snapshot suite (e.g. `swift-snapshot-testing`) renders views to images and fails on pixel drift — which changes the review question from "does this modifier chain look right?" to "is this before/after image pair intended?" That is a question a human answers in two seconds.

Snapshots earn their keep against a specific AI behavior: **collateral UI drift**. Ask an agent to fix a button's padding and it may "helpfully" normalize spacing across the whole screen. A failing snapshot on `NowPlayingView` when the ticket was about `LibraryView` is exactly the tripwire you want.

Configuration discipline the AI won't apply unless told: record snapshots for a **fixed device, OS, locale, and both color schemes plus one accessibility text size** — otherwise the suite flakes on environment drift and the team learns to ignore red, which is worse than no suite:

> *"Add snapshot tests for `NowPlayingView` in states: no track, playing, paused. Record on iPhone 16 / light + dark / `.extraExtraLarge` Dynamic Type. Pin the locale. If a snapshot fails on an intentional change, the diff image goes in the PR description."*

## Gate 4: Flows and the Accessibility Audit

Unit and snapshot layers can all pass while the app's *flows* are broken (a navigation destination never wired, a button disabled by a stale condition). A thin XCUITest layer — launch, tap through each top-level flow, assert the destination renders real data — catches integration failures cheaply. Keep it thin: UI tests are the most expensive gate to maintain, so they verify *reachability*, not business logic.

And every screen in that flow gets `try app.performAccessibilityAudit()` (Chapter 25), which turns the entire accessibility category from "hope the prompt worked" into a regression gate.

## Gate 5: Sanitizers — Guilty Until Proven Innocent

Strict concurrency proves what the *compiler* can see. Every `@unchecked Sendable`, every C/Objective-C boundary, every KVO bridge is a zone where it sees nothing — and those zones are precisely where AI-generated code concentrates its waivers. So the CI test run executes twice: once plain, once with **Thread Sanitizer** enabled. Address Sanitizer joins on a schedule (nightly) rather than per-PR — it's slower, and its findings (buffer overruns, use-after-free at framework boundaries) drift in more rarely.

The policy that makes this a *gate* rather than a dashboard: a TSan finding is a merge blocker, and the fix must remove the race, not the report. An agent asked to "fix the TSan failure" will, with nonzero probability, suggest suppressing it. The prompt rule from Chapter 12 applies verbatim: escape hatches are design errors.

## Gate 6: Performance Budgets

Chapter 15's lesson operationalized: AI-generated performance bugs are invisible on demo hardware, so the gate must be numeric. Three budgets, checked by CI on a real or simulated mid-range target:

- **Launch:** cold launch under the watchdog budget with margin (measure via `XCTApplicationLaunchMetric` or the App Launch instrument's CLI harness).
- **Hitches:** scroll the primary list; hitch time ratio under ~5ms/s (`XCTOSSignpostMetric.scrollDecelerationMetric` in a perf test).
- **Memory:** peak footprint on the golden path under a fixed ceiling — the jetsam insurance from Chapter 16's taxonomy.

Budgets move only by explicit decision, recorded in the ADR that owns them. "The new feature needs 80MB more" is sometimes true — but it's a *decision*, not a drift.

## The Probabilistic Layer: When Your App Ships an LLM

If the feature itself calls a model (Chapter 34's on-device intelligence, or a server-side LLM feature), classical tests can't assert exact outputs. The verification unit becomes an **eval**: a fixed set of inputs, a scoring rule (exact-match where possible, rubric-scored where not), and a threshold tracked over time like coverage. The rules: pin the eval set in the repo, run it on every model or prompt change, and never let the model that generated a prompt also be the sole judge of its outputs. Evals are to AI features what snapshot tests are to UI — a diffable artifact standing in for judgment you can't apply per-request.

## Wiring the Stack Into CI

On macOS runners (Chapter 20's cost note), the assembled pipeline for MusicApp-shaped projects:

```yaml
jobs:
  verify:
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v4
      - name: Build (strict concurrency, warnings as errors)
        run: xcodebuild build -scheme App -destination "$SIM" \
             SWIFT_TREAT_WARNINGS_AS_ERRORS=YES
      - name: Tests + snapshots
        run: xcodebuild test -scheme App -destination "$SIM"
      - name: Tests under Thread Sanitizer
        run: xcodebuild test -scheme App -destination "$SIM" -enableThreadSanitizer YES
      - name: UI flows + a11y audit
        run: xcodebuild test -scheme AppUITests -destination "$SIM"
      - name: Performance budgets
        run: xcodebuild test -scheme AppPerfTests -destination "$SIM"
```

Order matters — cheap gates first, so an agent iterating in a PR loop gets its compile failure in seconds, not after a 20-minute UI test run it was always going to fail.

## The Human Layer, Redefined

With six machine gates in front of you, your review (Chapter 14's tiers) starts from a provable baseline: it compiles under the strictest settings, its tests are falsifiable, its pixels and flows and budgets are unchanged unless declared. Everything that remains red-flaggable is *judgment*: does this belong here, does it match the ADRs, will we want to own it in a year. That is the job description. The machine verifies; you decide.
