# Changelog

All notable changes to the playbook, for readers and PDF buyers. Dates are release dates of the content, not of individual commits.

## 2026-07-08 — Chapter 20c: the autonomous delivery pipeline (Level 4)

The handbook grows to 40 chapters. Where Ch 20b delegated a single bounded task (Level 3), 20c chains the whole delivery line and names it honestly as Level 4.

### New chapter
- **Ch 20c — The Autonomous Delivery Pipeline:** vague user story → RFC → iOS tasks in Jira → self-iterating code → PR → code review, framed as a [prompt chain (Ch 8)](handbook/08-prompt-chaining.md) across Jira/GitHub MCP. The spine is a **cost-of-defect** argument — a wrong assumption is never a 1× waste but *wrong work plus redo*, compounding the further right it's caught — which is why the chapter's weight is on the **front** of the pipeline, not the code generation. Deep treatment of **S1 (story → a testable contract)** and **S2 (contract → layered iOS work orders)**: ground-first to minimize questions, classify every question by **cost of reversal** (🔴 blocking vs 🟡 assumed-with-default), a **strict, machine-enforced Gate A** (hard-block on any open 🔴; batched into one round; a machine-readable `gate_a: BLOCKED/READY` status that refuses to spawn Jira tasks until clear), tests-first topological decomposition by architecture layer, and the two human gates (spec, merge) that never automate. A full **S5 → S3 review loop-back** section applies the same cost-of-reversal classifier to review feedback — mechanical fixes auto-iterate (the Ch 20 auto-fixer), contract-level comments re-arm Gate A, questions get answered without touching code, and pushback citing an ADR outranks the thread — bounded by a round budget and an event-driven (not polling) substrate. Worked "add favorites" example throughout; iOS reality check (no cheap E2E, signing walls, macOS runner cost) and a crawl/walk/run adoption path. Cross-referenced to Ch 3/8/14/20/20b/21/26/35.

### Supporting change
- **`templates/rfc-template.md` gains an Acceptance Criteria section** — machine-checkable Given/When/Then criteria mapped to tests, the linchpin artifact Gate A freezes and S3's loop drives to green. Sections renumbered (Acceptance Criteria is now §5).

## 2026-07-08 — Autonomy Level 3: the playbook delegates, and dogfoods it

The handbook grows to 39 chapters, and the repo stops only *teaching* agentic workflows — it starts *running* one. Headline: a new chapter names the autonomy ladder, diagnoses the playbook as Level 2 (supervised), and moves it to Level 3 (delegated) by adding the three-part substrate the chapter prescribes.

### New chapter
- **Ch 20b — The Autonomy Ladder:** the axis Chapter 3's seniority ladder isn't — *how much of the plan→edit→build→test→fix→review loop you delegate*, ranked Level 0–5 (SAE-style), with the honest boundary at Level 5. Diagnoses "Plan First" supervision (Ch 19) as Level 2 and its ceiling (your reading speed), then teaches the three preconditions for Level 3 — a closeable verification loop, written-down guardrails, and a bounded task with a testable definition of done — plus the operating contract (what the agent owns vs. what you keep), blast-radius limits, escalation triggers, and the iOS-specific reasons delegation is harder here (macOS runner cost, no cheap E2E, signing walls). Slots after Ch 20 via the `20b` insertion convention; wired into the README and cross-referenced from Ch 3/19/19b/20/30/32/35.

### The repo now runs at Level 3 (dogfooding) — locally
- **Local-first by design:** the day-to-day Level-3 loop runs on a developer's Mac via a terminal agent (Claude Code / Cursor), not CI — the human arms it, the agent closes the build/test loop with the real commands (`xcodebuild test` on the touched sample app; `python3 tools/sync-site-chapters.py` for handbook edits), and the human reviews the PR. Fast, free, private, and where the simulator already is.
- **`AGENTS.md` at the root:** the tool-agnostic single source of truth from Ch 19b — the repo's content/Swift laws plus an explicit **Autonomy Contract** (§4): what an agent may do without step-by-step approval, its definition of done (run the local loop before asking for review), the escalation triggers, the protected paths, and the kill switch.
- **`.github/workflows/claude-autonomy.yml` — the Level-4 escalation:** the same rules, *self-triggering* on every PR via `anthropics/claude-code-action` (review against `AGENTS.md` + the ADRs, plus a bounded self-verified auto-fix on request). Ships **inert**: it does nothing until a maintainer sets the `CLAUDE_AUTONOMY_ENABLED` repo variable to `true` and provides an `ANTHROPIC_API_KEY` secret. Local L3 is the day-to-day rung; CI L4 is the opt-in, hands-off rung above it.

