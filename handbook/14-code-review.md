# Chapter 14: Code Review in the AI Era

> "Reviewing code is no longer about finding syntax errors; the compiler and the AI do that. It is about enforcing intent, security, and scale."

With the rise of AI generation, the volume of code submitted in Pull Requests has exploded. A Junior engineer using an AI agent can generate a 2,000-line PR in a day. If you review this code the way you reviewed human-written code in 2020 (line-by-line, looking for typos), you will drown.

Reviewing AI-generated code also requires a different mental model. Humans usually make *localized* mistakes (a typo, a missed edge case). AI makes *systemic* mistakes — it will confidently invent an entirely new dependency injection framework if it thinks it will solve the problem.

Code review must therefore evolve on two axes: you need to know the **failure modes unique to AI code**, and you need a **tiered auditing process** to handle the volume.

---

## Part A: The AI Failure Modes

### 1. The Common Hallucinations

AI models are probabilistic prediction engines. If they lack context, they will guess.

**What to look for:**
- **Phantom APIs:** The AI uses a method that doesn't exist in the current version of the SDK (e.g., using iOS 17 features when your target is iOS 15).
- **Made-up Dependencies:** The AI assumes you have `Alamofire` or `RxSwift` installed and writes code using their syntax.
- **Lost Context Variables:** The AI references a variable it deleted three steps ago in the prompt chain.

**How to review:**
*Always run a strict compiler build before you even look at the diff.* If it compiles, the phantom APIs are ruled out.

### 2. Over-Abstraction

Humans get tired. AI does not. If you ask an AI to "build a generic networking layer," it might generate 14 protocols, 6 wrapper classes, and a custom type-erased enum just to make a single GET request.

**What to look for:**
- Interfaces that only have one implementation.
- Generics with 3+ constrained types for simple data fetching.

**How to review:**
Ask yourself: *"Would a senior engineer at my company actually write this by hand?"* If the answer is no, reject the code and prompt the AI to simplify: *"Remove the generics. Hardcode this for the `User` model only. We do not need this level of abstraction yet."*

### 3. Architecture Drift

This is the most dangerous flaw. Because AI models are trained on the internet, they default to the "average" internet solution (which is usually a Massive View Controller or a tightly coupled singleton).

**What to look for:**
- A SwiftUI View that suddenly contains database write logic.
- A ViewModel that imports `UIKit`.
- State that is managed via `UserDefaults` instead of your established store.

**How to review:**
Do not manually fix this. If you manually fix architecture drift, you become the junior developer cleaning up after the AI. Instead, use a Context Anchor: *"You drifted from our architecture. Review `adrs/004-state-management.md` and rewrite this file to comply."*

### 4. Unused States & "Dead Code"

AI is hesitant to delete code unless explicitly told to. During iterative generation, it will often leave behind obsolete `@State` properties or old helper functions.

**What to look for:**
- Variables that are declared and mutated but never read.
- View modifiers that cancel each other out.

**How to review:**
Use an LLM to review the LLM.
> *"Act as a merciless code reviewer. Analyze this file and highlight any variables, states, or functions that are completely unused or redundant."*

(Full residue sweep: `prompts/review/dead-code-audit.md`.)

### 5. The "Happy Path" Bias

AI writes the perfect code for the perfect scenario. It rarely considers what happens when the user goes into a tunnel on a 3G connection while the database is locked.

**What to look for:**
- Empty `catch` blocks (`catch { print(error) }`).
- Missing loading states in the UI.
- No timeout handling on network calls.

**How to review:**
Force the adversarial mindset.
> *"I am reviewing this code. Assume the network takes 15 seconds to respond, and the user hits the 'Save' button 4 times rapidly. How does this code break? Fix it."*

---

## Part B: The Tiered Review Process

Knowing the failure modes tells you *what* to look for. The tiers tell you *who* looks for it, and *when*.

### 1. The Senior Review

The Senior Review assumes the code compiles and solves the basic Jira ticket. The goal here is maintainability and architecture.

**The Checklist**
- **Architecture Drift:** Does this code invent a new pattern, or does it follow our established ADRs? (e.g., *Did they use MVC when we agreed on MVVM?*)
- **Test Coverage:** Are the edge cases tested? AI is notorious for only testing the "happy path."
- **Dependency Inversion:** Is the business logic tightly coupled to the UI framework or the database?
- **State Management:** Is state centralized, or is it scattered across multiple singletons and views? (Anchor: `adrs/004-state-management.md`.)

### 2. The Principal / Staff Review

The Principal Review does not look at variable names. It looks at the system boundaries and the 12-month horizon.

**The Checklist**
- **Module Boundaries:** Does this PR increase cross-module coupling? Should this logic be extracted into a shared library?
- **API Contracts:** Are we exposing more data than the client needs? Are the API models strictly separated from the Domain models?
- **Observability:** If this feature fails in production, do we have enough telemetry and logging to know *why*?
- **Backward Compatibility:** Does this database migration or API change break older versions of the app?

### 3. The Specialized Audits

Do not try to do a Security review and a Performance review at the same time. You will miss things. You must do specialized passes (often automated via Prompt Systems).

**Security Review**
- **Input Validation:** Is all user input treated as malicious?
- **Authentication:** Are tokens stored securely (e.g., Keychain, not UserDefaults)?
- **IDOR (Insecure Direct Object Reference):** Can a user modify a resource they don't own just by changing an ID in the payload?

**Performance Review**
- **Algorithmic Complexity:** Is there an accidental O(N^2) loop hiding in a map/filter chain?
- **Memory Management:** Are there strong reference cycles in closures?
- **Main Thread Blocking:** Is heavy I/O or JSON parsing happening on the UI thread?

