# The AI-Native Interview Playbook

Structured mock interviews for Senior/Staff iOS interviews at AI-native companies. Every playbook is a full script — not a Q&A pair. Practice them **out loud**, ideally with a real LLM session open so you can rehearse the prompt sequences, not just the answers.

## The Two Question Types

Real vibe-coding interviews almost always take one of two shapes (see [Chapter 18](../handbook/18-ai-native-interviews.md)):

1. **Build from scratch** (the `machine-coding/` and `architecture/` playbooks): a product requirement, an LLM, and ~45 minutes. You plan the architecture *with* the LLM before any code, generate one logical piece at a time, and review everything it produces.
2. **Debug the unfamiliar codebase** (the `debugging/` playbooks): an existing app you have never seen and a vague symptom — "the feed stutters," "users see stale data." You use the LLM to build context fast, form a hypothesis *before* touching fixes, trace it, fix it, and defend the root cause.

The shared spine for both is the **Plan → Review → Fix** loop. The interviewer is not testing whether you can write code; they are testing whether you can *drive* — and whether you catch the LLM's mistakes before they ship.

## Structure of Every Playbook

1. **The Prompt** — the ambiguous question exactly as the interviewer asks it.
2. **Expected Reasoning** — what is actually being evaluated.
3. **The Poor Answer** — the common pitfall.
4. **The Great Answer** — the Senior response.
5. **Driving the LLM** — the vibe-coding prompt sequence for this exact question (Plan → Review → Fix).
6. **The Follow-Up** — the mid-interview extension ("now add offline mode"). This is intentional: interviewers test whether you can keep driving the LLM into new territory without breaking the existing design.
7. **The Ideal Discussion** — a transcript of the tradeoff conversation a Staff engineer would have.

## Index

### Machine Coding (`machine-coding/`)
| Playbook | Core skills tested |
| :-- | :-- |
| [Rate Limiter](machine-coding/rate-limiter.md) | Actor isolation, token bucket vs sliding window |
| [Image Cache with TTL](machine-coding/image-cache-ttl.md) | Two-tier caching, eviction, request coalescing |
| [Debounced Search](machine-coding/debounced-search.md) | Task cancellation, stale responses, async sequences |
| [Pagination](machine-coding/pagination.md) | Cursor vs offset, prefetching, in-flight guards |
| [Download Manager](machine-coding/download-manager.md) | Background URLSession, resume data, queue limits |

### Architecture (`architecture/`)
| Playbook | Core skills tested |
| :-- | :-- |
| [Offline-First Chat](architecture/offline-first-chat.md) | Local-first sync, conflict resolution, ordering |
| [Photo Feed](architecture/photo-feed.md) | Image pipeline, memory budget, prefetching |
| [Live Sports App](architecture/live-sports-app.md) | Real-time transport, reconnection, snapshot + delta |

### Code Review (`code-review/`)
| Playbook | Core skills tested |
| :-- | :-- |
| [The Sneaky Retain Cycle](code-review/retain-cycle.md) | Memory graph reasoning, weak vs unowned |
| [The Hidden Data Race](code-review/data-race.md) | Sendable, actor isolation, `@unchecked` abuse |
| [The SwiftUI Over-Render](code-review/swiftui-over-render.md) | Render loop, state scoping, Observation granularity |

### Debugging (`debugging/`) — the second question type
| Playbook | Core skills tested |
| :-- | :-- |
| [The Feed Scroll Stutter](debugging/feed-scroll-stutter.md) | Context-building, main-thread work, Instruments |
| [Stale Data After Logout](debugging/stale-data-after-logout.md) | State ownership, cache inventory, session teardown |
| [Crash on Older Devices](debugging/crash-on-older-devices.md) | Memory pressure vs availability, crash-log triage |
