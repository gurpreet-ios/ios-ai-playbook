# Chapter 3: Context Engineering

> "If Prompt Engineering is how you ask the question, Context Engineering is what the machine knows before you even ask."

Context Engineering is arguably the most valuable skill for an AI-native software engineer. It is the practice of systematically managing, compressing, and curating the information state that an LLM operates within. 

If you master prompt engineering but ignore context engineering, you will constantly fight hallucinations, architectural drift, and forgotten requirements. You will feel like you are working with an amnesiac.

This chapter breaks down the mechanics of managing context at an enterprise scale.

## The Anatomy of Context

### Context Windows
The context window is the total amount of text (tokens) an LLM can hold in its working memory at a given moment. While frontier models now boast million-token windows (see the [Model Landscape appendix](appendix-model-landscape.md) for current examples), treating the context window as a bottomless garbage can is a critical mistake.

**The "Lost in the Middle" Phenomenon:**
Even with massive context windows, models suffer from attention degradation. They heavily weight the beginning (system prompts, constraints) and the end (your immediate request) of the context, while information buried in the middle can be ignored. 

**Rule of Thumb:** Just because you *can* dump the entire codebase into the prompt doesn't mean you *should*. Precision beats volume.

### Memory & State Tracking
Unlike a human, an LLM session is stateless. Every time you send a message, the entire history is re-processed. 
To build complex features over long sessions, you must actively manage state. This is done via **State Tracking Artifacts** (e.g., `todo.md`, `architecture_decisions.md`). Instead of relying on the LLM to remember a conversation from 30 turns ago, you instruct the LLM to read the `todo.md` file before generating code.

### Compression
When context gets too large, you must compress it. 
Instead of feeding the LLM 10,000 lines of implementation code, feed it the interfaces.
Instead of feeding it 50 past Slack messages, feed it a 5-bullet-point summary.
*Code interfaces, type definitions, and protocol headers are the ultimate form of context compression.*

### Retrieval
RAG (Retrieval-Augmented Generation) is the automated form of context engineering. As a Senior AI Engineer, you act as the manual retrieval engine. You must know exactly which 3 files in a 1,000-file repository contain the relevant data structures to feed into the prompt.

## Advanced Techniques

### Incremental Prompting
Do not ask for the world in one prompt. Build context incrementally.
1. "Analyze `DatabaseManager.swift` and tell me its responsibilities." (Builds context)
2. "Now look at `NetworkClient.swift`. How would these two interact?" (Builds relational context)
3. "Now, write the repository layer that bridges them." (Executes based on primed context)

### Constraint Engineering
Constraints are negative context. They are boundaries.
* "Do not use `UserDefaults`."
* "Do not mutate state outside of this actor."
* "No third-party libraries."
By aggressively shrinking the solution space, you drastically reduce hallucinations.

### Persona Engineering
Setting a persona anchors the model's probabilistic weights toward a specific domain of expertise.
* "You are an Apple-certified Staff iOS Engineer specializing in CoreData performance..."
This isn't roleplay; it is latent space steering.

## The Evolution of Context (Real Examples)

To understand Context Engineering, let's look at how the same task is approached across different levels of maturity.

**Task:** Add a caching layer to a network request.

### 🔴 Poor Context (The Junior)
> "Add caching to my fetch request so it works offline."

*Result:* The AI hallucinates a completely new network client, imports a random caching library, and breaks the existing architecture.

### 🟡 Average Context (The Mid-Level)
> "Here is `NetworkManager.swift`. I need to add offline caching to `fetchUserProfile()`. Use `NSCache` for now. Don't break the existing async/await structure."

*Result:* The AI successfully adds `NSCache`, but it doesn't persist across app launches, and it ignores the company's existing caching protocol.

### 🟢 Excellent Context (The Senior)
> "We need to implement offline caching for `fetchUserProfile()` in `NetworkManager.swift`. 
> 
> **Context:**
> 1. Attached is `NetworkManager.swift`.
> 2. Attached is `CacheProvider.swift` (our internal protocol).
> 
> **Constraints:**
> - Implement `CacheProvider` using `FileManager` for disk persistence, not memory.
> - Ensure all disk I/O happens on a background `Task`.
> - If the cache is older than 24 hours, throw `CacheError.expired`.
> 
> Write the implementation."

*Result:* The AI writes a highly specific, architecturally compliant implementation that requires minimal review.

### 🟣 Enterprise Context (The Staff AI Engineer)
The Staff Engineer doesn't write this prompt manually. They orchestrate a system.

> "Execute the `/feature-setup` agent workflow.
> 
> **Objective:** Add disk-based offline caching to user profiles.
> 
> **Context Anchors:**
> - Read the ADR: `docs/ADRs/004-offline-first-architecture.md`
> - Read the Interface: `Protocols/CacheProvider.swift`
> - Target File: `Network/NetworkManager.swift`
> 
> **Execution Plan:**
> 1. Generate the implementation.
> 2. Run the `AI Code Review` prompt against the generated code, specifically checking for race conditions during concurrent disk writes and duplicate in-flight fetches when several views miss the cache simultaneously (requests must coalesce).
> 3. Generate unit tests mocking the file system.
> 4. Summarize the changes in `docs/changelog.md`."

*Result:* The AI reads the architectural decisions, writes the code, reviews its own code for race conditions, writes tests, and updates documentation. The human reviews the final PR.

---

Context Engineering is what separates toys from production software. In **Part II**, we will move from theory to practice by exploring the **Prompt Systems** that run on top of this engineered context.
