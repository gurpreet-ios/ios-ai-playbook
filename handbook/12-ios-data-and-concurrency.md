# Chapter 12: iOS Data and Concurrency

> "Concurrency in Swift 6 is no longer a suggestion. It is a strict compiler requirement. If you let the AI guess at thread isolation, your code will not compile."

The data and concurrency layer in iOS has seen a total paradigm shift. We have moved from `Combine` and `CoreData` to `Observation`, `SwiftData`, and strict `async/await` with `Actors`.

Because AI models are trained on historical data, their default behavior is often to generate outdated iOS 14 code. You must actively force the AI into the modern era.

---

## 1. SwiftData vs. CoreData

### Definition
`SwiftData` is Apple's modern, Swift-native macro-based persistence framework, effectively replacing the heavy boilerplate of `CoreData`.

### Architecture ADR
> See `adrs/001-swiftdata-over-coredata.md` (We default to SwiftData for all new projects unless extreme legacy migration is required).

### AI Prompting Strategy
LLMs love to generate `CoreData` XML schemas and `NSManagedObject` subclasses. Stop them.
* **Senior Prompt:** "Define the local database schema using `SwiftData`. Use the `@Model` macro. Ensure all relationships are explicitly marked with `@Relationship(deleteRule: .cascade)` where appropriate. DO NOT use CoreData or `NSManagedObject`."

---

## 2. The Observation Framework

### Definition
Introduced in iOS 17, the `@Observable` macro replaces the `ObservableObject` protocol and `@Published` properties from the Combine era. It drastically reduces view re-renders by tracking exactly which properties a view reads.

### Architecture ADR
> See `adrs/002-observation-over-combine.md` (Combine is superseded for state management; use Observation for all new ViewModels).

### AI Prompting Strategy
* **Senior Prompt:** "Generate the ViewModel using the iOS 17 `@Observable` macro. Do not use `ObservableObject`, `@Published`, or `Combine`. Inject dependencies via the initializer."

---

## 3. Strict Concurrency & Actors

### Definition
Swift 6 enforces strict concurrency checking, eliminating data races at compile time. Data shared across threads must be `Sendable`, and mutable state must be isolated to an `Actor` (or `@MainActor`).

### The Danger with AI
If you ask an AI to write a network fetcher, it will often write it using closure-based `URLSession` data tasks without actor isolation. This will instantly fail to compile under Swift 6.

### AI Prompting Strategy
* **Scaffolding:** "Write a `NetworkClient`. It must be an `actor` to isolate its internal cache. Use `async/await` for all network calls. Ensure the returned models are `Sendable`."
* **Review:** `prompts/review/swift-concurrency-audit.md` (Run this relentlessly against AI-generated code to catch MainActor violations).

### The Swift 6.2 Shift: MainActor by Default
Swift 6.2 introduced "approachable concurrency": a per-module default-isolation setting (`.defaultIsolation(MainActor.self)` in the package manifest) that makes everything in the module implicitly `@MainActor` unless it opts out. This matters enormously for prompting, because the correct annotations for a file now depend on a **build setting the AI cannot see**. Always tell it which world it's in:
* *"This module builds with default MainActor isolation. Do not sprinkle `@MainActor` everywhere — only annotate the types that must run OFF the main actor (`nonisolated`, or a dedicated `actor`)."*

Under the old Swift 6.0 default, the opposite instruction applies. An AI that guesses wrong produces code that is either noisy or doesn't compile.

### Interview Answer
> *"Concurrency is the hardest thing to get right in iOS. The beauty of Swift 6 is that the compiler now proves thread safety for us. I strictly use `actor` for shared mutable state and explicitly mark UI-driving ViewModels with `@MainActor`. I avoid un-checked `Sendable` conformances unless absolutely necessary. With 6.2's default-isolation modes, the first thing I check is the module's isolation setting — it decides what 'correctly annotated' even means."*

---

## 4. Networking

### Definition
Communicating with external REST or GraphQL APIs.

### Architecture: The Network Layer
Never let the AI put `URLSession` calls directly in a ViewModel. Force the use of an injected Repository or Client.

### AI Prompting Strategy
* **Senior Prompt:** "Generate a generic API client using `URLSession.shared.data(from:)`. It must accept a generic `Codable` type and return it. Handle HTTP status codes (200-299) and map them to a custom `APIError` enum. The function must be `async throws`."

---

## 5. Macros

### Definition
Swift Macros (like `@Model`, `@Observable`, or custom ones) allow you to generate repetitive boilerplate code at compile time.

### AI Prompting Strategy
Writing macros from scratch is incredibly difficult for AI because it requires interacting with the `SwiftSyntax` abstract syntax tree (AST). 
If you *must* have the AI write a macro:
* **Senior Prompt:** "Write a Swift Macro called `@RouteBuilder`. Attached is `SwiftSyntax` documentation for generating enum cases. Think step-by-step about the AST nodes required to generate a switch statement."

*(Note: Unless you are building platform-level tooling, avoid asking AI to write macros. Ask it to use them instead).*

