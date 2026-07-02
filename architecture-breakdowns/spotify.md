# AI Architecture Breakdown: Spotify

## The Core Challenge

Global playback state and offline-first storage. The audio must keep playing regardless of which screen the user navigates to — playback state has an *app* lifetime, not a *screen* lifetime — and downloaded tracks must be instantly available with no network. Every other decision in this blueprint falls out of those two sentences.

> **This blueprint is buildable.** It is the same architecture as the Part 3 spine app ([`sample-apps/music-interview-app`](../sample-apps/music-interview-app), walked through in Chapters 9–16) and the concise-prompt variant in [`sample-apps/spotify-clone`](../sample-apps/spotify-clone). Read this file for the *sequence*; read the apps for the resulting code.

## The Core Domain

`Track` (identity, metadata, a stream URL, an *optional* offline file URL — that optionality **is** the offline feature), `Playlist`, `PlaybackState` (playing / paused / buffering / stopped), and the queue. Sketch these before any prompt: the AI's entities drift unless yours are written down first.

## The Architecture Decisions (state them before prompting)

| Decision | Choice | Why |
| :--- | :--- | :--- |
| Presentation | MVVM, state scoped by **lifetime** | Playback outlives screens → app-scoped `PlayerViewModel`; library state is screen-scoped (Ch 9) |
| Persistence | SwiftData, DTO ↔ `@Model` split | `TrackDTO` crosses network/actor boundaries; `@Model` stays main-actor confined (Ch 12) |
| Audio | `AVFoundation` inside an `actor`, state out via `AsyncStream` | The engine is shared mutable state; the stream decouples it from Observation |
| Data access | Repository orchestrating network + store | Offline-or-stream resolution lives in exactly one place |
| Concurrency | Swift 6 strict | The playback/download paths are where AI-generated races live |

## The Prompt Sequence

Order matters: engine before state, state before UI. Each prompt names its boundary; each review hook targets the failure the AI actually produces at that layer.

### 1. The Domain Layer

> **Prompt:** "Define the domain for a music streaming app: a SwiftData `@Model` class `Track` (`id` unique, `title`, `artist`, `coverURL: URL?`, `streamURL: URL`, `offlineFileURL: URL?`), a `Playlist` model, and a separate `Codable, Sendable` struct `TrackDTO` mirroring the network payload. The DTO and the model are different types on purpose — do not merge them."

**Watch for:** the AI collapsing DTO and `@Model` into one type "for simplicity." That one type then can't safely cross an actor boundary, and layer 3 becomes unbuildable under Swift 6.

### 2. The Audio Engine

> **Prompt:** "Generate an `AudioEngine` **actor** wrapping `AVPlayer`: `play(url:)`, `pause()`, `resume()`, `stop()`, background-audio session category, Now Playing Info Center, and interruption/route-change handling (headphones unplugged → pause). Expose state as a `nonisolated let playbackStateStream: AsyncStream<PlaybackState>` created in `init`. Hide everything behind `AudioEngineProtocol` so tests can substitute a spy."

**Watch for:** KVO/notification observers capturing non-`Sendable` actor state, and any actor-isolated method called from `init` (the compile error the sample app actually hit — the fix is `nonisolated`).

### 3. The Offline Repository

> **Prompt:** "Generate a `@MainActor TrackRepository` behind `TrackRepositoryProtocol`: `fetchTracks()` pulls DTOs from `NetworkClientProtocol` and **upserts** them into SwiftData (fetch-by-id, update or insert — never blind insert); `downloadTrack(id:)` downloads the file via the network actor, then records the local URL on the model. Playback resolution is one expression owned here: `offlineFileURL ?? streamURL`."

**Watch for:** duplicate rows (the missing upsert), and any `Task.detached` around the SwiftData write — that is the Chapter 12 data race, and Swift 6 will reject it. Encrypt-at-rest, licensing windows, and eviction policy are the interviewer's natural follow-ups; name them even if you stub them.

### 4. Global Playback State

> **Prompt:** "Generate an `@Observable @MainActor PlayerViewModel` injected with `AudioEngineProtocol`. It owns `currentTrack`, the queue, and `playbackState` (consumed from the engine's stream via a cancellable task). `playNext`/`playPrevious` navigate the queue with no wrap-around. It is created **once at the composition root** — screen ViewModels never duplicate its state."

**Watch for:** the observation task capturing `self` strongly (retain cycle — `[weak self]` plus an explicit `cleanup()`), and playback properties leaking into screen ViewModels (the Massive-ViewModel trap, Ch 9).

### 5. The Mini Player & Screens

> **Prompt:** "Library and Now Playing screens plus a persistent `MiniPlayerView` overlaid at the bottom of the root `ZStack`, above the tab bar, visible on every screen while `currentTrack != nil`. All three read the single injected `PlayerViewModel`. High-frequency state (elapsed time) is read only inside the smallest subview that renders it."

**Watch for:** the 4Hz whole-screen re-render (Ch 11): a progress timestamp read in a screen-level `body` quietly re-evaluates everything, every tick, forever.

### 6. The Verification Pass

> **Prompt:** "Generate Swift Testing suites: queue navigation (advance, no-op at end), offline-URL preference over stream URL, and repository upsert idempotency against an in-memory `ModelContainer`. Then run the tautology audit from `prompts/testing/tautology-audit.md` on your own output."

## The Failure Modes to Probe (interview extension bank)

- **Force-quit during a download** — is a half-written file ever recorded as `offlineFileURL`? (Download to temp, move atomically, *then* save.)
- **Offline launch** — does the library render from SwiftData with zero network, or does a failed fetch blank the UI?
- **Audio interruptions** — phone call mid-song; CarPlay/AirPods route changes.
- **The 10,000-track library** — is artwork downsampled and the list lazy, or does scrolling jetsam the app (Ch 15)?

## Related Assets

- Interview simulation: [`interview-playbooks/machine-coding/download-manager.md`](../interview-playbooks/machine-coding/download-manager.md), [`interview-playbooks/architecture/offline-first-chat.md`](../interview-playbooks/architecture/offline-first-chat.md) (the same offline/outbox reasoning)
- Chapters: 9 (state scoping), 11 (over-render), 12 (the download engine + data race), 13 (Now Playing widget/Live Activity)
