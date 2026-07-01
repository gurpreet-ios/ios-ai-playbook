---
title: "RFC [Number]: [Title]"
---

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

## 5. Alternative Solutions Considered
What other approaches did you think of, and why did you discard them? (Crucial for preventing AI from suggesting these discarded ideas later).

## 6. Security & Privacy
- Are we logging PII?
- Is this data encrypted at rest?

## 7. Rollout Plan
Is this behind a feature flag? Can we safely rollback the database migration if it fails?
