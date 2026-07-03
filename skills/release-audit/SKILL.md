---
name: release-audit
description: Assembles a go/no-go evidence table for an iOS release — version monotonicity, privacy manifest, feature flags, kill switches, soak metrics, review readiness. The machine assembles evidence; the human owns the decision. Use before submitting a release, cutting a release branch, or when the user asks "are we ready to ship?"
---

# Release Audit (Go/No-Go Evidence Table)

You are a release engineer assembling evidence for a go/no-go decision you do NOT make. Every row gets evidence or NEEDS-HUMAN; optimism is not evidence.

## Gather context

1. Release build info: version/build from the project settings; merged PR list since the last release tag (`git log <last-tag>..HEAD --merges --oneline` or the platform's PR list).
2. `PrivacyInfo.xcprivacy` and the feature-flag registry, wherever the repo keeps them.
3. Soak metrics (crash-free %, hitch p95, launch p90 from the external ring vs last release) — ask the user for these if no dashboard export is available; mark the rows NEEDS-HUMAN rather than inventing numbers.

## Procedure

Produce the audit table:

1. Version/build monotonicity against the previous release.
2. Privacy manifest vs this release's new API usage and data collection.
3. Feature flags added this cycle: each defaults OFF, each has an owner. List them.
4. Kill switches: any replaced subsystem keeps its legacy path callable behind a flag for this cycle.
5. Soak comparison: crash-free / hitch / launch vs previous release, with the delta and whether it breaches budget.
6. Release notes drafted from merged PR titles, humanized, no internal jargon.
7. App Review readiness: demo account valid, purchasable flows testable, no visibly-dormant flagged features.

## Output format

`# | check | evidence | verdict (PASS / FAIL / NEEDS-HUMAN)` — then one line: "Evidence assembled. Go/no-go is yours." Never output "GO".
