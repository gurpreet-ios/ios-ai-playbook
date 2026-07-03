import Testing
import Foundation
@testable import MovieSearchUIKit

/// Persistence tests for the favorites store, run against an isolated
/// UserDefaults suite so they never touch (or are polluted by) `.standard`.
@MainActor
@Suite("FavoritesStore")
struct FavoritesStoreTests {

    @Test("Toggle marks a movie favorite and survives a new store instance")
    func togglePersistsAcrossInstances() throws {
        let suiteName = "favorites-tests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = UserDefaultsFavoritesStore(defaults: defaults)
        #expect(!store.isFavorite(42))

        store.toggle(42)
        #expect(store.isFavorite(42))

        // A fresh instance reads the same persisted truth.
        let rehydrated = UserDefaultsFavoritesStore(defaults: defaults)
        #expect(rehydrated.isFavorite(42))

        rehydrated.toggle(42)
        #expect(!rehydrated.isFavorite(42))
    }

    @Test("Toggling one movie does not affect another")
    func togglesAreIndependent() throws {
        let suiteName = "favorites-tests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = UserDefaultsFavoritesStore(defaults: defaults)
        store.toggle(1)

        #expect(store.isFavorite(1))
        #expect(!store.isFavorite(2))
    }
}
