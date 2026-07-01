---
title: "🎵 Music App — The \"Balanced\" Interview Strategy"
---

> **The codebase in this directory was generated using the "Balanced" prompting strategy. It perfectly blends explicit architectural constraints with concise commands, designed for a 1-hour machine coding interview.**

## The Problem with Extremes

In a live interview, you have two enemies when using AI:
1.  **Too Vague:** If you prompt *"Build a music app"*, the AI will generate monolithic `@ObservedObject` files full of iOS 14 legacy patterns. You will fail the interview because you surrendered architectural control.
2.  **Too Verbose:** If you write a 4-paragraph prompt detailing every struct (like the Uber clone), you will waste 15 minutes typing. You will fail the interview because you ran out of time.

## The Solution: Upfront Alignment + Balanced Prompts

This sample app demonstrates the optimal strategy.

### Step 1: The Upfront `.cursorrules` 
Before you start coding, you discuss the architecture with the interviewer. As you agree on constraints, you type them into a `.cursorrules` file (or system prompt). 
*Check the `.cursorrules` file in this directory to see what that looks like.*

### Step 2: The Balanced Prompts
Because the AI now understands the global rules (e.g., "Use Swift 6 strict concurrency, use SwiftData"), your per-file prompts can be fast, but they still explicitly reiterate the core constraints to prove to the interviewer that you know *why* the AI is generating what it's generating.

**Example from this project (`03-repositories.prompt.md`):**
> *"Generate TrackRepository. Make it a @MainActor class conforming to TrackRepositoryProtocol. Inject the NetworkClient. The download method must update the offlineFileURL on the SwiftData  *

It's 3 sentences. It proves you understand dependency injection and main-thread database writes. It takes 15 seconds to type.

## Architecture Highlights
- **Strict Concurrency:** `AudioEngine` and `NetworkClient` are isolated `actor` types.
- **Async Streams:** State flows from the background audio actor to the UI via `AsyncStream`.
- **Offline Caching:** SwiftData is used to cache downloaded tracks.
