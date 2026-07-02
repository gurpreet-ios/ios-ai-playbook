# AI Architecture Breakdown: Instagram

## The Core Challenge

A feed that scrolls at 120Hz while every cell carries full-bleed imagery, backed by an infinite paginated dataset, with interactions (likes) that must feel instant on flaky networks. Three hard problems wearing one UI: the **image pipeline** (bytes → downsampled pixels, off main), the **data spine** (cursor pagination without duplicates or gaps), and **optimistic mutation** (local truth ahead of server truth, with rollback). Decompose along those lines and each piece is prompt-sized; prompt for "an Instagram feed" and you get a monolith that stutters.

## The Core Domain

`Post` (id, author, caption, image *references* — never image bytes in the model), `FeedPage` (`posts: [PostDTO]`, `nextCursor: String?` — the cursor's optionality encodes "end of feed"), `LikeState` (local count + pending flag). The separation of `Post` from its pixels is the load-bearing decision: models are cheap and cacheable, decoded images are 4-bytes-a-pixel expensive and belong to a dedicated cache with eviction.

## The Architecture Decisions (state them before prompting)

| Decision | Choice | Why |
| :--- | :--- | :--- |
| Pagination | Cursor-based, state machine (`idle(next:)` / `loading` / `failed(retry:)` / `exhausted`) | Offsets break under insertions; the enum makes double-fetches unrepresentable |
| Images | Two-tier cache (`NSCache` + disk) inside an `actor`, decode-time downsampling | Full-res decodes are the #1 scroll killer and jetsam source |
| Mutations | Optimistic with explicit rollback path | Perceived latency is the product; failure must revert *and explain* |
| Cell isolation | Per-post `@Observable`, rows read only their own post | A like on cell #1 must not re-evaluate cell #40 |

## The Prompt Sequence

### 1. The Image Pipeline (before any UI — it's the hardest dependency)

> **Prompt:** "Generate an `ImageCache` **actor**: `image(for url: URL, targetSize: CGSize, scale: CGFloat) async throws -> UIImage`. Memory tier: `NSCache` with `totalCostLimit` and byte-cost accounting. Disk tier: hashed filenames in Caches. Decode with `CGImageSourceCreateThumbnailAtIndex` at the target pixel size — never decode full-res. **Coalesce concurrent requests** for the same URL via an in-flight `[URL: Task]` dictionary, and evict failed tasks from it so one timeout doesn't poison the URL forever."

**Watch for:** the failed-`Task` poisoning bug (a cached failed task replays its error forever) and decode happening after a full-res `UIImage(data:)` — downsampling must happen *during* decode or the memory win is fictional. This layer alone is a machine-coding interview: [`interview-playbooks/machine-coding/image-cache-ttl.md`](../interview-playbooks/machine-coding/image-cache-ttl.md).

### 2. The Pagination Engine

> **Prompt:** "Generate a `FeedRepository` with cursor pagination. Page state is an enum: `idle(nextCursor: String?)`, `loading`, `failed(retryCursor: String?)`, `exhausted` — `loadNextPage()` is a no-op unless state is `idle`. Trigger the next load when the user reaches the 5th-from-last item. De-duplicate posts by id across pages (the server may shift items between pages). Pull-to-refresh resets to page one and must cancel any in-flight next-page load before replacing the array."

**Watch for:** the refresh/next-page race (a stale page appended after a refresh reintroduces deleted posts) and a boolean `isLoading` where the enum should be — booleans are how double-fetch bugs are born. Full script: [`interview-playbooks/machine-coding/pagination.md`](../interview-playbooks/machine-coding/pagination.md).

### 3. Optimistic Likes

> **Prompt:** "Implement like/unlike on `PostViewModel`: toggle the local state and count immediately, then fire the request. On failure: revert the exact delta (not a blind refetch), surface a non-blocking toast, and leave the button enabled. **Rapid taps must collapse**: track the pending server op and send only the final desired state — never queue N requests for N taps."

**Watch for:** the AI reverting by refetching the whole feed (jarring scroll reset), and the rapid-tap queue — five taps producing five racing requests whose out-of-order completion leaves the heart in the wrong state. Ask it: *"the user taps 5 times in 300ms and request 2 fails — walk the state timeline."*

### 4. The Feed UI

> **Prompt:** "Feed as `LazyVStack` in a `ScrollView`. Each `PostCell` takes one `@Observable Post` and reads nothing screen-level. Images load through `ImageCache` with `.task(id:)` for reuse-cancellation, sized to the cell. A like mutates only that post object — verify with a DEBUG `Self._printChanges()` that neighboring cells do not re-evaluate."

**Watch for:** screen-level state (search text, a timer, the like of *any* post held in a screen-wide array) read inside the list body — the whole-feed invalidation of Chapter 11 / [`interview-playbooks/code-review/swiftui-over-render.md`](../interview-playbooks/code-review/swiftui-over-render.md).

### 5. The Verification Pass

> **Prompt:** "Swift Testing suites for: pagination state machine (no fetch while `loading`, retry from `failed`, `exhausted` terminal), like rollback restoring the exact prior state, and cache coalescing (two concurrent requests for one URL → one underlying load). Run `prompts/testing/tautology-audit.md` against your own output."

## The Failure Modes to Probe (interview extension bank)

- **Fast scroll** — decode pressure outruns the pipeline: does prefetching exist, and is it cancelled on direction change (velocity-keyed)?
- **Jetsam on mid-range devices** — what is peak decoded footprint for a screen of cells? (Cost-accounted `NSCache` or it's unbounded.)
- **Feed consistency** — a post deleted server-side appears via a stale page: who wins, cache or server?
- **Stories / video autoplay** (the classic extension) — a second media pipeline with play/pause driven by visibility: who tracks visible IDs, and does scrolling stay smooth with 3 autoplaying cells? See [`interview-playbooks/architecture/photo-feed.md`](../interview-playbooks/architecture/photo-feed.md) for the full mock-interview treatment of this design.

## Related Assets

- Interview simulations: [`photo-feed.md`](../interview-playbooks/architecture/photo-feed.md) (this design as an architecture interview), [`image-cache-ttl.md`](../interview-playbooks/machine-coding/image-cache-ttl.md), [`pagination.md`](../interview-playbooks/machine-coding/pagination.md), [`debounced-search.md`](../interview-playbooks/machine-coding/debounced-search.md)
- Chapters: 11 (render isolation), 15 (the image-decode stutter hunt — `ArtworkLoader` is this blueprint's layer 1 in miniature)
