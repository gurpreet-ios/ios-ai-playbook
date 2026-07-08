# The Senior AI Engineering Playbook — iOS Edition

> A practical handbook for iOS engineers who lead LLMs instead of being led by them: context engineering, prompt systems, and production Swift built the AI-native way.

This is not a book about "vibe coding." It is a working resource for operating like a Senior/Staff iOS engineer in the AI era — where the bottleneck is no longer typing Swift, but defining the problem, engineering the context, and rigorously reviewing what the machine produces.

**Primary teaching stack:** Swift 6 (strict concurrency), SwiftUI, the Observation framework, SwiftData, and the agentic IDE workflow (`.cursorrules`, context anchors, prompt systems). Legacy UIKit/Combine appear where real codebases demand them.

> Looking for the server-side version? The **Backend Edition** (Go/PostgreSQL/Kafka) lives in its own repository.

## What's in this repository

| Section | Contents |
| :-- | :-- |
| [`handbook/`](handbook/) | The 39-chapter handbook (below) + the dated [Model Landscape appendix](handbook/appendix-model-landscape.md) |
| [`prompts/`](prompts/README.md) | 42 production prompt systems, chapter-mapped — architecture, review, performance, debugging, testing, security, release |
| [`skills/`](skills/README.md) | 8 installable Agent Skills (`SKILL.md`) — the highest-leverage prompts packaged so your agent triggers them itself (Chapter 19c) |
| [`adrs/`](adrs/README.md) | 13 Architecture Decision Records, each usable as an AI context anchor |
| [`architecture-breakdowns/`](architecture-breakdowns/README.md) | Seed blueprints for deconstructing real products (Uber, Spotify, Instagram) with prompt sequences |
| [`interview-playbooks/`](interview-playbooks/README.md) | Structured mock interviews (machine coding, architecture, code review) |
| [`sample-apps/`](sample-apps/) | Four Swift sample apps — a deliberate prompting-strategy set (below) |
| [`templates/`](templates/) | RFC and PR templates designed for both human and machine reviewers |
| [`tools/`](tools/) | Book build scripts and a reference MCP server (`doc-mcp-server/`) |
| [`AGENTS.md`](AGENTS.md) | The single source of truth for agents working in this repo — architectural laws + the Level-3 **Autonomy Contract** (Chapter 20b). The repo dogfoods its own delegated-agent setup. |
| [`newsletter/`](newsletter/README.md) | Substack post drafts — the community-first distribution pipeline 
| [`site/`](site/) | Astro Starlight site — the full handbook, free (chapters synced via `tools/sync-site-chapters.py`;

Improvement work is tracked in [`BACKLOG.md`](BACKLOG.md).

## 🚀 Start here (for beginners)

New to iOS or overwhelmed by "Actor Isolation" and "Context Windows"? Don't panic — there's a track for you:

1. **[Chapter 0: The "Hello World" To-Do App](handbook/00-hello-world-todo-tutorial.md)** — build your first SwiftUI app with exactly three prompts.
2. **[Chapter 17: Fixing Xcode Compiler Errors with AI](handbook/17-xcode-compiler-errors-with-ai.md)** — handle scary compiler errors without letting the AI destroy your architecture.
3. **[Chapter 27: Prompting for UI/UX](handbook/27-prompting-for-ui-ux.md)** — make your apps look beautiful without memorizing SwiftUI modifiers.

## The Handbook

### Part I — The AI-Native Mindset
- [Chapter 1: The Future Engineer](handbook/01-the-future-engineer.md)
- [Chapter 2: Vibe Coding](handbook/02-vibe-coding.md)
- [Chapter 3: Context Engineering](handbook/03-context-engineering.md)

### Part II — Prompt Systems
- [Chapter 4: From Prompts to Systems](handbook/04-from-prompts-to-systems.md)
- [Chapter 5: Core Prompt Categories](handbook/05-core-prompt-categories.md)

### Part III — Managing Agents & Context
- [Chapter 6: Session Management & State Tracking](handbook/06-session-management.md)
- [Chapter 7: Memory Compression & Context Anchors](handbook/07-memory-compression.md)
- [Chapter 8: Prompt Chaining in Practice](handbook/08-prompt-chaining.md)

### Part IV — Architecture
- [Chapter 9: Presentation Architecture](handbook/09-presentation-architecture.md) (MVVM, MVI, VIPER, TCA)
- [Chapter 10: System Architecture](handbook/10-system-architecture.md) (Clean, modules, Repository, Coordinator)

### Part V — iOS Engineering
- [Chapter 11: iOS UI and Architecture](handbook/11-ios-ui-and-architecture.md) (SwiftUI, UIKit, navigation, animation)
- [Chapter 12: iOS Data and Concurrency](handbook/12-ios-data-and-concurrency.md) (SwiftData, Observation, actors, networking)
- [Chapter 13: iOS System Integration](handbook/13-ios-system-integration.md) (widgets, Live Activities, push, background tasks)

### Part VI — Quality: Review, Performance, Debugging
- [Chapter 14: Code Review in the AI Era](handbook/14-code-review.md)
- [Chapter 15: Performance Engineering](handbook/15-performance-engineering.md)
- [Chapter 16: Debugging Cookbook](handbook/16-debugging-cookbook.md)
- [Chapter 17: Fixing Xcode Compiler Errors with AI](handbook/17-xcode-compiler-errors-with-ai.md)

### Part VII — The AI-Native Interview
- [Chapter 18: Mastering the AI-Native Interview](handbook/18-ai-native-interviews.md)

### Part VIII — Agentic Engineering
- [Chapter 19: The Agentic IDE](handbook/19-agentic-ide.md)
- [Chapter 19b: Structuring Agent Rules](handbook/19b-structuring-agent-rules.md)
- [Chapter 19c: Packaging Workflows as Agent Skills](handbook/19c-agent-skills.md)
- [Chapter 20: Terminal, Browser, and CI Agents](handbook/20-terminal-browser-ci-agents.md)
- [Chapter 20b: The Autonomy Ladder](handbook/20b-autonomy-levels.md) — from supervised (Level 2) to delegated (Level 3) agents
- [Chapter 21: Tool Calling & MCP](handbook/21-tool-calling-mcp.md)

### Part IX — Documentation & Reference
- [Chapter 22: AI-Native Documentation](handbook/22-ai-native-documentation.md)
- [Chapter 23: System Design Breakdowns](handbook/23-system-design-breakdowns.md)
- [Chapter 24: Cheat Sheets](handbook/24-cheat-sheets.md)

### Part X — Production Craft
- [Chapter 25: Accessibility with AI](handbook/25-accessibility-with-ai.md)
- [Chapter 26: AI-Driven Testing & TDD](handbook/26-ai-driven-testing.md)
- [Chapter 27: Prompting for UI/UX](handbook/27-prompting-for-ui-ux.md)

### Part XI — AI Systems Engineering
- [Chapter 28: Agentic AI & RAG Deep Dives](handbook/28-rag-and-custom-agents.md)
- [Chapter 29: LLM Deployment Architecture](handbook/29-llm-deployment-architecture.md)

### Part XII — Shipping to Production
- [Chapter 30: Verifying AI Output at Scale](handbook/30-verifying-ai-output-at-scale.md)
- [Chapter 31: CI/CD & Release Engineering](handbook/31-cicd-release-engineering.md)
- [Chapter 32: Security & Privacy](handbook/32-security-and-privacy.md)
- [Chapter 33: Observability & Production Health](handbook/33-observability-production-health.md)

### Part XIII — The Frontier
- [Chapter 34: On-Device AI & App Intents](handbook/34-on-device-ai-app-intents.md)
- [Chapter 35: Agentic Security & Cost](handbook/35-agentic-security-and-cost.md)

### Appendix
- [The Model Landscape](handbook/appendix-model-landscape.md) — the only place model names live, dated and bumpable.

## The sample apps: a prompting-strategy set

The four apps in [`sample-apps/`](sample-apps/) are **not** four random demos — each was generated with a different prompting strategy, and each keeps the actual prompts next to the code in `_prompts/` directories so you can replay the build:

| App | Strategy | When to use it |
| :-- | :-- | :-- |
| [`uber-clone`](sample-apps/uber-clone/) | **Descriptive** — long, constraint-heavy prompts | Complex domains where architectural control matters most |
| [`spotify-clone`](sample-apps/spotify-clone/) | **Ultra-concise** — fast, authoritative commands | Under time pressure (live machine-coding interviews) |
| [`music-interview-app`](sample-apps/music-interview-app/) | **Balanced** — upfront `.cursorrules` + short per-file prompts | The recommended default; read its README first |
| [`movie-search-uikit`](sample-apps/movie-search-uikit/) | **Balanced + decision log** — `.cursorrules` + per-layer prompts + a live [`DECISIONS.md`](sample-apps/movie-search-uikit/DECISIONS.md) | UIKit/MVVM-C interviews (the legacy-stack round); proving the architecture is *yours* |

## How to use this playbook

The through-line is **context engineering**: the [ADRs](adrs/README.md) are not documentation for its own sake — they are the anchors you feed an agent so it writes *your* architecture instead of the internet's average. Every ADR ends with an explicit "AI Anchor Usage" note, and the chapters reference them by path.

**Suggested reading path:**
1. **Chapters 1–3** — the mindset and the single most important skill, context engineering.
2. **Chapters 4–8** — turn one-off prompts into repeatable prompt systems.
3. **Parts IV–VI (9–17)** — the iOS substance: architecture, modern Swift, and the quality gauntlet (review → performance → debugging).
4. **Parts VIII–XI (19–29)** — scale yourself across IDE, terminal, CI, and custom agents.
5. **Parts XII–XIII (30–35)** — ship it: the verification stack, release engineering, security, observability — then the frontier: on-device AI, App Intents, and securing/metering the agentic workflow itself.

Interviewing soon? Jump to [Chapter 18](handbook/18-ai-native-interviews.md), the [interview playbooks](interview-playbooks/README.md), and the sample-app trilogy above.
