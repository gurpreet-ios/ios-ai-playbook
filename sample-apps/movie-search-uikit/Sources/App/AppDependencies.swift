// AppDependencies.swift
// App layer — the composition root. The only place concrete types are
// constructed; everything below this file speaks in protocols.

import Foundation

/// The app's dependency graph, built once at launch and handed to the
/// `AppCoordinator`, which threads it into each flow.
@MainActor
struct AppDependencies {

    // MARK: Properties

    let movieRepository: MovieRepositoryProtocol
    let imageLoader: ImageLoading
    let favoritesStore: FavoritesStoreProtocol

    // MARK: Factory

    /// Production wiring.
    ///
    /// Demonstration note: `api.example.com` is a placeholder — swap in a
    /// real movie API base URL (and its auth query item) to run end-to-end.
    static func live() -> AppDependencies {
        let networkClient = NetworkClient(
            baseURL: URL(string: "https://api.example.com/v1")!
        )
        return AppDependencies(
            movieRepository: RemoteMovieRepository(networkClient: networkClient),
            imageLoader: ImageLoader(),
            favoritesStore: UserDefaultsFavoritesStore()
        )
    }
}