**Accessibility Review**
- **Semantic Structure:** Are heading levels correct?
- **VoiceOver:** Do UI elements have descriptive accessibility labels and traits?
- **Dynamic Type:** Does the UI scale correctly if the user increases the system font size by 200%?

---

## Automating the Tiers

You cannot manually run a 50-point checklist on a 2,000-line AI-generated PR. You must use AI to review AI.

As covered in Chapter 5, you should have dedicated Prompts for each of these audits. You feed the PR diff into the `security-owasp-audit.md` prompt, then the `swift-concurrency-audit.md` prompt. You let the AI flag the low-level violations, so you can focus on the Staff-level architectural decisions.

By shifting your focus from syntax errors to architectural integrity, you can safely shepherd massive volumes of AI-generated code into production without sacrificing stability.

---

## The Running Example: Reviewing a Real AI PR Against the ADRs

> *Continuing the Part 3 spine ([`sample-apps/music-interview-app`](../sample-apps/music-interview-app)). Theory above; now an actual review. The PR below is what a capable agent produced for "add a Recently Played section to the Library screen" — it compiles, it works in the simulator, and it should not merge.*

### The Diff (condensed)

```diff
+ // Sources/Services/RecentlyPlayedManager.swift
+ import Combine
+
+ final class RecentlyPlayedManager: ObservableObject {
+     static let shared = RecentlyPlayedManager()
+     @Published var recentTrackIDs: [UUID] = []
+
+     private init() {
+         let raw = UserDefaults.standard.stringArray(forKey: "recentlyPlayed") ?? []
+         recentTrackIDs = raw.compactMap(UUID.init)
+     }
+
+     func markPlayed(_ id: UUID) {
+         recentTrackIDs.removeAll { $0 == id }
+         recentTrackIDs.insert(id, at: 0)
+         UserDefaults.standard.set(recentTrackIDs.map(\.uuidString),
+                                   forKey: "recentlyPlayed")
+     }
+ }
```
```diff
  // Sources/ViewModels/PlayerViewModel.swift
  public func play(track: Track, in queue: [Track] = []) async {
      currentTrack = track
+     RecentlyPlayedManager.shared.markPlayed(track.id)
      self.queue = queue.isEmpty ? [track] : queue
      await audioEngine.play(url: track.offlineFileURL ?? track.streamURL)
  }
```
```diff
  // Sources/Views/LibraryView.swift
+ @StateObject private var recents = RecentlyPlayedManager.shared
+ // …
+ Section("Recently Played") {
+     ForEach(recents.recentTrackIDs, id: \.self) { id in
+         if let track = try? modelContext.fetch(
+             FetchDescriptor<Track>(predicate: #Predicate { $0.id == id })
+         ).first {
+             TrackRow(track: track)
+         }
+     }
+ }
```

### The Review, Tier by Tier

**Compiler pass:** green. Phantom APIs ruled out. This is precisely the PR that survives a lazy review — every remaining defect is architectural.

**Senior pass — the diff against the ADRs:**

1. **`ObservableObject` + `@Published` + Combine** — direct violation of `adrs/002-observation-over-combine.md`. This is *training-data gravity* (the Chapter 12 failure mode): the model reverted to the pattern it has seen most, not the one the repo mandates.
2. **`UserDefaults` as a store** — violates the state rules (`adrs/004-state-management.md`) and bypasses `adrs/001-swiftdata-over-coredata.md`. Recently-played is *queryable domain data* (it references `Track` rows); it belongs in SwiftData — a `lastPlayedAt: Date?` attribute on `Track` makes the whole feature one sorted `FetchDescriptor`. The AI invented a second, unsynchronized source of truth instead.
3. **`static let shared` singleton, reached from inside `PlayerViewModel`** — a hidden dependency wired around the composition root (Chapter 9). Untestable and invisible to anyone reading `PlayerViewModel`'s initializer.
4. **Database fetch inside `LibraryView.body`** — a synchronous `modelContext.fetch` *per row per render*: architecture drift (data access belongs in `TrackRepository`) and a Chapter 15 performance bug in embryo. Also note `try?` — a swallowed error, the happy-path bias in one character.

**The meta-observation:** this one small PR exhibits four of the five failure modes from Part A. That density is normal for AI-generated code. It is also why the tiers exist: no line-by-line reading catches "this entire file shouldn't exist."

### The Anchor Prompt, Not the Manual Fix

Fixing this by hand makes you the AI's junior. The review comment goes back into the loop instead:

> *"This PR violates our ADRs. Re-read `adrs/001-swiftdata-over-coredata.md`, `adrs/002-observation-over-combine.md`, and `adrs/004-state-management.md`, then rewrite: (1) delete `RecentlyPlayedManager` entirely; (2) add `lastPlayedAt: Date?` to the `Track` @Model; (3) `TrackRepository` gains `markPlayed(id:)` that stamps it and saves; (4) `PlayerViewModel.play` calls the repository it already owns — no singletons; (5) `LibraryView` gets recents from `LibraryViewModel`, backed by a `FetchDescriptor` sorted by `lastPlayedAt` — no fetches in view bodies. Keep the diff under 60 lines."*

The rewrite came back at 41 lines, four files, zero new types — deletion as a review outcome. The measure of AI-era review is not "did we find the bugs" but "did the codebase's rules, written down where the AI must read them, make the second attempt smaller than the first."

This whole review is a repeatable system: `prompts/review/adr-drift-audit.md` runs the ADR diff, and `prompts/documentation/pr-description-generator.md` writes the PR body both humans and review agents read first.
