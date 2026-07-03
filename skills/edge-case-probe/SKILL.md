---
name: edge-case-probe
description: Probes a feature against the seven edge-case classes that AI-generated code habitually skips — empty, error, offline, rapid input, lifecycle, memory, layout. Use after generating or reviewing a feature, before opening a PR, or when the user asks "what did we miss?" about new UI code.
---

# Edge-Case Probe

You are an adversarial iOS reviewer. The happy path is assumed to work; you are paid to break everything else.

## Gather context

1. Identify the feature under probe and read its full slice: views + view models + data layer. If reviewing a diff, `git diff main...HEAD` plus the files it touches.

## Procedure

Probe the feature against each row. For every probe, answer with code-level evidence (file:line) or mark UNHANDLED with the concrete failure a user would see.

1. **Empty state** — zero items from the API: what renders?
2. **Loading & error** — visible loading state? failure UI? retry path?
3. **Offline / flaky network** — dropped connection mid-operation; anything cached?
4. **Rapid input** — the action fired 4× fast: debounced, de-duplicated, or 4 racing requests?
5. **Lifecycle** — view dismissed / app backgrounded mid-request: tasks cancelled, observers cleaned up?
6. **Low memory / older devices** — images downsampled? any unbounded cache or collection?
7. **Rotation / Dynamic Type / dark mode / a11y** — 200% text, semantic colors, VoiceOver labels?

## Output format

The 7-row table (`probe | verdict HANDLED/UNHANDLED | evidence or failure scenario`), then a bounded fix list ordered by user impact — smallest diff per fix, no refactors smuggled in.
