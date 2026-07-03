# 04 – Repositories Prompt

> Companion prompt document for `Repositories/MovieRepository.swift` and
> `Repositories/FavoritesStore.swift`.

**Interview clock:** ~0:20 · **Time to type:** ~45 seconds

---

## What you say to the interviewer first

> "Repositories are the ViewModels' only data source. The search repository owns
> the DTO-to-domain mapping so nothing above it ever sees JSON. Favorites are
> deliberately just IDs in UserDefaults — a movie catalogue is server data;
> caching full objects locally buys nothing in this time-box." *(Decision #7 in
> DECISIONS.md.)*

---

## Prompt

```text
Create the Repositories layer.

1. MovieRepository.swift
   - protocol MovieRepositoryProtocol: Sendable with
     searchMovies(matching query: String) async throws -> [Movie]
   - struct RemoteMovieRepository conforming to it. Inject
     NetworkClientProtocol via init. Call GET search/movie with a "query"
     URLQueryItem, decode SearchResponseDTO, and map results through
     Movie.init(dto:). This is the only place DTOs are visible.

2. FavoritesStore.swift
   - @MainActor protocol FavoritesStoreProtocol: AnyObject with
     isFavorite(_ movieID: Int) -> Bool and toggle(_ movieID: Int)
   - @MainActor final class UserDefaultsFavoritesStore conforming to it.
     Inject UserDefaults (default .standard) so tests can use an isolated
     suite. Keep an in-memory Set<Int> mirror, hydrate it in init, write
     through to defaults on every toggle. Namespaced storage key.
```

---

## Key Constraints Enforced

| # | Constraint | Why |
|---|-----------|-----|
| 1 | `RemoteMovieRepository` is a `struct` | It's stateless; an actor here would add hops for nothing. The client behind it is already an actor. |
| 2 | Favorites store is `@MainActor`, not an actor | Only ViewModels touch it; keeping the read-toggle-read cycle synchronous avoids await interleaving bugs. |
| 3 | Injected `UserDefaults` | Tests run against `UserDefaults(suiteName:)` and clean up after themselves — never `.standard`. |
| 4 | In-memory mirror + write-through | Reads are O(1) set lookups; UserDefaults is only an I/O sink. |
| 5 | IDs only, never `Movie` blobs | UserDefaults is not a database; see DECISIONS.md #7. |

---

## What to Review in the Output

- [ ] No DTO type appears in any repository method **signature**.
- [ ] The storage key is namespaced (reverse-DNS), not `"favorites"`.
- [ ] `toggle` persists on every call — no "save later" batching to forget.
- [ ] `grep -rn "MovieDTO" Sources/ViewModels/ Sources/Views/` returns nothing (run after those layers exist).
