# Changelog

All notable changes to the playbook, for readers and PDF buyers. Dates are release dates of the content, not of individual commits.

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
