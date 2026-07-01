---
title: "Chapter 5: Core Prompt Categories"
---

> "Do not use one massive prompt to do the work of five specialized prompts."

A robust AI engineering pipeline relies on a chain of specialized prompts. Just as you wouldn't use a single massive function to handle networking, UI rendering, and database migrations, you shouldn't use a single prompt to plan, generate, and review code.

Here is a breakdown of the core prompt categories that you should use to build your personal Prompt Systems. (The actual 500+ production prompts can be found in the `prompts/` directory of this playbook).

## 1. Discovery Prompts
**Goal:** Codebase archaeology and context gathering.
Before you write code, you must understand what already exists. Discovery prompts are designed to read large amounts of code and summarize relationships.

* **Example Use Case:** "I need to add a new payment method. Find all protocols and classes that handle Checkout in the current workspace, and map out their dependencies."
* **System Characteristic:** These prompts prioritize exhaustiveness and often output Mermaid.js diagrams to visualize architecture.

## 2. Planning Prompts
**Goal:** Breaking down a feature into atomic, verifiable steps.
Do not ask an AI to "build the feature." Ask the AI to "plan the feature implementation."

* **Example Use Case:** "Given this Jira ticket for 'Offline Mode', generate a step-by-step implementation plan. Break the work down into chunks that will take no longer than 30 minutes to generate and review. Identify the files to be modified in each step."
* **System Characteristic:** Output is usually a markdown checklist (like a `task.md` file) that can be tracked.

## 3. Architecture Prompts
**Goal:** Generating scaffolding and defining boundaries.
These prompts are used to establish the skeletons of new features, ensuring they align with company standards.

* **Example Use Case:** "Generate the protocol definitions and folder structure for a new `UserProfile` feature using Clean Architecture. Do not implement the logic, only the interfaces and data models."
* **System Characteristic:** Strictly enforces design patterns (MVVM, VIPER, Redux) and prevents the AI from rushing into implementation details.

## 4. Review Prompts
**Goal:** Automated, rigorous PR reviews.
You should never review AI-generated code manually from scratch. You should use a Review Prompt to do the first pass.

* **Example Use Case:** "Act as a Principal Engineer. Review this diff. Focus exclusively on: 1) Retain cycles, 2) Main thread blocking, and 3) Missing error handling. Format your response as actionable PR comments."
* **System Characteristic:** Highly constrained. If you don't constrain a review prompt, it will nitpick variable names instead of finding architectural flaws.

## 5. Performance Prompts
**Goal:** Identifying bottlenecks and optimizing code.

* **Example Use Case:** "Analyze this SwiftUI View. Identify any state properties that will cause unnecessary re-renders of the entire view hierarchy. Suggest how to break this view down or use `@Observable` to localize updates."
* **System Characteristic:** Demands deep framework-specific knowledge (e.g., Apple's rendering loop, memory graph behavior).

## 6. Security Prompts
**Goal:** Hardening the application against vulnerabilities.

* **Example Use Case:** "Review this backend API endpoint. Assume the user is malicious. Can they achieve IDOR (Insecure Direct Object Reference)? Are the SQL queries parameterized? Is the rate limiting sufficient?"
* **System Characteristic:** Adopts an adversarial persona (Red Team).

## 7. Accessibility (a11y) Prompts
**Goal:** Ensuring the application is usable by everyone.

* **Example Use Case:** "Audit this React component for WCAG 2.1 AA compliance. Ensure all interactive elements are keyboard navigable, ARIA roles are correct, and color contrast ratios are met."
* **System Characteristic:** Requires strict adherence to external standards and guidelines.

## 8. Refactoring Prompts
**Goal:** Safely migrating legacy code.

* **Example Use Case:** "Migrate this UIKit `UIViewController` to SwiftUI. Maintain the exact same state machine. Break the UI down into at least 3 sub-views."
* **System Characteristic:** Often relies on a "Before/After" shot in the context, providing the legacy code and a target style guide.

## 9. Documentation Prompts
**Goal:** Generating maintenance artifacts.

* **Example Use Case:** "Read this completed PR diff. Generate a Release Note for the product team, and a Technical Spec for the engineering team explaining the new database schema."
* **System Characteristic:** Changes tone dynamically based on the target audience (Product vs. Engineering).

---

By chaining these prompts—(Discovery → Planning → Architecture → Generation → Review → Documentation)—you create a predictable, scalable AI engineering workflow. 

In the `prompts/` repository, you will find ready-to-use templates for all of these categories.
