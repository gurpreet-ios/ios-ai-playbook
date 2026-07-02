# Mock Interview: Infinite-Scroll Pagination

## 1. The Prompt
**Interviewer:** "Build an infinitely scrolling feed backed by a paginated API. It should feel seamless — the user shouldn't hit a wall and wait. Handle failures. Drive the LLM."

## 2. Expected Reasoning
Pagination sounds trivial and is a minefield — that's why it's asked. The interviewer wants to see you name the failure modes *before* the LLM steps on them:
1. **Cursor vs offset** — offsets break when items are inserted/deleted between pages (duplicated or skipped rows); cursors don't.
2. **The in-flight guard** — `onAppear` on the trigger row fires repeatedly during scroll bounces; without a guard you request page 2 five times.
3. **Prefetch distance** — loading when the *last* row appears means a visible wall; trigger a few rows early.
4. **Failure UX** — page 3 failing must not nuke pages 1–2; it needs an inline retry row.

## 3. The Poor Answer
> *"I'll keep `var page = 1`. On the last row's `onAppear` I call `loadMore()`, which does `page += 1` and appends the response. If it fails I show an alert."*

**Why it's poor:** No in-flight guard (bounce = duplicate requests = duplicate rows = `ForEach` ID crash), offset-based (a new post while scrolling shifts every page), loads at the wall (visible hitch), and an alert for a page failure is hostile — the user was mid-scroll.

## 4. The Great Answer
> *"State first: the feed is `items: [Item]`, plus a single `pageState` enum — `.idle(nextCursor: String?)`, `.loading`, `.failed(retryCursor: String)`, `.exhausted`. Making 'is a page in flight' a state, not a boolean, eliminates the duplicate-request bug by construction: `loadMore()` is a no-op unless state is `.idle`.
>
> Cursor-based: the server returns `nextCursor`; `nil` means exhausted. Cursors survive concurrent inserts/deletes, which offsets don't.
>
> Trigger: not the last row — I compute a threshold (`item at count - 5`) and fire when it appears, so the next page usually lands before the user reaches the bottom. As defense-in-depth against server hiccups, appended items are de-duplicated by ID before insertion.
>
> Failure: `.failed` renders an inline footer row with a retry button holding the cursor that failed. Pages 1–2 stay on screen."*

## 5. Driving the LLM

> **Plan:** "Infinite-scroll feed, cursor-paginated API. Before code: model the page state for me as a Swift enum (in-flight, exhausted, and failed-with-retry must all be unrepresentable as contradictory combinations), and tell me where the load trigger should live and why not on the last row. No code yet."

> **Generate (piece 1):** "Implement `FeedViewModel` (`@MainActor @Observable`) with `loadInitial()` and `loadMoreIfNeeded(currentItem:)`. The in-flight guard must come from the state enum, not a separate boolean. De-dupe appended items by ID."

> **Generate (piece 2):** "Now the SwiftUI `List`: trigger row at 5-from-end, a footer that switches on pageState — spinner for `.loading`, retry button for `.failed`, nothing for `.exhausted`."

> **Review hook:** "Walk me through a scroll bounce that makes the trigger row appear three times in 200ms. Show me the exact line that makes calls two and three no-ops."

**What you're watching for:** `isLoading` booleans multiplying (`isLoadingMore`, `isRefreshing`…) instead of one state machine, `page: Int` sneaking back in, `.onAppear` on the literal last row, and duplicate-ID crashes the LLM won't mention until the `ForEach` throws at runtime.

## 6. The Follow-Up (Mid-Interview Extension)
**Interviewer:** "Add pull-to-refresh, and make likes work — a user can like any row while page 4 is loading. Neither may corrupt the list."

## 7. The Ideal Discussion
> *"Pull-to-refresh during pagination is a race: if refresh replaces `items` while a page-append is in flight, the append lands on top of the new dataset — duplicates or worse. The rule: refresh *cancels* any in-flight page task, resets state to `.idle(nextCursor: fresh)`, and replaces items atomically. That's one `Task` handle stored on the ViewModel and cancelled up front.
>
> Likes are why item identity matters: the like mutates one element in place — optimistic update, revert on failure. If we'd modeled rows as raw server DTOs scattered through pages, we'd be hunting array indices; with `Identifiable` items and ID-keyed updates it's a one-liner. And it's the argument for de-duplicating by ID on append: the same post appearing on page 2 and page 3 (server-side insert shifting content) would otherwise double-render and receive inconsistent like state.
>
> If the interviewer pushes further — 'what about the item updating on the server while it's on screen?' — that's the cue to talk about a single source of truth (an in-memory store keyed by ID that pages merely *reference*), which is the SwiftData/store-backed design, and I'd say explicitly that it's out of scope for 45 minutes but the natural next refactor."*
