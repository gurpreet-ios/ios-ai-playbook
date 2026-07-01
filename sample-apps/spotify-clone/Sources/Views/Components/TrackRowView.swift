import SwiftUI

struct TrackRowView: View {
    let track: Track
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: track.coverURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
            }
            .frame(width: 48, height: 48)
            .cornerRadius(4)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(track.artist)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "ellipsis")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
