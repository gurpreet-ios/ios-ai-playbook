// AppDelegate.swift
// App layer — process-level entry point. Deliberately thin: all real
// wiring lives in SceneDelegate → AppCoordinator.

import UIKit

/// The main entry point for the Movie Search sample app.
///
/// Demonstrates the playbook's MVVM-C-on-UIKit interview strategy: every
/// layer was generated from the prompts stored in `_prompts/` directories,
/// and every architectural call is logged in `DECISIONS.md`.
@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: UIApplicationDelegate

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        true
    }

    // MARK: Scene Configuration

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        // Configured in code (no Info.plist scene manifest) so the package
        // stays self-contained.
        let configuration = UISceneConfiguration(
            name: "Default",
            sessionRole: connectingSceneSession.role
        )
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
}
