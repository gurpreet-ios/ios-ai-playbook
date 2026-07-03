# 01 – Models Layer Prompt

> Companion prompt document for the **Models/** layer. Records the exact prompt
> used during the interview, after the `.cursorrules` alignment (see the app
> README for the interview timeline).

**Interview clock:** ~0:05 · **Time to type:** ~40 seconds

---

## What you say to the interviewer first

> "I'll start at the bottom of the dependency graph: a domain `Movie` that the UI
> consumes, and separate DTOs that mirror the API's JSON. Keeping them separate
> means an API rename never ripples above the repository."

---

## Prompt

```text
Create the Models layer in Sources/Models/.

1. Movie.swift — the domain model. A struct that is Identifiable, Hashable,
   Sendable with: id (Int), title, overview, releaseYear (String?, 4 digits),
   posterURL (URL?), rating (Double, 0–10 scale). Plain value type — nothing
   in this app persists whole movies.

2. APIModels.swift — the DTOs:
   - MovieDTO (Codable, Sendable, Hashable): id, title, overview,
     releaseDate (String?), posterPath (String?), voteAverage (Double).
     camelCase names — the decoder uses .convertFromSnakeCase.
   - SearchResponseDTO (Codable, Sendable, Hashable): page, results
     ([MovieDTO]), totalPages.
   - An extension Movie { init(dto:) } that maps DTO → domain: take the first
     4 chars of releaseDate as releaseYear (nil if absent/short), and resolve
     posterPath against a poster CDN base URL constant.

Doc-comments on every type and property. Foundation only — no UIKit here.
```

---

## Key Constraints Enforced

| # | Constraint | Why |
|---|-----------|-----|
| 1 | DTOs separate from domain model | API contract can change without touching ViewModels or Views. |
| 2 | `Movie` is `Hashable` | It goes straight into the diffable data source as the item identifier. |
| 3 | Everything `Sendable` | Values cross the `NetworkClient`/`ImageLoader` actor boundaries under Swift 6 strict concurrency. |
| 4 | Mapping lives with the DTOs | One place to audit when a field's semantics change. |
| 5 | No UIKit import in Models | Layer purity — models must be usable from any target, including tests. |

---

## What to Review in the Output

- [ ] `Movie` has no `Codable` conformance — the domain model never touches JSON.
- [ ] `releaseYear` mapping handles nil **and** too-short date strings.
- [ ] `posterURL` is nil (not a broken URL) when `posterPath` is nil.
- [ ] No force-unwraps in the mapping path.
- [ ] `grep -r "import UIKit" Sources/Models/` returns nothing.