### Housekeeping
- Chapter count corrected 38 → 39 (README, site landing + card); site prompt-count corrected 41 → 42 to match the library.

## 2026-07-03 — Fourth sample app: the UIKit MVVM-C interview

The prompting-strategy trilogy becomes a quartet, and the new app adds the habit the others only implied: a live decision log.

### New sample app: `sample-apps/movie-search-uikit`
- **The legacy-stack interview round:** a 1-hour machine-coding simulation — movie search → detail → favorites — on **UIKit (fully programmatic) + MVVM + Coordinator**, Swift 6 strict concurrency, zero third-party dependencies. Every layer was generated from prompts stored in `_prompts/` directories (11 prompt documents, each with the spoken interviewer framing, the exact prompt, a constraints table, and a review checklist), plus the upfront `.cursorrules` alignment file.
- **`DECISIONS.md` — the per-app decision log:** 9 mini-ADRs in the repo `adrs/` format (UIKit-without-storyboards, Coordinator ownership, `Box<Value>` binding over Combine/Rx, diffable data sources, composition-root DI, actor services, UserDefaults favorites, debounce-as-Task, the coordinator memory contract), each ending with the one-liner actually said to the interviewer.
- **Verified:** builds and passes its 9-test Swift Testing suite on the iOS Simulator; added to the `sample-apps` CI workflow matrix. Root README sample-app table updated to four apps.

### Prompt library: 41 → 42
- **New `debugging/codebase-orientation` prompt:** the missing step zero of the debugging flow — build a mental model of a codebase you've never seen (architecture as practiced vs as documented, one end-to-end trace, the conventions that bite newcomers, a ranked 5-file reading list) *before* any symptom-chasing. Chains explicitly into `codebase-mapping` → `hypothesis-first-debug`; mapped to Chapters 16 and 18.
- `interview-playbooks/architecture/photo-feed.md` rewritten for readability: same technical substance, jargon now explained at first use (jetsam, downsampling, cursor pagination, optimistic likes), the poor answer unpacked landmine-by-landmine.

## 2026-07-04 — Community-first pivot

The paid-PDF funnel is retired before launch; the repo is now fully open and distribution runs community-first.

- **`MONETIZATION.md` rewritten** as the community-first decision record: open repo + weekly Substack posts as the capture layer + posting in iOS channels as distribution, with forcing functions (weekly cadence from 2026-07-11, 90-day checkpoint on 2026-10-04) and monetization explicitly deferred.
- **New `newsletter/` directory** with the first two post drafts, each standalone value from a load-bearing chapter: *The same feature, four prompts* (from Ch 3) and *The data race Swift 6 refused to compile* (from Ch 12), plus a candidate pipeline drawn from Ch 26, 17, 19c, 11/15, and 14.
- **Site paywall removed:** all 38 chapters + the Model Landscape appendix are now published on the Astro site (41 pages, full search index), synced from `handbook/` by the new `tools/sync-site-chapters.py` (frontmatter injection + link rewriting). The pricing page is deleted, the sidebar's "Get the book" is gone, and the homepage CTAs are now read / star on GitHub / subscribe (Substack URL placeholder pending).

## 2026-07-03 — Agent Skills

The playbook's workflows become installable. Headline: the handbook grew to 38 chapters, and 8 of the 41 prompts now ship in the open `SKILL.md` format so your agent triggers them itself.

### New chapter
- **Ch 19c — Packaging Workflows as Agent Skills:** the third layer of the agentic stack (rules = constraints, skills = procedures, MCP = reach). SKILL.md anatomy, progressive disclosure and the trigger budget, the prompt-system → skill conversion mapping (`// INJECT_X_HERE` placeholders become context-gathering steps the agent executes), skills that act via the terminal loop, and the trust/scope cautions. Completes the Ch 19 → 19b arc; 19b's Next Steps now route through it.

