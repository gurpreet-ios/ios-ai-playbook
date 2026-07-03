# Mock Interview: Photo Feed (Instagram-Style)

## 1. The Prompt

**Interviewer:** "Design an Instagram-style photo feed: infinite scroll, mixed image sizes, likes, and it has to scroll at 120Hz on a five-year-old phone. Walk me through the architecture, then we'll build a slice of it."

## 2. Expected Reasoning

At first glance this sounds like one feature: "show photos in a list." That's the trap. A photo feed is really **three separate problems stitched together**, and the interviewer is checking whether you can see the seams:

1. **The data problem** — fetching the feed one page at a time, remembering what you already have, and keeping things like like-counts correct when the user interacts.
2. **The image problem** — a photo goes through a whole journey before it can appear on screen: download the bytes → decode them into a bitmap → shrink that bitmap to the size the screen actually needs → keep it around so you don't repeat the work. This journey has nothing to do with feed logic and should be its own component.
3. **The performance problem** — at 120Hz, the screen redraws every **8 milliseconds**. Any work you do while a cell is appearing (decoding an image, formatting a date, running layout math) eats into those 8ms. So you need a *budget*: decide up front which work is allowed to happen during scroll, and push everything else to earlier (when the page loads) or elsewhere (a background thread).

Why does this decomposition matter so much? Because the two failure modes of a photo feed — janky scrolling and the app being killed for using too much memory — are both caused by mixing these systems together. Candidates who treat it as one system build the app that gets terminated by iOS around post #200.

