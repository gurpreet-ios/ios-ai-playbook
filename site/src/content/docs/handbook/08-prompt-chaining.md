---
title: "Chapter 8: Prompt Chaining in Practice"
---

> "The output of one prompt is the input to the next."

If you try to execute a massive task (e.g., "Build an offline-first chat feature") with a single prompt, the AI will fail. It might write the database layer correctly, but it will hallucinate the UI, and it will completely forget to write the network synchronization logic.

The solution is **Prompt Chaining**. 

Prompt Chaining is the process of breaking a complex workflow into discrete steps, where the LLM evaluates its own previous output before moving to the next step. It is the defining characteristic of "Agentic Engineering."

## The Core Concept

Instead of writing one massive prompt:
> *Poor: "Build the chat feature (DB, Network, and UI)."*

You write a chain of specific prompts:
1. **Planning:** "Break down the chat feature into 3 technical milestones."
2. **Architecture:** "For Milestone 1 (DB), define the `CoreData` schema. Do not write the implementation."
3. **Generation:** "Implement the `CoreData` schema defined in the previous step."
4. **Review:** "Audit the implementation for main-thread blocking."

(The planning step is productionized as `prompts/planning/feature-breakdown.md`.)

## A Real-World Example: The "Refactor Chain"

Let's look at a common scenario: Refactoring a massive 2,000-line "God Class" (e.g., `ProfileViewController`) into a clean architecture.

If you paste the 2,000 lines and say *"Refactor this to MVVM"*, the AI will inevitably delete logic, hallucinate variables, or just stop generating halfway through due to output token limits.

Here is how a Senior AI Engineer chains the prompts to guarantee success:

### Step 1: The Discovery Prompt
You must first force the AI to map the chaos.
> **Prompt 1:** "Read `ProfileViewController.swift`. Map out all side-effects, state properties, and network calls. Group them into logical domains (e.g., User Data, Preferences, Billing). Do not write any Swift code. Output a Markdown summary."

### Step 2: The Boundary Prompt
Once the AI has grouped the logic, you force it to define the interfaces.
> **Prompt 2:** "Based on your summary, define the Swift `Protocols` for the three ViewModels we will need (UserViewModel, PreferencesViewModel, BillingViewModel). Do not implement them. Just write the protocols."

### Step 3: The Iterative Generation Prompts
Now you can safely ask the AI to generate the implementation, but you do it *one piece at a time*.
> **Prompt 3:** "Implement `UserViewModel.swift` conforming to the protocol you just defined. Extract only the relevant logic from `ProfileViewController.swift`. Ensure it is fully `MainActor` isolated."

*(You then review the output, save the file, and move to the next).*

> **Prompt 4:** "Now implement `PreferencesViewModel.swift`..."

### Step 4: The Integration Prompt
Once all the pieces are built, you wire them together.
> **Prompt 5:** "Rewrite `ProfileViewController.swift`. Remove all business logic. It should now only observe state from the three new ViewModels and render the UI."

## Why Chaining Works

1. **Token Exhaustion:** By breaking the task down, you never hit the output token limit (usually 4k-8k tokens).
2. **Error Isolation:** If the AI hallucinates during Step 2, you correct it *before* it writes 1,000 lines of bad code in Step 3.
3. **Traceability:** You have a clear log of *why* the architecture looks the way it does.

Chaining requires discipline. It requires you to slow down and act as a Manager rather than an Individual Contributor. But when executed correctly, it allows you to orchestrate massive, multi-file refactors with near-zero bugs.

---

With Mindset, Prompts, and Context mastered, we are ready to dive into platform-specific execution. In **Part IV**, we will apply these systems specifically to **iOS Engineering**.
