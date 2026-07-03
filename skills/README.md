# Agent Skills Library

Installable [Agent Skills](../handbook/19c-agent-skills.md) — the highest-leverage workflows from the [prompt library](../prompts/README.md), packaged in the open `SKILL.md` format so your agent discovers and runs them itself instead of waiting for you to paste them.

Each skill is a folder containing a `SKILL.md`: YAML frontmatter (`name` + `description` — the trigger) plus the procedure. The conversion from prompt to skill is taught in **Chapter 19c**; the key upgrade is that `// INJECT_X_HERE` placeholders become context-gathering steps the agent executes itself (`git diff`, reading ADRs, running `xcodebuild`).

Two invariants hold, mirroring the prompt library's: **every skill is taught by a chapter**, and **every skill converted from a prompt names its source**. If you add a skill, wire both.

## Install

```bash
# Project-level — shared with your team via git
cp -r skills/swift-concurrency-audit /path/to/your-app/.claude/skills/

# Personal — available in all your projects
cp -r skills/hypothesis-first-debug ~/.claude/skills/
```

Frontmatter is deliberately minimal (`name`, `description`) for portability across tools that load the open spec. Add tool-specific fields (like Claude Code's `allowed-tools`) where you deploy, not here.

## Index

| Skill | Does | Chapter | Source prompt |
| :-- | :-- | :-- | :-- |
| [swift-concurrency-audit](swift-concurrency-audit/SKILL.md) | Swift 6 strict-concurrency and data-race audit on a diff | 12 | [review/swift-concurrency-audit](../prompts/review/swift-concurrency-audit.md) |
| [adr-drift-audit](adr-drift-audit/SKILL.md) | Diff vs the repo's ADRs → anchor-prompt rewrite instructions | 14 | [review/adr-drift-audit](../prompts/review/adr-drift-audit.md) |
| [edge-case-probe](edge-case-probe/SKILL.md) | The 7-row happy-path breaker on a generated feature | 24 | [review/edge-case-probe](../prompts/review/edge-case-probe.md) |
| [hypothesis-first-debug](hypothesis-first-debug/SKILL.md) | Ranked hypotheses with evidence before any fix; challenges your theory too | 16 | [debugging/hypothesis-first-debug](../prompts/debugging/hypothesis-first-debug.md) |
| [xcode-build-triage](xcode-build-triage/SKILL.md) | Runs the build, classifies error cascades, fixes by category — kills the hallucination loop | 17 | — (new for the skill format) |
| [render-isolation-audit](render-isolation-audit/SKILL.md) | Read-map + over-render findings for stuttering SwiftUI screens | 11, 15 | [performance/render-isolation-audit](../prompts/performance/render-isolation-audit.md) |
| [legacy-code-archaeology](legacy-code-archaeology/SKILL.md) | Maps responsibilities and side effects in inherited code, analysis only | 16 | [discovery/legacy-code-archaeology](../prompts/discovery/legacy-code-archaeology.md) |
| [release-audit](release-audit/SKILL.md) | Go/no-go evidence table (never says GO) | 31 | [release/release-audit](../prompts/release/release-audit.md) |

## Why 8 and not 41

Skill descriptions compete for the agent's trigger attention — every installed skill costs a little triggering accuracy for all the others (Chapter 19c, "the trigger budget"). These 8 are the recurring, whole-workflow prompts: the ones you'd otherwise paste weekly. Scaffolds and one-off migrations stay in [`prompts/`](../prompts/README.md), findable when needed, costing nothing when not. Convert more for your own team using the Chapter 19c mapping — it's a 15-minute job per prompt.
