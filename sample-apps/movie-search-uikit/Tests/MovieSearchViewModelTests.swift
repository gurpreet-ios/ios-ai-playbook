import Testing
import Foundation
@testable import MovieSearchUIKit

/// Behavioral tests for the search ViewModel — the layer the interview's
/// unit-testing question always lands on. The repository is stubbed through
/// `MovieRepositoryProtocol`; the debounce is injected as `.zero` so tests
/// await the real task instead of sleeping.
@MainActor
@Suite("MovieSearchViewModel")
struct MovieSearchViewModelTests {

    // MARK: Stubs

    private struct StubRepository: MovieRepositoryProtocol {
        var result: Result<[Movie], any Error>

        func searchMovies(matching query: String) async throws -> [Movie] {
            try result.get()
        }
    }

    private static let dune = Movie(
        id: 438631,
        title: "Dune",
        overview: "Paul Atreides journeys to Arrakis.",
        releaseYear: "2021",
        posterURL: nil,
        rating: 7.8
    )

    private func makeViewModel(returning result: Result<[Movie], any Error>) -> MovieSearchViewModel {
        MovieSearchViewModel(
            repository: StubRepository(result: result),
            debounceInterval: .zero
        )
    }

    // MARK: Tests

    @Test("Empty input resets to idle without starting a search")
    func emptyInputGoesIdle() {
        let viewModel = makeViewModel(returning: .success([Self.dune]))

        viewModel.searchTextDidChange("   ")

        #expect(viewModel.state.value == .idle)
        #expect(viewModel.activeSearchTask == nil)
    }

    @Test("Successful search publishes loaded state with mapped movies")
    func successfulSearchLoads() async {
        let viewModel = makeViewModel(returning: .success([Self.dune]))

        viewModel.searchTextDidChange("dune")
        await viewModel.activeSearchTask?.value

        #expect(viewModel.state.value == .loaded([Self.dune]))
    }

    @Test("A query with no matches publishes the empty state, echoing the query")
    func noMatchesGoesEmpty() async {
        let viewModel = makeViewModel(returning: .success([]))

        viewModel.searchTextDidChange("zzzzz")
        await viewModel.activeSearchTask?.value

        #expect(viewModel.state.value == .empty(query: "zzzzz"))
    }

    @Test("A repository failure publishes a user-presentable failed state")
    func repositoryFailureGoesFailed() async {
        let viewModel = makeViewModel(
            returning: .failure(NetworkError.requestFailed(statusCode: 500))
        )

        viewModel.searchTextDidChange("dune")
        await viewModel.activeSearchTask?.value

        guard case .failed(let message) = viewModel.state.value else {
            Issue.record("Expected .failed, got \(viewModel.state.value)")
            return
        }
        #expect(!message.isEmpty)
    }

    @Test("A new keystroke cancels the pending search so only the latest query wins")
    func newKeystrokeCancelsPendingSearch() async {
        let viewModel = MovieSearchViewModel(
            repository: StubRepository(result: .success([Self.dune])),
            debounceInterval: .seconds(60) // long enough that only cancellation can end it
        )

        viewModel.searchTextDidChange("d")
        let firstTask = viewModel.activeSearchTask
        viewModel.searchTextDidChange("dune")

        await firstTask?.value

        #expect(firstTask?.isCancelled == true)
        // The superseded task must not have flipped the state.
        #expect(viewModel.state.value == .idle)
    }

    @Test("Selecting a movie forwards it to the coordinator callback")
    func selectionForwardsToCoordinator() {
        let viewModel = makeViewModel(returning: .success([Self.dune]))
        var selected: Movie?
        viewModel.onMovieSelected = { selected = $0 }

        viewModel.didSelectMovie(Self.dune)

        #expect(selected == Self.dune)
    }

    @Test("Box delivers the current value immediately on bind")
    func boxFiresOnBind() {
        let box = Box(41)
        var received: [Int] = []

        box.bind { received.append($0) }
        box.value = 42

        #expect(received == [41, 42])
    }
}
