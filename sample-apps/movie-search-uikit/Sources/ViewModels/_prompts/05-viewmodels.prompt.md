# 05 – ViewModels Layer Prompt

> Companion prompt document for `ViewModels/Box.swift`,
> `ViewModels/MovieSearchViewModel.swift`, and
> `ViewModels/MovieDetailViewModel.swift`.

**Interview clock:** ~0:27 · **Time to type:** ~60 seconds

---

## What you say to the interviewer first

> "MVVM on UIKit needs a binding mechanism, and the honest zero-dependency
> answer is a closure box — fifteen lines I can defend completely, versus
> Combine which we agreed to keep out. Screen state is one exhaustive enum so
> the ViewController can't render a half-state like 'loading spinner over stale
> results'." *(Decisions #3 and #4-adjacent in DECISIONS.md.)*

---

## Prompt

```text
Create the ViewModels layer.

1. Box.swift — the binding primitive.
   @MainActor final class Box<Value>: `value` property with didSet notifying
   a single stored listener; bind(_:) stores the listener AND fires it
   immediately with the current value. Document the one-listener limitation.

2. MovieSearchViewModel.swift
   - enum SearchState: Equatable — idle, loading, loaded([Movie]),
     empty(query: String), failed(message: String).
   - @MainActor final class MovieSearchViewModel:
     - let state = Box<SearchState>(.idle)
     - var onMovieSelected: ((Movie) -> Void)?   // fulfilled by Coordinator
     - init(repository: MovieRepositoryProtocol,
            debounceInterval: Duration = .milliseconds(300))
     - searchTextDidChange(_ text: String): cancel the previous task; trim
       whitespace; empty → .idle and return; otherwise start a Task that
       sleeps debounceInterval, bails if cancelled, then performs the search.
       Keep the task in `private(set) var activeSearchTask` so tests can
       await it.
     - performSearch: set .loading, await repository, then loaded/empty/
       failed. Re-check Task.isCancelled after the await before writing
       state — a stale response must never overwrite a newer query's state.
     - didSelectMovie(_ movie: Movie?): guard-let then onMovieSelected.

3. MovieDetailViewModel.swift
   - @MainActor final class holding the Movie (passed in — no refetch),
     FavoritesStoreProtocol, and let isFavorite = Box<Bool>(...) seeded from
     the store.
   - Presentation strings: titleText, metadataText ("2021 · ★ 7.8", with a
     "Year unknown" fallback), overviewText (fallback for empty overview).
   - toggleFavorite(): toggle the store, then re-read the store into the Box
     (persisted truth, not a local flip).

No UIKit import anywhere in this layer.
```

---

## Key Constraints Enforced

| # | Constraint | Why |
|---|-----------|-----|
| 1 | State is one exhaustive enum | Impossible states are unrepresentable; the view is a single `switch`. |
| 2 | Debounce is injectable | Tests pass `.zero` and await the task — no `sleep`-based flaky tests. |
| 3 | Cancellation re-checked **after** the await | The classic race: slow response for "du" landing after results for "dune". |
| 4 | Navigation is a closure, not a push | The ViewModel doesn't know UIKit exists; the Coordinator owns the graph. |
| 5 | `Box` is `@MainActor` | Bindings drive UIKit; delivering off-main should be a compile error, not a crash report. |
| 6 | Favorite state re-read from the store | UI can never drift from persistence. |

---

## What to Review in the Output

- [ ] `grep -rn "import UIKit" Sources/ViewModels/` returns nothing.
- [ ] Whitespace-only input goes `.idle` without creating a task.
- [ ] `Task.isCancelled` is checked both after the sleep **and** after the repository await.
- [ ] `bind` fires immediately — a screen bound after state changed still renders.
- [ ] No `[weak self]` omissions in the stored task (ViewModel must not retain itself).
