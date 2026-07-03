---
title: "Chapter 34: On-Device AI & App Intents"
---

> "Every other chapter in this book is about using AI to build the app. This one is about the app itself becoming a citizen of an AI-native operating system."

Two Apple platform surfaces define what "AI-native iOS app" means, and both are underbuilt in the wild: **on-device models** (the Foundation Models framework and Core ML) that put inference inside your process with zero marginal cost and zero data egress, and **App Intents** — which quietly became the most strategically important framework on the platform, because it is how Siri, Apple Intelligence, Shortcuts, Spotlight, and widgets *call your app as a tool*. If Chapter 21 taught you MCP — how your IDE's model calls tools — App Intents is the same idea pointed at your users: your app's verbs, published as a schema the system's AI can invoke.

## 1. The Decision Framework: On-Device vs. Server

Before either API, the architecture question. On-device inference wins when:

- **Privacy is the feature** — the data never leaves the device, the Chapter 32 manifest entry never exists.
- **Marginal cost matters** — summarizing every notification through a server LLM is a cloud bill; on-device it's battery you already budgeted.
- **Offline is required** — the Chapter 9–16 spine app plays downloads in airplane mode; its intelligence should work there too.
- **Latency is interactive** — no round trip beats a fast round trip.

The server model wins on raw capability, long context, and knowledge freshness. The senior design is a **tiered fallback**: on-device for the common case, server for the hard case, and an explicit capability check deciding — never an assumption that the model is present (older devices, Apple Intelligence disabled, model still downloading):

```swift
switch SystemLanguageModel.default.availability {
case .available:                    // on-device path
case .unavailable(let reason):      // designed fallback, not a blank screen
}
```

That `.unavailable` arm is this chapter's version of the empty-state rule: the AI feature must degrade into a non-AI feature, not into an apology.

## 2. The Foundation Models Framework

Since iOS 26, the OS ships an on-device LLM your app calls directly — no API key, no per-token bill, no payload leaving the device. It is a small model (a few billion parameters): built for summarization, extraction, classification, and short structured generation — not for open-ended chat expertise. Design for what it is.

The API's defining feature is **guided generation**: instead of parsing free text and praying, you declare a Swift type and the framework constrains decoding to produce it:

```swift
import FoundationModels

@Generable
struct PlaylistSuggestion {
    @Guide(description: "A short, evocative playlist name — no emoji")
    var name: String
    @Guide(description: "Track IDs from the provided library, most fitting first",
           .count(5...20))
    var trackIDs: [String]
}

let session = LanguageModelSession(instructions: """
    You name playlists for a music app. You only reference tracks \
    from the library the user provides.
    """)
let suggestion = try await session.respond(
    to: "A rainy-evening playlist from: \(libraryDigest)",
    generating: PlaylistSuggestion.self
).content
```

No JSON parsing, no regex, no "the model wrapped it in markdown" failure class — the type *is* the contract. Everything this book taught about prompting LLMs applies to the one in your process: the `instructions` are a rules file, the `@Guide` descriptions are constraints, and the eval discipline from Chapter 30 is how you verify it (a pinned input set scored in CI — `#expect(suggestion.trackIDs.allSatisfy(library.contains))` is a real assertion against a probabilistic feature).

The framework also supports **tool calling** — you expose Swift functions (conforming to `Tool`) and the on-device model decides when to invoke them, exactly the Chapter 21 loop with your app as the tool host. Which raises the question: what should an iOS app's tools *be*? Apple already answered it.

## 3. App Intents: Your App's Tool Schema

An `AppIntent` is a verb your app publishes to the operating system:

```swift
struct PlayDownloadsIntent: AppIntent {
    static let title: LocalizedStringResource = "Play My Downloads"
    static let description = IntentDescription(
        "Plays your downloaded tracks, newest first — works offline.")

    @Dependency var player: PlayerViewModel   // AppDependencyManager-registered

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let downloads = try await player.queueDownloads()
        guard !downloads.isEmpty else {
            return .result(dialog: "You haven't downloaded any tracks yet.")
        }
        return .result(dialog: "Playing \(downloads.count) downloaded tracks.")
    }
}
```

One declaration and the verb exists in Shortcuts, Spotlight, widgets' interactive buttons, Action Button configuration — and, through Apple Intelligence's assistant schemas, in Siri's model-driven planning. The strategic read: **the system LLM decides which app satisfies a user's request by reading intent metadata.** Apps with rich, well-described intents are *callable*; apps without them are opaque icons. This is app discoverability rewritten as tool-schema quality — the same skill as writing a good MCP tool description, aimed at the OS.

Design rules (the AI will violate each unprompted):

- **Intents call the same seams as your UI** — `PlayDownloadsIntent` goes through `PlayerViewModel`, not a parallel playback path that drifts (Chapter 9's ownership rule, again). If your composition root is clean, intents are ten lines each; if intents are hard to write, that's an architecture smell report.
- **Entities and queries, not just verbs** — expose `TrackEntity` with an `EntityQuery` so "play *Karma Police*" can resolve a parameter against your library. Parameters make intents composable; composable intents make your app scriptable by the system's AI.
- **Descriptions are prompts.** The `IntentDescription` is read by a model deciding whether to call you. Write it like a tool description from Chapter 21: what it does, when to use it, what it needs.

(Scaffold the whole surface with `prompts/architecture/app-intents-surface.md`.)

## 4. Core ML: When You Bring Your Own Model

The Foundation Models framework covers language tasks; **Core ML** covers everything else — audio classification for MusicApp's "hum to search," vision, embeddings for on-device semantic search, or a fine-tuned small model that outperforms the general one on your niche. The workflow AI accelerates: convert (PyTorch → `coremltools`, quantize to fit the memory budget you set in Chapter 33), validate numerically against the source model, then wrap it in an actor with the same protocol discipline as any engine:

> *"Wrap `MelodyClassifier.mlmodelc` in a `MelodyClassifierEngine` actor behind a protocol: load lazily on first use (compiled model load is not free — never in `App.init`, per the watchdog budget), run predictions off the main actor, return a `Sendable` result struct. Include the model version in every result for telemetry segmentation."*

The performance chapters apply unchanged: model loads show up in launch budgets, inference shows up in hitch metrics, and the Chapter 15 rule — measure on the mid-range device, not the demo unit — is doubly true for ML workloads.

## 5. The Convergence

Put the pieces together and the shape of the AI-native iOS app appears:

- Its **verbs are App Intents** — callable by users, Shortcuts, and the system's models alike, backed by the same ViewModels the UI uses.
- Its **intelligence is tiered** — on-device Foundation Models for private, free, offline inference; server models behind a flag (Chapter 31) for the heavy cases; a designed fallback when neither is available.
- Its **AI features are verified like AI output** — evals in CI, budgets in MetricKit, the same skepticism this book applies to generated code applied to generated content.

The engineer who ships this is using both halves of the playbook at once: agents building the app (Chapters 1–30), and the app itself joining the agent ecosystem it was built by. That convergence — not any single API — is the actual frontier.
