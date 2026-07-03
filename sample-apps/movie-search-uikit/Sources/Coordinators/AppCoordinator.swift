// AppCoordinator.swift
// Coordinators layer — root coordinator; owns the window and the nav stack.

import UIKit

/// The single entry point into the UI. Owns the `UIWindow`, installs the
/// root `UINavigationController`, and delegates the first flow to
/// `SearchCoordinator`.
///
/// Today the app has one flow; the child-coordinator plumbing exists so a
/// second tab or an onboarding flow drops in without touching this shape.
@MainActor
final class AppCoordinator: Coordinator {

    // MARK: Properties

    var childCoordinators: [Coordinator] = []

    private let window: UIWindow
    private let navigationController = UINavigationController()
    private let dependencies: AppDependencies

    // MARK: Initialisation

    init(window: UIWindow, dependencies: AppDependencies) {
        self.window = window
        self.dependencies = dependencies
    }

    // MARK: Coordinator

    func start() {
        navigationController.navigationBar.prefersLargeTitles = true
        window.rootViewController = navigationController
        window.makeKeyAndVisible()

        let searchCoordinator = SearchCoordinator(
            navigationController: navigationController,
            dependencies: dependencies
        )
        searchCoordinator.parent = self
        childCoordinators.append(searchCoordinator)
        searchCoordinator.start()
    }
}
