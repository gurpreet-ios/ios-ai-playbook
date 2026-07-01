import SwiftUI
import SwiftData

/// The main entry point for the Uber Clone sample app.
///
/// This app demonstrates the AI-Native Engineering Playbook's approach
/// to building a complex, real-time ride-sharing application using
/// layered architecture and AI-generated code.
@main
struct UberCloneApp: App {
    
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(for: [Trip.self, Driver.self, Rider.self])
    }
}

// MARK: - App Root View

/// The root view that manages top-level navigation using a Router.
struct AppRootView: View {
    @State private var router = AppRouter()
    
    var body: some View {
        NavigationStack(path: $router.path) {
            RideRequestView(
                viewModel: RideRequestViewModel(
                    tripRepository: TripRepository(
                        networkClient: NetworkClient(baseURL: URL(string: "https://api.example.com")!)
                    ),
                    locationService: LocationService()
                )
            )
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .activeTrip(let tripId):
                    ActiveTripView(
                        viewModel: ActiveTripViewModel(
                            tripRepository: TripRepository(
                                networkClient: NetworkClient(baseURL: URL(string: "https://api.example.com")!)
                            ),
                            driverRepository: DriverRepository(
                                networkClient: NetworkClient(baseURL: URL(string: "https://api.example.com")!),
                                webSocketManager: WebSocketManager()
                            )
                        )
                    )
                }
            }
        }
        .environment(router)
    }
}