(That termination is called a **jetsam**: iOS silently kills apps that use too much memory. It doesn't show a crash dialog — the app just vanishes, and users blame you.)

## 3. The Poor Answer

> *"SwiftUI `LazyVStack` in a `ScrollView`, each cell has an `AsyncImage` pointing at the CDN URL. Page when the last cell appears. Likes just PATCH the API and update the item. `LazyVStack` only renders what's visible so memory is handled."*

**Why it's poor:** every sentence contains a hidden landmine.

- **`AsyncImage` is a demo tool, not a pipeline.** It has no shared cache (scroll back up and every photo re-downloads), no downsampling (a 4K photo gets decoded at full resolution just to fill a 400-point cell), and no way to pre-warm images before they're needed.
- **"Lazy means memory is handled" is a half-truth.** `LazyVStack` releases *views* that scroll off-screen — but the decoded bitmaps living in caches and image views are what actually fill memory, and laziness does nothing about those.
- **Paging when the *last* cell appears is too late.** The user is already staring at the bottom of the content; now they get a spinner. Pagination should trigger several items *before* the end, so new content arrives while they're still scrolling toward it.
- **"PATCH and update" makes every like feel broken.** If the heart only fills in after the server round-trip, the user taps and waits ~400ms staring at an unfilled heart. Likes must update the UI *instantly* and reconcile with the server afterwards.

## 4. The Great Answer

> *"I'd build this as three systems that talk through narrow interfaces — because the failure modes here come from letting them bleed into each other.*
>
> ***The data spine.*** *A `FeedRepository` that pages with a cursor — the server gives us an opaque 'continue from here' token, which survives insertions and deletions where page numbers don't. The key structural decision: pages don't hold posts, they hold post IDs. The posts themselves live once in an ID-keyed store. So if the same post shows up on page 2 and page 5, there's one copy and one truth — its like state can't disagree with itself.*
>
> *Likes are **optimistic**: flip the heart and bump the count immediately, send the request in the background, and keep a tiny rollback closure so a server failure snaps the UI back and tells the user. The user gets a 0ms like; correctness is preserved.*
>
> ***The image pipeline.*** *A dedicated `ImageLoader` actor — this is the classic image-cache interview question embedded inside a bigger one. It has four jobs: a fast in-memory cache (`NSCache`, so iOS can evict under pressure), a disk cache with expiry for scroll-backs and relaunches, request coalescing — if six cells want the same image, that's one download, not six — and, the single highest-impact line in this whole design: **downsample at decode time**. Decode the image directly to the pixel size of the cell that will show it. A 4K original becomes a ~300KB bitmap instead of ~30MB. That one decision is usually the difference between a healthy feed and a jetsam. The feed layer never touches raw image data — it asks the loader for 'this URL at this size' and gets back a ready-to-render image.*
>
> ***The render budget.*** *Cells are dumb renderers: no formatting, no decoding, no layout math while scrolling. When a page arrives, we precompute a display model off the main thread — '1.2M likes', '3h ago', the target pixel size — so appearing on screen is just assignment. And we prefetch: when item N becomes visible, start warming images N+1 through N+6 through the same coalescing loader — and **cancel** the warms for items the user scrolled away from. Prefetch without cancellation isn't an optimization; it's a bandwidth leak with good intentions."*

## 5. Driving the LLM

The interview isn't just "do you know the answer" — it's "can you get an AI to build it without letting it smuggle the poor answer back in." The sequence:

> **Plan (before any code):** "Photo feed at 120Hz on old hardware. Before writing code: list every piece of work that could happen at the moment a cell appears — decoding, string formatting, layout, network fetch. Classify each as: precompute at page-load, prefetch ahead of scroll, or allowed during cell appearance. That classification is our render budget; we'll enforce it in review. No code yet."

> **Generate (piece 1 — data):** "Build the display-model layer: `FeedItemDisplay` with precomputed strings and target pixel size, constructed from the DTO page off the main actor. Then `FeedViewModel` with the cursor-pagination state machine."

> **Generate (piece 2 — the cell):** "Now the cell: image loaded through our injected `ImageLoader` actor with `.task`-scoped lifetime so it cancels when the cell disappears; like button with optimistic toggle and a rollback closure. Add `let _ = Self._printChanges()` under a DEBUG flag so we can watch what re-renders."

> **Review hook (make the AI audit itself):** "Audit your own cell for render-budget violations: anything allocating, formatting, or decoding inside `body`? Is the cell observing any state that changes more often than the cell's own content?"

**What you're watching for in the output:** `AsyncImage` sneaking back in, a `DateFormatter()` allocated per cell (allocating one is surprisingly expensive, and per-cell allocation during scroll is the classic Chapter 16 jank source), prefetch with no cancellation path, and a like implementation that mutates the array so every visible cell re-renders instead of just the one that was tapped.

## 6. The Follow-Up (Mid-Interview Extension)

**Interviewer:** "Product adds a stories rail at the top and autoplaying video posts. Memory incidents spike in the field. Where do you look, and what changes?"

## 7. The Ideal Discussion

> *"Video changes the economics of the whole design. A decoded image costs hundreds of KB; a live `AVPlayer` pipeline costs tens of MB. So the invariant flips from 'cache as much as fits' to **'at most one live player at a time'** — the most-visible video plays, every other video post shows a poster frame, and poster frames are just images, so they ride the existing pipeline for free. I'd also gate playback on scroll velocity: while the user is flinging the feed, nothing should autoplay — they can't watch it anyway, and we'd be creating and destroying players at scroll speed.*
>
> *The stories rail looks like a new feature but is architecturally an old one: a second feed, horizontal, embedded in the first. The rule that matters is that it must **share** the image loader and its memory budget, not instantiate its own. Two uncoordinated caches is a classic field failure: each stays under its own limit, their sum gets the app jetsammed, and both report healthy sizes in your metrics while it happens.*
>
> *For the field incidents, I'd resist the urge to jump straight to a fix. First: MetricKit memory reports, and triage whether these are jetsams or real crashes — they have different causes and different fixes. Then I have a ranked hypothesis list: (1) video poster frames or decoded video frames not being downsampled, (2) `NSCache` cost limits never set — an unbounded cache is just a leak with better branding, (3) players not torn down when their cell leaves the screen. I'd verify with Instruments' Allocations against a scripted scroll session, fix in that order, and re-measure. The field metric decides when we're done — not the vibe on my test device."*
