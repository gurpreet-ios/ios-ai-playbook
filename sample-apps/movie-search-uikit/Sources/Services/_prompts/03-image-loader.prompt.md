# 03 – ImageLoader Prompt

> Companion prompt document for `Services/ImageLoader.swift`.

**Interview clock:** ~0:15 · **Time to type:** ~30 seconds

---

## What you say to the interviewer first

> "No Kingfisher — the constraint is zero dependencies, and hand-rolling this
> is a classic interview probe anyway. The two failure modes to design against
> are duplicate downloads during a fast scroll and unbounded memory. NSCache
> solves the second; coalescing in-flight tasks solves the first."

---

## Prompt

```text
Create Services/ImageLoader.swift.

1. ImageLoaderError enum: invalidImageData.

2. protocol ImageLoading: Sendable with:
   image(from url: URL) async throws -> UIImage

3. actor ImageLoader conforming to it, with:
   - an NSCache<NSURL, UIImage> for decoded images
   - an inFlight: [URL: Task<UIImage, Error>] table
   - injected URLSession (default .shared)

   image(from:) order of operations:
   a. return cached image if present
   b. if a task for this URL is already in flight, await ITS value (do not
      start a second download)
   c. otherwise start a Task that downloads and decodes (throw
      invalidImageData if UIImage(data:) fails), record it in inFlight,
      remove it in a defer, cache the result, return it.

Why an actor: the cache and the in-flight table are mutable state hit
concurrently by every visible cell.
```

---

## Key Constraints Enforced

| # | Constraint | Why |
|---|-----------|-----|
| 1 | In-flight coalescing | Ten visible cells sharing a poster = one download, not ten. |
| 2 | `NSCache` over a dictionary | Auto-eviction under memory pressure for free; a `[URL: UIImage]` dictionary is an OOM in disguise. |
| 3 | `defer { inFlight[url] = nil }` | The table can't leak entries on the error path. |
| 4 | Protocol seam (`ImageLoading`) | Cells are testable with a stub that returns a fixed image. |
| 5 | No `UIImageView` extension API | Loading stays in the service; cancellation stays in the cell where reuse happens. |

---

## What to Review in the Output

- [ ] Cache hit is checked **before** the in-flight table.
- [ ] The download task captures `session`, not `self` (no actor re-entrancy surprise inside the closure).
- [ ] Failed downloads are not cached.
- [ ] The actor exposes no mutable state publicly.
