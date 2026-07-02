# Chapter 24: Cheat Sheets

> Keep this open on your second monitor. 

This is the rapid-fire reference guide for AI-Native Engineering.

---

## 1. The Prompt Anatomy Cheat Sheet

Every senior prompt must contain these 5 elements:

1. **Role:** `You are a Principal iOS Engineer.`
2. **Context:** `Read @adrs/001-swiftdata-over-coredata.md and @adrs/002-observation-over-combine.md.`
3. **Task:** `Implement the ProfileViewModel and ProfileView.`
4. **Constraint:** `You MUST use @MainActor. Do NOT import UIKit.`
5. **Review Hook:** `Before the code, explain where the state lives and who owns the task lifecycle — so I can verify the reasoning, not just the syntax.`

---

## 2. The Context Engineering Cheat Sheet

If the AI hallucinates, you violated one of these rules:

- **Rule of Locality:** Keep the files you feed the AI small (under 500 lines). Extract large functions before prompting.
- **Rule of Anchoring:** Always inject an ADR or a strict Architecture rule file (`.cursorrules`).
- **Rule of Iteration:** Never ask for a whole feature at once. Ask for the Model, then the ViewModel, then the View.

---

## 3. The Debugging Heuristics Cheat Sheet

When the AI gives you a bug, don't just say "this crashed, fix it." Form a hypothesis first:

| Symptom | Probable Cause | AI Prompt Direction |
| :--- | :--- | :--- |
| **Crash on Navigation (SwiftUI)** | State mutated off Main Thread. | *"Audit this ViewModel for MainActor violations."* |
| **Memory usage steadily climbing** | Retain cycle in an async closure. | *"Check this network closure for strong `self` capture. Fix with `[weak self]`."* |
| **Stuttering / Dropped Frames** | Heavy synchronous work in `body`. | *"Extract the date formatting out of this View's body and cache it."* |
| **Offline data is stale** | Wrote to a background DB context. | *"Verify that the background ModelContext is saving and merging to the Main UI context."* |

---

## 4. The Edge-Case Probe Checklist

LLMs ship the happy path. Before accepting any generated feature, probe every row — in an interview, probing these *out loud* is the skill being evaluated. (As a runnable review: `prompts/review/edge-case-probe.md`.)

| Probe | The question to ask |
| :--- | :--- |
| **Empty state** | What renders when the API returns zero items? |
| **Loading & error states** | Is there a visible loading state? What does the user see on failure — and can they retry? |
| **Offline / flaky network** | What happens on a dropped connection mid-scroll? Is anything cached? |
| **Rapid input** | The user taps "Save" 4 times fast — is the work debounced or the request de-duplicated? |
| **Lifecycle** | View dismissed (or app backgrounded) mid-request — are tasks canceled and subscriptions cleaned up? |
| **Low memory / older devices** | Are images downsampled? Is any cache unbounded? |
| **Rotation / Dynamic Type / dark mode / a11y** | Does the layout survive size changes and 200% text? Semantic colors? VoiceOver labels? |

---

## 5. The Concurrency Annotation Cheat Sheet

The compiler errors AI-generated Swift 6 code produces are almost always one of these picked wrong. What each annotation means, and when the AI reaches for it incorrectly:

