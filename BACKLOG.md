# Backlog — iOS Playbook

Tracking of improvement work from the lead-level review of this playbook (benchmarked against the polished Backend Edition in `backend-playbook-draft`). Items are ordered by phase; each has enough specifics (files, line numbers) to act on without re-deriving context.

_Last updated: 2026-07-02._

---

## ✅ Completed (Phase 1 — structural integrity)

- **Scope locked: iOS Edition** — removed the empty multi-platform directories (`android/`, `backend/`, `frontend/`, `sample-projects/`, `mock-interviews/`, `design-docs/`) and the multi-platform promises. The Backend Edition is its own repo.
- **Chapter 17 collision resolved** — merged `17-ai-code-review.md` into Chapter 14 (now "Code Review in the AI Era"); `17-xcode-compiler-errors-with-ai.md` is the sole Chapter 17. Chapters run 00–29 contiguously.
- **Honest README** — real per-chapter TOC grouped by Part, relative links (was `file:///Users/...`), and an asset inventory that matches reality (was "500+ prompts / 100+ ADRs / 50+ mock interviews").
- **ADR library normalized** — consistent `NNN-` naming (two files claimed "ADR 001"), two new ADRs (003 reactive-frameworks, 004 state-management) so every ADR referenced by a chapter exists, plus `adrs/README.md` index.
- **Dangling prompt refs fixed** — created `prompts/architecture/mvvm-scaffold.md` and `prompts/review/mvvm-audit.md` (referenced in Ch 9).
- **Volatile-model-specifics pass** — chapter prose now uses capability language ("frontier model", "small open-weight model"); concrete names live only in the dated `handbook/appendix-model-landscape.md`.
- **Fact-check pass** — "Combine is deprecated" softened (Ch 12), "excludes 15% of the population" reframed to the WHO 1-in-6 estimate (Ch 25), "90% of testing infrastructure" and "50% of time" framed as illustrative (Ch 26, Ch 1), "dozens of mock interviews" corrected (Ch 18).
- **Empty-app reference fixed** — Ch 13 no longer points at `ios/AIPlaybookSampleApp` (which shipped an empty Sources dir); the directory is removed.

## 🧷 Decisions log (intentionally kept — do not "fix")

- **The three sample apps are NOT duplicates.** They form a deliberate prompting-strategy trilogy: `uber-clone` (verbose/descriptive prompts), `spotify-clone` (ultra-concise under-pressure prompts), `music-interview-app` (the balanced strategy, with `.cursorrules`). Keep all three; the README documents the contrast.
- `docs/adrs/004-offline-caching.md` (Ch 7) and `@adrs/user-schema.md` (Ch 19) are **illustrative** paths inside hypothetical-project prose, not claimed repo files.
- The site publishes only chapters 0–2 **on purpose** — free-teaser funnel for the paid PDF (see `MONETIZATION.md`).

---

## 🔜 Remaining work

