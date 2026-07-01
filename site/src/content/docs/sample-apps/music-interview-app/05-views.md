---
title: "Views Layer Prompt"
---

Generate two SwiftUI views for the Music app: `LibraryView` and `NowPlayingView`.

**Goal:**
- `LibraryView` should display a horizontal scrollable list of tracks (using a `LazyHStack` inside a `ScrollView`).
- `NowPlayingView` should be a full-screen view showing the current track's album art (as a placeholder), title, artist, and primary playback controls (previous, play/pause, next).

**Architectural Constraints:**
- Target iOS 17+ and use Swift 6 strict concurrency (views should be implicitly or explicitly `@MainActor`).
- These views must contain **no business logic**; all state and operations should be delegated to their respective `@Observable` `@MainActor` ViewModels (`LibraryViewModel` and `PlayerViewModel`).
- Bind them properly by passing the ViewModels into the views via standard initialization.
- Use the `.task` modifier instead of `.onAppear` for asynchronous data loading (e.g., loading tracks when `LibraryView` appears).
- Provide a clean, modern SwiftUI implementation using `SF Symbols` for playback icons. Ensure that the playback controls correctly reflect the `isPlaying` state from the ViewModel.
