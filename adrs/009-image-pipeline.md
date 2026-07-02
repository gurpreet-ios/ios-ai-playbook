# ADR 009: Downsampling Image Pipeline with Bounded Caches

## Status
Accepted

## Context
The AI's default image code — `Data(contentsOf:)` into `UIImage(data:)` inside a view body — synchronously decodes full-resolution images on the main thread. It demos fine and jetsams mid-range devices (Chapter 15's stutter hunt; Chapter 16's kill taxonomy). `AsyncImage` fixes the blocking but not decode size, cache bounds, or request coalescing.

## Decision
All remote imagery goes through one **`ImageLoader` actor**: fetch via `URLSession`, decode with `CGImageSourceCreateThumbnailAtIndex` **at the target pixel size** (never full-res), memory-cache in `NSCache` with byte-cost accounting and `totalCostLimit`, coalesce concurrent requests per URL via an in-flight task map (evicting failed tasks), and respond to memory-pressure notifications by purging. Views consume it with `.task(id:)` so cell reuse cancels loads. No view body performs I/O or decoding — ever.

## Consequences
**Positive:**
- Scroll hitches and jetsam risk drop an order of magnitude (160pt thumbnail ≈ 100KB vs ≈ 9MB full-res decode).
- One choke point for instrumentation (Ch 33) and for policy changes (disk tier, TTL).

**Negative:**
- More code than `AsyncImage`; prefetching and disk tiering are explicit follow-on work when profiling demands them.
- Target sizes must be passed down — a small API tax on every image view.

## AI Anchor Usage
Inject when generating any view that displays remote images, or when reviewing image-adjacent diffs. Anchor phrase: *"All artwork goes through `ImageLoader` at an explicit target size — flag any `Data(contentsOf:)`, full-res decode, or unbounded cache as a violation."*
