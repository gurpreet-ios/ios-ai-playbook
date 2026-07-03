# The data race Swift 6 refused to compile

**Subtitle:** Your AI pair programmer learned concurrency from a decade of pre-Swift-6 code. Its reflexes are iOS 14. Here's the race it keeps writing, the compiler errors that catch it — and the one "fix" you must never let it apply.

---

AI models are trained on historical code. For Swift, that history is overwhelmingly pre-strict-concurrency: closure-based `URLSession` callbacks, `DispatchQueue.global()`, mutable state shared on vibes. So when an AI generates concurrency code, its default behavior is to reach for patterns it has seen ten thousand times — patterns that Swift 6 now rejects at compile time.

This is actually the best news in AI-assisted iOS development: **the compiler is the one reviewer that never gets tired.** But only if you read its diagnostics correctly, and only if you forbid the escape hatch the AI will offer you. Let me show you both, with real code from a real feature.

## The feature: offline downloads

From the sample app in my playbook — a music app where "downloaded tracks play offline." That one sentence is a sync engine: fetch metadata, persist it in SwiftData, download the audio file, record its local URL on the persisted row, prefer that URL at playback. It crosses network, disk, model, and UI — which is exactly where AI-generated concurrency goes to die.

The working architecture splits the engine across three isolation domains, each chosen deliberately:

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

Note the shape: the *slow thing* (`downloadTrackFile`) happens inside the network actor and returns a `Sendable` value (a `URL`). The *mutable thing* (`track`) never leaves the main actor. **Values cross isolation boundaries; models don't.** That sentence is most of Swift 6 concurrency.

## The AI's "optimization"

Ask an AI to review that code for performance, and there's a decent chance it produces this — a pattern burned into it by years of pre-Swift-6 training data:

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

Under Swift 5, this compiles, ships, and corrupts state *intermittently*: a background thread mutates a model object the UI is simultaneously reading, and a main-actor-bound `ModelContext` gets touched off its actor. The crash reports are unreproducible. The bug review is miserable.

Under Swift 6 strict concurrency, it simply does not build:

```text
error: capture of 'track' with non-Sendable type 'Track' in a '@Sendable' closure
error: main actor-isolated property 'modelContext' can not be referenced
       from a Sendable closure
```

Here's the part that matters: **read those diagnostics as the compiler telling you the design is wrong — not that annotations are missing.** The download already ran on the network actor. Detaching the model write bought nothing but the race.

## The trap inside the trap

This is where the classic AI failure loop begins. Paste those errors back into the chat, and the model will offer its favorite fix:

> "Add `@unchecked Sendable` to `Track`."

That deletes the diagnostic *while keeping the race.* You've silenced the one reviewer that never gets tired, and shipped the Swift 5 bug with a Swift 6 compiler.

House rule worth stealing: **any AI-added `@unchecked Sendable` or `nonisolated(unsafe)` is a review-blocking waiver.** Not "look closer" — blocking. There are legitimate uses (the sample app's `Track` carries one to satisfy a protocol requirement, and it's safe *only because* every mutation site is main-actor-confined) — but that's a human judgment call recorded in an ADR, never an autocomplete.

## The Swift 6.2 twist: the setting the AI cannot see

Swift 6.2's "approachable concurrency" added a per-module default-isolation setting — `.defaultIsolation(MainActor.self)` in the package manifest makes everything in the module implicitly `@MainActor` unless it opts out.

This matters enormously for prompting, because the correct annotations for a file now depend on **a build setting that exists outside the code the AI is reading.** Always tell it which world it's in:

- Default-isolated module: *"This module builds with default MainActor isolation. Do not sprinkle `@MainActor` everywhere — only annotate what must run OFF the main actor (`nonisolated`, or a dedicated `actor`)."*
- Classic Swift 6 module: the opposite instruction.

An AI that guesses wrong produces code that is either noisy or doesn't compile. It will guess wrong roughly half the time, because it cannot see your manifest.

## The prompt that prevents all of it

Here's the shape of the prompt that gets the working version on the first try:

> "Implement `downloadTrack(id:)` in `TrackRepository` (`@MainActor`, Swift 6 strict concurrency). Rules: (1) file I/O and networking run inside `NetworkClient` (an actor) and return `Sendable` values only; (2) `Track` is a SwiftData `@Model` — it must never be captured by a detached task or sent across an isolation boundary; (3) all `ModelContext` access stays on the main actor; (4) if the compiler reports a Sendable violation, treat it as a design error — do NOT add `@unchecked Sendable` or `nonisolated(unsafe)` anywhere. Build with strict concurrency before presenting the diff."

Four rules. The first three encode the isolation design; the fourth forbids the escape hatch. Swift 6 turns an entire class of AI-generated production crashes into build failures — your job in the prompt is to make sure they stay failures until the *design* is fixed.

---

*The full walkthrough — including when to escalate from main-actor confinement to a `@ModelActor`, and the code-review playbook for AI-added concurrency waivers — is in my open-source playbook, free on GitHub: [github.com/gurpreet-ios/ios-ai-playbook](https://github.com/gurpreet-ios/ios-ai-playbook). The sample app with this exact code compiles and passes its tests in CI.*

*Last week: [The same feature, four prompts](LINK-TO-POST-1). Next week: the tests AI writes that can never fail — and the two-minute audit that deletes them. Subscribe below.*

---
---

## Publishing notes (strip before posting)

- **Substack title:** The data race Swift 6 refused to compile
- **Subtitle options:** the one above, or shorter: "Your AI pair programmer's concurrency reflexes are from iOS 14."
- **Cross-post targets:** r/iOSProgramming and r/swift (both love strict-concurrency war stories), X thread (the ❌ code block + the two compiler errors is the hook tweet), HN has decent odds with title "The data race Swift 6 refused to compile" — concrete, no listicle smell.
- **Source:** [handbook/12-ios-data-and-concurrency.md](../handbook/12-ios-data-and-concurrency.md) §3 and §6 (the running example), plus the Swift 6.2 default-isolation note. Working code lives in [sample-apps/music-interview-app](../sample-apps/music-interview-app/).
- **Before posting:** replace `LINK-TO-POST-1` with the published URL of post 001; verify the sample-app CI badge is green that day (the post claims it compiles and passes tests — a reader will check).
- **CTA mechanics:** subscribe button after the footer; consider pinning the repo link as a comment.