---

## 6. The Running Example: MusicApp's Offline Download Engine

> *Continuing the Part 3 spine ([`sample-apps/music-interview-app`](../sample-apps/music-interview-app)). This chapter is where the architecture meets the compiler: the offline-downloads feature, and a data race Swift 6 refuses to build.*

### The Task

"Downloaded tracks play offline." That one sentence is a sync engine: fetch metadata from the network, persist it in SwiftData, download the audio file, record its local URL on the persisted row, and prefer that URL at playback time. It crosses every boundary this chapter covers — network, disk, model, UI — which is why it's also where AI-generated concurrency goes to die.

### The Working Architecture

MusicApp splits the engine across three isolation domains, each chosen deliberately:

- **`NetworkClient` is an `actor`** — it owns mutable session state and does slow work; nothing else should wait on it.
- **`TrackRepository` is `@MainActor`** — it mutates SwiftData `@Model` objects, and this app confines all model mutation to the main actor's `ModelContext`.
- **`Track` is a SwiftData `@Model` class** — reference-typed, mutable, and *not* naturally `Sendable`.

```swift
@MainActor
public final class TrackRepository: TrackRepositoryProtocol {
    private let networkClient: any NetworkClientProtocol   // an actor
    private let modelContext: ModelContext

    public func downloadTrack(id: UUID) async throws {
        let track = try await getTrack(id: id)          // main actor: fetch/upsert the row
        let fileURL = try await networkClient
            .downloadTrackFile(id: id)                  // hops to the actor: slow I/O off main
        track.offlineFileURL = fileURL                  // back on main: mutate the model
        try modelContext.save()
    }
}
```

Note the shape: the *slow thing* (`downloadTrackFile`) happens inside the network actor and returns a `Sendable` value (`URL`). The *mutable thing* (`track`) never leaves the main actor. Values cross the boundary; models don't.

### The Failure: The Race Swift 6 Caught

The AI's first draft "optimized" the repository by pushing the whole operation into a background task — a pattern it has seen ten thousand times in pre-Swift-6 training data:

```swift
// ❌ The AI's "faster" version
public func downloadTrack(id: UUID) async throws {
    let track = try await getTrack(id: id)
    Task.detached {                                   // escape the main actor…
        let fileURL = try await self.networkClient.downloadTrackFile(id: id)
        track.offlineFileURL = fileURL                // …and mutate the @Model from nowhere
        try self.modelContext.save()
    }
}
```

Under Swift 5 this compiles, ships, and corrupts state intermittently: a background thread mutates a model object the UI is simultaneously reading, and `ModelContext` (non-`Sendable`, main-actor-bound here) gets touched off its actor. Under Swift 6 strict concurrency it simply does not build:

```text
error: capture of 'track' with non-Sendable type 'Track' in a '@Sendable' closure
error: main actor-isolated property 'modelContext' can not be referenced
       from a Sendable closure
```

Read those diagnostics as the compiler telling you *the design is wrong*, not that annotations are missing. The classic AI failure loop starts here: it will offer to "fix" the error by slapping `@unchecked Sendable` on `Track` — which deletes the diagnostic while keeping the race. (MusicApp's `Track` does carry an `@unchecked Sendable` conformance to satisfy protocol requirements; it is safe *only because* every mutation site is `@MainActor`-confined. Treat any AI-added `@unchecked Sendable` as a review-blocking waiver, per the data-race playbook in `interview-playbooks/code-review/data-race.md`.)

The correct fix is the working version above: keep the mutation on the main actor and move only the *waiting* off it. The download already ran on the network actor; detaching the model write bought nothing but the race.

### Why Not a `ModelActor`?

For heavier sync loads (hundreds of rows, import jobs), the right tool is SwiftData's `@ModelActor` — a dedicated actor with its own `ModelContext` doing bulk writes off the main thread, coordinating with the UI via saves and re-fetches rather than shared objects. MusicApp doesn't need it: its writes are a handful of rows on user action, and the main-actor context is nowhere near contended. That's an ADR-worthy judgment call — *default to main-actor confinement, escalate to `@ModelActor` when profiling says the main thread pays for writes* — and it belongs in your rules file so the AI stops guessing which world it's in.

### The Prompt That Prevents It

> *"Implement `downloadTrack(id:)` in `TrackRepository` (`@MainActor`, Swift 6 strict concurrency). Rules: (1) file I/O and networking run inside `NetworkClient` (an actor) and return `Sendable` values only; (2) `Track` is a SwiftData `@Model` — it must never be captured by a detached task or sent across an isolation boundary; (3) all `ModelContext` access stays on the main actor; (4) if the compiler reports a Sendable violation, treat it as a design error — do NOT add `@unchecked Sendable` or `nonisolated(unsafe)` anywhere. Build with strict concurrency before presenting the diff."*

The compiler is the one reviewer that never gets tired. Swift 6's strictness turns an entire class of AI-generated production crashes into build failures — your job in the prompt is to forbid the escape hatches that would turn them back.
