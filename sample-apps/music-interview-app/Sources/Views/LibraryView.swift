import SwiftUI

@MainActor
public struct LibraryView: View {
    var viewModel: LibraryViewModel
    
    public init(viewModel: LibraryViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 20) {
                    ForEach(viewModel.tracks) { track in
                        VStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.secondary.opacity(0.2))
                                .frame(width: 160, height: 160)
                            
                            Text(track.title)
                                .font(.headline)
                                .lineLimit(1)
                            
                            Text(track.artist)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        .frame(width: 160)
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Library")
            .task {
                await viewModel.loadTracks()
            }
        }
    }
}
