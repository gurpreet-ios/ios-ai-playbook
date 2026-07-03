---
title: "Chapter 13: iOS System Integration"
---

> "An app that only exists when it is open on the screen is not an iOS app. It is a web page."

Modern iOS development requires deep integration with the operating system. Users expect your app to surface data on their Lock Screen, update them dynamically via the Dynamic Island, and sync silently in the background.

AI struggles with system integration because it requires orchestrating multiple targets (e.g., the Main App and a Widget Extension) and sharing data across deeply isolated process boundaries.

---

## 1. Widgets & App Extensions

### Definition
Home Screen and Lock Screen widgets written in SwiftUI using the `WidgetKit` framework. 

### The Architecture Challenge
Widgets run in a completely separate process from your main app. If your AI generates a widget that tries to read from a standard `UserDefaults.standard` or an in-memory Singleton, it will fail silently.

### AI Prompting Strategy
You must explicitly command the AI to cross the process boundary using App Groups.
* **Senior Prompt:** "Generate a `Widget` using `WidgetKit`. **CRITICAL:** Do not use standard UserDefaults. You must read the widget data from the shared App Group container `group.com.company.app`. Read the data from a shared JSON file written to that group's FileManager directory."

---

## 2. Live Activities & Dynamic Island

### Definition
Real-time, glanceable updates on the Lock Screen and Dynamic Island using `ActivityKit`.

### Tradeoffs
- **Pros:** Incredible user engagement for time-sensitive events (Uber rides, sports scores).
- **Cons:** Extremely strict payload size limits (4KB) and update frequency limits.

### AI Prompting Strategy
* **Senior Prompt:** "Implement a Live Activity for a 'Delivery Tracker'. Define the `ActivityAttributes`. Ensure the Dynamic Island views (expanded, compact leading, compact trailing, and minimal) all use highly constrained layouts. Do not use complex imagery that exceeds the 4KB payload limit."

---

## 3. Push Notifications & Deep Links

### Definition
Waking the app up remotely (`UNUserNotificationCenter`) and routing the user to a specific screen based on a URL scheme or Universal Link.

### AI Prompting Strategy
The AI is very good at parsing JSON payloads, but bad at injecting that payload into your View hierarchy. 
* **Senior Prompt:** "Write the `UNUserNotificationCenterDelegate` to handle incoming push notifications. When the user taps the notification, extract the `order_id` from the `userInfo` dictionary. Pass this ID into our `AppRouter` class via deep link URL so the UI can navigate to the Order Details screen."

---

## 4. Background Tasks

### Definition
Executing code when the app is suspended (e.g., syncing a database at 3 AM) using `BGTaskScheduler`.

### AI Prompting Strategy
Background tasks have strict time limits (usually ~30 seconds) before the OS kills your app.
* **Senior Prompt:** "Implement a `BGAppRefreshTask`. You must wrap the execution logic in a `Task`. You MUST handle task expiration gracefully by listening to `task.expirationHandler` and canceling the ongoing network request immediately if triggered."

---

## 5. VisionOS (Spatial Computing)

### Definition
Developing for the Apple Vision Pro using `visionOS`. While it uses SwiftUI, the Z-axis (depth), Volumes, and Immersive Spaces completely alter the interaction paradigm.

### AI Prompting Strategy
LLMs trained before 2024 have very little knowledge of VisionOS. You must use RAG (Context Engineering) to feed them the latest Apple documentation.
* **Senior Prompt:** "We are building a visionOS app. Attached is the documentation for `ImmersiveSpace` and `RealityView`. Generate a SwiftUI view that opens an `ImmersiveSpace` and places a 3D `ModelEntity` at coordinate (0, 1.5, -2)."

---

---

## 6. The Running Example: MusicApp on the Lock Screen

