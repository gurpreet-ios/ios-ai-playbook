# Mock Interview: Image Cache with TTL

## 1. The Prompt
**Interviewer:** "Build an image cache for a feed-based app. Images should be cached with a 24-hour TTL, work across app launches, and the same image must never be downloaded twice at the same time. You have an LLM — drive it."

## 2. Expected Reasoning
This question layers three distinct skills:
1. **Tiered storage design** — memory (fast, evictable) vs disk (persistent, TTL-checked).
2. **Concurrency** — the cache is hammered from dozens of cells simultaneously; "never download twice" is a request-coalescing problem, not a locking problem.
3. **Platform judgment** — knowing that `NSCache` already handles memory-pressure eviction, and that reinventing it with a dictionary is a red flag.

## 3. The Poor Answer
> *"I'll make a singleton with a `static var cache: [URL: UIImage]`. Before downloading I check the dictionary. For TTL I'll store the date too and compare. For disk I'll write the UIImage data to Documents."*

**Why it's poor:** The dictionary is a data race waiting to happen and never evicts under memory pressure (feed apps die by jetsam, not by crashes). There's no in-flight deduplication — 10 visible cells with the same avatar trigger 10 downloads. Documents is the wrong directory for purgeable caches (it gets backed up to iCloud); caches belong in `Caches`.

## 4. The Great Answer
> *"Two tiers behind one `actor`. The memory tier is `NSCache<NSURL, UIImage>` — it's already thread-safe and evicts automatically under memory pressure. The disk tier lives in the `Caches` directory (purgeable by the OS, excluded from backup), with the TTL enforced by comparing the file's modification date on read; expired entries are deleted lazily on access.
>
> For 'never download twice,' the actor keeps a dictionary of in-flight `Task<UIImage, Error>` keyed by URL. If a request arrives for a URL that's already downloading, it awaits the *existing* task instead of starting a new one. The actor guarantees the check-then-insert on that dictionary is atomic.
>
> Read path: memory → disk (with TTL check) → network, promoting hits upward at each level."*

## 5. Driving the LLM

> **Plan:** "We're building `ImageCache` for a feed app: memory + disk tiers, 24h TTL, request coalescing. Before code: propose the actor's stored properties and the exact read-path order, and tell me which parts `NSCache` already solves so we don't reinvent them. No code yet."

> **Generate (piece 1):** "Implement the actor skeleton with the in-flight coalescing only: `func image(for url: URL) async throws -> UIImage`. Use a `[URL: Task<UIImage, Error>]` dictionary; make sure the task is removed on completion *and* on failure."

> **Generate (piece 2):** "Now add the disk tier in the Caches directory. TTL is enforced on read via the file's modification date. All file I/O stays inside the actor — do not introduce a `DispatchQueue`."

> **Review hook:** "Explain the failure path: if the download throws, is the failed Task evicted from the in-flight dictionary? If not, every future request for that URL awaits a corpse and fails forever."

**What you're watching for:** the LLM caching the *failed* Task (the classic coalescing bug), storing to `Documents`, wrapping `NSCache` access in redundant locks, or decoding images inside the actor without downsampling (fine here, but name it — it becomes the follow-up).

## 6. The Follow-Up (Mid-Interview Extension)
**Interviewer:** "Product wants the feed to show 4K originals scaled into 100×100 avatars, and users report the app being killed in the background after browsing. Extend your design."

## 7. The Ideal Discussion
> *"Those two facts are the same bug: decoding a 4K JPEG creates a ~30MB bitmap no matter how small the view is, and `UIImage(data:)` decodes at full resolution. The fix is downsampling at decode time with `CGImageSourceCreateThumbnailAtIndex`, sized to the target point size × screen scale — the 100×100 avatar becomes a ~120KB bitmap instead of 30MB.
>
> That changes the cache key: the same URL at different sizes is now different entries, so the memory tier keys on `(url, pixelSize)`. The disk tier keeps the *original* encoded bytes keyed by URL only — re-downsampling from local data is cheap; re-downloading is not.
>
> I'd also set `totalCostLimit` on the `NSCache` using bytes-per-pixel as the cost, and I'd verify the win in Instruments' Allocations track before claiming victory — 'it feels smoother' is not evidence."*
