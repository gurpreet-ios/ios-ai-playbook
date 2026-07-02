import SwiftUI

struct HomeView: View {
    var viewModel: HomeViewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Recently Played")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(viewModel.recentlyPlayed) { track in
                                VStack(alignment: .leading) {
                                    AsyncImage(url: track.coverURL) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Rectangle()
                                            .fill(Color.secondary.opacity(0.2))
                                    }
                                    .frame(width: 120, height: 120)
                                    .cornerRadius(8)
                                    
                                    Text(track.title)
                                        .font(.caption)
                                        .bold()
                                        .lineLimit(1)
                                    
                                    Text(track.artist)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                .frame(width: 120)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Home")
            .task {
                await viewModel.loadHome()
            }
        }
    }
}
