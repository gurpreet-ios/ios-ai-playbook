# Chapter 9: Presentation Architecture

> "If you do not strictly define the boundaries of your presentation layer, the AI will invent its own."

AI models are stochastic. They do not naturally adhere to strict boundaries unless explicitly forced to. In this chapter, we explore the most common Presentation Architectures (the UI layer). For each pattern, we define the tradeoffs, how to answer interview questions about them, and crucially, how to prompt the AI to generate and review them.

---

## 1. MVVM (Model-View-ViewModel)

### Definition
MVVM separates the UI (View) from the business logic and state (ViewModel). The ViewModel exposes observable streams of data that the View binds to. It is the de facto standard for modern declarative frameworks like SwiftUI and Jetpack Compose.

### When to Use
- The default choice for 90% of modern mobile and web applications.
- When using reactive/declarative UI frameworks (SwiftUI, React, Compose).

### When NOT to Use
- Extremely simple CRUD screens where the ViewModel just passes data through.
- Massive, hyper-complex screens with dozens of independent state streams (can lead to "Massive ViewModel").

### Tradeoffs
- **Pros:** Excellent separation of concerns, highly testable, native support in modern SDKs.
- **Cons:** Can lead to massive ViewModels; routing/navigation is often awkwardly shoehorned into the ViewModel.

### Interview Answer
> *"I prefer MVVM for declarative frameworks because it perfectly aligns with data-binding. However, my main critique of vanilla MVVM is that it lacks a dedicated router, meaning navigation logic often bleeds into the view or the ViewModel. I usually solve this by combining MVVM with a Coordinator pattern."*

### AI Prompts
- **Scaffolding:** `prompts/architecture/mvvm-scaffold.md` 
  - *"Generate the ViewModel and View using MVVM. The ViewModel must be a `@MainActor` class using the `@Observable` macro (per `adrs/002-observation-over-combine.md`) — do not use `ObservableObject` or `@Published`."*
- **Review:** `prompts/review/mvvm-audit.md`
  - *"Review this ViewModel. Flag any UIKit/Foundation imports that belong in the View. Flag any missing `MainActor` annotations."*

---

## 2. MVI (Model-View-Intent)

### Definition
MVI builds on MVVM by enforcing a strictly unidirectional data flow. The View sends `Intents` to the Model/ViewModel, which processes them and emits a single, immutable `State` object back to the View.

### When to Use
- Applications with highly complex state machines (e.g., video editors, complex forms).
- When debugging state consistency is a primary concern.

### When NOT to Use
- Simple list-and-detail apps. The boilerplate of defining Actions, States, and Reducers will slow you down unnecessarily.

### Tradeoffs
- **Pros:** State is perfectly predictable; easy to reproduce bugs by replaying Intents.
- **Cons:** High boilerplate; minor UI updates (like typing in a text field) must route through the entire intent loop.

### Interview Answer
> *"MVI shines when state management becomes a nightmare. By forcing all changes through a single intent channel and rendering a single immutable state, you eliminate race conditions. The tradeoff is velocity—you write more boilerplate. I reserve MVI for core, high-complexity features."*

### AI Prompts
- **Scaffolding:** *"Implement this feature using MVI. Define `State` as a single struct. Define `Intent` as an enum. The ViewModel should have a single public `process(intent:)` function."*

---

## 3. VIPER (View-Interactor-Presenter-Entity-Router)

### Definition
VIPER is an implementation of Clean Architecture specifically for iOS. It separates logic into 5 distinct layers, completely isolating UI, business rules, and navigation.

### When to Use
- Massive enterprise applications (e.g., Uber, Banking apps) with 50+ engineers.
- When you need aggressive separation of concerns to prevent merge conflicts.

### When NOT to Use
- Small to medium apps.
- When using SwiftUI (VIPER was designed for UIKit and struggles with declarative state binding).

### Tradeoffs
- **Pros:** Maximum testability; every component has exactly one responsibility.
- **Cons:** Unbearable boilerplate. Creating a simple screen requires 5 files and 5 protocols.

