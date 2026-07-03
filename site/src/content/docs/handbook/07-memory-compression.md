---
title: "Chapter 7: Memory Compression & Context Anchors"
---

> "You don't need the AI to read the entire library. You just need it to read the index cards."

When developers first get access to tools with massive context windows (like Cursor or Claude), their instinct is to @-mention the entire codebase. "Here is my entire `src` folder. Build the feature."

This approach fails spectacularly for two reasons:
1. **Latency & Cost:** Processing 200,000 tokens for every chat message is slow and incredibly expensive.
2. **Attention Degradation:** The AI gets distracted by utility functions, CSS files, and legacy code that have nothing to do with the current task.

To scale AI engineering, you must master **Memory Compression** and the use of **Context Anchors**.

## Memory Compression Techniques

Memory compression is the act of providing the AI with the *shape* of the code, rather than the *implementation* of the code.

### 1. The Interface-Only Injection
If you want the AI to write a UI component that fetches data from a network manager, the AI does not need to know *how* the network manager makes the HTTP request. It only needs to know the public signature.

**Instead of injecting `NetworkManager.swift` (1,000 lines):**
Inject `NetworkManagerProtocol.swift` (20 lines):
```swift
protocol NetworkManagerProtocol {
    func fetchUser(id: String) async throws -> User
    func updateProfile(_ profile: UserProfile) async throws -> Void
}
```
This reduces the context load by 98% and removes all distracting implementation details.

### 2. Architectural Summaries
When a codebase grows beyond a few dozen files, you should maintain a high-level `architecture.md` file in the root of the project.

This file should contain:
- The folder structure logic (e.g., "We use feature-based modules").
- The state management paradigm (e.g., "We use Redux for global state").
- The networking paradigm (e.g., "We use Apollo GraphQL").

When starting a new session, you inject `architecture.md`. This 50-line file provides more valuable steering context to the AI than injecting 50,000 lines of raw code.

## Context Anchors

A **Context Anchor** is a specific, highly-curated file that grounds the AI's generation process. You force the AI to read this anchor before it writes a single line of code.

### Anchor 1: The ADR (Architecture Decision Record)
If you are asking the AI to build a new caching layer, you must anchor it to your team's caching strategy.
> *"Before you generate the code, read `docs/adrs/004-offline-caching.md`. Ensure your implementation strictly follows the strategy outlined there."*

### Anchor 2: The Style Guide
AI models are trained on the internet. The internet contains terrible, outdated code. If you want the AI to write modern, idiomatic code, you must anchor it to a style guide.
> *"Read `docs/swift-style-guide.md`. Do not use implicit unwrapping. Ensure all UI updates are explicitly routed to the MainActor."*

### Anchor 3: The Golden Example
LLMs are few-shot learners. They perform exponentially better if you show them a perfect example of what you want.

If you want the AI to build `SettingsFeature.swift` using your specific flavor of MVVM:
> *"Read `ProfileFeature.swift`. This is our **Golden Example** for how an MVVM feature should be structured. Build `SettingsFeature.swift` using the exact same structural patterns."*

## The Compression Workflow

A professional AI engineer's context injection looks like this:
1. `architecture.md` (To understand the project shape)
2. `GoldenExample.swift` (To understand the required pattern)
3. `TargetProtocol.swift` (The interface to satisfy)
4. `JiraTicket.md` (The business logic to implement)

This highly compressed, highly relevant context payload is often less than 2,000 tokens. It is lightning fast to process, costs fractions of a cent, and results in near-perfect code generation because the AI has zero noise to distract it.

In the next chapter, we will look at how to string these concepts together into **Prompt Chaining**.
