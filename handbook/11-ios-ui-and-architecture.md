# Chapter 11: iOS UI and Architecture

> "SwiftUI is a state-driven framework. If you fight the state, you fight the framework. If your AI fights the state, it generates garbage."

When developing for iOS natively, the user interface layer has undergone a radical transformation from imperative (UIKit) to declarative (SwiftUI). 
For AI-native engineers, this shift is a massive advantage: LLMs are exceptionally good at writing declarative UI because the structure of the code perfectly mirrors the visual hierarchy.

---

## 1. SwiftUI

### Definition
Apple's modern, declarative framework for building user interfaces across all Apple platforms. It uses a struct-based hierarchy driven by data bindings.

### AI Prompting Strategy
When prompting an LLM to generate SwiftUI, you must enforce strict constraints to prevent it from hallucinating UIKit paradigms.
* **Bad Prompt:** "Build a settings screen."
* **Senior Prompt:** "Build a `SettingsView` in SwiftUI. Use `Form` and `Section` components. All state must be injected via `@Environment` or passed down as `@Binding`. Do NOT use `@State` internally unless the state is purely ephemeral (like a disclosure group's expanded state)."

### The Design-Language Trap
AI models default to the design language of their training data. Since iOS 26 the system look is **Liquid Glass** (`.glassEffect()`, `.buttonStyle(.glass)`); if you target it, say so explicitly, or the AI will hand you a faked frosted look built from `.ultraThinMaterial` and shadows. Chapter 27 covers the full aesthetic vocabulary.

### Tradeoffs
- **Pros:** Massively reduced boilerplate; AI can generate full screens with perfect preview fidelity in seconds.
- **Cons:** Complex view hierarchies can lead to massive recompilations if state isn't scoped correctly.

### Interview Answer
> *"I use SwiftUI for 95% of new development. Its declarative nature is perfect for rapid iteration and state-driven design. However, for ultra-complex text rendering or legacy integration, I still drop down to `UIViewRepresentable`."*

---

## 2. UIKit (Legacy Integration)

### Definition
Apple's original imperative UI framework. While largely superseded by SwiftUI for new views, it remains the foundation of iOS and is heavily present in legacy codebases.

### AI Prompting Strategy
When refactoring or interacting with UIKit, you must explicitly tell the AI about the memory management model (ARC).
* **Senior Prompt:** "Refactor this `UIViewController`. Extract the table view logic into a separate `UITableViewDataSource`. **CRITICAL:** Ensure all delegate references are `weak` to prevent retain cycles."
* **Full migration prompt:** `prompts/refactoring/legacy-to-modern-migration.md`.

### Tradeoffs
- **Pros:** Unparalleled control over the rendering pipeline; vast ecosystem of libraries.
- **Cons:** Highly imperative, prone to Massive View Controller anti-patterns, and difficult for AI to reason about due to dispersed lifecycle methods (`viewDidLoad`, `viewDidAppear`).

---

## 3. Navigation

### Definition
Moving the user between screens. In SwiftUI, this evolved from `NavigationView` (deprecated) to `NavigationStack` and `NavigationSplitView`.

### Architecture: The Router Pattern
Do not let the AI scatter `NavigationLink` throughout your views. Force it to use a Router.
* **Architecture Rules:** Define a `enum Route: Hashable` and use a state-driven `NavigationPath` inside a router class.

### AI Prompting Strategy
* **Senior Prompt:** "Implement navigation for this flow using iOS 16+ `NavigationStack` and `NavigationPath`. Create a `Router` class (Observable) that manages the path. The views should NOT contain any hardcoded `NavigationLink` destinations; they should only call `router.navigate(to:)`." (Full scaffold: `prompts/architecture/router-scaffold.md`; decision record: `adrs/007-navigation-router.md`.)

---

## 4. Animation

### Definition
Fluid transitions between state changes. Apple platforms pride themselves on butter-smooth 120Hz animations.

### AI Prompting Strategy
AI models often default to jarring, linear animations or forget them entirely. You must specify the animation curve.
* **Senior Prompt:** "Animate the appearance of this subview. Do not use `.linear`. Use `.spring(response: 0.4, dampingFraction: 0.7)` for a natural Apple-like bounce. Ensure the transition uses `.opacity.combined(with: .scale)`."

### Code Review Focus
When auditing AI-generated animations, watch for:
1. Animating the wrong state properties (causing the whole screen to redraw).
2. Forgetting to use `.transaction { $0.animation = nil }` when you explicitly *want* an instant update.

---

## 5. The Running Example: Building MusicApp's Now Playing Screen