### New library: `skills/`
- **8 installable Agent Skills**, chapter-mapped and source-mapped to the prompt library: `swift-concurrency-audit`, `adr-drift-audit`, `edge-case-probe`, `hypothesis-first-debug`, `render-isolation-audit`, `legacy-code-archaeology`, `release-audit`, and the new `xcode-build-triage` (runs the build, classifies the error cascade, fixes by category). Frontmatter kept to the portable core (`name` + `description`); install is a `cp -r` into `.claude/skills/`.
- Curation is deliberate — 8, not 41: skill descriptions compete for the agent's trigger attention, so only the recurring whole-workflow prompts convert. The reasoning is documented in `skills/README.md`.

### Site
- Teaser site copy updated: chapter count corrected (30 → 38) on the landing and pricing pages, and the prompt-library cards now mention the installable skills.

## 2026-07-02 — The "Complete Edition" content drop

The largest revision since the initial draft. Headline: the handbook grew from 30 to 37 chapters, every chapter in the iOS core now teaches on one real codebase, and all three sample apps compile and pass tests.

### New chapters
- **Part XII — Shipping to Production:** Ch 30 *Verifying AI Output at Scale* (the six-gate verification stack), Ch 31 *CI/CD & Release Engineering* (the no-instant-rollback reality), Ch 32 *Security & Privacy* (insecure AI defaults, privacy manifests, the agent-context leak surface), Ch 33 *Observability & Production Health* (MetricKit closes the crash-reporter blindspot).
- **Part XIII — The Frontier:** Ch 34 *On-Device AI & App Intents* (Foundation Models guided generation; App Intents as your app's tool schema), Ch 35 *Agentic Security & Cost* (prompt injection, slopsquatting, token economics, the governance one-pager).
- **Ch 19b — Structuring Agent Rules:** modular `.cursor/rules/*.mdc` + `AGENTS.md` single-source-of-truth strategy, with copy-pasteable templates in `templates/agent-rules/`.

### The running example
Chapters 9–16 now share one codebase — `sample-apps/music-interview-app` — with a "Running Example" section per chapter: the MVVM decision and the Massive-ViewModel trap (9), the SwiftPM cycle failure (10), the 4Hz over-render fix (11), the Swift 6-rejected data race (12), the silently-stale widget (13), a real AI PR reviewed against the ADRs (14), a scroll-stutter hunt with verified numbers (15), and the app's own composition-root crash debugged end-to-end (16).

### Deepened chapters
- Ch 26 *AI-Driven Testing* rewritten around the tautological-test audit (the mirror, the echo, the vacuous async test, and the two-minute deletion test).
- Ch 25 *Accessibility* gained an end-to-end audit workflow with before/after code and VoiceOver transcripts.
- Ch 24 *Cheat Sheets* gained three real reference tables: concurrency annotations (with the AI's classic misuse per row), SwiftUI property wrappers, and the Instruments picker.
- Ch 18 *AI-Native Interviews* names the two interview question types (build-from-scratch vs debug-the-unfamiliar-codebase).

### Libraries
- **Interview playbooks: 3 stubs → 14 full scripts** across four categories, including the new `debugging/` category, each with a "Driving the LLM" prompt sequence and a mid-interview extension.
- **Prompts: 21 → 41**, chapter-mapped both directions, with new `debugging/` and `release/` categories.
- **ADRs: 5 → 13**, adding modularization, navigation, networking, image pipeline, DI, testing, deployment target, and strict concurrency.
- **Architecture breakdowns** (Spotify/Instagram/Uber) expanded from stubs to full blueprints with 6-layer prompt sequences and failure-mode banks.

### Sample apps
All three apps now **build and pass their Swift Testing suites** on the iOS Simulator. `spotify-clone` and `uber-clone` received integration repairs (the uber-clone repair is itself a case study in per-file generation drift — see BACKLOG item 8 for the full inventory). `_prompts/` directories synced to the final APIs. CI workflows added for the apps and the teaser site.

### Corrections
- Modern TCA (`@Reducer`/`@Dependency`) replaces the removed `Environment` API in Ch 9 and the TCA prompt.
- Chapter 0's SwiftData contradiction fixed; its three prompts now compose.
- Tool landscape modernized beyond Cursor: terminal-first agents, `CLAUDE.md`/`AGENTS.md`, the xcodebuild/simctl loop.
- Liquid Glass (iOS 26) design language; Swift 6.2 default-isolation guidance; Swift Testing as the baseline framework.

---

*Earlier history (initial draft, Phase 0/1 structural fixes) predates this changelog; see git history.*
