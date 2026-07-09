# RFC [Number]: [Title]

**Author:** [Name]  
**Date:** [YYYY-MM-DD]  
**Status:** [Draft / Under Review / Accepted / Rejected]  

## 1. Problem Statement
What specific business or technical problem are we solving? Do not propose a solution here, only state the problem. 

## 2. Proposed Solution
Explain the high-level architecture of your solution. 
*Note for AI Agents: This section acts as the primary constraint guide for code generation.*

## 3. Data Models
Define the schemas required for this feature.
```swift
// Example
struct User {
    let id: UUID
    let name: String
}
```

## 4. Edge Cases & Constraints
Identify how this system can break.
- **Offline Behavior:** What happens if the user drops connection during step 2?
- **Concurrency:** Can two users mutate this state simultaneously?
- **Scale:** Does this hold up if the array has 100,000 items?

## 5. Acceptance Criteria
The **machine-checkable** definition of done. Write each criterion as Given / When / Then and map it to the test that proves it. In an autonomous pipeline (see Chapter 20c) these become the failing tests the implementation is driven to make pass, and freezing them is what a human approves at "Gate A" — so keep them testable, not aspirational.
- **AC-1:** *Given* [initial state], *when* [action], *then* [observable, assertable result]. → `SomeTests.testThing`
- **AC-2:** ...

*A criterion no test can check is not an acceptance criterion — it's a visual/UX concern. Move it to §4 or the PR's Human Review Checklist, and flag it for human sign-off rather than the automated loop.*

## 6. Alternative Solutions Considered
What other approaches did you think of, and why did you discard them? (Crucial for preventing AI from suggesting these discarded ideas later).

## 7. Security & Privacy
- Are we logging PII?
- Is this data encrypted at rest?

## 8. Rollout Plan
Is this behind a feature flag? Can we safely rollback the database migration if it fails?
