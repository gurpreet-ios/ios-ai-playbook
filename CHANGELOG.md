# Changelog

All notable changes to the playbook, for readers and PDF buyers. Dates are release dates of the content, not of individual commits.

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
