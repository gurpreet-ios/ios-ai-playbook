---
title: "Services Layer Prompt"
---

**Goal**: Implement the Services layer for the Music app, providing robust networking and audio playback capabilities.

**Requirements**:
1. Create a `NetworkClient` for making REST API calls. It must be an `actor` to guarantee thread-safe network execution and should expose a generic `fetch<T: Decodable & Sendable>(url: URL)` method.
2. Create an `AudioEngine` wrapping `AVPlayer` to handle music playback. It must also be an `actor` to encapsulate the AVPlayer safely.
3. The `AudioEngine` must expose playback state (`playing`, `paused`, `buffering`, `stopped`) using an `AsyncStream<PlaybackState>` so that view models on the `@MainActor` can easily consume and observe the state over time without data races.
4. Define protocol abstractions (e.g., `AudioEngineProtocol`, `NetworkClientProtocol`) for both services to enable protocol-based Dependency Injection.
5. Ensure Swift 6 strict concurrency compliance (`Sendable` types where necessary, safe cross-actor communication).