### Interview Answer
> *"VIPER is fantastic for isolating domains in massive teams using UIKit. However, I believe it is largely obsolete for SwiftUI. The tight coupling of Presenter-to-View protocols fights against SwiftUI’s natural state-binding mechanisms."*

### AI Prompts
- **Scaffolding:** *"Generate a VIPER module for the Login feature. Create the 5 protocols and classes. Ensure the Router handles all navigation and the Interactor has zero knowledge of UIKit."*

---

## 4. Redux (TCA - The Composable Architecture)

### Definition
Derived from React, Redux (and its Swift equivalent, TCA) relies on a single global `Store`. The state is immutable and can only be changed by dispatching `Actions` to a pure function called a `Reducer`.

### When to Use
- Apps where global state needs to be accessed and mutated from many disparate screens.
- When you want unparalleled testability (testing reducers is literally just `state + action = new state`).

### When NOT to Use
- Rapid prototyping.
- Teams unfamiliar with functional programming concepts.

### Tradeoffs
- **Pros:** State predictability is flawless. Testing is trivial. Excellent ecosystem (like pointfreeco's TCA).
- **Cons:** Very steep learning curve. The global store can become a performance bottleneck if not modularized correctly.

### Interview Answer
> *"I am a huge proponent of Redux/TCA for apps with complex shared state. The ability to write exhaustive tests that verify not just state changes, but also asynchronous side effects, is unmatched. However, I avoid it if the team lacks functional programming experience, as the paradigm shift can severely hurt velocity."*

### AI Prompts
- **Scaffolding:** `prompts/architecture/ios-tca-feature.md`
  - *"Generate a TCA feature using the `@Reducer` macro: the `State` struct, the `Action` enum, and the `@Dependency` clients it needs. Do not use the legacy `Environment` type — it was removed from TCA years ago, and models trained on old tutorials still reach for it."*
- **Review:** *"Audit this Reducer. Ensure no side-effects are performed outside of the `Effect` (or `run`) closure. Verify State is not mutated asynchronously."*

---

## 5. The Running Example: Choosing an Architecture for MusicApp

> **The spine of Part 3.** Chapters 9–16 evolve one codebase: **MusicApp**, the streaming-app skeleton in [`sample-apps/music-interview-app`](../sample-apps/music-interview-app). Every decision in these chapters is made on it, and every failure mode shown is one an AI actually produces. By Chapter 16 you will have seen the same app architected, modularized, built, made concurrent, reviewed, profiled, and debugged.

### The Decision

MusicApp is a streaming client: a library list, a Now Playing screen, offline downloads. Small team, SwiftUI-first, iOS 17+. Working down this chapter's catalog:

- **VIPER** is out immediately — this is SwiftUI, and five protocols per screen for a two-tab app is self-harm.
- **TCA** is defensible but unpaid-for: there is no complex shared-state graph, no undo/replay requirement, and the team would be debugging the framework *and* the AI's stale TCA training data at the same time.
- **MVI** would help the player's state machine but taxes every boring screen with intent plumbing.
- **MVVM + Router** wins: native fit with `@Observable`, testable seams via protocol-injected dependencies, and boilerplate so conventional the AI cannot get creative with it.

The decision is recorded in an ADR (`adrs/004-state-management.md` establishes the state rules; the scaffold prompt in `prompts/architecture/mvvm-scaffold.md` enforces them) so no future prompt can relitigate it.

### The Trap: The First Generation

The lazy prompt — *"Build a music streaming app in SwiftUI with a library screen and a player screen. Use MVVM."* — produces MVVM in name only. The model reads "an app" and generates **one** ViewModel:

```swift
@MainActor @Observable
final class MusicAppViewModel {          // ← "the" ViewModel
    // Library state
    var tracks: [Track] = []
    var isLoadingLibrary = false
    // Playback state
    var playbackState: PlaybackState = .stopped
    var currentTrack: Track?
    // Download state
    var downloadProgress: [UUID: Double] = [:]
    // Navigation state
    var isShowingPlayerSheet = false
    // Whose error is this? Nobody knows.
    var errorMessage: String?

    func loadTracks() async { /* … */ }
    func play(track: Track) async { /* … */ }
    func togglePlayPause() async { /* … */ }
    func download(track: Track) async { /* … */ }
    // …400 lines by the third feature
}
```

This is the **Massive-ViewModel trap**, and it costs you three ways:

1. **Render blast radius.** Every view reads this object. (With `ObservableObject` this is catastrophic — any change invalidates every observer. `@Observable`'s property-level tracking softens it, but coarse state like a shared `errorMessage` still couples unrelated screens.)
2. **Test surface.** Testing "does the library load?" requires constructing playback, download, and navigation dependencies too.
3. **The context magnet** — the AI-era cost. Every future prompt about *any* feature must drag this entire file into context. Every generated diff touches the same file. The god object doesn't just rot your architecture; it rots your prompts.

### The Fix: Scope State by Lifetime

The split rule that MusicApp uses — and the one to dictate in your prompts — is **scope state by lifetime, not by screen count**:

- Library state is *screen-scoped*: it can die when the screen does. → `LibraryViewModel`.
- Playback state is *app-scoped*: the music keeps playing while you browse. → `PlayerViewModel`, created once at the composition root and injected wherever it's needed.

```swift
@MainActor @Observable
public final class LibraryViewModel {
    public var tracks: [Track] = []
    public var isLoading: Bool = false
    public var errorMessage: String?

    private let repository: any TrackRepositoryProtocol

    public init(repository: any TrackRepositoryProtocol) {
        self.repository = repository
    }

    public func loadTracks() async { /* delegate to repository */ }
}

@MainActor @Observable
public final class PlayerViewModel {
    public var playbackState: PlaybackState = .stopped
    public private(set) var currentTrack: Track?

    public var isPlaying: Bool { playbackState == .playing }

    private var queue: [Track] = []
    private let audioEngine: any AudioEngineProtocol

    public init(audioEngine: any AudioEngineProtocol) { /* … */ }

    public func play(track: Track, in queue: [Track] = []) async { /* … */ }
    public func togglePlayPause() async { /* … */ }
}
```

Both are constructed in one place — the **composition root** (`AppRootView` in `Sources/App/MusicInterviewApp.swift`), which builds the dependency graph and hands each screen exactly the object matching its lifetime. Chapter 12 returns to why that file is also where concurrency correctness is won or lost.

### The Router

MusicApp today is a two-tab `TabView`, so its routing is trivial. But the moment a third screen appears (playlist detail, artist page), navigation must not be scattered as inline `NavigationLink` destinations — that is how the AI welds screens together. The pattern the next feature drops into:

```swift
enum Route: Hashable {
    case playlistDetail(Playlist.ID)
    case artist(String)
}

@MainActor @Observable
final class Router {
    var path = NavigationPath()
    func navigate(to route: Route) { path.append(route) }
    func popToRoot() { path = NavigationPath() }
}
```

Views call `router.navigate(to:)` and stay ignorant of destinations; one `.navigationDestination(for: Route.self)` at the stack root maps routes to screens.

### The Prompt That Prevents the Trap

The difference between the god object and the clean split is one paragraph of constraints:

> *"Add a [feature] screen to MusicApp. Architecture rules: (1) One `@Observable @MainActor` ViewModel per screen — do NOT add state to any existing ViewModel. (2) Playback state lives only in `PlayerViewModel`; if you need it, inject `PlayerViewModel`, never duplicate its properties. (3) All dependencies injected via initializer as protocols. (4) Navigation goes through `Router.navigate(to:)` — no inline `NavigationLink(destination:)`. Review `adrs/004-state-management.md` before writing code."*

The catalog above tells you what the patterns are. The lesson of MusicApp is that *the pattern is not the deliverable — the boundary is.* MVVM without an ownership rule degenerates into a god object within three prompts.

---

*In the next chapter, we will move beneath the UI layer and explore **System Architectures** like Clean, DDD, and Repository patterns.*
