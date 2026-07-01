# Chapter 19: The Agentic IDE

> "An IDE is no longer just a text editor with a compiler. It is a multi-agent system where you are the orchestrator."

The transition from traditional IDEs (like Xcode, IntelliJ, or VSCode) to Agentic IDEs (like Cursor and Windsurf) marks the biggest leap in developer productivity since the invention of syntax highlighting. 

An Agentic IDE doesn't just autocomplete a line of code; it reads your entire repository, writes code across multiple files simultaneously, and runs terminal commands to test its own work.

---

## 1. Cursor vs. Windsurf vs. Copilot

### GitHub Copilot (The Autocomplete Era)
Copilot in its original form is "reactive." You write a comment, it writes a function. It is incredibly useful for boilerplate, but it lacks the autonomy to design systems. It is essentially a very smart keyboard.

### Cursor (The Composer Era)
Cursor introduced the `Cmd+K` (inline generation) and the `Composer` (multi-file generation) paradigms. 
* **The Magic:** Cursor's primary advantage is its codebase indexing. It understands the relationship between your database schema in `schema.prisma` and your UI component in `Profile.tsx` without you needing to explicitly paste both into the chat.
* **The Danger:** Because it can edit 10 files at once, a poorly scoped prompt can instantly corrupt your entire architecture (see Chapter 17 on Architecture Drift).

### Windsurf (The Flow State)
Windsurf introduced "Flows"—agents that act proactively rather than reactively. While Cursor waits for your command, a true Agentic IDE can watch you type a failing test, automatically read the stack trace, and propose the fix in the background before you even ask for it.

---

## 2. Setting Up the `.cursorrules`

To master an Agentic IDE, you must define its boundary constraints. You do this via a `.cursorrules` (or equivalent `.windsurfrules`) file at the root of your repository. 

This file acts as the permanent System Prompt for the IDE's agents.

### Example `.cursorrules` Snippet:
```markdown
# Role
You are a Principal iOS Engineer. 

# Architecture Constraints
1. We use MVVM + Observation. Do NOT use Combine (`@Published`).
2. We use SwiftData. Do NOT generate CoreData XML or NSManagedObject.
3. UI must be SwiftUI. Fallback to UIKit only via UIViewRepresentable.

# Coding Style
- Explicitly mark ViewModels with `@MainActor`.
- All network logic must happen in injected `Repository` classes, not ViewModels.
```

Without this file, the IDE will hallucinate outdated patterns. With this file, the IDE operates like a Senior Engineer trained exactly on your company's ADRs.

---

## 3. The "Y-Shaped" Developer Workflow

In an Agentic IDE, the traditional "I-shaped" (deep in one stack) or "T-shaped" (broad knowledge, deep in one stack) developer model evolves into the **Y-Shaped Developer**.

1. **The Trunk (Architecture & Domain):** You spend 80% of your time defining data models, system boundaries, and business constraints in plain English or markdown.
2. **The Left Branch (Prompting):** You feed the architecture to the Agentic IDE and supervise the generation.
3. **The Right Branch (Auditing):** You review the generated code for security, performance, and memory leaks.

You rarely type the actual syntax yourself unless you are fixing a highly specific algorithmic bug.

## 4. Best Practices for IDE Prompts

- **The `@` Operator:** Always use `@` to explicitly attach Context Anchors. E.g., `Update @ProfileView.swift to use the data models defined in @adrs/user-schema.md`.
- **The "Plan First" Rule:** Never tell the Composer to "Build a login screen." Tell it to: *"Read @Auth.md. Create an implementation plan for the login screen. Do not write code yet. Wait for my approval."* Once approved, command it to execute.
