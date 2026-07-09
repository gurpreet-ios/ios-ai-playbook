# Chapter 20c: The Autonomous Delivery Pipeline

> "The pipeline that turns a vague story into a merged PR isn't an autonomy engine bolted to your codebase. It's a *specification factory* bolted to an autonomy amplifier — and the factory is the hard part."

[Chapter 20b](20b-autonomy-levels.md) delegated *one bounded task*: you hand the agent a crisp work order, it runs the inner loop, you review the PR. This chapter chains the whole delivery line — **vague user story → RFC → iOS tasks in Jira → self-iterating code → PR → code review** — so that a single story, dropped in one end, comes out the other as a reviewed pull request.

The moment that chain runs without a human kicking off each step, you have left Level 3. Self-triggering from a work source is the definition of **Level 4 — Orchestrated** ([Chapter 20b §2](20b-autonomy-levels.md#2-the-five-rungs)). Mechanically, the pipeline is a [prompt chain (Chapter 8)](08-prompt-chaining.md) that reaches across tools — Jira and GitHub over [MCP (Chapter 21)](21-tool-calling-mcp.md). But the engineering that makes it *safe* is almost entirely at the front.

---

## 1. The counterintuitive law: the bottleneck is specification, not code

Hand an LLM a vague story — *"let users favorite tracks"* — and it will not stall on the ambiguity. It will **fill every gap with a silent assumption** and generate confident, well-tested code for a feature nobody asked for. Code generation is the easy 20% of this pipeline. The hard, load-bearing 80% is manufacturing enough *specification* to make the generation safe.

This is [Chapter 20b's](20b-autonomy-levels.md#1-two-ladders-not-one) core law turned into a warning: **you cannot raise autonomy faster than specification, and a vague story is minimum specification.** So a pipeline that runs *vague → autonomous code* is the exact anti-pattern — **unless its first stage's entire job is to raise the specification** before any autonomy is spent. Get that stage right and everything downstream is mechanical. Get it wrong and you have built a very fast, very expensive way to ship the wrong thing.

---

## 2. Why the front gate is the cheapest control point

The economics are the classic "shift-left," and they are *sharper* with agents than with humans. Trace where one wrong assumption gets caught:

| Caught at… | What you've burned |
| :-- | :-- |
| **Gate A (spec review, S1)** | One clarifying question. Cents. |
| S3 (self-iterating code) | Agent tokens + local build/test cycles for throwaway code |
| S5 (review) | The above + reviewer attention + a rejected PR |
| **After merge** | The above + a revert + the *right* feature built again from scratch |

An agent doesn't get tired or cheaper on the retry — it costs the same tokens to build the wrong thing as the right thing, and then *again* to build the right one. A wrong assumption is never a 1× waste; it's **wrong work plus redo**, compounding the further right it's caught (see [Chapter 35 on agentic cost](35-agentic-security-and-cost.md)). That single fact justifies the whole design: **spend a human's two minutes at the front to avoid an agent's dollars at the back.**

---

## 3. The pipeline at a glance

| # | Stage | Agent does | Tool / artifact | Human gate |
| :-- | :-- | :-- | :-- | :-- |
| S1 | **Story → contract** | Grounds, interrogates, writes an RFC with testable acceptance criteria | Terminal agent + [`rfc-template.md`](../templates/rfc-template.md) | **🔒 GATE A — approve the spec** |
| S2 | **Contract → work orders** | Decomposes into layered, bounded iOS subtasks, tests-first | Jira MCP | (folds into Gate A) |
| S3 | **Work order → code** | The local Level-3 loop: plan→edit→`xcodebuild test`→fix→green | Terminal agent + [`AGENTS.md`](../AGENTS.md) | exception only |
| S4 | **Raise PR** | Opens PR, auto-fills the AI-context + machine-review checklist | GitHub MCP + [`pr-template.md`](../templates/pr-template.md) | exception only |
| S5 | **Code review** | Reviews against `AGENTS.md` + ADRs; iterates on comments | [`claude-autonomy.yml`](../.github/workflows/claude-autonomy.yml) | **🔒 GATE B — approve the merge** |

Two gates are human and stay human; everything between is delegable *if the substrate from Chapter 20b exists.* The rest of this chapter is mostly about S1 and S2, because that is where the pipeline is won or lost.

---

## 4. S1 — Story → a testable contract

S1 has exactly one job: **convert ambiguity into a contract whose acceptance criteria are machine-checkable.** Those criteria become the definition-of-done that S3's self-iterating loop verifies against — so a vague criterion here poisons the entire downstream loop. Four steps, walked through the story *"let users favorite tracks"*:

**1. Ground before asking.** The agent first answers what the codebase and ADRs already decide, so it only spends a human's attention on genuine unknowns. It reads `adrs/` and the existing layers — *"persistence is governed by the SwiftData ADR; a `TrackRepository` and `LibraryViewModel` already exist to extend."* Half the would-be questions evaporate. (This is the repo's existing `codebase-orientation` prompt, used as pipeline step zero.)

**2. Interrogate — and classify every question by cost of reversal.** This is the heart of S1. The agent emits its open questions, each tagged by *what a wrong guess costs*:

- 🔴 **Blocking** — a wrong guess means throwaway work or shipped-wrong behavior: *"Favorites local-only, or synced across devices?"* (guess wrong and the model, repository, and tests are all rebuilt) · *"Do favorites survive sign-out?"*
- 🟡 **Assumed** — cheaply reversible later, so proceed on a flagged default: *"Heart icon vs. star"* (a one-line change at Gate B) · *"No undo, for v1."*

The classifier is the cost argument itself: **block only where being wrong is expensive to reverse.** This is what keeps a strict gate (next section) from degenerating into a wall of trivial questions the human rubber-stamps.

**3. Draft the RFC** into [`templates/rfc-template.md`](../templates/rfc-template.md), whose newly-added **Acceptance Criteria** section is the linchpin — each criterion written Given/When/Then and mapped to the test that proves it:

> *AC-1:* Given a track, when the user taps the heart, the favorite persists and survives relaunch. → `FavoritesRepositoryTests.testRoundTripAcrossLaunch`
> *AC-2:* Given a favorited track, when un-hearted, it disappears everywhere the UI reflects it. → `FavoritesViewModelTests.testToggleRemoves`

**4. Keep an assumptions ledger.** Every 🟡 default, listed explicitly, so Gate A approval is informed rather than a rubber stamp.

---

## 5. Gate A — strict, and machine-enforced

Gate A hard-blocks on **any** open 🔴 question. The rationale is the cost table in §2: an assumption that reaches code is expensive work you may throw away entirely, and the agent will happily bill you to build it. A cheap gate at the front is worth more than any speed you'd gain by letting the agent guess.

But "strict" only works with the three disciplines that keep it from becoming a bottleneck:

1. **Batch every 🔴 into one round.** A hard block must not become death-by-a-thousand-round-trips. The agent surfaces *all* blocking questions at once; the human answers once; the gate opens.
2. **Ground first to drive the count down.** Most "questions" are already answered by your written-down context. The better your ADRs, the fewer 🔴 questions — so the gate gets *cheaper as your substrate matures*. Track "blocking questions per story" as a health metric; a rising count means your context is decaying.
3. **The gate re-arms downstream.** If S3 later hits a genuine unknown the frozen contract doesn't cover, it must **stop and re-open Gate A**, not guess forward. This is already the standing rule in the [Autonomy Contract](../AGENTS.md): *the loop won't close → hand back a diagnosis, don't guess.*

**What the human actually reviews** is not the RFC prose — it's a decision-focused summary: *"3 decisions I need, 5 defaults I chose, 1 feasibility flag."* Two minutes, high-signal. Approving does three things: it **freezes the acceptance criteria** (they become every subtask's definition-of-done), **resolves the blockers**, and **routes feasibility** — a story needing device-only capabilities or code signing (say, a Home-Screen-widget favorite) can't be closed by a simulator loop, so Gate A sends it to a human implementer instead of the autonomous path.

**Make it a precondition, not a vibe.** S1 emits a machine-readable gate status, and the orchestrator refuses to invoke the Jira MCP until it clears:

```
gate_a: BLOCKED — 3 unanswered blocking questions   → S2 will not run
gate_a: READY  — 0 open blocking, 5 assumptions logged → S2 proceeds
```

Now no RFC with an open 🔴 can spawn a single Jira task or burn a single agent-token downstream. "Strict" is code, not good intentions.

---

## 6. S2 — Contract → iOS work orders

With a frozen contract, S2 is mechanical decomposition. The axis that makes it *iOS* rather than generic: **decompose by architecture layer**, and make each layer one bounded Level-3 work order. For "favorites":

| Subtask (Jira) | Bounded scope | Per-task definition of done | Depends on | Flag |
| :-- | :-- | :-- | :-- | :-- |
| `Favorite` model | `Models/` | round-trip test passes | — | — |
| `FavoritesRepository` (actor) | `Repositories/` | add/remove/list tests vs. in-memory store | model | — |
| `FavoritesViewModel` (`@Observable`) | `ViewModels/` | toggle + persistence tests (AC-1/AC-2) | repository | — |
| Heart button on the track row | `Views/` | snapshot test; **UX correctness → Gate B** | view model | visual |

Four rules keep S2 honest:

- **Topological order, Models first.** The densest context leads ([Chapter 3](03-context-engineering.md)), and the dependency DAG stops an agent building a View against a ViewModel that doesn't exist yet.
- **Tests-first.** Generate the test subtask from each acceptance criterion *before* its implementation subtask, so S3's loop has a concrete, machine-checkable target from the first token — it cannot wander and rack up spend on unverifiable work. The AC→test mapping frozen at Gate A *becomes* the failing test S3 drives to green. This is [Chapter 26's TDD](26-ai-driven-testing.md), weaponized for autonomy.
- **Every subtask traces to an acceptance criterion.** If it doesn't, it's scope creep — cut it. The RFC's Problem Statement is the fence.
- **A subtask no test can verify is a smell.** Either it's really a Gate-B/visual concern (flag it), or the acceptance criterion was too vague — kick it back to S1.

