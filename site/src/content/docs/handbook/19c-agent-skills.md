---
title: "Chapter 19c: Packaging Workflows as Agent Skills"
---

> "A prompt you have to remember to paste is a checklist taped inside your locker. A skill is a colleague who shows up when their name is called."

Chapters 4–5 taught you to engineer **Prompt Systems** — persona, context anchors, task, constraints, output schema. Chapter 19b taught you to structure **Rules Files** so constraints load themselves. This chapter covers the layer between them, and the newest of the three: **Agent Skills**.

A skill is a prompt system packaged in a folder with trigger metadata, so the agent *discovers and invokes it by itself*. You stop being the delivery mechanism for your own expertise.

---

## 1. The Delivery Problem

This playbook ships 41 production prompt systems. They share a weakness that has nothing to do with their content: **you are the trigger**. You must remember the right prompt exists, find it, paste it, and splice the context in by hand. Under deadline pressure, nobody does this — they type "fix it" and get junior output from a senior library.

The agentic stack has three layers, and each answers a different question:

| Layer | Question it answers | Loaded | Taught in |
| :-- | :-- | :-- | :-- |
| **Rules** (`.cursor/rules/`, `AGENTS.md`, `CLAUDE.md`) | "What is *always* true in this repo?" | Always (scoped by globs) | Ch 19b |
| **Skills** (`SKILL.md` folders) | "How do we do *this recurring job* here?" | On demand, when triggered | This chapter |
| **MCP** (servers, tools) | "What external systems can the agent *touch*?" | Per tool call | Ch 21 |

Rules are constraints; they make every task better but do no work themselves. MCP is reach; it connects the agent to build systems and data. Skills are **procedures** — the concurrency audit, the release checklist, the debugging loop — packaged so the agent runs them the way *you* run them, without being asked twice.

If it must hold on every edit, it's a rule. If it's an external system, it's an MCP server. If it's a workflow you'd otherwise paste from this playbook, it's a skill.

---

## 2. Anatomy of a SKILL.md

A skill is a directory containing a `SKILL.md` file — YAML frontmatter plus Markdown instructions. The format is an open specification (Anthropic released it in late 2025 and opened the spec; Claude Code, claude.ai, and a growing set of agents and IDEs load it natively).

```
.claude/skills/
└── xcode-build-triage/
    └── SKILL.md
```

**Example: `xcode-build-triage/SKILL.md`**
```yaml
---
name: xcode-build-triage
description: Triages Xcode build failures by classifying compiler errors before fixing them. Use when a Swift/iOS build fails, xcodebuild reports errors, or the user pastes a compiler error like "MainActor isolation" or "does not conform to Sendable".
---

# Xcode Build Triage

Run the build, classify every error, fix by category — never one error at a time.

1. Reproduce: `xcodebuild build -quiet` (or the project's build command).
2. Classify each error into: actor isolation, Sendable conformance,
   opaque return types, missing dependency, or stale generated code.
3. Fix the CATEGORY, not the instance — one isolation fix often
   clears a dozen downstream errors. Re-run the build between categories.
4. NEVER weaken concurrency to silence an error: no `@unchecked Sendable`
   without a synchronization mechanism, no removing `@MainActor` from UI.
```

Two frontmatter fields do all the work:

- **`name`** — lowercase, hyphenated, matches the folder name.
- **`description`** — the trigger. This is the only part of the skill the agent sees *before* deciding to use it. Write it in the third person and answer both halves: *what it does* and *when to use it*, including the words a user would actually say ("build fails", "Sendable error").

The body is your prompt system. It loads into context only after the description matches the task.

---

## 3. Progressive Disclosure and the Trigger Budget

Skills are cheap until they aren't. The mechanism that makes them scale is **progressive disclosure** — three levels, each loaded only when earned:

1. **Metadata** (`name` + `description`): always in context. Costs a few dozen tokens per installed skill.
2. **Body** (the SKILL.md text): loaded when the agent decides the skill matches.
3. **Bundled files** (reference docs, scripts, templates in the same folder): read only when the body points to them.

This is the same lesson as Chapter 19b's monolith problem, one layer up. A 500-line rules file degrades context; fifty installed skills degrade *triggering*. Every description competes with every other description for the agent's attention, and two skills with overlapping descriptions ("reviews code for issues") will misfire on each other's jobs.

