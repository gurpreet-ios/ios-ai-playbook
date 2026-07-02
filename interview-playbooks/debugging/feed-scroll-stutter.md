# Mock Interview: Debugging — The Feed Scroll Stutter

*(Question Type 2: you are handed an unfamiliar codebase and a vague symptom. The evaluated skill is context-building speed and hypothesis discipline — not how fast you start editing.)*

## 1. The Prompt
**Interviewer:** "Here's our app — about 40 files, you've never seen it. Users report: 'the home feed stutters when scrolling, especially on mid-range devices.' You have the repo and an LLM. Find it and fix it."

## 2. Expected Reasoning
The interviewer scores four behaviors, in order:
1. **Context-building via the LLM, not file-spelunking.** Reading 40 files yourself burns the whole interview; asking the LLM to map the rendering path takes two minutes.
2. **A stated hypothesis before any fix.** "Stutter while scrolling" has a short, known suspect list: synchronous work in cell render (formatting, decoding), full-resolution image decode, over-invalidated view trees, main-thread I/O.
3. **Evidence before surgery.** Naming the tool that would confirm each hypothesis (Time Profiler, SwiftUI Instrument, `_printChanges`) even if the interview is code-only.
4. **Root-cause articulation + regression guard** at the end — not just "it's fixed."

## 3. The Poor Answer
> *"Let me open the feed view file… I'll paste it into the LLM and ask it to 'optimize this for performance.' It suggests LazyVStack, some `.drawingGroup()`, caching — I'll apply those and see if it feels better."*

**Why it's poor:** No hypothesis, no evidence, shotgun fixes. "See if it feels better" on the interviewer's laptop proves nothing about mid-range devices. And a vague "optimize this" prompt invites the LLM to rewrite architecture — the Chapter 17 failure mode — leaving a diff nobody can review against a bug nobody has characterized.

## 4. The Great Answer
> *"Before touching anything I'll narrow the search space, because 'scroll stutter' means per-frame work exceeding the frame budget — so the bug lives on the render path, and mid-range-only means it's CPU/memory-bound work that flagship chips absorb.
>
> I'll have the LLM map that path: which views render feed cells, where cell data comes from, and what work happens per cell appearance. From the known suspect list — formatter/object allocation in body, synchronous image decode, main-thread I/O, whole-tree invalidation — I'll rank hypotheses against what the map shows, state the top one explicitly, and confirm it in the code (or name the Instruments track that would confirm it on-device) before prescribing a one-line-scope fix. Then: fix, explain why it's the root cause and not a symptom, and add the guard that stops it regressing."*

## 5. Driving the LLM

The context-building sequence — this is the section to rehearse out loud:

> **Map (don't read):** "Give me a high-level map of this codebase's home feed: which view renders the list, which type provides its data, and every piece of work that executes per cell appearance — formatting, image handling, anything. File names and line references only; no fixes yet."

> **Rank suspects:** "The symptom is scroll stutter on mid-range devices. Given your map, rank these hypotheses by likelihood with evidence from the code: (a) allocation/formatting in cell body, (b) full-res image decode on main, (c) screen-level state invalidating all cells, (d) main-thread disk/DB reads. Cite the exact lines that support or kill each."

> **Confirm the winner:** "You ranked (a): `FeedCellView` constructs a `DateFormatter` and runs `AttributedString` markdown parsing in `body`. Show me the call path from scroll to that work, and estimate why flagship devices mask it. If the evidence is weak, say so — do not confirm my bias."

> **Fix (bounded):** "Fix exactly this: hoist the formatter to a `static let`, precompute the attributed body when the model loads (off the main actor), leave everything else untouched. Then list what you did NOT fix that we should file — e.g., the images are still decoded full-res."

> **Verify + guard:** "Describe the on-device verification: Time Profiler before/after on the scroll gesture, expecting the `FeedCellView.body` samples to collapse. Then add a DEBUG `Self._printChanges()` and a comment banning allocation in this body."

**What you're watching for:** the LLM inventing performance folklore (`.drawingGroup()` as a talisman), fixing by rewriting the ViewModel layer, or agreeing with your hypothesis instantly without citing lines — sycophancy is a debugging hazard; the "if the evidence is weak, say so" hook counters it.

## 6. The Follow-Up (Mid-Interview Extension)
**Interviewer:** "Your fix ships. A week later the same report comes back — but now only when users scroll fast, and the profiler shows nothing in your cell code. Extend your diagnosis."

## 7. The Ideal Discussion
> *"New symptom, new hypothesis — I don't get to reuse the old diagnosis. 'Fast scroll only' plus 'clean cell profile' points off the CPU: most likely image decode pressure (fast scroll churns more images per second than the pipeline can decode off-main, and the jank is memory/IO contention, not body time) or cell churn allocating per-appearance objects that GC-era intuitions miss — Swift's refcounting shows this as `swift_release` noise across the profile rather than one hot frame.
>
> Diagnostic move: switch tracks. The SwiftUI Instrument for invalidation counts during fast scroll, Allocations for transient spikes, and the hitch-rate metric in Xcode's Organizer — because 'stutter' should now be measured as hitch time ratio, not vibes. If it's decode pressure, the fix is the image pipeline's job: downsampling plus prefetch-with-cancellation keyed to scroll velocity — and notably, that was on the 'did NOT fix' list we filed in the first pass, which is exactly why that list exists.
>
> The meta-answer the interviewer wants: performance debugging is a loop, not an event — hypothesis, instrument, fix, re-measure, and each fix's leftover list seeds the next hypothesis ranking."*