Each subtask carries its scope, its slice of the acceptance criteria, its dependencies, the ADRs that constrain it, and an escalation flag if it touches signing/device/security. The Jira MCP creates the Story (the RFC) and its Subtasks (the layers), and the agent drives their status as the pipeline runs.

---

## 7. The back half: S3 → S5

With well-formed work orders, the back half is largely the Chapter 20b machinery:

- **S3 — self-iterating code** is the local Level-3 loop from [Chapter 20b §5](20b-autonomy-levels.md#5-running-this-repository-at-level-3--locally): per subtask, plan → edit → `xcodebuild test` → read failures → fix → green, driven against the tests-first target. Run it **locally**, not in CI — self-iteration on macOS runners is a runaway bill.
- **S4 — raise PR** uses the GitHub MCP and [`templates/pr-template.md`](../templates/pr-template.md), whose *AI Generation Context* and *Machine Review Checklist* the agent auto-fills, linking the Jira story.
- **S5 — code review** is the Level-4 reviewer in [`claude-autonomy.yml`](../.github/workflows/claude-autonomy.yml): it reviews the diff against `AGENTS.md` and the ADRs ([Chapter 14](14-code-review.md)) and posts inline comments, with a human as the final approver at **Gate B**, who owns what ships. What happens to those comments — how they re-enter the loop *without* eroding the frozen contract — is the whole of the next section.

---

## 8. S5 → S3: the review loop-back

A straight line isn't a pipeline; the cycle is what makes it Level 4. Review comments and CI failures are new *unknowns* discovered after the contract froze, and they have to re-enter the loop — but a naïve loop-back quietly destroys everything Gate A bought you.

**The core risk: an agent complies with *any* comment.** Left unguarded, a coding agent treats every review comment as a command. A reviewer muses *"would a protocol be cleaner here?"* — a rhetorical question — and the agent rewrites the architecture. That is how a frozen contract erodes, one polite comment at a time. So the loop-back's first job isn't *responding* to feedback; it's **classifying** it.

**Classify feedback the way S1 classified questions — by cost of reversal.** The same economic test that split 🔴-blocking from 🟡-assumed at the front of the pipeline decides what the agent may touch at the back:

| Feedback | Example | Loop-back action |
| :-- | :-- | :-- |
| **Mechanical / objective** | CI red, a failing test, lint, an ADR-drift flag from the machine-review checklist | **Auto-iterate** — the bounded S3 loop: fix, self-verify, push. No human. This is the [Chapter 20](20-terminal-browser-ci-agents.md) auto-fixer. |
| **Bounded judgment** | "extract a helper", "rename for clarity" | Auto-iterate *if* the fix is cheaply reversible and in-scope. |
| **Contract-level judgment** | "reconsider the approach", "why not sync instead of local?" | **Re-arm Gate A** — this reopens a frozen decision; escalate, don't silently comply. |
| **A question, not a request** | "why debounce here?" | **Answer in-thread; touch no code.** |

A comment whose fix is bounded and machine-verifiable, the agent owns. A comment that implies throwing away work or changing the spec is a Gate-A decision wearing a review-comment costume — it goes back to the human.

Four disciplines keep the loop-back honest:

- **Pushback is allowed — the ADR is the authority, not the last comment.** The agent may *decline* a change with a rationale that cites an ADR (*"per the persistence ADR this stays local; syncing is out of this RFC's scope"*). Blind compliance is how architecture drifts; [`AGENTS.md`](../AGENTS.md) and the ADRs outrank the thread.
- **A round budget, or you get a review war.** Requests → push → requests again is an unbounded [cost sink (Chapter 35)](35-agentic-security-and-cost.md). Bound it to *N* rounds, like S3's fix-attempt budget; past *N*, stop and hand to a human.
- **The agent replies; only a human resolves.** The agent addresses a comment and responds, but *resolving* the thread and approving is Gate B. An agent marking its own comments resolved is a smell.
- **Jira status is the "whose turn is it" source of truth.** `In Review → Changes Requested → In Progress → In Review → Done`. The loop-back is that state machine cycling, and it's what stops two workers grabbing the same subtask.

**The substrate is events, not polling.** CI failures and review comments arrive as *events* that wake the agent, which re-diagnoses and re-kicks the affected subtask — never a poll loop. The repo's own `claude-autonomy.yml` plus a PR-activity subscription is the concrete wiring; the mechanical-feedback lane simply *is* the Chapter 20 auto-fixer, now fenced by the classifier above.

The payoff: mechanical feedback iterates freely and fast, while **contract-level feedback re-arms Gate A and the merge stays human.** The cost-of-reversal test now governs the whole line — one idea applied three times: S1 questions, the S3 fix-attempt budget, and these review comments.

---

## 9. The two gates you never automate

Everything between S1 and S5 is delegable. Two decisions are not, for product work, ever:

- **Gate A (spec):** resolving ambiguity is a *product* decision, and it manufactures the testable definition-of-done that makes all downstream autonomy safe.
- **Gate B (merge):** someone owns what reaches users.

Hold those two and the pipeline is aggressive but *legible* — a human sets the destination and inspects the landing, which is exactly the posture [Chapter 20b](20b-autonomy-levels.md) demands.

---

## 10. The iOS reality check

The same constraints that shape Level 3 shape the whole pipeline, and each defines a boundary rather than a blocker:

- **No cheap E2E.** Acceptance criteria must lean on unit and snapshot tests; "the screen looks right" is not loop-closeable, so it lives at Gate B with a screenshot, never inside S3.
- **Signing / provisioning / device-only capabilities** can't be verified on a simulator → S1 flags them, Gate A routes them to a human.
- **macOS runner cost** → S3 self-iteration runs at local Level 3; CI is reserved for the S5 *gate*, not the grind ([Chapter 35](35-agentic-security-and-cost.md)).

---

## 11. Don't build it all at once

The failure mode is jumping straight to a self-triggering "Run." Earn each stage:

1. **Crawl** *(you already have this after Chapter 20b)* — S3 + S4: a bounded task → code → PR, locally.
2. **Walk** *(the real leap)* — add S1 + S2: story → RFC → Jira subtasks, behind a strict Gate A. Most of the value **and** most of the risk live here.
3. **Run** *(true Level 4)* — automate S5 and let a new story self-trigger the chain.

Each rung is only as trustworthy as the definition-of-done it self-verifies against — which is why the whole chapter kept dragging you back to S1.

---

## Next Steps

The pipeline reaches across Jira and GitHub, which means it lives or dies on the tools you expose to the agent — proceed to **[Chapter 21: Tool Calling & MCP](21-tool-calling-mcp.md)** for the MCP servers that make S2 and S4 possible. Then revisit **[Chapter 35: Agentic Security & Cost](35-agentic-security-and-cost.md)**: a self-triggering delivery line is also a self-triggering *spender*, and the cost table in §2 is only cheap if you meter it.
