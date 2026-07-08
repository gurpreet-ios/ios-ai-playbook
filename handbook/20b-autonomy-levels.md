# Chapter 20b: The Autonomy Ladder — From Supervised to Delegated Agents

> "The question is no longer *can* the agent write the code. It's *how much of the loop* you're willing to hand it — and whether you've built the guardrails that make handing it over safe."

Chapter 20 showed you agents running in the terminal, the browser, and CI. This chapter answers the question those tools force on you: **how much do you delegate, and how do you do it without losing control of your architecture?**

The mistake is to treat autonomy as a single switch — "agentic" vs "not." It isn't. It's a ladder, and knowing which rung you're standing on (and which one you're ready to climb to) is the difference between a 3× throughput unlock and a weekend spent reverting a confident agent's mess.

---

## 1. Two ladders, not one

This playbook already has a ladder. In [Chapter 3](03-context-engineering.md) and the "[same feature, four prompts](../newsletter/001-the-same-feature-four-prompts.md)" framing, we ranked prompts Junior → Mid → Senior → Staff. **That ladder measures the quality of your *specification*** — how much context, constraint, and house-rule you encode before the model runs.

The autonomy ladder is a **different, orthogonal axis. It measures the size of the *loop* you delegate** — how much of plan → edit → build → test → fix → review the agent runs before a human touches it.

| | The **seniority** ladder (Ch 3) | The **autonomy** ladder (this chapter) |
| :-- | :-- | :-- |
| Measures | How well you *specify* the work | How much of the *loop* you delegate |
| Bad end | A wish → the internet's average answer | A confident agent editing 40 files unsupervised |
| Good end | Context anchors + constraints + a workflow | The agent runs the inner loop; you review outcomes |

They are orthogonal, and the interaction is the whole point of this chapter: **you cannot safely raise autonomy faster than you raise specification.** A Level-3 agent (high autonomy) driven by a Junior prompt (low specification) is exactly the "corrupt your entire architecture in one prompt" disaster from Chapter 19. High autonomy is only safe on top of high-quality context. Climb the seniority ladder first; it is what makes the autonomy ladder survivable.

---

## 2. The five rungs

Borrowed, deliberately, from the SAE J3016 levels of driving automation — because the mental model transfers cleanly. The car metaphor keeps you honest about *who is responsible when it goes wrong.*

### Level 0 — Manual
You type the Swift. Autocomplete off, or ignored. The machine is a text editor. Responsibility: 100% you.

### Level 1 — Assisted
Inline autocomplete and single-shot generation: classic Copilot, Xcode's predictive completion, Cursor's `Cmd+K` on one function. The AI completes a line or a function; **you own every keystroke and read every token as it lands.** This is the "very smart keyboard" from [Chapter 19](19-agentic-ide.md). The loop is one line long.

