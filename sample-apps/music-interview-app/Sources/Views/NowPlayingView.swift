import SwiftUI

@MainActor
public struct NowPlayingView: View {
    var viewModel: PlayerViewModel
    
    public init(viewModel: PlayerViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Album Art Placeholder
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.secondary.opacity(0.2))
                .aspectRatio(1.0, contentMode: .fit)
                .padding(.horizontal, 40)
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                .accessibilityLabel(viewModel.currentTrack != nil ? "Album Art for \\(viewModel.currentTrack!.title)" : "No Album Art")
                .accessibilityAddTraits(.isImage)
            
            VStack(spacing: 8) {
                Text(viewModel.currentTrack?.title ?? "Not Playing")
                    .font(.title)
                    .fontWeight(.bold)
                    .lineLimit(1)
                
                Text(viewModel.currentTrack?.artist ?? "--")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal)
            
            // Playback Controls
            HStack(spacing: 50) {
                Button {
                    Task { await viewModel.playPrevious() }
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.largeTitle)
                }
                .disabled(viewModel.currentTrack == nil)
                .accessibilityLabel("Previous Track")
                
                Button {
                    Task { await viewModel.togglePlayPause() }
                } label: {
                    Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 72)) // Kept explicit size here for specific UI styling, but wrapped in A11y
                }
                .disabled(viewModel.currentTrack == nil)
                .accessibilityLabel(viewModel.isPlaying ? "Pause" : "Play")
                
                Button {
                    Task { await viewModel.playNext() }
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.largeTitle)
                }
                .disabled(viewModel.currentTrack == nil)
                .accessibilityLabel("Next Track")
            }
            .foregroundStyle(.primary)
            
            Spacer()
        }
        .padding()
    }
}
