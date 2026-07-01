import Foundation
import SwiftUI

@MainActor
@Observable
public final class HomeViewModel {
    public var recentlyPlayed: [Track] = []
    public var isLoading: Bool = false
    
    private let repository: any TrackRepositoryProtocol
    
    public init(repository: any TrackRepositoryProtocol) {
        self.repository = repository
    }
    
    public func loadHome() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            recentlyPlayed = try await repository.fetchRecentlyPlayed()
        } catch {
            print("Failed to load recently played tracks: \(error)")
        }
    }
}