> *Continuing the Part 3 spine ([`sample-apps/music-interview-app`](../sample-apps/music-interview-app)). Chapter 9 gave us `PlayerViewModel`; this chapter puts a screen on it — and catches the AI's favorite rendering mistake.*

### The Build

The screen is `Sources/Views/NowPlayingView.swift`: album art, title/artist, transport controls. The prompt that produced its skeleton leaned on the chapter's rules — declarative structure, injected state, no internal `@State` for anything that isn't ephemeral:

> *"Build `NowPlayingView` in SwiftUI. It takes a `PlayerViewModel` (an `@Observable` `@MainActor` class — do not wrap it in `@ObservedObject`, plain `var` is correct for iOS 17 Observation). Layout: square album art, track title + artist, previous/play-pause/next controls. Controls are disabled when `currentTrack == nil`. Every control gets an `accessibilityLabel`. Actions call the ViewModel's async methods inside `Task { }` — the view contains zero playback logic."*

The interesting part of the result is what it *doesn't* contain:

```swift
public struct NowPlayingView: View {
    var viewModel: PlayerViewModel     // plain var — Observation tracks reads

    public var body: some View {
        VStack(spacing: 40) {
            // …album art…
            Text(viewModel.currentTrack?.title ?? "Not Playing")
            // …
            Button {
                Task { await viewModel.togglePlayPause() }
            } label: {
                Image(systemName: viewModel.isPlaying
                    ? "pause.circle.fill" : "play.circle.fill")
            }
            .disabled(viewModel.currentTrack == nil)
        }
    }
}
```

No `@ObservedObject`, no `objectWillChange`, no closure callbacks. With the `@Observable` macro, SwiftUI records exactly which properties this `body` reads (`currentTrack`, `isPlaying`) and re-evaluates only when *those* change. `LibraryView` holds a different ViewModel and never reads playback state — so a play/pause toggle re-renders the player screen and nothing else. That is Observation-scoped state working as designed, and it's free *as long as you keep reads scoped*.

### The Failure: The 4Hz Screen

Then the obvious next feature: a progress bar. The AI's instinct is to put time on the ViewModel — publish `currentTime` from the audio engine a few times a second:

```swift
// In PlayerViewModel — the AI's first draft
public var currentTime: TimeInterval = 0   // updated 4×/sec from the engine
```

```swift
// In NowPlayingView.body
ProgressView(value: viewModel.currentTime,
             total: viewModel.currentTrack?.duration ?? 1)
Text(timeString(viewModel.currentTime))
```

It works. It also makes the **entire screen body re-evaluate four times per second** — Observation is property-scoped, but the *view* reading the property is the whole screen, so the album art, the shadow, the title stack, and three buttons all get rebuilt and re-diffed at 4Hz, forever, while the phone is warm in someone's pocket. Nothing is visibly wrong, which is exactly why AI-generated over-rendering survives review: the diff looks correct and the damage only shows in Instruments.

Confirm it in ten seconds — drop this in the body and watch the console tick:

```swift
let _ = Self._printChanges()   // logs every body re-evaluation and why
```

### The Fix: Shrink the View That Reads the Hot Property

The rule from the animation section applies to *all* state, not just animated state: **high-frequency state may only be read by the smallest view that can render it.**

```swift
struct PlaybackProgressBar: View {
    var viewModel: PlayerViewModel   // same object — different read scope

    var body: some View {
        ProgressView(value: viewModel.currentTime,
                     total: viewModel.currentTrack?.duration ?? 1)
    }
}
```

`NowPlayingView` embeds `PlaybackProgressBar()` but never reads `currentTime` itself — so the 4Hz tick now invalidates a one-line subview and nothing else. Same object, same data flow; the only thing that moved is *where the read happens*. (For pure time display there's a zero-state option too: `Text(timerInterval:)` and `TimelineView` let the framework tick the label without any body re-evaluation — reach for them when the requirement is cosmetic time, not real engine position.)

### The Prompt That Prevents It

> *"Add a playback progress bar to `NowPlayingView`. Constraint: `currentTime` updates several times per second, so it must be read ONLY inside a new, minimal subview — `NowPlayingView.body` must not reference it directly. After generating, list every view whose body reads `currentTime` and justify each. Add a DEBUG `Self._printChanges()` to `NowPlayingView` and confirm it does not log during steady playback."*

The verification clause is the senior move: "only the progress bar re-renders" is a checkable claim, so the prompt makes the AI check it. To audit an existing screen for this whole failure class, run `prompts/performance/render-isolation-audit.md`.
