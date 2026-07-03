---
title: "Chapter 10: System Architecture"
---

> "AI can write functions. It cannot write systems. You must define the boundaries."

If the Presentation layer is how the application looks, the System Architecture is how the application survives. It dictates how data is fetched, how modules communicate, and how business rules are protected from UI framework churn.

When working with AI, System Architecture is your ultimate leverage. By giving the AI clear interfaces and isolated modules, you bound its context and eliminate hallucinations.

---

## 1. Clean Architecture

### Definition
Introduced by Uncle Bob, Clean Architecture separates software into concentric layers (Domain, UseCases, Interface Adapters, Frameworks). The defining rule is the **Dependency Rule**: dependencies must only point *inward* toward the Domain.

### When to Use
- Complex enterprise applications that will live for 5+ years.
- When the business logic is complex and must be decoupled from UI frameworks (e.g., migrating from UIKit to SwiftUI).

### When NOT to Use
- Prototyping or highly UI-driven apps with no complex business rules.

### Tradeoffs
- **Pros:** Ultimate testability; you can test the entire business logic without launching a UI or mocking a database.
- **Cons:** High cognitive overhead and file bloat (you often need DTOs, Domain Entities, and ViewModels mapping to the same concept).

### Interview Answer
> *"Clean Architecture is the gold standard for separating business rules from infrastructure. The Dependency Rule ensures that my core logic doesn't care if we use CoreData or SwiftData. The tradeoff is the mapping boilerplate across boundaries, which I mitigate by having AI generate my DTO-to-Domain mappers."*

### AI Prompts
- **Scaffolding:** `prompts/architecture/clean-architecture-scaffold.md`
- **Review:** *"Audit this UseCase. Flag any import of UI frameworks (UIKit/SwiftUI). Ensure it only depends on Repository interfaces, not concrete implementations."*

---

## 2. Feature Modules (Modular Architecture)

### Definition
Instead of organizing code by layer (e.g., all ViewModels in one folder), code is organized by Feature (e.g., `SearchFeature`, `CheckoutFeature`). These features are often isolated into separate physical frameworks (Swift Packages or Gradle modules).

### When to Use
- Large codebases with multiple engineers.
- When build times are becoming a bottleneck.

### When NOT to Use
- Small apps where the overhead of managing module dependencies outweighs the build-time benefits.

### Tradeoffs
- **Pros:** Drastically reduces build times; prevents features from tangling together (spaghetti code).
- **Cons:** Requires a strict dependency injection strategy to allow features to navigate to one another without circular dependencies.

### Interview Answer
> *"I always push for Feature Modules in teams of 3 or more. By isolating features into Swift Packages, we get enforced access control—you literally cannot import a private internal class from another feature. It also forces us to define clear API contracts for how features communicate."*

### AI Prompts
- **Scaffolding:** *"Generate a new Swift Package for the `OnboardingFeature`. Include a public API file, and keep all UI and logic `internal`."*

---

## 3. The Repository Pattern

### Definition
Abstracts data access logic behind an interface. The rest of the app asks the Repository for a `User`, and the Repository decides whether to fetch it from the Network, the Disk, or memory.

### When to Use
- When you need caching.
- When integrating with external APIs.

