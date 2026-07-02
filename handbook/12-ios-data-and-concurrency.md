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
