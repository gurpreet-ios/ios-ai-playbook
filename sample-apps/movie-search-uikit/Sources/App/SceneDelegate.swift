// SceneDelegate.swift
// App layer — builds the window, the dependency graph, and the root
// coordinator. No screen types appear here; that is the coordinators' job.

import UIKit

/// Connects the scene to the coordinator hierarchy.
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    // MARK: Properties

    var window: UIWindow?

    /// Strong reference — the coordinator tree is rooted here.
    private var appCoordinator: AppCoordinator?

    // MARK: UIWindowSceneDelegate

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        let coordinator = AppCoordinator(window: window, dependencies: .live())

        self.window = window
        self.appCoordinator = coordinator

        coordinator.start()
    }
}
