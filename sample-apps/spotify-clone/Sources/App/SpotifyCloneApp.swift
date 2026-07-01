import SwiftUI
import SwiftData

/// The main entry point for the Spotify Clone sample app.
@main
struct SpotifyCloneApp: App {
    // Singleton-like instances for the app lifecycle
    let networkClient = NetworkClient(baseURL: URL(string: "https://api.example.com")!)
    let audioEngine = AudioEngine()
    
    var body: some Scene {
        WindowGroup {
            AppRootView(networkClient: networkClient, audioEngine: audioEngine)
        }
        .modelContainer(for: [Track.self, Playlist.self])
    }
}

/// Root view injecting global dependencies
struct AppRootView: View {
    let networkClient: NetworkClient
    let audioEngine: AudioEngine
    
    @State private var playerViewModel: PlayerViewModel
    @State private var homeViewModel: HomeViewModel
    
    init(networkClient: NetworkClient, audioEngine: AudioEngine) {
        self.networkClient = networkClient
        self.audioEngine = audioEngine
        
        let trackRepo = TrackRepository(networkClient: networkClient)
        _playerViewModel = State(initialValue: PlayerViewModel(audioEngine: audioEngine))
        _homeViewModel = State(initialValue: HomeViewModel(trackRepository: trackRepo))
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
