# Mock Interview: Debounced Search

## 1. The Prompt
**Interviewer:** "Build a search screen: a text field that queries a REST API as the user types. Don't hammer the API on every keystroke, and make sure the results shown always match what's in the field. Drive the LLM."

## 2. Expected Reasoning
The word "debounce" never appears in the prompt — noticing that it's needed *is* the test. Three layered problems:
1. **Debouncing** — wait for the user to pause before firing.
2. **Cancellation** — a new keystroke must cancel the in-flight request, not just ignore it.
3. **Out-of-order responses** — the query for "sw" can return *after* the query for "swift"; if you naively assign results, the UI shows stale data. This is the part most candidates miss.

## 3. The Poor Answer
> *"On every keystroke I'll fire the API call and update `results`. To avoid hammering the API I'll add a `DispatchQueue.asyncAfter` with 0.3 seconds before firing. If results come back out of order… I guess that's rare."*

**Why it's poor:** `asyncAfter` delays but doesn't *cancel* — type 10 characters and 10 requests still fire, just later. And out-of-order responses aren't rare; they're guaranteed on real networks, because a short query hits a bigger index and can take longer than the more specific query typed after it.

## 4. The Great Answer
> *"Structured concurrency gives us all three properties from one mechanism: task cancellation.
>
> In SwiftUI I'd hang the work off `.task(id: query)` — when `query` changes, SwiftUI cancels the previous task and starts a new one. Inside the task: `try await Task.sleep(for: .milliseconds(300))` first. If the user keeps typing, the task is cancelled *during the sleep* and the request never fires — that's the debounce. If the sleep completes, fire the request.
>
> Cancellation also solves out-of-order responses: the task for 'sw' is cancelled the moment 'swi' is typed, and `URLSession`'s async API checks cancellation, throwing `CancellationError` instead of delivering stale results. As a belt-and-braces guard, I'd still verify the response's query matches the current field before assigning — it makes the invariant explicit and testable."*

## 5. Driving the LLM

> **Plan:** "Search-as-you-type against a REST API in SwiftUI. Requirements: debounce ~300ms, cancel in-flight requests on new input, and stale responses must never overwrite fresher results. Before code: explain how `.task(id:)` + `Task.sleep` gives us debounce and cancellation in one mechanism, and where `CancellationError` needs handling. No code yet."

> **Generate:** "Implement `SearchViewModel` (`@MainActor @Observable`): `var query: String`, `var results: [SearchResult]`, `var phase: Phase` (idle/searching/loaded/failed). The View uses `.task(id: viewModel.query)`. Catch `CancellationError` separately and do NOT surface it as a user-facing error."

> **Review hook:** "Trace this sequence for me: user types 'sw', pauses 400ms, types 'ift', response for 'sw' arrives now. Show exactly which line prevents the 'sw' results from rendering."

> **Test:** "Swift Testing: inject a mock client whose response delay is controllable. Prove (1) rapid keystrokes yield exactly one request, (2) a slow 'sw' response never overwrites 'swift' results."

**What you're watching for:** `DispatchWorkItem`-era debounce bolted onto async code, `catch { errorMessage = ... }` blocks that turn every cancellation into a red error banner, and tests that sleep real milliseconds instead of controlling the clock.

## 6. The Follow-Up (Mid-Interview Extension)
**Interviewer:** "Extend it: results should page as the user scrolls, and the search should work offline against recently cached results. Keep the existing behavior intact."

## 7. The Ideal Discussion
> *"Pagination and debounced search interact badly if you're not careful: a page-2 fetch must attach to the *query it belongs to*. I'd make the task identity a struct — `.task(id: SearchRequest(query:page:))` — so changing the query cancels pending page loads too, and I'd never append page results whose query doesn't match the current one.
>
> For offline, the cache slots in at the repository layer, keyed by normalized query: serve cached results immediately (marked as such in the UI), then let the network response replace them — stale-while-revalidate. The ViewModel doesn't change; that's the payoff of keeping the transport behind a protocol from step one.
>
> The subtle regression risk in this extension is the loading state: with cached results on screen, 'searching' must not blank the list. That's why `phase` was modeled as an enum from the start — I'd add a `.refreshing(cached:)` case rather than a second boolean."*
