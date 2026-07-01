---
title: "Models"
---

Generate the SwiftData models and networking DTOs for a Music Interview App.
The goal is to create `Track` and `Playlist` models using `@Model` that can be stored offline, alongside `TrackDTO` and `PlaylistDTO` for API responses.
Architectural Constraints: Target iOS 17+ using Swift 6 strict concurrency. The SwiftData models must conform to `@unchecked Sendable` to be passed safely across actor boundaries, and all DTOs must be explicitly `Sendable`. Keep files focused with one type per file.