So curate. This playbook converts 8 of its 41 prompts into skills — the recurring, whole-workflow ones — and leaves the rest as prompts. That ratio is deliberate, and it is the same judgment call you'll make for your own team: **a skill earns installation when the workflow recurs weekly and has a stable shape.** One-off scaffolds and rarely-used migrations stay in the library, findable when needed, costing nothing when not.

---

## 4. Converting a Prompt System into a Skill

The five pillars from Chapter 4 map almost one-to-one — with one upgrade that changes the character of the artifact:

| Prompt System (Ch 4) | SKILL.md | What changes |
| :-- | :-- | :-- |
| Persona | Opening role statement in the body | Unchanged |
| Context Anchors (`// INJECT_X_HERE`) | **Context-gathering steps** | The big one — see below |
| Task Definition | Numbered procedure | Unchanged |
| Constraints | Constraints section | Unchanged |
| Output Schema | Output format section | Unchanged |
| *(you, remembering it exists)* | `description` frontmatter | Automated away |

The upgrade: a prompt system says `// INJECT_PR_DIFF_HERE` because *you* were the one assembling context. A skill runs inside an agent that has tools — so the placeholder becomes an instruction: *"Run `git diff main...HEAD` and collect the touched files. Read `adrs/README.md` and pull the ADRs that govern the touched layers."* The skill doesn't wait for context; it goes and gets it. When you convert your own prompts, walk each `INJECT` line and ask: *can the agent fetch this itself?* Almost always yes — and what remains (the user's hypothesis, the symptom description) is exactly what the skill should ask the user for.

**Before** (from `prompts/review/swift-concurrency-audit.md`):

```
# CONTEXT INJECTION
// INJECT_PR_DIFF_HERE
// INJECT_RELATED_ACTORS_HERE
```

**After** (from `skills/swift-concurrency-audit/SKILL.md`):

```
1. Collect the diff: `git diff main...HEAD -- '*.swift'`.
2. For every type touched by the diff, read its declaration to
   determine its isolation (actor, @MainActor, nonisolated, none).
```

Everything else — the `@unchecked Sendable` constraint, the findings table, the exact "CONCURRENCY AUDIT: PASSED" pass-string — transfers verbatim. The engineering you did in Chapter 4 was the hard part; the skill wrapper is packaging.

---

## 5. Skills That Act, Not Just Advise

Because the body is instructions to an agent with tools, a skill can drive the Chapter 20 terminal loop, not just produce analysis. The `xcode-build-triage` example above *runs the build*. A release skill can read the flag registry and the privacy manifest itself. A skill folder can also bundle a script the agent executes instead of re-deriving logic in tokens — deterministic beats generated for anything you can write once.

Two cautions, both foreshadowed elsewhere in this playbook:

- **Trust**: a skill is text that becomes agent behavior — treat third-party skills exactly like third-party build scripts and dependencies (Chapter 35's prompt-injection surface). Read every skill you install; write your own for anything that touches release or security.
- **Scope**: don't rebuild MCP in a skill. If the job is "talk to an external system," that's a server (Chapter 21). Skills orchestrate; servers connect.

---

## 6. Team Distribution: the `skills/` Folder

Skills follow the same single-source-of-truth logic as Chapter 19b's `AGENTS.md`:

- **Project-level** (`.claude/skills/` in the repo): the team's shared procedures — code-review gates, release checklists — versioned with the code they govern, in the PR flow like any other change.
- **Personal** (`~/.claude/skills/`): your own workflow preferences that follow you across repos.

This playbook ships its skills in [`skills/`](https://github.com/gurpreet-ios/ios-ai-playbook/blob/main/skills/README.md) — 8 installable conversions of the highest-leverage prompts, each mapped to the chapter that teaches it. Installation is a copy:

```bash
# Project-level (shared with your team via git)
cp -r skills/swift-concurrency-audit /path/to/your-app/.claude/skills/

# Personal (available in all your projects)
cp -r skills/hypothesis-first-debug ~/.claude/skills/
```

The frontmatter is deliberately minimal — `name` and `description` only — because that is the portable core of the spec. Tool-specific fields exist (Claude Code supports `allowed-tools` to sandbox what a skill may touch); add them where you deploy, not in the shared source. Support across other IDEs and agents is expanding but uneven — verify against your tool's current docs, the same freshness rule as the Model Landscape appendix.

---

## Next Steps

Rules constrain the agent, skills give it your procedures — but both depend on the repo having decisions worth citing. Proceed to **Chapter 22: AI-Native Documentation** to learn how to write the Context Anchors and ADRs that skills like `adr-drift-audit` run against.
