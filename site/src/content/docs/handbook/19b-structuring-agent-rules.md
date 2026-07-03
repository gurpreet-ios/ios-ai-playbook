---
title: "Chapter 19b: Structuring Agent Rules"
---

> "If you give an AI an empty text box, you get junior code. If you give it constraints, you get senior architecture."

As discussed in Chapter 19, the Rules File (`.cursorrules`, `.windsurfrules`, `CLAUDE.md`, `AGENTS.md`) is the permanent system prompt for any agent that touches your codebase. 

However, as agentic IDEs evolve, the strategy for structuring these rules has shifted from a **monolithic file** to a **modular, scoped directory**.

---

## 1. The Monolith vs. Modular Rules

Historically, iOS engineers placed a single `.cursorrules` file at the root of their repository. This worked for small projects, but as codebases scale, a 500-line rules file degrades the AI's context window. It gets confused, applies SwiftData rules to SwiftUI views, and loses track of critical constraints.

### The Modern Approach: `.cursor/rules/`
Modern agentic IDEs (like Cursor >0.40) support directory-based rules. Instead of one `.cursorrules`, you create a `.cursor/rules/` directory containing multiple Markdown with Cursor (`.mdc`) files.

These `.mdc` files use YAML frontmatter to target specific file patterns (globs).

**Example: `swiftui-architecture.mdc`**
```yaml
---
description: Architectural constraints for SwiftUI Views and ViewModels.
globs: *.swift
---
# SwiftUI Constraints
- All ViewModels MUST be annotated with `@MainActor`.
- Use the `@Observable` macro...
```

**Example: `swiftdata-models.mdc`**
```yaml
---
description: Guidelines for defining SwiftData models.
globs: *Model.swift, *Schema.swift
---
# SwiftData Constraints
- Use `SwiftData` via the `@Model` macro.
- DO NOT use CoreData XML...
```

By scoping rules, the AI only reads the SwiftData constraints when it is actually editing a database model.

---

## 2. Behavioral vs. Architectural Rules

Most developers only write **Architectural Rules** ("Use MVVM", "No Combine"). But to truly lead an LLM, you must also write **Behavioral Rules** — telling the agent *how* to act.

Create a `global-behavior.mdc` that applies to everything (`globs: *`):
- **Tone**: "Be concise. Do not apologize. Do not explain the code unless asked."
- **Safety**: "Never remove existing comments or docstrings unless explicitly told."
- **Workflow**: "Think step-by-step in a `<thought>` block before generating code."

*(Check the `templates/agent-rules/` folder in this playbook for copy-pasteable examples).*

---

## 3. The Single Source of Truth

When your team uses multiple tools — say, some devs use Cursor, some use Windsurf, and CI uses Claude Code — rule drift is inevitable.

**The Solution:**
1. Create an `AGENTS.md` file at the root of your repository holding the universal architectural laws.
2. In your specific tool configs (`CLAUDE.md`, `.windsurfrules`), add a prompt directive: *"Before starting any task, read `AGENTS.md`."*
3. For Cursor `.mdc` files, you can reference `AGENTS.md` in the global behavior rule.

This keeps your architectural constraints in one place while allowing tool-specific instructions (like terminal commands for Claude Code) to live in their respective files.

---

## Next Steps

Rules make the agent behave; they don't teach it your workflows. Proceed to **Chapter 19c: Packaging Workflows as Agent Skills** to turn the prompt systems from this playbook into procedures the agent invokes by itself.