| # | Item | Phase | Priority | Effort |
| :-- | :-- | :-- | :-- | :-- |
| 0 | ✅ ~~Credibility & staleness fixes (second review pass, 2026-07-02)~~ (done 2026-07-02: all sub-bullets verified in tree; App Intents coverage lands with item 3's On-Device AI chapter) | 1 | P0 | Small |
| 1 | ✅ ~~Port polished shared chapters from Backend Edition~~ (done 2026-07-02: full diff of all 13 shared pairs — the iOS edition is now *ahead* of the backend twins after the Phase-1 polish; one genuine backend-only improvement ported: Ch 3 cache-miss coalescing review clause) | 1 | P1 | Small |
| 2 | ✅ ~~Running-example spine through Ch 9–16~~ (done 2026-07-02: every chapter has a Running Example section on music-interview-app with a real failure mode; Ch 16 uses the app's actual composition-root crash; new graph-constructing regression test passes on simulator) | 2 | P1 | Large |
| 3 | ✅ ~~New chapters: Verification, CI/CD & Release, Security & Privacy, On-Device AI, Observability, Agentic Security & Cost~~ (done 2026-07-02: Ch 30–35 written + wired into README as Parts XII–XIII; prompts/security/ recreated; bonus Ch 19b (agent rules) + templates/agent-rules/ landed alongside) | 2 | P1 | Large |
| 4 | ✅ ~~Deepen weakest chapters (Testing, A11y, Cheat Sheets, Breakdowns)~~ (done 2026-07-02: Ch 26 full rewrite w/ tautology audit + new prompt file; Ch 25 end-to-end workflow w/ before/after; Ch 24 three reference tables; 3 breakdowns → full blueprints + README index) | 2 | P1 | Med |
| 5 | ✅ ~~ADR library 5 → ~12~~ (done 2026-07-02: ADRs 006–013 added — modularization, router, networking, image pipeline, DI, testing, deployment target, strict concurrency — all with AI Anchor Usage; README index updated) | 3 | P2 | Med |
| 6 | ✅ ~~Interview playbooks 3 → ~12 with full scripts~~ (done 2026-07-02: 14 playbooks across 4 categories incl. new `debugging/`; 7-part format with Driving the LLM; Ch 18 + README aligned) | 3 | P2 | Med |
| 7 | ✅ ~~Prompt library 18 → 40–60, chapter-mapped~~ (done 2026-07-02: 41 prompts; 20 new incl. debugging/ + release/ categories; 3 backend leftovers re-flavored to iOS; both invariants verified — every referenced prompt exists, every prompt chapter-referenced; README is a chapter-mapped index) | 3 | P2 | Med |
| 8 | ✅ ~~Sample apps: tests, compile CI, fill empty `Components/`~~ (done 2026-07-02: spotify-clone + uber-clone repaired, all three apps BUILD+TEST green on simulator; `_prompts/` synced; `TrackArtworkView` component extracted; `.github/workflows/sample-apps.yml` added) | 3 | P2 | Small–Med |
| 9 | ✅ ~~Site CI (build + link check, port from Backend Edition)~~ (done 2026-07-02: `.github/workflows/site.yml` ported; `check:links` script added; placeholder Starlight social URL removed; committed lockfile intact for `npm ci`. Local `node_modules` was corrupt — CI verifies from a clean install) | 4 | P2 | Small |
| 10 | 🟡 ~~Regenerate PDF + CHANGELOG after Phase 2 content lands~~ (CHANGELOG.md written 2026-07-02; PDF regen deferred to a local run: `python3 tools/build-book-pdf.py` — needs Chrome + `pip3 install markdown pygments`; new chapters 19b/30–35 are picked up by the glob) | 4 | P3 | Small |

### 0. Credibility & staleness fixes · P0 · Small
Found in the 2026-07-02 second review pass. Cheap to fix, expensive to leave in — these are the errors the target (senior iOS) reader spots instantly:

- **Ch 0 contradicts itself and ships a dead ViewModel** (`handbook/00-hello-world-todo-tutorial.md`): Step 1 says "do NOT check Use SwiftData — we'll write the data layer manually," then `.cursorrules` and Prompt 1 use SwiftData anyway. Worse, Prompt 2's `TodoListViewModel` is never used — Prompt 3's ContentView uses `@Query` directly. Rewire so the three prompts compose.
- **Ch 9 TCA prompt is years stale** (`handbook/09-presentation-architecture.md`): "State, Action, **Environment**, and Reducer" — `Environment` was removed from TCA long ago; modern TCA is the `@Reducer` macro + `@Dependency`. Check `prompts/architecture/ios-tca-feature.md` for the same problem.
- **Tool landscape is Cursor-only** (Ch 19/20/22): no terminal-first agents (Claude Code), no Xcode 26 built-in intelligence, no `CLAUDE.md`/`AGENTS.md` (the book speaks only `.cursorrules`), no build/run/simulator MCP loop, and Ch 20 has zero iOS-specific content (xcodebuild/simctl automation, macOS CI runners).
- **Ch 26 is XCTest-era**: reframe to Swift Testing (`@Test`, `#expect`) first (full rewrite is item 4; the framing swap shouldn't wait).
- **Ch 25 misses `performAccessibilityAudit()`** — the one genuinely automatable a11y audit API.
- **Design language is pre-WWDC-2025** (Ch 11/27): no Liquid Glass / iOS 26 vocabulary; Ch 27 still teaches neumorphism.
- **Ch 12 misses Swift 6.2** approachable-concurrency / MainActor-by-default modes, which change the prompting advice.
- **Ch 13 misses App Intents entirely** — the key system framework for an AI-native iOS book (folds into new-chapter item 3.4, On-Device AI).
- **Ch 18 promises what the playbooks can't deliver**: the 6-part format (incl. "Ideal Discussion transcript") vs 31–41-line stubs in `interview-playbooks/` (ties into item 6).
- **Repo hygiene**: stray `site/site/` (accidental 83-byte package-lock.json) — delete; large Phase-1 changeset uncommitted — commit.

### 1. ✅ Port polished shared chapters · P1 · Small — DONE 2026-07-02
Diffed all 13 shared pairs (1–8, 19↔17, 20↔18, 21↔19, 28↔20, 29↔21). Finding: after this repo's Phase-1 credibility pass, the iOS edition is **ahead** of the backend twins (5-pillar prompt anatomy, model-landscape appendix references, iOS Loop section — the backend still carries stale model names). Remaining diffs are intentional platform flavoring. One genuine backend-only improvement ported: Ch 3's review clause now also checks cache-miss request coalescing (the backend's thundering-herd check, iOS-flavored). If the Backend Edition is maintained, the port direction is now reversed.

### 2. ✅ Running-example spine through Ch 9–16 · P1 · Large — DONE 2026-07-02
All eight chapters gained a "Running Example" section built on `music-interview-app` (introduced as the Part 3 spine in Ch 9), each with real code matching the repo API, a chapter-specific failure mode, and a prompt-that-prevents-it:
- **Ch 9:** MVVM+Router decision narrative; the Massive-ViewModel trap; lifetime-scoped split (LibraryViewModel vs app-scoped PlayerViewModel); Router pattern.
- **Ch 10:** SwiftPM modularization; the `cyclic dependency declaration found` failure; dependency-rule fix with TrackRepository as the orchestration home; context-bounding payoff.
- **Ch 11:** NowPlayingView build; Observation property-level tracking; the 4Hz whole-screen over-render from `currentTime` and the subview-scoped fix.
- **Ch 12:** offline download engine across three isolation domains; the `Task.detached` + `@Model` capture data race Swift 6 rejects at compile time; `@unchecked Sendable` waiver honesty; `@ModelActor` escalation criteria.
- **Ch 13:** Now Playing widget + Live Activity; the silently-stale widget (fresh process, fresh singleton); App Group snapshot DTO pattern (scope-honest: SPM repo, code is what the extension targets contain).
- **Ch 14:** full AI-generated "Recently Played" PR diff reviewed tier-by-tier against ADRs 001/002/004; four failure modes in one small PR; anchor-prompt rewrite outcome.
- **Ch 15:** Library artwork scroll stutter; Time Profiler + Hitches evidence; downsampling `ArtworkLoader` actor fix; before/after verification numbers.
- **Ch 16:** the app's own real composition-root crash (`@Environment(\.modelContext)` read in `init` → container-less context) debugged end-to-end; regression test added to the repo (`Tests/TrackRepositoryTests.swift`, constructs the real graph, passes on simulator).

### 3. ✅ New chapters · P1 · Large — DONE 2026-07-02
All six written (Ch 30–35, Parts XII–XIII in the README), plus Ch 19b "Structuring Agent Rules" + `templates/agent-rules/` landed alongside. Original priority list:
1. **Verifying AI Output at Scale — iOS** (Swift Testing, snapshot tests, UI tests, Thread Sanitizer, screenshot diffing, CI gates). Mirror of the Backend Edition's flagship Ch 13.
2. **CI/CD & Release Engineering** — code signing, fastlane/Xcode Cloud, TestFlight, App Review, phased rollout, the no-instant-rollback reality.
3. **Security & Privacy** — Keychain, ATS, privacy manifests (`PrivacyInfo.xcprivacy`), required-reason APIs, secrets leaking into prompt context. Also recreate `prompts/security/` with real prompts (the empty placeholder dir was removed in Phase 1; the OWASP audit currently lives in `prompts/review/`).
4. **On-Device AI** — Core ML, Apple's Foundation Models framework, App Intents. The differentiator chapter for an AI-native iOS book. *(2026-07-02 review: consider writing this one first — it's the positioning chapter, and App Intents currently has zero coverage anywhere.)*
5. **Observability & Production Health** — MetricKit, crash triage with AI, os_signpost, hang/launch metrics.
6. **Agentic Security & Cost** — prompt injection via tool results, secrets in context, blast radius, token economics (same gap the Backend Edition logged as its backlog #2).

### 4. ✅ Deepen weakest chapters · P1 · Med — DONE 2026-07-02
- `26-ai-driven-testing.md` → full rewrite (~1,700 words): Swift Testing API table, spy generation grounded in `AudioEngineSpy`, names-first TDD on MusicApp queue navigation, the tautological-test audit (mirror / implementation-echo / vacuous-async + the deletion test), async-stream testing without sleeps, the regression rule. New `prompts/testing/tautology-audit.md`.
- `25-accessibility-with-ai.md` → "The Audit Workflow, End to End" on NowPlayingView: before/after code, VoiceOver transcripts, findings table, `performAccessibilityAudit()` gate, rules-file feedback loop.
- `24-cheat-sheets.md` → three real reference tables: concurrency annotations (with the AI's classic misuse per row), SwiftUI property wrappers (incl. legacy-rejection row), Instruments picker (symptom → tool).
- `architecture-breakdowns/*.md` → full blueprints (~1,000 words each): core domain, decision tables, 6-layer prompt sequences with per-layer "watch for" review hooks, failure-mode banks, cross-links to playbooks/sample apps (all links verified). README is now a real index.

### 5. ADR library 5 → ~12 · P2 · Med
Each with the "AI Anchor Usage" section: modularization strategy, navigation/router, networking stack, image pipeline, DI approach, testing strategy, min-deployment-target policy, strict-concurrency adoption.

### 6. Interview playbooks 3 → ~12 · P2 · Med
Machine coding: image cache w/ TTL, debounced search, pagination, download manager. Architecture: offline-first chat (exists — deepen), photo feed, live-sports app. Code review: retain cycle (exists — deepen), data race, SwiftUI over-render. Full scripts, not 30-line stubs. **Note:** Ch 18 promises a 6-part format per playbook (Prompt / Expected Reasoning / Poor Answer / Great Answer / Follow-Up / Ideal Discussion transcript) — every playbook must actually follow it.

**Alignment with a real vibe-coding interview rubric (2026-07-02, from a candidate prep guide for mobile-engineer vibe-coding interviews):**
- **Add a fourth playbook category: `debugging/`.** Real interviews split ~50/50 between build-from-scratch and *debugging an unfamiliar codebase from a vague symptom* ("the app crashes on older devices", "the list stutters", "stale data after logout"). The playbook has the skills (Ch 16, discovery prompts) but no interview simulation: unfamiliar codebase + vague symptom → use the LLM to build context fast (don't read every file) → hypothesis → trace → fix → articulate root cause. Seed scenarios: feed scroll stutter, stale data after logout, crash on older devices.
- **Every playbook's "Follow-Up" must be a mid-interview extension** (add offline mode / pagination / a new UI state) — interviewers test whether you keep driving the LLM into new territory without breaking the existing design.
- **Ch 18: name the two question types explicitly** (build-from-scratch vs. debug-the-unfamiliar-codebase) with the Plan → Review → Fix loop as the shared spine.
- ✅ *Done 2026-07-02:* review hook added as the 5th prompt pillar (Ch 4 + Ch 24); edge-case probe checklist added to Ch 24.

### 7. Prompt library 18 → 40–60 · P2 · Med
Rule: every prompt referenced in a chapter exists; every prompt is referenced by a chapter. Organize to mirror the Part structure.

### 8. Sample apps · **P1 (upgraded)** · Med
**2026-07-02 build verification: none of the three apps compiled.** All three manifests declared `Tests/` dirs that didn't exist (fixed — each app now has a Swift Testing smoke suite). Beyond that:

- **`music-interview-app` — ✅ repaired 2026-07-02.** Builds for iOS Simulator and its test suite passes. Fixes: reconciled `NetworkClientProtocol` (DTO-returning domain methods), added `fetchTracks()` to the repository, gave `PlayerViewModel` the surface `NowPlayingView` binds to (`currentTrack`, `isPlaying`, `togglePlayPause`, `playNext`, `playPrevious` + queue), made `AudioEngine.setupAudioSession()` `nonisolated` and added `stop()`, fixed the composition root (was reading `@Environment(\.modelContext)` in `init` → container-less context at runtime), fixed a broken string interpolation in an accessibility label.
- **`spotify-clone` — ✅ repaired 2026-07-02.** BUILD + TEST green on simulator. Fixes: added `NetworkClientProtocol` and conformed the actor; `fetchRecentlyPlayed()` added to protocol + local-first impl; `setupAudioSession()` made `nonisolated`; `deinit`-touching-main-actor-state replaced with explicit `cleanup()`; `play(url:)` resolution via `offlineFileURL ?? streamURL`; composition root now owns the `ModelContainer` and passes `mainContext` explicitly (same Ch 16 pitfall as the flagship); two view call sites aligned (`loadHome`, `togglePlayPause`).
- **`uber-clone` — ✅ repaired 2026-07-02.** BUILD + TEST green on simulator. The redesign-level integration: duplicate `LocationUpdate`/`WebSocketManager` declarations removed (Models owns the type; the socket protocol redeclaration deleted); repo protocols made `@MainActor` and renamed to what ViewModels call (`fetchActiveTrip`, `estimateFare(from:to:)`, `requestTrip(from:to:pickupAddress:dropoffAddress:)`, `fetchNearbyDrivers`, `streamDriverLocation`); `DriverDTO`/`TripDTO` added so `@Model` types never cross the network boundary (ADR 008); both ViewModels rewritten to the surface the Views bind to (incl. `cameraPosition`, `route`, `pickupText`/`dropoffText`, `preview` stubs); `TripStatusCard` `.searching` → `.requested`; Endpoint call sites fixed (`[URLQueryItem]`, DTO body not pre-encoded Data, 404 → `nil` via `APIError`).
- **Follow-ups — ✅ done 2026-07-02:** `_prompts/` synced in both clones (uber repositories/components prompts, spotify repositories prompt); `Components/` filled with `TrackArtworkView` (extracted from both views, owns its a11y semantics) + `06-components.prompt.md`; `.github/workflows/sample-apps.yml` builds + tests all three on macOS CI.

### 9. Site CI · P2 · Small
Port `.github/workflows/site.yml` + link-check from the Backend Edition. Also fix placeholder URLs in `site/astro.config.mjs` if present.

### 10. PDF + CHANGELOG · P3 · Small — CHANGELOG ✅, PDF deferred
`CHANGELOG.md` written 2026-07-02 covering the full content drop. PDF regeneration left as a local one-liner (needs Chrome + pip deps, not run from the agent session): `python3 tools/build-book-pdf.py` — new chapters 19b/30–35 are picked up automatically by the handbook glob.