### When NOT to Use
- If the app just writes directly to a local DB with no remote syncing (though even then, it's cheap insurance).

### Tradeoffs
- **Pros:** Hides the complexity of data orchestration; makes the UI layer completely agnostic to networking.
- **Cons:** Can become a dumping ground for all data-related methods if not scoped correctly.

### Interview Answer
> *"The Repository pattern is essential for any app that works offline. It allows the ViewModel to simply say 'give me the user', while the Repository handles the complexity of checking the cache, firing a network request, and saving the result back to disk."*

### AI Prompts
- **Scaffolding:** *"Implement a `UserRepository` conforming to `UserRepositoryProtocol`. It must fetch from `NetworkClient` first, fallback to `DiskCache`, and handle all mapping from DTOs to Domain entities."*

---

## 4. Coordinator Pattern

### Definition
Extracts navigation logic out of the View and ViewModel into a dedicated `Coordinator` class. 

### When to Use
- When screens need to be reusable in different flows (e.g., a "Profile" screen accessed from Settings and from a Chat).
- When using UIKit.

### When NOT to Use
- Simple, linear SwiftUI apps (SwiftUI's `NavigationStack` with `NavigationPath` often reduces the need for heavy UIKit-style Coordinators).

### Tradeoffs
- **Pros:** Massive reusability of views; deep-linking becomes trivial.
- **Cons:** Managing the Coordinator hierarchy can get complex and leak memory if delegates aren't weak.

### Interview Answer
> *"Coordinators solve the massive View problem by taking over routing. In UIKit, they are mandatory. In SwiftUI, I adapt them into `Router` objects that manage a `NavigationPath`, keeping the Views completely ignorant of where they go next."*

---

## 5. Advanced Patterns: DDD, CQRS, Hexagonal

For Senior/Staff roles, you must be familiar with backend-derived patterns, even on mobile.

* **Domain-Driven Design (DDD):** Focusing on the core domain logic and ubiquitous language. Useful when business logic is highly complex (e.g., FinTech).
* **CQRS (Command Query Responsibility Segregation):** Separating read operations (Queries) from write operations (Commands). Extremely useful in complex offline-sync scenarios where reading from a local DB is fundamentally different than writing to a server.
* **Hexagonal Architecture (Ports and Adapters):** Similar to Clean Architecture, focusing on the application core communicating with the outside world via Ports (Interfaces) and Adapters (Implementations).

### AI Prompts for Advanced Systems
- **Scaffolding:** *"Generate a CQRS architecture for the `OrderService`. Define the `Command` models for creating orders, and the `Query` models for fetching order history."*

---

## 6. The Running Example: Modularizing MusicApp

> *Continuing the Part 3 spine ([`sample-apps/music-interview-app`](https://github.com/gurpreet-ios/ios-ai-playbook/tree/main/sample-apps/music-interview-app)). Chapter 9 chose MVVM + Router; this chapter draws the module boundaries beneath it.*

MusicApp ships as a single SwiftPM target today — fine for a codebase you can read in one sitting. But its folder layout (`Models/`, `Services/`, `Repositories/`, `ViewModels/`, `Views/`) is already the module map waiting to happen, and doing the split on a small app is the cheapest way to learn where the AI gets it wrong.

### The Ask

> *"Split MusicApp into SwiftPM targets. Layers: models, networking, persistence, audio, and the app layer (ViewModels + Views). Update `Package.swift`; each target gets its own `Sources/<TargetName>` directory. Keep everything compiling."*

(The cycle-proof version of this ask is `prompts/architecture/swiftpm-modularization.md`, backed by `adrs/006-modularization-strategy.md`.)

### The Failure: The Cycle

The AI's first `Package.swift` looked plausible:

```swift
targets: [
    .target(name: "MusicModels"),
    .target(name: "MusicNetworking", dependencies: ["MusicModels", "MusicPersistence"]),
    .target(name: "MusicPersistence", dependencies: ["MusicModels", "MusicNetworking"]),
    // …
]
```

Its reasoning was locally sensible — the networking layer "needs to cache responses" (so it imports persistence), and the persistence layer "needs to fetch what's missing" (so it imports networking). Two locally-sensible decisions, one globally illegal graph. SwiftPM refuses at resolution time:

```text
error: cyclic dependency declaration found:
MusicNetworking -> MusicPersistence -> MusicNetworking
```

You will meet this failure constantly, because **an AI generating file-by-file optimizes each file's convenience, and cycles are precisely what convenient local decisions sum to.** In a monolith the same cycle forms silently as tangled imports; SwiftPM's refusal to build is the feature you are buying.

### The Fix: Point Dependencies at the Contract

The cycle exists because two peers each want the other's *implementation*. The repair is the Dependency Rule from Clean Architecture, applied with SwiftPM as the enforcement mechanism: peers may only share what sits **below** them.

```swift
targets: [
    // Leaf: pure value types (TrackDTO, PlaybackState). No dependencies.
    .target(name: "MusicModels"),

    // Peers: know the models, not each other.
    .target(name: "MusicNetworking",  dependencies: ["MusicModels"]),
    .target(name: "MusicPersistence", dependencies: ["MusicModels"]),
    .target(name: "MusicAudio",       dependencies: ["MusicModels"]),

    // Composition: repositories + ViewModels + Views orchestrate the peers.
    .target(name: "MusicApp",
            dependencies: ["MusicModels", "MusicNetworking",
                           "MusicPersistence", "MusicAudio"]),
]
```

"Networking caches" and "persistence fetches" were never one layer's job — they are *orchestration*, and MusicApp already has the right home for it: `TrackRepository`. It takes both a `NetworkClientProtocol` and a `ModelContext`, fetches DTOs from one, upserts `@Model` rows into the other, and neither lower layer knows the other exists. The Repository pattern from §3 of this chapter isn't just an abstraction nicety — it is *where the cycle goes to die*.

Two boundary rules fall out of the split, and both should appear verbatim in your prompts:

1. **DTOs stay in the leaf; `@Model` classes stay in persistence.** `TrackDTO` (a `Sendable` struct) can be passed anywhere; `Track` (a SwiftData `@Model`) is persistence machinery. If a "models" module imports SwiftData, every consumer inherits that import.
2. **Peers export protocols, the composition layer owns the concrete graph.** `NetworkClientProtocol` and `AudioEngineProtocol` are the public API; the composition root (Chapter 9) is the only place concrete types meet.

### The Payoff for AI Work

Modularization is usually sold on build times. For AI-assisted development the bigger payoff is **context bounding**: "fix the retry logic in `MusicNetworking`" now ships the AI a target with three files and one protocol surface, not the whole app. The module boundary *is* the context window boundary — and access control (`internal` by default, `public` on the contract) means the AI physically cannot generate a call to something it shouldn't touch, because the compiler will reject it.

### The Prompt That Prevents the Cycle

> *"Split this app into SwiftPM targets. Draw the dependency graph BEFORE writing `Package.swift`, as a list of `target → dependencies`. Rules: (1) value types in a leaf `Models` target with zero dependencies; (2) networking, persistence, and audio are peers that depend only on `Models` — never on each other; (3) any logic needing two peers lives in a repository in the app layer; (4) mark everything `internal` except the protocol each target exports. If you find yourself wanting a peer-to-peer import, stop and tell me instead."*

The last sentence matters: it converts the AI's silent workaround (a cycle, a re-declared type, a copy-pasted DTO) into a surfaced design question — which is exactly what a senior engineer on your team would do.
