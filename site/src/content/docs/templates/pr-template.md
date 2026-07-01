---
title: "Pull Request: [Title]"
---

## Summary
Briefly describe the goal of this PR. Link to the relevant Jira ticket or RFC.

## AI Generation Context
- **Tool Used:** [Cursor / Windsurf / Copilot / Manual]
- **Primary Prompts Used:** Provide a brief summary of the prompts used to generate the core logic, so reviewers understand the AI's context.

## Machine Review Checklist
*To be evaluated by the CI Agent (or manually verified).*
- [ ] Code compiles without warnings.
- [ ] No `UIKit` imports inside SwiftData models.
- [ ] All new asynchronous network requests use `Task` cancellation.
- [ ] Unit tests cover the "unhappy path" (e.g., 500 error, empty array).

## Human Review Checklist
*To be evaluated by a Staff/Principal Engineer.*
- [ ] Does this PR introduce a new architectural pattern? (If yes, block PR and request ADR).
- [ ] Are the module boundaries respected?
- [ ] Are there any hidden retain cycles in closures?
- [ ] Is the UI performant (no main-thread blocking during data parsing)?

## Screenshots / Screen Recordings
(If UI changes are included, attach a video here).