### Level 2 — Supervised (the "Plan First" rung)
The agent proposes a multi-step change; **you approve every step.** You make it write the plan and wait ([Chapter 19's](19-agentic-ide.md) "Plan First" rule), you read every diff before it lands, you run the build yourself. The agent can edit ten files — but nothing reaches your branch without passing under your eyes first.

**This is where this playbook, and most competent iOS teams, sit today.** It is a genuinely good place to be — far past vibe-coding. But it has a hard ceiling: *your reading speed.* Because you are in the loop on every edit, throughput is capped by how fast a human can review diffs. You have made the machine type faster; you have not removed yourself from the critical path.

### Level 3 — Delegated (the rung this chapter is about)
You hand the agent a **bounded task with an explicit definition of done**, and it runs the **entire inner loop autonomously**: plan → edit → build → run tests → read failures → fix → repeat, until its own tests are green. Then it opens a PR and asks for review. **You review the *outcome*, not the steps.**

The shift is subtle and total. At Level 2 you are a co-pilot with hands on the yoke. At Level 3 you are an air-traffic controller: you set the destination and the no-fly zones, the agent flies the plane, and you inspect where it lands. Your job moves from *reviewing every diff* to *defining the task well and reviewing the final result* — plus handling the exceptions the agent escalates.

The unlock is real: you can have three bounded tasks in flight while you do architecture work, because you're no longer the per-edit bottleneck. **The risk is equally real, and section 3 is the price of admission.**

### Level 4 — Orchestrated
The agent **self-triggers from a work source** — a labeled issue, a failing CI run, a backlog item — and multiple agents run in parallel. This is the CI Auto-Fixer and Automated Reviewer from [Chapter 20 §3](20-terminal-browser-ci-agents.md): a test goes red, an agent pulls the branch, fixes it, pushes, re-runs, all without a human initiating. Humans manage by **exception and policy**: you review merges and set the rules, you don't kick off the work. Fleets, not pairs.

### Level 5 — Full autonomy
The agent owns a service end to end, including production decisions, with no human in the loop. **This does not exist for real iOS product work today, and this playbook will tell you plainly when a claim of it is marketing.** It's on the ladder so the ladder is honest and so you have a name for the boundary you should be suspicious of.

| Level | Name | Who drives the loop | Where you sit | iOS example |
| :-- | :-- | :-- | :-- | :-- |
| 0 | Manual | You | Typing | Hand-written Swift |
| 1 | Assisted | You + inline AI | Every keystroke | Xcode predictive completion, `Cmd+K` |
| 2 | Supervised | Agent proposes, you approve each step | In the loop, every diff | "Plan first, wait for approval," you read each diff |
| 3 | **Delegated** | **Agent runs the whole inner loop** | **Reviewing the outcome + exceptions** | **"Add offline caching to `fetchUserProfile()`; self-verify with tests; open a PR"** |
| 4 | Orchestrated | Agents self-trigger, run in parallel | Policy + exception | CI auto-fixer, automated PR reviewer |
| 5 | Full | Agent owns the service | (Aspirational — treat claims with suspicion) | — |

---

## 3. You cannot skip the substrate: three preconditions for Level 3

Level 3 is not a setting you turn on. It is earned by building three things first. Skip any one and "delegated" degrades into "unsupervised," which is just Level 1 vibe-coding with a bigger blast radius.

**1. A verification loop the agent can close by itself.**
At Level 3 the agent, not you, decides when the work is done — so the agent must be able to *check its own work*. On the web that's `npm test`. On iOS it is the loop Chapter 19 called the reality check and [Chapter 20](20-terminal-browser-ci-agents.md) operationalized: `xcodebuild build`, `xcodebuild test`, `xcrun simctl` to boot a simulator, install, screenshot, and read logs. **An agent that cannot build and run your app cannot operate at Level 3 — it can only guess its code works and hand you the guess.** The tests are the agent's steering feedback; without them it is driving with its eyes closed. This is why [Chapter 30 (Verifying AI Output at Scale)](30-verifying-ai-output-at-scale.md) is a prerequisite, not a sequel.

**2. Written-down guardrails the agent reads.**
The "lane markings." These are the ADRs ([`adrs/`](../adrs/README.md)), the rules files, and the `AGENTS.md` single source of truth from [Chapter 19b](19b-structuring-agent-rules.md). At Level 2 *you* are the one who catches "this violates ADR-001, we use SwiftData not CoreData" — you're reading every diff. At Level 3 you're not in that loop, so the constraint has to live somewhere the agent consults *itself*. **Undocumented architecture is un-delegatable architecture.** The context you wrote down before the prompt existed is exactly what lets you leave the room.

**3. A bounded task with an explicit definition of done.**
This is where the two ladders meet. The **Level-4 *prompt* from Chapter 3** — objective, context anchors, execution plan, "summarize the changes" — *is* the Level-3 *work order*. Autonomy is only as safe as the specification it runs on. A delegated task needs a crisp boundary ("`fetchUserProfile()` in `NetworkManager.swift`, disk cache, 24h expiry") and a testable definition of done ("the new tests pass and existing tests still pass"), or the agent will happily expand the scope to fill the ambiguity.

> **The one-line test for "am I ready for Level 3?"** Can the agent tell, without asking me, whether it succeeded? If the answer is no, you are not ready to delegate — you are ready to keep supervising.

---

## 4. The Level-3 operating contract

Delegation is not abdication. Moving to Level 3 means writing down, explicitly, what the agent owns and what you keep — and what makes it stop and escalate.

| The agent owns | The human keeps |
| :-- | :-- |
| Planning the change within the stated scope | Defining the task and its definition of done |
| Editing the code | Approving the merge |
| Running the build and tests until green | Anything the agent escalates |
| Fixing its own compiler and test failures | Architecture decisions not yet in an ADR |
| Opening the PR and summarizing the change | Setting the guardrails and the kill switch |

**Blast-radius limits — encode these, don't trust them to good behavior:**

- **PR-only, never `main`.** The agent pushes to a feature branch; a protected `main` branch (required reviews, required status checks) is the wall it cannot cross. This one branch-protection rule turns "the agent broke production" into "the agent opened a PR I declined."
- **Bounded scope.** The task names its files or its module. "Refactor the networking layer" is not a Level-3 task; "extract retry logic from `NetworkClient.swift` into `RetryPolicy.swift`, behavior unchanged, tests still green" is.
- **A kill switch.** Autonomy must be revocable in one action — an enable flag you can flip off, a workflow you can disable. If you can't turn it off from your phone, it's not ready to run without you.

**Escalation triggers — the agent must stop and ask, not guess, when:**

- the change would touch a **security- or privacy-sensitive** path (auth, Keychain, cryptography, PII) — see [Chapter 32](32-security-and-privacy.md);
- the right answer requires a **decision no ADR covers** (it's being asked to *set* architecture, not follow it);
- resolving the task would **exceed the stated scope** (more files, a new dependency, a schema migration);
- the loop **won't close** — tests still fail after a bounded number of attempts. A Level-3 agent that can't get to green must hand back a diagnosis, not a broken PR or an infinite spend.

---

## 5. Running *this repository* at Level 3

This chapter is dogfooded. The repo you are reading was moved from Level 2 to Level 3 by adding exactly the three-part substrate above — nothing more:

1. **The closeable loop** already existed: [`.github/workflows/sample-apps.yml`](../.github/workflows/sample-apps.yml) builds and tests all four sample apps on the iOS Simulator. That CI *is* the agent's definition of done for any sample-app change — the eyes it verifies its own work with.
2. **The guardrails, written down:** [`AGENTS.md`](../AGENTS.md) at the repo root is the single source of truth from [Chapter 19b](19b-structuring-agent-rules.md), extended with an explicit **Autonomy Contract** — the scope, the definition of done (handbook edits must re-run `tools/sync-site-chapters.py`; sample-app edits must stay build-and-test green), the escalation triggers, the protected paths, and the kill switch.
3. **The substrate that executes it:** [`.github/workflows/claude-autonomy.yml`](../.github/workflows/claude-autonomy.yml) runs [`anthropics/claude-code-action`](https://github.com/anthropics/claude-code-action) on each PR. It reads `AGENTS.md` and the ADRs, reviews the diff for architecture drift, and — for a failing sample-app test — can push a fix and let the sample-apps CI re-verify it. It is the [Chapter 20](20-terminal-browser-ci-agents.md) Automated Reviewer and Auto-Fixer, wired to *this* repo's rules.

The kill switch is deliberate and load-bearing: the workflow is **inert until a maintainer sets both the `ANTHROPIC_API_KEY` secret and the `CLAUDE_AUTONOMY_ENABLED` repository variable to `true`.** That is Level 3, not Level 4 — the human still arms it, still reviews every merge, and can disarm it by flipping one variable. Autonomy you can revoke in one click is the only autonomy worth granting.

---

## 6. The iOS reality check (again): why Level 3 is harder here

Most autonomy tooling was born on the web, where the loop is cheap: `npm run dev` is instant, E2E is a headless browser, and a bad deploy rolls back in seconds. iOS resists delegation in specific, knowable ways, and each one defines an escalation boundary rather than a reason to stay at Level 2:

- **The loop is slow and expensive.** iOS CI runs on macOS runners ([Chapter 20 §3](20-terminal-browser-ci-agents.md)) — minutes per build, real money per minute. This makes bounded scope and a *fix-attempt budget* mandatory: an unbounded Level-3 agent retrying a flaky simulator test is a runaway bill (see [Chapter 35 on agentic cost](35-agentic-security-and-cost.md)).
- **There is no cheap E2E.** Simulator UI automation is slower and flakier than a headless browser, so the agent's "definition of done" leans harder on unit and integration tests than a web agent's would. Design the verification layer knowing that.
- **Signing and provisioning are hard walls.** Codesigning failures, provisioning profiles, and device-only capabilities are exactly the class of problem an agent *cannot* resolve autonomously — they need a human with an Apple Developer account. These belong on the escalation list from day one.

None of these block Level 3. They shape its boundaries — which is the whole discipline of delegation: knowing precisely where the agent's authority ends.

---

## 7. Making the jump: an L2 → L3 checklist

- [ ] **Close the loop.** Can an agent build and test the target from the command line, unattended? (For iOS: a green `xcodebuild test` on a simulator.) If not, fix this first — it is the whole game.
- [ ] **Write the guardrails down.** The architecture the agent must not violate lives in `adrs/` and an `AGENTS.md` it is told to read — not only in your head.
- [ ] **Protect `main`.** Required reviews + required status checks, so a delegated agent can only ever *propose*.
- [ ] **Scope the first task tightly.** One clear boundary, one testable definition of done. Delegate the boring, well-fenced change first, not the architectural one.
- [ ] **Set a fix-attempt / cost budget.** The agent hands back a diagnosis instead of looping forever.
- [ ] **Add the kill switch.** One flag, off in one action.
- [ ] **Review outcomes, log the misses.** When the agent's PR is wrong, the fix is usually a missing ADR or a loose definition of done — improve the *substrate*, not just that one PR. That is how Level 3 compounds.

---

## Next Steps

Level 3 extends the agent's *judgment* over a bigger loop; the next two chapters extend its *reach* and account for its *cost*. Proceed to **[Chapter 21: Tool Calling & MCP](21-tool-calling-mcp.md)** to give the delegated agent the build/run/screenshot tools that make its verification loop richer than a shell — then **[Chapter 35: Agentic Security & Cost](35-agentic-security-and-cost.md)**, because every rung you climb up this ladder is also a rung up the blast-radius and the bill.
