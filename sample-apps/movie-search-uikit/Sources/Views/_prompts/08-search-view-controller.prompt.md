# 08 – MovieSearchViewController Prompt

> Companion prompt document for `Views/MovieSearchViewController.swift`.

**Interview clock:** ~0:42 · **Time to type:** ~60 seconds

---

## What you say to the interviewer first

> "The ViewController is deliberately boring: it binds once and its render
> method is a switch over SearchState. Diffable data source instead of
> reloadData — with Hashable movies the snapshot diffing is free, and there's
> no index-out-of-bounds class of bug at all." *(Decision #4 in DECISIONS.md.)*

---

## Prompt

```text
Create Views/MovieSearchViewController.swift.

final class MovieSearchViewController: UIViewController, injected with
MovieSearchViewModel and ImageLoading via init (init(coder:) unavailable,
fatalError).

Structure:
- UICollectionView with UICollectionViewCompositionalLayout.list(.plain),
  pinned to all edges, keyboardDismissMode = .onDrag.
- UISearchController in navigationItem (hidesSearchBarWhenScrolling = false,
  placeholder "Search movies"). Conform to UISearchResultsUpdating and
  forward searchBar.text to viewModel.searchTextDidChange.
- UICollectionViewDiffableDataSource<Section, Movie> with a single .results
  section and a CellRegistration for MovieCell (pass the imageLoader in).
- bindViewModel(): viewModel.state.bind → render(state).
- render(_:) switches over SearchState:
  - idle    → empty snapshot + EmptyStateView("Find a movie", magnifyingglass)
  - loading → large UIActivityIndicatorView centered
  - loaded  → hide overlays, apply snapshot with the movies
  - empty   → empty snapshot + EmptyStateView("No results", echo the query)
  - failed  → empty snapshot + EmptyStateView with the message
  EmptyStateView goes in collectionView.backgroundView.
- UICollectionViewDelegate didSelectItemAt: deselect, then
  viewModel.didSelectMovie(dataSource.itemIdentifier(for:)).

FORBIDDEN in this file: URLSession, repository types, pushViewController,
DispatchQueue, reloadData.
```

---

## Key Constraints Enforced

| # | Constraint | Why |
|---|-----------|-----|
| 1 | `render` is a single exhaustive switch | Adding a state without UI handling becomes a compile error. |
| 2 | Diffable + `Hashable` items | Animated diffs for free; no manual index math to get wrong. |
| 3 | `itemIdentifier(for:)`, never `movies[indexPath.item]` | The data source is the single source of truth for what's on screen. |
| 4 | Selection goes through the ViewModel | The VC doesn't know what selection *means*; the Coordinator decides. |
| 5 | `keyboardDismissMode = .onDrag` | Small UX detail interviewers notice. |

---

## What to Review in the Output

- [ ] `[weak self]` in the state binding (VC ↔ ViewModel cycle otherwise).
- [ ] Snapshot is rebuilt from state, never mutated incrementally from events.
- [ ] The activity indicator stops in every non-loading branch.
- [ ] `grep -n "reloadData" Sources/Views/` returns nothing.
