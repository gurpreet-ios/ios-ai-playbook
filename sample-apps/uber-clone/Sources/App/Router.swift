import SwiftUI

// MARK: - Route Definition

/// All navigable destinations in the app, defined as a single enum.
/// This prevents scattered NavigationLink destinations across views.
enum AppRoute: Hashable {
    case activeTrip(tripId: UUID)
}

// MARK: - App Router

/// Centralized navigation manager. Views call `router.navigate(to:)`
/// instead of embedding NavigationLink destinations directly.
///
/// ## Architecture Note
/// This Router is injected via SwiftUI's `@Environment` so any view
/// in the hierarchy can trigger navigation without coupling to the
/// NavigationStack's path.
@MainActor
@Observable
final class AppRouter {
    var path = NavigationPath()
    
    func navigate(to route: AppRoute) {
        path.append(route)
    }
    
    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
    
    func popToRoot() {
        path = NavigationPath()
    }
}
