import SwiftUI
import SwiftData

/// The main entry point for the Music Interview App.
@main
struct MusicInterviewApp: App {
    let networkClient = NetworkClient()
    let audioEngine = AudioEngine()
    
    var body: some Scene {
        if #available(macOS 14.0, iOS 17.0, *) {
            WindowGroup {
                AppRootView(networkClient: networkClient, audioEngine: audioEngine)
            }
            .modelContainer(for: [Track.self, Playlist.self])
        } else {
            // Fallback on earlier versions without SwiftData's modelContainer
            WindowGroup {
                AppRootView(networkClient: networkClient, audioEngine: audioEngine)
            }
        }
    }
}

/// The Composition Root that constructs the dependency graph.
struct AppRootView: View {
    let networkClient: NetworkClient
    let audioEngine: AudioEngine
    @Environment(\.modelContext) private var modelContext
    
    @State private var libraryViewModel: LibraryViewModel
    @State private var playerViewModel: PlayerViewModel
    
    init(networkClient: NetworkClient, audioEngine: AudioEngine) {
        self.networkClient = networkClient
        self.audioEngine = audioEngine
        
        let trackRepo = TrackRepository(networkClient: networkClient, modelContext: modelContext)
        _libraryViewModel = State(initialValue: LibraryViewModel(trackRepository: trackRepo))
        _playerViewModel = State(initialValue: PlayerViewModel(audioEngine: audioEngine))
    }
    
    var body: some View {
        TabView {
            NavigationStack {
                LibraryView(viewModel: libraryViewModel)
            }
            .tabItem {
                Label("Library", systemImage: "music.note.list")
            }
            
            NavigationStack {
                NowPlayingView(viewModel: playerViewModel)
            }
            .tabItem {
                Label("Now Playing", systemImage: "play.circle.fill")
            }
        }
    }
}
