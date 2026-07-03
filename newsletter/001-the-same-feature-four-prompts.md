# The same feature, four prompts

**Subtitle:** "Add offline caching to a network request" — asked the way a junior, a mid-level, a senior, and a staff engineer would ask it. The code you get back is wildly different, and the difference is not the model.

---

The bottleneck in iOS development has moved. It is no longer typing Swift — the machine types faster than any of us. The bottleneck is *specifying* Swift: defining the problem, engineering the context, and reviewing what comes back.

Here's the cleanest way I know to show what that actually means. One task, four prompts. Same model, same codebase, four completely different outcomes.

**The task:** add a caching layer to a network request.

## Level 1 — The Junior

> "Add caching to my fetch request so it works offline."

The result: the AI hallucinates a brand-new network client, imports a random caching library you've never heard of, and cheerfully breaks your existing architecture. You spend an hour untangling it and conclude "AI coding is overrated."

The model didn't fail. The prompt gave it a solution space the size of the internet, and it picked the internet's average answer.

## Level 2 — The Mid-Level

> "Here is `NetworkManager.swift`. I need to add offline caching to `fetchUserProfile()`. Use `NSCache` for now. Don't break the existing async/await structure."

Better. The AI touches the right file and preserves the structure. But `NSCache` is memory-only — nothing persists across launches, so "works offline" quietly isn't true. And it ignored your company's existing caching protocol, because it had no way to know one existed.

This is the level most engineers plateau at: the prompt names the *what*, but the *constraints* and the *house rules* still live only in the engineer's head.

## Level 3 — The Senior

> "We need to implement offline caching for `fetchUserProfile()` in `NetworkManager.swift`.
>
> **Context:**
> 1. Attached is `NetworkManager.swift`.
> 2. Attached is `CacheProvider.swift` (our internal protocol).
>
> **Constraints:**
> - Implement `CacheProvider` using `FileManager` for disk persistence, not memory.
> - Ensure all disk I/O happens on a background `Task`.
> - If the cache is older than 24 hours, throw `CacheError.expired`.
>
> Write the implementation."

The result is a highly specific, architecturally compliant implementation that needs minimal review.

Notice what changed. Two things:

**Context anchors.** The prompt doesn't describe the architecture — it *attaches* it. `CacheProvider.swift` is worth a thousand words of prose, because interfaces and protocol headers are the densest form of context there is. You don't feed the model 10,000 lines of implementation; you feed it the types.

**Constraints as negative context.** "Disk, not memory." "Background task." "Throw after 24 hours." Every constraint aggressively shrinks the solution space, and a smaller solution space means fewer places for the model to hallucinate. Junior prompts describe the destination; senior prompts also fence off the cliffs.

## Level 4 — The Staff Engineer

Here's the part that surprises people: the staff engineer doesn't write a better version of the Level 3 prompt. They stop writing prompts manually at all.

> "Execute the `/feature-setup` agent workflow.
>
> **Objective:** Add disk-based offline caching to user profiles.
>
> **Context Anchors:**
> - Read the ADR: `docs/ADRs/004-offline-first-architecture.md`
> - Read the Interface: `Protocols/CacheProvider.swift`
> - Target File: `Network/NetworkManager.swift`
>
> **Execution Plan:**
> 1. Generate the implementation.
> 2. Run the `AI Code Review` prompt against the generated code, specifically checking for race conditions during concurrent disk writes and duplicate in-flight fetches when several views miss the cache simultaneously (requests must coalesce).
> 3. Generate unit tests mocking the file system.
> 4. Summarize the changes in `docs/changelog.md`."

The AI reads the recorded architectural decisions, writes the code, reviews its own output for the two race conditions that actually matter here, writes the tests, and updates the docs. The human reviews the final PR.

The difference at this level isn't prompt-writing skill — it's *infrastructure*. Architecture Decision Records the agent can read. A review prompt that encodes what "good" means in this codebase. A workflow that chains them. The staff engineer's leverage is that the Level 3 prompt now writes itself, every time, for every feature.

## The ladder, compressed

| Level | What the prompt contains | What you get back |
| :-- | :-- | :-- |
| Junior | A wish | The internet's average answer |
| Mid | The right file + the what | Plausible code that ignores your house rules |
| Senior | Context anchors + constraints | Compliant code, minimal review |
| Staff | A system that assembles all of the above | A reviewed, tested PR |

Two principles carry the whole ladder:

1. **Precision beats volume.** Million-token context windows tempt you to dump the repo in. Don't — models weight the beginning and end of context heavily and lose the middle. Three carefully chosen files beat three hundred.
2. **The best context is the context you wrote down before the prompt existed.** ADRs, protocol definitions, rules files. The Level 4 prompt is only possible because the architecture was recorded somewhere an agent could read it.

If you take one action from this post: next time you're about to prompt for a feature, write the constraints line first. What must it *not* do? That single habit moves you a full level.

---

*This is the first post in a series on AI-native iOS engineering. Everything here is from my open-source playbook — 38 chapters, 41 production prompt systems, installable agent skills, and three sample apps with CI, all free: [github.com/gurpreet-ios/ios-ai-playbook](https://github.com/gurpreet-ios/ios-ai-playbook). Star it if it's useful.*

*Next week: the data race Swift 6 refused to compile — and why your AI pair programmer keeps writing it anyway. Subscribe so you don't miss it.*

---
---

## Publishing notes (strip before posting)

- **Substack title:** The same feature, four prompts
- **Subtitle options:** the one above, or shorter: "What seniority actually looks like when the machine writes the Swift."
- **Cross-post targets:** r/iOSProgramming (frame as "how I structure prompts for iOS work — one task at four levels"), X/Twitter thread (the four prompts make a natural 6-tweet thread ending on the table), Hacker News only if reworked with a less listicle-ish framing.
- **Source:** [handbook/03-context-engineering.md](../handbook/03-context-engineering.md) — the post is the chapter's "Evolution of Context" section expanded with the principles from its first half.
- **CTA mechanics:** add Substack's subscribe button after the italic footer; the repo link goes in both the footer and your Substack "About" page.
