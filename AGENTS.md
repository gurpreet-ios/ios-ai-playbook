# AGENTS.md — Single Source of Truth for Agents in This Repo

> This is the universal, tool-agnostic rules file described in
> [Chapter 19b](handbook/19b-structuring-agent-rules.md). Cursor (`.cursor/rules/`),
> Claude Code (`CLAUDE.md`), Windsurf, and CI agents should all be pointed here.
> If your tool has its own config, add one directive to it: **"Before starting any
> task, read `AGENTS.md`."**

This repository is **The Senior AI Engineering Playbook — iOS Edition**: a
39-chapter handbook, a prompt/skill/ADR library, an Astro site, and four Swift
sample apps. It is mostly *content*, with real Swift code that must compile and
pass tests. Both halves have laws.

---

## 1. Repository map (where things live)

| Path | What it is | The law that governs it |
| :-- | :-- | :-- |
| `handbook/*.md` | The 39 chapters + the model-landscape appendix | §2 Content laws |
| `site/` | Astro Starlight site — a **generated mirror** of `handbook/` | Never hand-edit `site/src/content/docs/handbook/` |
| `prompts/`, `skills/`, `adrs/` | The context-anchor libraries | §2 — cross-references must resolve |
| `sample-apps/` | Four Swift apps + their `_prompts/` build logs | §3 Swift laws |
| `.github/workflows/` | CI: `sample-apps.yml` (build+test), `claude-autonomy.yml` (the L3 agent) | §4 Autonomy Contract |
| `AGENTS.md` (this file) | The rules the agents read | Change it deliberately |

---

## 2. Content laws

- **The handbook is the source; the site is generated.** After *any* edit under
  `handbook/`, run `python3 tools/sync-site-chapters.py` and commit the resulting
  `site/src/content/docs/handbook/` changes in the same commit. Never edit the
  synced site copies by hand — the script overwrites them.
- **Model names live in exactly one place.** Chapter prose uses capability
  language ("a frontier model", "a small open-weight model"). Concrete model
  names and prices go **only** in `handbook/appendix-model-landscape.md`. This
  keeps the book from going stale every model release.
- **Cross-references must resolve.** Every prompt referenced by a chapter must
  exist in `prompts/`; every ADR referenced must exist in `adrs/`. Every chapter
  ends by routing to the next one. If you add a chapter, wire it into `README.md`
  and add a `CHANGELOG.md` entry.
- **New numbered chapters use the `NNb`/`NNc` insertion convention** (e.g. `19b`,
  `20b`) rather than renumbering everything downstream — the site sidebar
  autogenerates and sorts by filename, so `20b-*.md` slots after `20-*.md`
  automatically.
- **Voice:** opinionated, concrete, iOS-specific. Tables and pull-quotes over
  walls of prose. Match the surrounding chapters.

---

## 3. Swift laws (sample apps)

- **Swift 6, strict concurrency.** ViewModels are `@MainActor`; shared mutable
  state that crosses actors must be made safe, not silenced.
- **Stack:** SwiftUI + the Observation framework (`@Observable`), SwiftData where
  persistence is needed. UIKit/MVVM-C only in `movie-search-uikit`, on purpose.
- **Zero third-party dependencies** in the sample apps — no SPM packages, no
  CocoaPods. If a task seems to need one, that is an escalation (§4), not a
  decision to make.
- **Every app builds and passes its Swift Testing suite on the iOS Simulator.**
  A broken sample app is a credibility bug, not just a code bug — the apps are
  the playbook's proof. `sample-apps.yml` is the gate.
- **Follow the ADRs.** `adrs/` is architectural law for the sample code. Don't
  introduce a pattern an ADR forbids (e.g. CoreData XML — we use SwiftData).

---

## 4. The Autonomy Contract (this repo runs at Level 3)

Per [Chapter 20b: The Autonomy Ladder](handbook/20b-autonomy-levels.md), this repo
is set up for **Level 3 — Delegated** autonomy: an agent may run a bounded task's
full loop and open a PR, and a human reviews the outcome. This section is that
contract, made explicit so it can be delegated instead of living in a maintainer's
head.

**The primary mode is local.** A terminal agent on a developer's Mac closes the
build/test loop and a human reviews the PR — no CI, no secret. The self-triggering
CI workflow (`.github/workflows/claude-autonomy.yml`) is the opt-in **Level-4**
escalation, and it is inert until a maintainer arms it (see the kill switch below).

### An agent operating here MAY, without step-by-step approval:
- plan and make a **bounded, clearly-scoped** change;
- edit files, run the build and tests, and **fix its own build/test failures**;
- run `tools/sync-site-chapters.py` and commit the generated site output;
- open a pull request and summarize what it changed.

### Definition of done (the agent must self-verify *locally* before asking for review):
Run the loop yourself before handing back a PR — don't outsource the first check to CI.
- Sample-app changes: **build + test green on the iOS Simulator** — `xcodebuild test`
  on the touched app (the same check `sample-apps.yml` re-runs in CI). Don't hand
  back a red PR.
- Handbook changes: **site re-synced** — run `python3 tools/sync-site-chapters.py`,
  commit the result so the tree is clean, and confirm cross-references resolve.
- The change stayed **inside its stated scope**.

### An agent MUST stop and escalate (ask a human) when:
- the task would need a **new dependency**, a **schema migration**, or otherwise
  **exceed its stated scope**;
- it touches a **security- or privacy-sensitive** path (auth, Keychain, crypto,
  PII) — see [Chapter 32](handbook/32-security-and-privacy.md);
- the right answer requires **an architecture decision no ADR covers** (it's being
  asked to *set* architecture, not follow it);
- the loop **won't close** — tests still fail after a bounded number of attempts.
  Hand back a diagnosis, not a broken PR or an unbounded spend.

### Hard limits (encoded, not trusted to good behavior):
- **PR-only. Never push to `main`.** `main` is protected (required review +
  required status checks); a delegated agent can only ever *propose*.
- **Protected paths — do not edit autonomously:** `MONETIZATION.md`,
  `LICENSE`, `.github/workflows/*` (changing the agent's own guardrails or CI is a
  human decision), and this file, `AGENTS.md`.
- **Kill switch:** locally, autonomy is revoked by interrupting or not starting
  the agent — the developer arms it and reviews every PR (the day-to-day Level-3
  mode). The self-triggering CI agent in `claude-autonomy.yml` is the **Level-4**
  escalation and is inert unless a maintainer sets the `CLAUDE_AUTONOMY_ENABLED`
  repository variable to `true` and provides the `ANTHROPIC_API_KEY` secret; flip
  the variable off to revoke it in one action.

> This contract is the difference between *delegated* and *unsupervised*. If a
> requested task doesn't fit inside it, the right move is to ask — raising the
> question is doing the job well, not failing to.
