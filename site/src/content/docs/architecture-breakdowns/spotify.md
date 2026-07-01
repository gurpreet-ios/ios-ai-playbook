---
title: "AI Architecture Breakdown: Spotify"
---

## Core Challenge
Global playback state and massive offline caching. The audio must continue playing regardless of what screen the user navigates to, and downloaded tracks must be encrypted and instantly available.

## The Blueprint (AI Prompting Sequence)

### 1. The Audio Engine
*The engine must be entirely decoupled from the UI.*
**Prompt:** "Generate an `AudioEngine` using `AVFoundation`. It must handle background audio playback, lock screen controls (Now Playing Info Center), and headphone unplug events. Expose the current `PlaybackState` (playing, paused, buffering) as an async stream."

### 2. The Offline Cache (Repository)
**Prompt:** "Generate a `TrackRepository` using SwiftData. When fetching a track, it must first check the local SwiftData cache. If the track is downloaded, return the local file URL. If not, return the remote streaming URL. Hide this logic behind a `TrackFetching` protocol."

### 3. Global State (Observation)
**Prompt:** "Generate a `@Observable` class called `PlayerViewModel`. It must inject the `AudioEngine`. Any screen in the app should be able to read `PlayerViewModel.currentTrack` without causing the entire navigation stack to re-render."

### 4. The Mini Player UI
**Prompt:** "Generate a SwiftUI `MiniPlayerView`. It must sit at the bottom of the `ZStack` in the main App layout, persisting across all navigation pushes. It should observe the `PlayerViewModel` for state changes."
