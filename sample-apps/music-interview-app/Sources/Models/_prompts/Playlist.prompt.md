Write a SwiftData `@Model` for `Playlist` targeting iOS 17+ and Swift 6 strict concurrency.
It must contain `id: UUID`, `name: String`, and a relationship to a collection of `Track` models.
Conform the model to `@unchecked Sendable` for actor-boundary safety.
Ensure proper inverse relationship mappings are configured to link with the `Track` model.
