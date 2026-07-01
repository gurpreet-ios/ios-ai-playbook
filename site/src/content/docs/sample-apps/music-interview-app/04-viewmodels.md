---
title: "Objective"
---

Generate the ViewModels for the Music Interview app, specifically `PlayerViewModel` and `LibraryViewModel`.

# Requirements
- Create `PlayerViewModel` and `LibraryViewModel` as `@MainActor` and `@Observable` classes. Do not use `Combine` or `ObservableObject`.
- Use protocol-based dependency injection. `PlayerViewModel` should inject an `AudioEngineProtocol` and `LibraryViewModel` should inject a `TrackRepositoryProtocol`.
- In `PlayerViewModel`, observe the `AsyncStream` of the audio playback state inside a `Task` created in the initializer. 
- Explicitly hold a reference to this `Task` and provide an explicit `cleanup()` method to cancel it, preventing memory leaks during the interview process.
- Ensure strict concurrency rules are followed (Swift 6), handling actor isolation appropriately when updating state or canceling tasks.
