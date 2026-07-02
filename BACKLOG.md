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
| 0 | Credibility & staleness fixes (second review pass, 2026-07-02) | 1 | P0 | Small |
| 1 | Port polished shared chapters from Backend Edition | 1 | P1 | Small |
| 2 | Running-example spine through Ch 9–16 | 2 | P1 | Large |
| 3 | New chapters: Verification, CI/CD & Release, Security & Privacy, On-Device AI, Observability, Agentic Security & Cost | 2 | P1 | Large |
| 4 | Deepen weakest chapters (Testing, A11y, Cheat Sheets, Breakdowns) | 2 | P1 | Med |
| 5 | ADR library 5 → ~12 | 3 | P2 | Med |
| 6 | ✅ ~~Interview playbooks 3 → ~12 with full scripts~~ (done 2026-07-02: 14 playbooks across 4 categories incl. new `debugging/`; 7-part format with Driving the LLM; Ch 18 + README aligned) | 3 | P2 | Med |
| 7 | Prompt library 18 → 40–60, chapter-mapped | 3 | P2 | Med |
| 8 | Sample apps: tests, compile CI, fill empty `Components/` | 3 | P2 | Small–Med |
| 9 | Site CI (build + link check, port from Backend Edition) | 4 | P2 | Small |
| 10 | Regenerate PDF + CHANGELOG after Phase 2 content lands | 4 | P3 | Small |

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

### 1. Port polished shared chapters · P1 · Small
Chapters 1–8, 19–21, 28–29 have near-identical twins in `../backend-playbook-draft/handbook/` that received reference fixes and small improvements (word deltas of +5 to +30 each). Diff each pair, back-port the fixes, re-flavor examples to Swift where the backend version went Go.

### 2. Running-example spine through Ch 9–16 · P1 · Large
The Backend Edition proved the format (its Checkout Service spine, chapters rebuilt to ~1,500 words with compilable code + failure modes). Do the same here with one flagship app (recommend evolving `music-interview-app`):
- **Ch 9:** choose MVVM+Router for it; show the Massive-ViewModel trap.
- **Ch 10:** modularize into Swift Packages; show a circular-dependency failure.
- **Ch 11:** build the NowPlaying screen; Observation-scoped state; over-render fix.
- **Ch 12:** offline sync engine — SwiftData + actor; a real data race caught by Swift 6.
- **Ch 13:** widget + Live Activity across the App Group boundary (replaces the deleted `AIPlaybookSampleApp` promise).
- **Ch 14:** review an actual AI-generated PR diff against the ADRs.
- **Ch 15:** profile a real scroll stutter in it with Instruments; fix; verify.
- **Ch 16:** debug a real crash in it end-to-end.

### 3. New chapters · P1 · Large
In priority order:
1. **Verifying AI Output at Scale — iOS** (Swift Testing, snapshot tests, UI tests, Thread Sanitizer, screenshot diffing, CI gates). Mirror of the Backend Edition's flagship Ch 13.
2. **CI/CD & Release Engineering** — code signing, fastlane/Xcode Cloud, TestFlight, App Review, phased rollout, the no-instant-rollback reality.
3. **Security & Privacy** — Keychain, ATS, privacy manifests (`PrivacyInfo.xcprivacy`), required-reason APIs, secrets leaking into prompt context. Also recreate `prompts/security/` with real prompts (the empty placeholder dir was removed in Phase 1; the OWASP audit currently lives in `prompts/review/`).
4. **On-Device AI** — Core ML, Apple's Foundation Models framework, App Intents. The differentiator chapter for an AI-native iOS book. *(2026-07-02 review: consider writing this one first — it's the positioning chapter, and App Intents currently has zero coverage anywhere.)*
5. **Observability & Production Health** — MetricKit, crash triage with AI, os_signpost, hang/launch metrics.
6. **Agentic Security & Cost** — prompt injection via tool results, secrets in context, blast radius, token economics (same gap the Backend Edition logged as its backlog #2).

### 4. Deepen weakest chapters · P1 · Med
- `26-ai-driven-testing.md` (338 words) → full chapter; lead with **Swift Testing** (`@Test`, `#expect`), keep XCTest for legacy; tautological-test audit workflow.
- `25-accessibility-with-ai.md` → add a complete audit workflow with before/after code.
- `24-cheat-sheets.md` → real reference tables (concurrency annotations, property wrappers, Instruments picker).
- `architecture-breakdowns/*.md` (19 lines each) → 800–1,200-word blueprints with the prompt sequences Ch 23 promises.

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
- **`spotify-clone` — ❌ ~6 errors**, same flavor: App passes `baseURL:` its `NetworkClient` doesn't accept, `NetworkClientProtocol` not in scope in `TrackRepository`, `fetchRecentlyPlayed` missing from the repo protocol, the same `setupAudioSession()` actor-isolation error, `stateObservationTask` touched from a nonisolated context (likely `deinit`), `play(track:)` vs `play(url:)` label mismatch.
- **`uber-clone` — ❌ ~50 errors**, generated per-file and never integrated: `LocationUpdate` and `WebSocketManager` each declared twice, repo protocols don't match implementations (`fetchActiveTrip`/`estimateFare`/`streamDriverLocation`/`fetchNearbyDrivers` missing), Views bound to ViewModel members that don't exist (`cameraPosition`, `pickupText`, `route`, `driverName`, `vehicleInfo`, `preview`, `onAppear`, `startTracking`), `TripStatus.searching` used but the enum case is `.requested`, `Trip`/`Driver` not `Decodable`/`Sendable` where the network client needs them, `Trip` initializer signature drift. This is a redesign-level repair — treat it as its own work item.
- After repairs: sync each app's `_prompts/` with the final APIs (music-interview-app's `03-repositories.prompt.md` updated 2026-07-02; audit the others), fill `music-interview-app/Sources/Views/Components/` (empty), add a CI job that builds all three + runs tests.

### 9. Site CI · P2 · Small
Port `.github/workflows/site.yml` + link-check from the Backend Edition. Also fix placeholder URLs in `site/astro.config.mjs` if present.

### 10. PDF + CHANGELOG · P3 · Small
Regenerate `dist-book/` only after Phase 2 lands; add a CHANGELOG for buyers.
