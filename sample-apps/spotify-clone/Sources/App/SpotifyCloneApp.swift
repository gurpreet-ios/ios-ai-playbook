import SwiftUI
import SwiftData

/// The main entry point for the Spotify Clone sample app.
@main
struct SpotifyCloneApp: App {
    // Singleton-like instances for the app lifecycle
    let container: ModelContainer
    let networkClient = NetworkClient()
    let audioEngine = AudioEngine()

    init() {
        do {
            container = try ModelContainer(for: Track.self, Playlist.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView(
                networkClient: networkClient,
                audioEngine: audioEngine,
                modelContext: container.mainContext
            )
        }
        .modelContainer(container)
    }
}

/// Root view injecting global dependencies.
///
/// The `ModelContext` is passed in explicitly: reading
/// `@Environment(\.modelContext)` inside an `init` returns a default,
/// container-less context, so the environment cannot be used here.
struct AppRootView: View {
    let networkClient: NetworkClient
    let audioEngine: AudioEngine

    @State private var playerViewModel: PlayerViewModel
    @State private var homeViewModel: HomeViewModel

    @MainActor
    init(networkClient: NetworkClient, audioEngine: AudioEngine, modelContext: ModelContext) {
        self.networkClient = networkClient
        self.audioEngine = audioEngine

        let trackRepo = TrackRepository(networkClient: networkClient, modelContext: modelContext)
        _playerViewModel = State(initialValue: PlayerViewModel(audioEngine: audioEngine))
        _homeViewModel = State(initialValue: HomeViewModel(repository: trackRepo))
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            NavigationStack {
                HomeView(viewModel: homeViewModel)
            }
            
            MiniPlayerView(viewModel: playerViewModel)
                .padding(.bottom, 49) // Approximate tab bar height padding
        }
    }
}
