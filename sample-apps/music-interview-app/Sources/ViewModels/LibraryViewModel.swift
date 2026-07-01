import Foundation
import Observation

@MainActor
@Observable
public final class LibraryViewModel {
    public var tracks: [Track] = []
    public var isLoading: Bool = false
    public var errorMessage: String?
    
    private let repository: any TrackRepositoryProtocol
    
    public init(repository: any TrackRepositoryProtocol) {
        self.repository = repository
    }
    
    public func loadTracks() async {
        isLoading = true
        errorMessage = nil
        
        do {
            tracks = try await repository.fetchTracks()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
