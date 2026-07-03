---
title: "Chapter 4: From Prompts to Systems"
---

> "A prompt is a single command. A Prompt System is an automated engineering workflow."

The biggest mistake engineers make when transitioning to AI-native development is treating prompt engineering like a Google search. They type a query, get an answer, copy-paste it, and move on. 

This is the equivalent of writing a script that you run manually every time you deploy, instead of building a CI/CD pipeline. 

In this handbook, we do not teach you how to "write better prompts" (e.g., "be polite to the AI," "use clear English"). Instead, we teach you how to build **Prompt Systems**.

## What is a Prompt System?

A Prompt System is a structured, repeatable, and composable template designed to execute a specific engineering task predictably. 

It is characterized by:
1. **Determinism:** The prompt is engineered to reduce the LLM's variance. Given the same inputs, it produces highly consistent outputs.
2. **Modularity:** It does one thing exceptionally well (e.g., *only* reviewing performance, *only* generating test cases).
3. **Integration:** It expects specific context artifacts (like an ADR or an API spec) as inputs.

## The Architecture of a Production Prompt

A professional prompt is structured like a well-written API payload. It has a header (persona/intent), a body (context and instructions), and strict output formatting rules.

### The 5 Pillars of a Production Prompt

1. **The System Persona:** Who is the AI? What are its intrinsic biases?
2. **The Context Injection Area:** The exact spot where the script/agent injects the relevant files.
3. **The Execution Constraints:** The "Do Nots." (e.g., "Do not use implicit unwrapping," "Do not alter the database schema").
4. **The Output Schema:** The exact format you expect back. (e.g., "Output ONLY a valid JSON object," "Format the response as a GitHub PR review comment").
5. **The Review Hook:** An instruction forcing the AI to explain its key decisions *before* (or alongside) the code — "State where the state lives, what owns the lifecycle, and why, before showing the implementation." You verify the reasoning, not just the syntax; if the explanation is wrong, reject the code without reading it.

## The Shift in Mentality

When you shift from writing prompts to building systems, your workflow changes drastically:

* **Before (Amateur):** You highlight a function and ask, *"Can you review this for bugs?"*
* **After (Professional):** You trigger a macro that executes the `Security_Review_Prompt`, which automatically injects the `Security_Guidelines.md` and the selected function, and returns a structured markdown table of vulnerabilities categorized by OWASP Top 10.

## The Prompt Library

To support Prompt Systems, this playbook includes a dedicated `prompts/` repository. We organize our prompts into discrete categories that mirror the Software Development Life Cycle (SDLC). 

We do not use a "coding prompt." We use:
- **Discovery Prompts:** For codebase archaeology.
- **Planning Prompts:** For breaking down Jira tickets into implementation steps.
- **Architecture Prompts:** For generating ADRs and system diagrams.
- **Review Prompts:** For auditing code against specific company standards.
- **Performance Prompts:** For identifying bottlenecks like O(n^2) operations or retain cycles.
- **Security Prompts:** For finding injection vectors and improper access control.
- **Accessibility Prompts:** For ensuring VoiceOver and contrast compliance.
- **Refactoring Prompts:** For migrating legacy patterns (e.g., MVC to MVVM).
- **Documentation Prompts:** For generating beautiful RFCs and PR descriptions.

In the next chapter, we will look at how to construct and chain these specific prompt categories to automate massive chunks of engineering work.
