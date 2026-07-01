# Chapter 16: Debugging Cookbook

> "Do not paste stack traces into the AI and pray. Form a hypothesis first."

Pasting a 500-line crash log into an LLM with the prompt "fix this" is a Junior move. It often leads the AI down a rabbit hole of hallucinating incorrect dependencies. 

A Senior AI Engineer uses the AI as a sparring partner to test hypotheses. Below is a cookbook for tackling the most common bugs you will encounter, modeled around the scientific method: **Hypothesis → Investigation → Prompt → Fix → Regression**.

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

By forming a hypothesis *before* you prompt the AI, you bound the AI's search space. You force it to look for the specific needle in the haystack, rather than asking it to rewrite the entire haystack.
