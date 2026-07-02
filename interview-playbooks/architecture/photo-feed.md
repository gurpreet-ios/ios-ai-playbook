# Mock Interview: Photo Feed (Instagram-Style)

## 1. The Prompt
**Interviewer:** "Design an Instagram-style photo feed: infinite scroll, mixed image sizes, likes, and it has to scroll at 120Hz on a five-year-old phone. Walk me through the architecture, then we'll build a slice of it."

## 2. Expected Reasoning
"Photo feed" is the canonical composite question — it's pagination + image pipeline + memory budget wearing one trench coat. The interviewer is checking whether you decompose it into the three independent systems it actually is:
1. **The data spine** — paginated feed items from the API, cached, with mutations (likes) applied by ID.
2. **The image pipeline** — download → decode → downsample → cache, completely decoupled from the feed data.
3. **The render budget** — what work is allowed per cell appearance, and what must be precomputed or prefetched.

Candidates who treat it as one system produce the app that jetsams at post #200.

## 3. The Poor Answer
> *"SwiftUI `LazyVStack` in a `ScrollView`, each cell has an `AsyncImage` pointing at the CDN URL. Page when the last cell appears. Likes just PATCH the API and update the item. `LazyVStack` only renders what's visible so memory is handled."*

**Why it's poor:** `AsyncImage` has no cross-cell cache, no downsampling, and no prefetch — every scroll-back re-downloads, and full-resolution decodes blow the memory budget (`Lazy` containers release views, not decoded bitmaps held by caches). Paging on the *last* cell means a visible wall. And "PATCH and update" with no optimistic state means every like feels like a 400ms lag.

## 4. The Great Answer
> *"Three systems with narrow interfaces.
>
> **Data spine:** cursor-paginated `FeedRepository` backed by a store keyed by post ID — the pages hold IDs, the store holds the posts. Likes are optimistic ID-keyed mutations with rollback; because pages reference the store, a post appearing on page 2 and page 5 can't disagree about its like state.
>
> **Image pipeline:** a dedicated `ImageLoader` actor (this is the image-cache playbook embedded in a bigger question): memory tier in `NSCache`, disk tier with TTL, in-flight request coalescing, and — the load-bearing part — downsampling at decode time to the cell's pixel size. A 4K original becomes a ~300KB bitmap instead of 30MB. The feed never sees `UIImage(data:)`.
>
> **Render budget:** cells are dumb — no formatting, no decoding, no layout math in `body`. Precompute display models (formatted counts, relative dates) when the page arrives, off the main actor. Prefetch: when item N appears, warm images for N+1…N+6 through the same coalescing loader, and *cancel* warms for items that scrolled away — prefetch without cancellation is just a bandwidth leak."*

## 5. Driving the LLM

> **Plan:** "Photo feed at 120Hz on old hardware. Before code: list every piece of work that could happen during cell appearance (decode, format, layout, fetch), and classify each as: precompute at page-load, prefetch, or allowed in body. That classification is our render budget — we'll enforce it in review. No code yet."

> **Generate (piece 1):** "The display-model layer: `FeedItemDisplay` (precomputed strings, target pixel size) built from the DTO page off the main actor. Then `FeedViewModel` with the cursor state machine from our pagination pattern."

> **Generate (piece 2):** "The cell: image via our injected `ImageLoader` actor with `.task`-scoped lifetime (cancel on disappear), like button with optimistic toggle + rollback closure. `let _ = Self._printChanges()` under a DEBUG flag so we can watch re-renders."

> **Review hook:** "Audit your own cell for render-budget violations: anything allocating, formatting, or decoding in `body`? Any state observed by the cell that changes more often than the cell's own content?"

**What you're watching for:** `AsyncImage` sneaking in, `DateFormatter()` allocated per cell (the Ch 16 classic), prefetch with no cancellation, and likes mutating the array element in place in a way that re-renders every visible cell instead of one.

## 6. The Follow-Up (Mid-Interview Extension)
**Interviewer:** "Product adds a stories rail at the top and autoplaying video posts. Memory incidents spike in the field. Where do you look, and what changes?"

## 7. The Ideal Discussion
> *"Autoplay video changes the budget class entirely: an `AVPlayer` pipeline is tens of MB each, so the invariant becomes 'at most one live player' — the most-visible video plays, others show poster frames (which ride the existing image pipeline). Scroll velocity gates playback: nothing autoplays while flinging.
>
> The stories rail is an embedded horizontal feed — it must share the image loader and its budget, not instantiate its own; two uncoordinated caches is how you get evicted by jetsam while both report healthy sizes.
>
> For the field incidents: MetricKit memory reports and a jetsam-vs-crash triage first — my hypothesis stack is (1) decoded video/poster frames not downsampled, (2) `NSCache` cost limits never set so 'cache' means 'leak with better branding', (3) players not torn down on disappear. I'd verify with Instruments' Allocations against a scripted scroll, fix in that order, and re-measure — the field metric, not the vibe, decides when we're done."*
