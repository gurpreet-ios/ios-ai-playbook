---
title: "Generate TrackRepository"
---

Implement the Repositories layer for the Music app, specifically `TrackRepository.swift`.

Your task is to create a repository that manages `Track` data, abstracting the data sources (network vs. local database) from the rest of the application.

**Requirements**:
1. Define a `TrackRepositoryProtocol` with the following methods:
   - `getTrack(id: UUID) async throws -> Track`
   - `downloadTrack(id: UUID) async throws`
2. Implement a concrete `TrackRepository` class that conforms to this protocol.
3. **Dependency Injection**: Use protocol-based dependency injection for testing. The repository must accept an abstraction of the network layer (e.g., `NetworkClientProtocol`) and a SwiftData `ModelContext` via its initializer.
4. **Concurrency**: Enforce `@MainActor` isolation on both the protocol and the concrete class. This is an explicit constraint to ensure that SwiftData reads and writes are safely executed on the main thread, strictly complying with Swift 6 strict concurrency rules.
5. **Business Logic**: When `downloadTrack` is called, it should retrieve the track, use the injected network client to download the track's file, update the `offlineFileURL` property of the retrieved `Track` model, and persist the change using the injected context.
