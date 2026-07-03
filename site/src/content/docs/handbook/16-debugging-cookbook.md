---
title: "Chapter 16: Debugging Cookbook"
---

> "Do not paste stack traces into the AI and pray. Form a hypothesis first."

Pasting a 500-line crash log into an LLM with the prompt "fix this" is a Junior move. It often leads the AI down a rabbit hole of hallucinating incorrect dependencies. 

A Senior AI Engineer uses the AI as a sparring partner to test hypotheses. Below is a cookbook for tackling the most common bugs you will encounter, modeled around the scientific method: **Hypothesis → Investigation → Prompt → Fix → Regression**.

The method is packaged as standing prompts: `prompts/debugging/codebase-mapping.md` (build the map before reading files — essential in unfamiliar code), `prompts/debugging/hypothesis-first-debug.md` (ranked hypotheses with the anti-sycophancy hook), and `prompts/discovery/legacy-code-archaeology.md` (when the codebase itself is the mystery).

---

## Bug 1: Unexplained Crash on Navigation (SwiftUI)

**Scenario:** User taps a `NavigationLink` and the app immediately crashes with an `EXC_BAD_ACCESS` or `index out of bounds`.

* **Hypothesis:** The state driving the destination view was mutated or destroyed before the view could render, or the `NavigationPath` was corrupted.
* **Investigation:** 
  - Add print statements to the `init()` and `deinit` of the destination ViewModel. 
  - Check if the array backing the List was mutated asynchronously.
* **LLM Prompt:** *"I am getting an `EXC_BAD_ACCESS` crash when navigating to `DetailView`. Attached is the `ListView` and `ListViewModel`. My hypothesis is that the `items` array is being mutated on a background thread while SwiftUI is trying to read it for the `NavigationLink`. Review the code to confirm or deny this hypothesis."*
* **Fix:** The AI confirms the array was mutated off the MainActor. Apply `@MainActor` to the ViewModel.
* **Regression:** Ask the AI: *"Write a unit test that concurrently modifies the `items` array to ensure our MainActor isolation prevents the crash."*

---

## Bug 2: "Stale Data" in Offline Cache (CoreData/SwiftData)

**Scenario:** User updates their profile on the web, opens the iOS app, and sees the old data despite the network call succeeding.

