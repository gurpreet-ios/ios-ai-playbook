# Mock Interview: Code Review — The SwiftUI Over-Render

## 1. The Prompt
**Interviewer:** "Users say this screen makes their phone warm and the scroll hitches. The feature works. Review the code."

```swift
struct FeedScreen: View {
    @State private var viewModel = FeedViewModel()
    @State private var now = Date()

    let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(viewModel.posts) { post in
                    VStack(alignment: .leading) {
                        Text(post.author)
                        Text(post.body)
                        Text(relativeTime(from: post.createdAt))
                            .font(.caption)
                    }
                    .padding()
                }
            }
        }
        .onReceive(clock) { now = $0 }
    }

    private func relativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: now)
    }
}
```

## 2. Expected Reasoning
The interviewer wants to hear you reason about **why SwiftUI re-evaluates a body** — dependency tracking, not magic. The kill chain here: the timer updates `now` every second → `now` is `@State` read by `body` → the *entire screen's* body re-evaluates every second → every visible cell re-runs, allocating a fresh `RelativeDateTimeFormatter` per row per second (formatters are notoriously expensive to create). The feature "works" — this is a review about performance-by-structure, and about knowing the diagnostic tools (`Self._printChanges()`, the SwiftUI Instrument) rather than eyeballing.

## 3. The Poor Answer
> *"SwiftUI diffs efficiently so the re-renders are probably fine — `LazyVStack` only renders visible cells anyway. The formatter allocation could move to a `static let`. Maybe the hitch is the images or the network layer; I'd profile before changing anything."*

**Why it's poor:** "Profile first" sounds senior but here it's deflection — the pathology is visible in the code: a 1Hz invalidation of the entire tree is structural, not speculative. And "diffing is efficient" confuses *render* cost with *body evaluation* cost: diffing only happens after every body in the hierarchy has re-run, which is exactly the CPU burn users feel as heat.

## 4. The Great Answer
> *"Three findings, one root cause: state is scoped to the wrong node.
>
> **The invalidation:** `now` changes every second and is read by the screen-level `body`, so the whole tree re-evaluates at 1Hz — while scrolling, that compounds with scroll-driven updates. The timestamp is per-row presentation detail; the *row* should depend on time, never the screen.
>
> **The allocation:** `RelativeDateTimeFormatter()` per row per tick. Formatters should be created once — `static let` or injected — and reused.
>
> **The design smell:** ticking wall-clock state to relabel '2m ago' is brute force. SwiftUI has a purpose-built answer: `Text(post.createdAt, style: .relative)` — the framework updates the label itself with no timer, no state, no body re-evaluation at all.
>
> Fix shape: delete `now` and the timer; extract `FeedRow` as its own view taking just `post`; use the relative text style. If product needs custom formatting the style can't do, isolate the timer inside the row (`TimelineView` scoped per-row) so a tick invalidates one row, not the screen. I'd verify with `Self._printChanges()` before and the SwiftUI Instrument after — the claim 'only rows re-render now' is checkable, so check it."*

## 5. Driving the LLM

> **Fix:** "Refactor for render isolation: (1) remove the `now` state and the Timer publisher entirely, (2) extract `FeedRow` as a separate view, (3) render the timestamp with `Text(_, style: .relative)`. Do not touch `FeedViewModel` or the data flow — this is a view-layer-only diff."

> **Review hook:** "Explain what `Text(_, style: .relative)` does under the hood that our timer couldn't — specifically, why it updates without invalidating any view's body."

> **Regression guard:** "Add a DEBUG-only `let _ = Self._printChanges()` to `FeedScreen` and `FeedRow`, and describe a 30-second manual check: idle on the feed, confirm the screen body logs nothing while row labels still tick."

**What you're watching for:** the LLM keeping the timer "but making it more efficient" (the disease survives), extracting `FeedRow` but passing `now` into it as a parameter (recreating the same 1Hz full-tree invalidation through arguments), or reaching for `EquatableView`/`.equatable()` as a band-aid over state that shouldn't exist.

## 6. The Follow-Up (Mid-Interview Extension)
**Interviewer:** "New requirement: rows now show a live view-count badge streamed over a socket, updating up to 10×/second across all visible rows. Your relative-time fix doesn't cover this. Extend the design."

## 7. The Ideal Discussion
> *"Now we genuinely have high-frequency shared state, so the question becomes *observation granularity* — which is what the `@Observable` macro actually buys us. If each `Post` is `@Observable` with a `viewCount` property, and only `FeedRow` reads it, then a count mutation invalidates exactly the rows displaying that post — SwiftUI tracks property-level reads per body. The screen, which never reads `viewCount`, never re-evaluates. The old `ObservableObject`/`@Published` world couldn't express this: any published property change invalidated every observer of the object.
>
> Two rate problems remain. First, 10Hz × 50 visible rows is 500 text updates a second — human eyes can't use that, so coalesce at the store: batch socket deltas and publish at most ~2Hz per post. Second, off-screen rows: the socket must not fan out to rows that don't exist; `LazyVStack` helps by not creating them, but the *store* should also only maintain hot subscriptions for visible IDs — `onAppear`/`onDisappear` on rows feeding a visible-set the socket layer respects.
>
> The through-line from the original bug to this extension is the same sentence: state changes should invalidate the smallest view that semantically depends on them — first we achieved it by deleting state, now we achieve it by scoping observation."*
