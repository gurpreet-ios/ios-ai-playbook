# 11 – Tests Prompt

> Companion prompt document for `Tests/MovieSearchViewModelTests.swift` and
> `Tests/FavoritesStoreTests.swift`.

**Interview clock:** ~0:56 · **Time to type:** ~40 seconds

---

## What you say to the interviewer first

> "With the last minutes I'll test the two layers with real logic: the search
> ViewModel and the favorites store. The DI seams pay off now — a stub
> repository through the protocol, an isolated UserDefaults suite, and a `.zero`
> debounce so the tests await the real task instead of sleeping."

---

## Prompt

```text
Create the test target (Swift Testing, @Suite/@Test/#expect — not XCTest).

1. MovieSearchViewModelTests.swift — @MainActor suite with a StubRepository
   (MovieRepositoryProtocol backed by a Result) and debounceInterval: .zero.
   Await viewModel.activeSearchTask?.value instead of sleeping. Cover:
   - whitespace-only input → .idle, no task created
   - success → .loaded with the stubbed movies
   - success with zero results → .empty echoing the query
   - repository error → .failed with a non-empty message
   - a second keystroke cancels the first pending task (use a 60s debounce
     so only cancellation can end it) and state is untouched
   - didSelectMovie forwards to onMovieSelected
   - Box fires the current value immediately on bind

2. FavoritesStoreTests.swift — @MainActor suite using
   UserDefaults(suiteName: unique-UUID) with removePersistentDomain in a
   defer. Cover:
   - toggle persists and survives a NEW store instance (rehydration)
   - toggling one ID doesn't affect another

No sleeps, no timeouts, no testing of ViewControllers.
```

---

## Key Constraints Enforced

| # | Constraint | Why |
|---|-----------|-----|
| 1 | Await the exposed task, never sleep | Deterministic tests; `sleep`-based async tests are flakes on CI. |
| 2 | Isolated UserDefaults suite | Tests must not read or pollute the developer's `.standard` defaults. |
| 3 | Stub via the protocol, not a mock framework | The DI seams are the interview's proof of testability. |
| 4 | Behavioral assertions only | Per Ch 26: no tautological "stub returns what stub was given" tests. |

---

## What to Review in the Output

- [ ] Every async test awaits `activeSearchTask` — `grep -n "sleep" Tests/` only matches the ViewModel's own debounce, never a test.
- [ ] The cancellation test asserts both `isCancelled` **and** untouched state.
- [ ] `removePersistentDomain` runs in `defer` so failures still clean up.
