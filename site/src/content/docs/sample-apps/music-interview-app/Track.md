---
title: "Track"
---

Write a SwiftData `@Model` for `Track` in Swift 6.
The model must include `id: UUID`, `title: String`, `artist: String`, `coverURL: URL?`, `streamURL: URL`, and `offlineFileURL: URL?`.
Ensure it is a `final class` and conforms to `@unchecked Sendable` so it can be used safely across actor boundaries, satisfying strict concurrency checking for iOS 17+.