* **Hypothesis:** The network call fetched the new data, but it was written to a background database context that was never merged into the main UI context.
* **Investigation:**
  - Log the JSON payload (it's correct).
  - Log the database fetch (it returns the old data).
* **LLM Prompt:** *"Attached is `SyncManager.swift`. We fetch new JSON, but the UI doesn't update. My hypothesis is that we are inserting the new data into a `ModelContext` that isn't the `mainContext`, and the changes aren't propagating. Show me exactly how to ensure the background context saves and merges into the MainActor context."*
* **Fix:** AI provides the proper `ModelActor` implementation for background saving.
* **Regression:** *"Generate a UI test that taps 'Sync', waits 2 seconds, and asserts the Text label updates to the new value."*

---

## Bug 3: Intermittent API Timeouts (Networking)

**Scenario:** Network requests randomly timeout or fail with `-1001` error.

* **Hypothesis:** We are either not configuring the `URLSession` properly, or we are deadlocking a custom async queue, causing the request to never fire.
* **Investigation:** 
  - Proxy traffic through Charles or Proxyman. (The request never hits the wire).
* **LLM Prompt:** *"API calls are timing out. The requests are not hitting Charles Proxy. Attached is `NetworkClient.swift`. My hypothesis is that our custom `Actor` is deadlocking because we are waiting on a refresh token inside a `TaskGroup`. Audit the token refresh logic for deadlocks."*
* **Fix:** AI identifies a circular `await` where the token refresh waits for a queue that is blocked by the failed request.
* **Regression:** *"Write a test that mocks a 401 response and simulates 5 concurrent requests to ensure the token refresh resolves without deadlocking."*

---

## Bug 4: Jerky "Feed Lag" (UI Performance)

**Scenario:** The social feed stutters violently when scrolling.

* **Hypothesis:** We are performing heavy synchronous work (like date formatting or image decoding) inside the `body` of the SwiftUI cell.
* **Investigation:**
  - Run the Time Profiler in Instruments.
  - See `DateFormatter.string(from:)` taking 15ms per cell.
* **LLM Prompt:** *"Instruments shows that `DateFormatter` initialization inside `FeedCell.swift` is dropping frames. Refactor this code to use a static, pre-configured `DateFormatter` or the new iOS 15 `Date.FormatStyle` to remove the allocation cost from the view's render loop."*
* **Fix:** AI extracts the formatter to a global static let.
* **Regression:** *"Add a comment above the struct enforcing that no object allocations happen in this body."*

---

---

## The Running Example: A Real Crash in MusicApp, End to End

> *Continuing the Part 3 spine ([`sample-apps/music-interview-app`](https://github.com/gurpreet-ios/ios-ai-playbook/tree/main/sample-apps/music-interview-app)). Full disclosure: the bug below is not invented for the book — it shipped in this book's own sample app, generated by a capable model, and survived until someone ran the app. That is the point of this section.*

### The Symptom

Fresh install, launch, the Library tab starts loading — and the app dies instantly with a SwiftData fatal error:

```text
SwiftData/ModelContext.swift:…: Fatal error:
failed to find a currently active container for Track
```

The truncated stack: `ModelContext.insert` ← `TrackRepository.upsert` ← `fetchTracks` ← `LibraryViewModel.loadTracks`. Reproduces 100% of the time, which is the first diagnostic gift: this is not a race, it's a wiring error.

### Hypotheses Before Prompts

Per the cookbook rule, rank the suspects *before* touching the LLM. "No active container for `Track`" has three known causes:

1. **Schema registration** — `Track` missing from the `ModelContainer(for:)` list. *Check: 30 seconds.* The app's `init` clearly lists `Track.self, Playlist.self`. Eliminated.
2. **An orphaned `ModelContext`** — the context the repository holds is not attached to the container the app created. Consistent with "always crashes on first insert."
3. **Actor/threading** — an insert off the main context's actor. Possible, but everything on the path is `@MainActor`. Ranked last.

### The Investigation

One print in the composition root settles hypothesis 2:

```swift
print(ObjectIdentifier(container.mainContext.container),
      ObjectIdentifier(trackRepo.modelContext.container))  // 💥 different identities
```

The repository's context belongs to *no configured container*. Now find where it came from. The composition root, as originally generated:

```swift
// ❌ As the AI generated it
struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext   // looks idiomatic…

    init(networkClient: NetworkClient, audioEngine: AudioEngine) {
        let trackRepo = TrackRepository(networkClient: networkClient,
                                        modelContext: modelContext)   // …but read in init
        // …
    }
}
```

`@Environment` values are installed by SwiftUI *when the view joins the hierarchy* — inside `init`, the property wrapper hands back its **default value**, a context wired to nothing. The code compiles cleanly, reads exactly like a hundred tutorials, and is wrong in a way no static check flags. This is the signature AI failure of Chapter 14's taxonomy in crash form: the model pattern-matched the idiom (`@Environment(\.modelContext)`) without the semantic (*property wrappers are inert during `init`*).

### The Prompt

With the hypothesis confirmed, the LLM gets a bounded job, not a haystack:

> *"`AppRootView` reads `@Environment(\.modelContext)` inside `init` to construct `TrackRepository` — at that point the environment isn't installed, so the repository gets a container-less default context and the first insert dies with 'failed to find a currently active container'. Restructure the composition root so the context is passed explicitly: the `App` owns the `ModelContainer` and hands `container.mainContext` to `AppRootView.init`. Do not move repository construction into `body`, and do not create a second container. Add a comment explaining why the environment cannot be used here."*

### The Fix (Live in the Repo)

What ships in `Sources/App/MusicInterviewApp.swift` today:

```swift
@main
struct MusicInterviewApp: App {
    let container: ModelContainer
    // …
    var body: some Scene {
        WindowGroup {
            AppRootView(networkClient: networkClient,
                        audioEngine: audioEngine,
                        modelContext: container.mainContext)  // ✅ explicit
        }
        .modelContainer(container)
    }
}

/// The `ModelContext` is passed in explicitly: reading
/// `@Environment(\.modelContext)` inside an `init` returns a default,
/// container-less context, so the environment cannot be used here.
struct AppRootView: View { /* … */ }
```

The comment is part of the fix. It exists for the *next* AI session — which, prompted to "clean up" this file, would otherwise happily restore the idiomatic-looking environment read. Chapter 22's rules-file discipline is how a debugging session ends: the root cause becomes a written constraint.

### The Regression Guard

The repo's smoke suite (`Tests/TrackTests.swift`) constructs the real graph — in-memory container, repository, insert, fetch — so this class of wiring error now fails in `swift test`, not on a user's phone. The generalizable habit: **when a crash's root cause is "two objects that should share infrastructure didn't," the regression test constructs the actual object graph**, not mocks of it.

---

By forming a hypothesis *before* you prompt the AI, you bound the AI's search space. You force it to look for the specific needle in the haystack, rather than asking it to rewrite the entire haystack.