| Annotation | Meaning | Reach for it when | The AI's classic misuse |
| :--- | :--- | :--- | :--- |
| `@MainActor` | Type/member isolated to the main actor | UI state, ViewModels, `ModelContext` access | Slapping it on everything until errors stop (works, but serializes your whole app onto main) |
| `actor` | Reference type with its own serialized executor | Shared mutable state off main: caches, connections, download managers | Forgetting every call becomes `await`; adding it to a type the UI reads per-frame |
| `nonisolated` | Member opts out of its type's isolation | Pure functions on actors; immutable `let`s needed synchronously (e.g. from `init`) | Marking something `nonisolated` that touches actor state — instant compile error |
| `nonisolated(unsafe)` | Opts out with **no checking** | Almost never; interop shims with proven external synchronization | Using it as an error-silencer — it deletes the diagnostic and keeps the race |
| `Sendable` | Type is safe to cross isolation boundaries | Value types, immutable classes, checked automatically | Assuming classes get it for free (they don't — only final + immutable qualify) |
| `@unchecked Sendable` | "Trust me" conformance, compiler verifies nothing | Types with internal locking; confined types satisfying protocol requirements | The #1 AI escape hatch: making the error disappear while shipping the race. Treat as a review-blocking waiver |
| `@ModelActor` | SwiftData actor with its own `ModelContext` | Bulk/background persistence work | Generating it for apps whose writes are trivially main-actor-sized |
| `Task { }` | Async work **inheriting** current isolation | Bridging sync → async in the current context (button actions) | Believing it "moves work to the background" — inside `@MainActor` it stays on main |
| `Task.detached { }` | Async work with **no** inherited isolation/context | Rarely; truly independent work | Using it to "fix" main-thread stalls and capturing non-`Sendable` state across the boundary (Ch 12's data race) |
| `.defaultIsolation(MainActor.self)` | Swift 6.2: whole module defaults to main actor | App/UI modules under approachable concurrency | The AI can't see build settings — *tell it* which world the module is in, or its annotations will be wrong in either direction |

---

## 6. The Property Wrapper Cheat Sheet (SwiftUI State)

| Wrapper | Owns the value? | Use for | AI failure mode |
| :--- | :--- | :--- | :--- |
| `@State` | Yes (view-local) | Ephemeral UI state; owning an `@Observable` object's lifetime | Using it for data that belongs in a ViewModel |
| `@Binding` | No | Child mutating parent-owned state | Passing bindings three levels deep instead of restructuring |
| plain `var` (of `@Observable`) | No | **The modern default** for injected ViewModels (iOS 17+) | Wrapping it in `@ObservedObject` (compile error) or `@State` (lifetime bug if injected) |
| `@Environment` | No | System values; app-wide dependencies (`\.modelContext`) | Reading it in `init` — returns the default value, not the injected one (the Ch 16 crash) |
| `@Query` | No | SwiftData fetches driving a view directly | Using it inside non-view types; it is a view-layer tool |
| `@StateObject` / `@ObservedObject` / `@Published` | — | **Legacy** (`ObservableObject` era) | The training-data default: the AI generates these unprompted in new code — per ADR-002, reject on sight |
| `@AppStorage` | Yes (UserDefaults) | Tiny user preferences (flags, enums) | Using it as a database — queryable domain data belongs in SwiftData (the Ch 14 PR) |

---

## 7. The Instruments Picker Cheat Sheet

The AI can *fix* what the profiler finds; it cannot run the profiler. Symptom → tool, so you start in the right instrument (always on a real, mid-range device):

| Symptom | Instrument / Tool | What you're looking for |
| :--- | :--- | :--- |
| Scroll stutter, dropped frames | **Time Profiler** + **Hitches** | Heavy stacks on main thread; hitch time ratio (>5ms/s is user-visible) |
| Screen is "warm", battery drain | **Time Profiler** (steady state) | Periodic wake-ups: timers ticking whole view trees, polling loops |
| Whole screen re-rendering | **SwiftUI instrument**; `Self._printChanges()` in DEBUG | Body counts out of proportion to what changed |
| Memory climbing, never dropping | **Leaks** + **Allocations**; Memory Graph Debugger | Retain cycles (closure → self), caches without limits |
| Killed in background / jetsam | **Allocations** peak footprint; MetricKit `MXMemoryDiagnostic` | Full-res image decodes, unbounded in-memory stores |
| Slow launch / watchdog `0x8badf00d` | **App Launch** instrument; MetricKit launch metrics | Main-thread I/O, migrations, sync network in the launch path |
| Stutter only when images appear | **Time Profiler** (look for `ImageIO` on main) | Decode-at-full-res; missing downsampling (Ch 15's `ArtworkLoader`) |
| Intermittent data corruption | **Thread Sanitizer** (scheme diagnostic, not Instruments) | Races that strict concurrency hasn't fenced yet (`@unchecked Sendable` zones) |
| Requests slow / duplicated | **Network instrument**, or Proxyman/Charles | Serial waterfalls that should be parallel; missing dedup (rapid-tap) |
| Disk churn, slow persistence | **File Activity**; SwiftData/Core Data instrument | Saves per keystroke; fetches in view bodies (the Ch 14 PR) |

---

## 8. The Agentic IDE Cheat Sheet (Cursor/Windsurf)

- **`Cmd+K` (Inline Edit):** Best for localized algorithmic fixes (e.g., *"Refactor this map/filter chain to be O(N)"*).
- **Composer / Flow:** Best for multi-file generation (e.g., *"Generate a Settings feature based on `@SettingsRFC.md`."*).
- **`.cursor/rules/` / `AGENTS.md`:** The most important configurations in your repository. They dictate the AI's default behavior and architecture.

---

## 9. The Interview Cheat Sheet

When asked a System Design or Machine Coding question:
1. **Define Constraints first:** DAU, Offline support, Security.
2. **Establish the boundaries:** "The View will only talk to the ViewModel. The ViewModel will only talk to the Repository."
3. **Analyze Tradeoffs openly:** "I am choosing SwiftData over CoreData for velocity, acknowledging we lose iOS 16 support."
4. **Embrace the Adversary:** "If the network drops exactly when this function runs, we have a corrupted state. Here is how I will wrap it in a transaction." (Run the Edge-Case Probe Checklist above, out loud.)
