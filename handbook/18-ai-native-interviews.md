# Chapter 18: Mastering the AI-Native Interview

> "Interviewers at top-tier tech companies are no longer testing if you know the syntax of a `for` loop. They are testing if you know how to architect a system that an AI can safely build and maintain."

As AI continues to commoditize code generation, the Senior/Staff engineering interview is evolving. The classic LeetCode grind is giving way to deeper, more ambiguous evaluations. Companies like OpenAI, Anthropic, Stripe, and Apple want to know: *Can this person orchestrate systems? Can they debug complex state? Can they review code effectively?*

This chapter breaks down the new interview landscape.

---

## 1. The Shift in Evaluation

Historically, interviews were heavily weighted toward **Implementation** (Data Structures and Algorithms). 
In the AI-native era, the weight has shifted toward **Design, Debugging, and Review**.

| Phase | Classic Interview Focus | AI-Native Interview Focus |
| :--- | :--- | :--- |
| **Machine Coding** | Speed of typing; memorizing APIs. | Defining strict interfaces; prompting/reviewing AI output; testing. |
| **System Design** | Drawing boxes on a whiteboard. | Defining exact module boundaries, data contracts, and failure modes. |
| **Debugging** | Fixing a syntax error. | Finding a race condition in a multi-threaded, multi-module system. |
| **Code Review** | Pointing out missing semicolons or bad variable names. | Identifying architectural drift, retain cycles, and scaling bottlenecks. |

## 2. The Two Question Types

Strip away the branding and almost every vibe-coding interview is one of two questions:

### Type 1: Build from Scratch
You get a product requirement, an LLM, and ~45 minutes: *"Build a feature that shows nearby restaurants with infinite scroll."* You are expected to run a planning session with the LLM (architecture, component hierarchy, state management) **before any code exists**, then generate one logical piece at a time, reviewing everything. You are explicitly *not* expected to type the code yourself — and you *are* expected to catch the LLM's lifecycle bugs, missing error states, and memory leaks as they appear.

### Type 2: Debug the Unfamiliar Codebase
You get an existing app you have never seen and a vague symptom: *"The list stutters when scrolling."* The evaluated skill is context-building speed — using the LLM to map the code instead of reading every file — followed by a disciplined hypothesis → trace → fix → defend loop. Jumping straight to fixes without a stated hypothesis is the fastest way to fail this round.

Both types run on the same spine: **Plan → Review → Fix.** Expect a **mid-interview extension** in either type ("now add offline mode", "now handle pagination") — it is scripted, and it tests whether you can drive the LLM into new territory without breaking the existing design.

## 3. How to Use the Interview Playbook

This repository contains a dedicated `interview-playbooks/` folder with structured mock interviews across four formats — machine coding, architecture, code review, and debugging (Type 2 above). These are not just "questions and answers." They are structured simulations.

Every mock interview in the playbook follows this format:
1. **The Prompt:** The ambiguous question the interviewer asks.
2. **Expected Reasoning:** What the interviewer is *actually* trying to evaluate.
3. **The Poor Answer:** How a Junior/Mid-level engineer answers (usually jumping straight to code).
4. **The Great Answer:** How a Senior/Staff engineer answers (asking clarifying questions, defining constraints, evaluating tradeoffs).
5. **Driving the LLM:** The vibe-coding prompt sequence for this exact question — the Plan → Review → Fix loop in practice.
6. **The Follow-Up:** The mid-interview extension the interviewer throws when you answer perfectly.
7. **The Ideal Discussion:** A transcript of a successful back-and-forth.

## 4. The Core Competencies

When practicing the mock interviews, focus on demonstrating these three competencies:

### Competency A: Constraint Engineering
Before writing code or drawing a diagram, you must define the constraints. 
* *"What is the expected DAU (Daily Active Users)?"*
* *"Are we optimizing for time-to-market or long-term maintainability?"*
* *"Is this feature offline-first?"*

### Competency B: Tradeoff Analysis
There is no perfect architecture. If you pitch MVVM or Clean Architecture as flawless, you will fail the interview.
* *"I am choosing a global Redux store here because state predictability is our highest priority, but the tradeoff is that we will incur a performance penalty if we don't strictly memoize our view updates."*

### Competency C: The Adversarial Mindset
When reviewing code or designing a system, you must actively try to break it.
* *"If the user force-quits the app exactly here, the database will be left in an inconsistent state. We need to wrap this in a transaction."*

---

The mock interviews provided in this playbook are modeled after real questions asked at FAANG and top-tier AI startups. Treat them as sparring sessions. Do not just read the answers—speak your answer out loud, then compare it to the "Great Answer" provided.
