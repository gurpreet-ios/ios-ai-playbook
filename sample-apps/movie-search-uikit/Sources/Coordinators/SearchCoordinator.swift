// SearchCoordinator.swift
// Coordinators layer — the search → detail flow. The ONLY place in the app
// that creates these screens or calls pushViewController for them.

import UIKit

/// Runs the movie-search flow: search screen first, detail screen on
/// selection. ViewModels signal intent through closures; this coordinator
/// turns intent into navigation.
@MainActor
final class SearchCoordinator: Coordinator {

    // MARK: Properties

    var childCoordinators: [Coordinator] = []

    /// Weak: the parent owns us via `childCoordinators`, not vice versa.
    weak var parent: Coordinator?

    private let navigationController: UINavigationController
    private let dependencies: AppDependencies

    // MARK: Initialisation

    init(navigationController: UINavigationController, dependencies: AppDependencies) {
        self.navigationController = navigationController
        self.dependencies = dependencies
    }

    // MARK: Coordinator

    func start() {
        let viewModel = MovieSearchViewModel(repository: dependencies.movieRepository)
        viewModel.onMovieSelected = { [weak self] movie in
            self?.showDetail(for: movie)
        }
        let viewController = MovieSearchViewController(
            viewModel: viewModel,
            imageLoader: dependencies.imageLoader
        )
        navigationController.pushViewController(viewController, animated: false)
    }

    // MARK: Navigation

    private func showDetail(for movie: Movie) {
        let viewModel = MovieDetailViewModel(
            movie: movie,
            favorites: dependencies.favoritesStore
        )
        let viewController = MovieDetailViewController(
            viewModel: viewModel,
            imageLoader: dependencies.imageLoader
        )
        navigationController.pushViewController(viewController, animated: true)
    }
}
