---
title: "🎧 Spotify Clone — 1-Hour Machine Coding Interview"
---

> **The codebase in this directory was generated using ultra-concise, fast prompts designed for a live 60-minute machine coding interview.**

Unlike the highly-descriptive Uber sample app, this repository demonstrates how to prompt **under pressure**. When you have a ticking clock, you don't have time to write 3 paragraphs of constraints. You need fast, confident, authoritative commands that leverage tools like Cursor Composer or GitHub Copilot inline chat.

---

## The "Under Pressure" Prompting Style

Check the `_prompts/` directories in each layer. You'll notice they are extremely short:

**Bad (Too Slow):**
> *"Please act as a Senior iOS Developer. I need a Track model using SwiftData. It should have an id, a title, an artist, and a way to store if it's downloaded offline. Please ensure it follows Swift 6 concurrency rules."*

**Good (Interview Speed):**
> *"Generate SwiftData Track model with offlineFileURL and isDownloaded. Sendable."*

By establishing your project rules globally (via `.cursorrules` or `.windsurfrules`), your per-file prompts can become terse commands.

---

## Architecture

This app implements the core global state challenge of Spotify: **The persistent Mini Player.**

```
┌─────────────────────────────────────────────────┐
│                    Views                         │
│        HomeView · MiniPlayerView · TrackRow     │
├─────────────────────────────────────────────────┤
│                  ViewModels                      │
│         HomeViewModel · PlayerViewModel          │
├─────────────────────────────────────────────────┤
│                 Repositories                     │
│                TrackRepository                   │
├─────────────────────────────────────────────────┤
│                   Services                       │
│          AudioEngine · NetworkClient             │
├─────────────────────────────────────────────────┤
│                    Models                        │
│               Track · Playlist                   │
└─────────────────────────────────────────────────┘
```

## Key Challenges Handled

1. **Global ZStack:** The `SpotifyCloneApp` embeds the `MiniPlayerView` at the root, hovering over the `NavigationStack`.
2. **Actor-based Audio:** `AudioEngine` is an actor wrapping `AVPlayer`, exposing state safely to the main thread via an `AsyncStream<PlaybackState>`.
3. **SwiftData Offline Caching:** `TrackRepository` handles downloading the audio file and updating the `offlineFileURL` directly on the `@Model`.

## Tech Stack
- **Swift 6** strict concurrency
- **SwiftUI** (iOS 17+)
- **SwiftData**
- **Observation**
- **AVFoundation**

## Running
Open `Package.swift` in Xcode 16+ and build for iOS 17 Simulator. 
*(Note: API endpoints point to mock URLs).*
