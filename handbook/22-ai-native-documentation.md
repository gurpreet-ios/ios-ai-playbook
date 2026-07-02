# Chapter 22: AI-Native Documentation

> "Historically, documentation was written for humans to read when they got stuck. Today, documentation is written for AI to read so it doesn't get stuck in the first place."

The purpose of documentation has fundamentally shifted. In a traditional codebase, a `README.md` might explain how to run the app, and an RFC (Request for Comments) might explain why you chose a specific database. 

In an AI-native codebase, documentation acts as **Context Anchors**. When you ask an LLM to build a feature, you inject these documents into its context window. If the documentation is vague, the AI hallucinates. If it is precise, the AI writes perfect code.

---

## 1. Writing for the Machine

When writing documentation for an AI, you must remove ambiguity and focus on hard constraints.

**Human-focused writing (Bad for AI):**
> "We try to keep our view models pretty clean and mostly use SwiftData for saving stuff locally."

**Machine-focused writing (Good for AI):**
> "CONSTRAINT: All ViewModels MUST be annotated with `@MainActor`. 
> CONSTRAINT: All local persistence MUST use `SwiftData` via the `@Model` macro. Do not use CoreData."

### The "Rules" File
Every repository must have a root rules file. The names vary by tool — `.cursorrules`/`.windsurfrules` for the agentic IDEs, `CLAUDE.md` for Claude Code, and the cross-tool `AGENTS.md` convention — but they are all the same artifact: the permanent system prompt for any agent that touches your codebase. Maintain the content once and mirror it into whichever filenames your team's tools read; nothing rots trust faster than two rules files that disagree.

## 2. Tech Specs and RFCs

Before writing a massive feature, you should write an RFC. But you shouldn't write it alone.
1. **Drafting:** Write a rough outline of the business requirements in bullet points.
2. **AI Sparring:** Prompt the AI: *"Read this outline. Act as a Staff Staff Engineer. Poke holes in my edge cases, specifically around offline syncing and authentication."*
3. **Formalizing:** Have the AI generate the final RFC using a strict markdown template.

*(See the `templates/` directory in this playbook for the ideal RFC template).*

## 3. The Pull Request (PR) Template

AI agents are generating PRs. AI agents are reviewing PRs. Your PR template must serve both.

A good PR template in the AI era contains a **"Machine Review Checklist"**:
- [ ] This PR does not violate `adrs/001-swiftdata-over-coredata.md`.
- [ ] This PR does not introduce un-isolated background threads mutating `@Observable` state.
- [ ] The AI generated unit tests for the "unhappy path" (network failure, disk full).

You can configure a GitHub Action to automatically run an LLM over the diff and check these boxes before a human even looks at the PR.

---

## 4. The Decision Log (ADRs)

Architecture Decision Records (ADRs) are the most critical form of documentation. 
If an AI suggests using `RxSwift` in a 2026 project, you simply reply: *"Read `adrs/003-reactive-frameworks.md`."* The AI reads the file, realizes you banned RxSwift in favor of async/await, and instantly corrects itself.

Keep ADRs short. Status, Context, Decision, and Consequences. If it's longer than a page, the AI's attention mechanism might dilute its importance.
