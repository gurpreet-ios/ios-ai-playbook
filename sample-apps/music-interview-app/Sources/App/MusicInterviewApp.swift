import SwiftUI
import SwiftData

/// The main entry point for the Music Interview App.
@main
struct MusicInterviewApp: App {
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

/// The Composition Root that constructs the dependency graph.
///
/// The `ModelContext` is passed in explicitly: reading
/// `@Environment(\.modelContext)` inside an `init` returns a default,
/// container-less context, so the environment cannot be used here.
struct AppRootView: View {
    @State private var libraryViewModel: LibraryViewModel
    @State private var playerViewModel: PlayerViewModel

    @MainActor
    init(networkClient: NetworkClient, audioEngine: AudioEngine, modelContext: ModelContext) {
        let trackRepo = TrackRepository(networkClient: networkClient, modelContext: modelContext)
        _libraryViewModel = State(initialValue: LibraryViewModel(repository: trackRepo))
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
