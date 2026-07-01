# Chapter 14: Code Review

> "Reviewing code is no longer about finding syntax errors; the compiler and the AI do that. It is about enforcing intent, security, and scale."

With the rise of AI generation, the volume of code submitted in Pull Requests has exploded. A Junior engineer using an AI agent can generate a 2,000-line PR in a day. If you review this code the way you reviewed human-written code in 2020 (line-by-line, looking for typos), you will drown.

Code review must evolve into a structured, tiered auditing process.

---

## 1. The Senior Review

The Senior Review assumes the code compiles and solves the basic Jira ticket. The goal here is maintainability and architecture.

### The Checklist
- **Architecture Drift:** Does this code invent a new pattern, or does it follow our established ADRs? (e.g., *Did they use MVC when we agreed on MVVM?*)
- **Test Coverage:** Are the edge cases tested? AI is notorious for only testing the "happy path."
- **Dependency Inversion:** Is the business logic tightly coupled to the UI framework or the database?
- **State Management:** Is state centralized, or is it scattered across multiple singletons and views?

---

## 2. The Principal / Staff Review

The Principal Review does not look at variable names. It looks at the system boundaries and the 12-month horizon.

### The Checklist
- **Module Boundaries:** Does this PR increase cross-module coupling? Should this logic be extracted into a shared library?
- **API Contracts:** Are we exposing more data than the client needs? Are the API models strictly separated from the Domain models?
- **Observability:** If this feature fails in production, do we have enough telemetry and logging to know *why*?
- **Backward Compatibility:** Does this database migration or API change break older versions of the app?

---

## 3. The Specialized Audits

Do not try to do a Security review and a Performance review at the same time. You will miss things. You must do specialized passes (often automated via Prompt Systems).

### Security Review
- **Input Validation:** Is all user input treated as malicious?
- **Authentication:** Are tokens stored securely (e.g., Keychain, not UserDefaults)?
- **IDOR (Insecure Direct Object Reference):** Can a user modify a resource they don't own just by changing an ID in the payload?

### Performance Review
- **Algorithmic Complexity:** Is there an accidental O(N^2) loop hiding in a map/filter chain?
- **Memory Management:** Are there strong reference cycles in closures?
- **Main Thread Blocking:** Is heavy I/O or JSON parsing happening on the UI thread?

### Accessibility Review
- **Semantic Structure:** Are heading levels correct?
- **VoiceOver:** Do UI elements have descriptive accessibility labels and traits?
- **Dynamic Type:** Does the UI scale correctly if the user increases the system font size by 200%?

## Automating the Tiers
You cannot manually run a 50-point checklist on a 2,000-line AI-generated PR. You must use AI to review AI. 

As covered in Chapter 5, you should have dedicated Prompts for each of these audits. You feed the PR diff into the `security-owasp-audit.md` prompt, then the `swift-concurrency-audit.md` prompt. You let the AI flag the low-level violations, so you can focus on the Staff-level architectural decisions.
