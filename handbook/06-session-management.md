# Chapter 6: Session Management & State Tracking

> "An AI session without explicit state tracking is a session destined to hallucinate."

In Part I, we introduced the concept of Context Engineering. Here in Part III, we dive deep into the daily, practical mechanics of it. The single most important concept to master when interacting with agents (like Cursor, Windsurf, or Claude) is **Session Management**.

## The Illusion of Memory

When you have a long conversation with an LLM, it feels like the model is "remembering" what you talked about an hour ago. It isn't. Every time you press enter, the *entire* history of your conversation is appended together and re-processed from scratch. 

As the conversation gets longer, two critical failures occur:
1. **Token Exhaustion:** You hit the maximum context window size. The UI silently truncates early messages, causing the model to suddenly "forget" the architectural rules you established in prompt #1.
2. **Attention Dilution:** Even if you don't hit the token limit, the "signal-to-noise" ratio plummets. The model gets confused by code you generated, subsequently deleted, and rewrote three times in the chat history.

## Session Lifecycle Management

To prevent these failures, Senior AI Engineers manage their sessions aggressively. A session should be treated like a temporary workspace, not a permanent diary.

### Rule 1: The One-Task Session
Do not use the same chat thread to build a networking layer, design a UI, and write unit tests. 
* **Start a new session** when you change contexts. 
* A clean context window is the most powerful debugging tool you have.

### Rule 2: The Context Refresh
If you are iterating on a complex problem and the AI starts making obvious mistakes, the context has degraded. **Do not fight the AI in a degraded context.**
1. Stop the conversation.
2. Ask the AI: *"Summarize the current state of our implementation, what we have successfully built, and the exact bug we are currently trying to solve."*
3. Copy that summary.
4. Start a **new session** and paste the summary as the initial prompt, along with the latest file states.

This is called a **Context Refresh**. It resets the signal-to-noise ratio to 100%.

## State Tracking & Decision Logs

Because sessions are ephemeral, you must externalize your state into the filesystem. The filesystem is your source of truth, not the chat history.

### The `task.md` Pattern

Before executing any code generation, require the agent to create and maintain a `task.md` file.

```markdown
# Current Objective: Add Offline Sync

- [x] Phase 1: Update CoreData schema
- [x] Phase 2: Create NetworkSyncManager
- [/] Phase 3: Implement Conflict Resolution (In Progress)
  - [x] Server-wins strategy
  - [ ] Client-wins strategy
- [ ] Phase 4: UI Error Handling
```

**Why this works:** Every time the agent starts a new generation step, you instruct it to "Read `task.md` to understand your current objective." This anchors the agent in reality, preventing it from getting distracted by unrelated parts of the codebase.

### Decision Logs (The Micro-ADR)

During a session, you will make micro-architectural decisions (e.g., "We decided to use a singleton for the Logger because of X"). If you start a new session tomorrow, the AI won't know this, and might try to refactor your singleton into dependency injection.

**Solution:** Maintain a `decision_log.md` in your project root.
When you resolve a debate with the AI, instruct it: 
> *"Document this decision in `decision_log.md` before we move on."*

When you start a new session tomorrow, your first prompt is:
> *"Review `decision_log.md` before suggesting any architectural changes."*

By externalizing memory into State Tracking and Decision Logs, you effectively give your AI agents infinite, perfect memory that persists across tools, sessions, and even human engineers.
