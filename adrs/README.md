# Architecture Decision Records

ADRs here serve a double purpose:

1. **Documentation** — the classic role: what we decided, why, and what it costs.
2. **AI context anchors** — every ADR ends with an **AI Anchor Usage** section describing when to inject it into a prompt. This is the playbook's core move (Chapter 3, Chapter 7): an ADR fed to an agent makes it write *your* architecture instead of the internet's average. When a generation drifts, you don't re-explain — you reply *"Read `adrs/NNN-….md` and rewrite to comply."*

## Index

| ADR | Decision | Anchor when… |
| :-- | :-- | :-- |
| [001](001-swiftdata-over-coredata.md) | SwiftData over CoreData | generating any persistence code |
| [002](002-observation-over-combine.md) | Observation framework over Combine | generating Views/ViewModels |
| [003](003-reactive-frameworks.md) | Structured concurrency over reactive frameworks | any asynchronous code |
| [004](004-state-management.md) | State ownership hierarchy | scaffolding features; reviewing drift |
| [005](005-mcp-tools.md) | MCP for local tools | wiring agents to internal docs/tools |

## Writing a new ADR

Copy the structure of ADR 001 (Status / Context / Decision / Consequences / AI Anchor Usage). Keep it under a page — an ADR that doesn't fit in a context window alongside the code it governs is too long to be an anchor.
