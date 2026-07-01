# Chapter 26: AI-Driven Testing & TDD

> "The most powerful use-case for AI in software engineering is not writing feature code; it is writing the scaffolding that proves the feature code works."

Testing is historically the most neglected part of software development because it requires writing massive amounts of boilerplate (mocks, stubs, spies, setup/teardown methods). AI completely eliminates this bottleneck.

As a Senior AI Engineer, you should use AI to generate 90% of your testing infrastructure, allowing you to focus purely on defining the assertions and edge cases.

## The Mock Generation Strategy

If you have adhered to the architectural rules in Chapter 11 (Protocol-based Dependency Injection), mocking is trivial.

Instead of writing mocks by hand, feed the protocol to the AI with a strict prompt:

**Senior Prompt (`prompts/testing/generate-mock.md`):**
> "Generate a Mock class for this protocol. Use the `Spy` pattern. For every function, generate a `[functionName]CallCount` integer and a `[functionName]ReturnValue` property. Ensure the mock conforms to `@unchecked Sendable` if it is used across async boundaries."

## AI-Assisted TDD (Test-Driven Development)

TDD is incredibly powerful when paired with AI because it provides the AI with the exact constraints it needs to generate correct code on the first try.

**The Workflow:**
1. **Human writes the Test Definition:** You write the empty test functions defining the exact behavior you want.
2. **AI implements the Tests:** You ask the AI to fill in the assertions and mock setups based on your test names.
3. **AI writes the Feature:** You feed the failing tests back to the AI and say: "Here are the tests. Write the `ViewModel` that makes them pass."

## Auditing Generated Tests

LLMs are prone to generating "tautological tests"—tests that simply repeat the implementation logic and always pass, testing nothing of value.

**Reviewing Tests:**
Always check:
1. Did the AI test the *behavior* or just the *implementation*?
2. Did it mock the dependencies correctly, or did it instantiate real network clients?
3. Did it use `XCTest` expectations for async code properly? (e.g., `expectation(description:)` instead of `try await Task.sleep()`).
