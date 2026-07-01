import SwiftUI

struct MiniPlayerView: View {
    var viewModel: PlayerViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            if let track = viewModel.currentTrack {
                HStack {
                    AsyncImage(url: track.coverURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.2))
                    }
                    .frame(width: 40, height: 40)
                    .cornerRadius(4)
                    
                    VStack(alignment: .leading) {
                        Text(track.title)
                            .font(.subheadline)
                            .bold()
                            .lineLimit(1)
                        
                        Text(track.artist)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Button {
                        viewModel.togglePlayback()
                    } label: {
                        Image(systemName: viewModel.playbackState == .playing ? "pause.fill" : "play.fill")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
                .padding(.horizontal)
            }
        }
    }
}