> *Continuing the Part 3 spine ([`sample-apps/music-interview-app`](https://github.com/gurpreet-ios/ios-ai-playbook/tree/main/sample-apps/music-interview-app)). The app plays music; now it has to exist while closed — a Now Playing widget and a Live Activity. One note on scope: the sample repo is a plain SwiftPM package, and widget/Live Activity targets require an Xcode app project with extension targets and App Group entitlements. The code below is exactly what those targets contain — it's the process-boundary reasoning that this section is really about.*

### The Failure First: The Widget That Always Showed "Not Playing"

The naive prompt — *"Add a home-screen widget showing the currently playing track"* — produced a widget that imported the app module and did this:

```swift
// ❌ In the widget's TimelineProvider
func getTimeline(in context: Context, completion: …) {
    let track = PlayerViewModel.shared.currentTrack   // ← a *different* PlayerViewModel
    …
}
```

It compiled. It shipped. It rendered "Not Playing" forever. The widget runs in a **separate process**: its `PlayerViewModel.shared` is a fresh instance in fresh memory that has never played anything. No crash, no log, no error — the AI's mental model of "the app" as one address space fails *silently*, which is what makes this the most dangerous category in the chapter. (The same draft's fallback used `UserDefaults.standard` — also per-process sandbox, also silently empty.)

### The Fix: Treat the Widget Like a Remote Client

The only channel between the app and its extensions is the **App Group container**. MusicApp defines a snapshot value type — note it's a Codable struct, not the SwiftData `@Model`:

```swift
// In the shared target — visible to app AND widget
public struct NowPlayingSnapshot: Codable {
    public let title: String
    public let artist: String
    public let isPlaying: Bool
    public let updatedAt: Date

    static let fileURL = FileManager.default
        .containerURL(forSecurityApplicationGroupIdentifier: "group.com.example.musicapp")!
        .appending(path: "now-playing.json")
}
```

The app writes it at every playback transition — the natural hook is `PlayerViewModel`, which Chapter 9 made the single owner of playback state, so there is exactly one place to add this:

```swift
// In PlayerViewModel, after currentTrack/playbackState change
private func publishSnapshot() {
    let snapshot = NowPlayingSnapshot(title: currentTrack?.title ?? "",
                                      artist: currentTrack?.artist ?? "",
                                      isPlaying: isPlaying,
                                      updatedAt: .now)
    try? JSONEncoder().encode(snapshot).write(to: NowPlayingSnapshot.fileURL)
    WidgetCenter.shared.reloadTimelines(ofKind: "NowPlayingWidget")
}
```

And the widget *reads the file* — it never talks to live objects:

```swift
// ✅ In the widget's TimelineProvider
func timeline(for config: …) async -> Timeline<NowPlayingEntry> {
    let snapshot = (try? Data(contentsOf: NowPlayingSnapshot.fileURL))
        .flatMap { try? JSONDecoder().decode(NowPlayingSnapshot.self, from: $0) }
    let entry = NowPlayingEntry(snapshot: snapshot)   // nil → explicit "Nothing Playing" state
    return Timeline(entries: [entry], policy: .never) // app pushes reloads; don't poll
}
```

Three decisions worth calling out because the AI gets each wrong by default: the snapshot is a **DTO, not the `@Model`** (SwiftData models don't cross process boundaries any better than they cross actor boundaries — Chapter 12's rule again); the reload policy is `.never` **plus explicit `reloadTimelines`** (the app knows when playback changes; polling burns the widget's daily refresh budget); and `nil` decodes to a **designed empty state**, not a stale last snapshot.

### The Live Activity

Playback is exactly what `ActivityKit` is for — long-running, time-sensitive, glanceable:

```swift
public struct NowPlayingAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var title: String
        public var artist: String
        public var isPlaying: Bool
    }
}
```

`PlayerViewModel.play(track:in:)` requests the Activity if none is running and updates `ContentState` on every transition; `stop()` ends it. The same ownership argument applies: because playback state has one owner, the Live Activity has one update site — if your Activity updates are scattered across five call sites, that's Chapter 9's massive-ViewModel smell resurfacing at the system boundary. Keep `ContentState` to strings and flags: the payload budget is 4KB, so album art travels as an App Group file URL rendered by the extension, never as encoded image data.

### The Prompt That Prevents the Silent Failure

> *"Add a Now Playing widget to MusicApp. CRITICAL — the widget is a separate PROCESS: (1) it must not reference `PlayerViewModel`, `AudioEngine`, or any live app object; (2) all shared data flows through a `Codable` snapshot struct in the App Group container `group.com.example.musicapp` — define the struct first; (3) the app writes the snapshot and calls `WidgetCenter.reloadTimelines` at every playback transition; the widget only reads; (4) a missing/undecodable snapshot renders a designed 'Nothing Playing' state, never a crash or a stale entry. List every assumption you're making about data freshness."*

(Generalized: `prompts/architecture/widget-app-group.md`.)

---

By mastering these system integrations, you elevate your app from a basic utility to a first-class citizen in the Apple ecosystem. The prompts in this chapter are the pattern: name the process boundary explicitly, and the AI stops generating code that only works inside a single target.
