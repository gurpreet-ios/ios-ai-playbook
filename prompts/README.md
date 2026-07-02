# Prompt Library

This directory contains production-ready Prompt Systems. These are not casual conversational prompts; they are engineered workflows designed to execute specific tasks with high determinism.

## Structure

The library is organized by SDLC phase:

- `/discovery`: Understanding existing codebases.
- `/planning`: Breaking down requirements.
- `/architecture`: Generating interfaces and scaffolding.
- `/review`: Rigorous code auditing (including the OWASP security audit).
- `/performance`: Identifying bottlenecks.
- `/accessibility`: Ensuring inclusive design.
- `/refactoring`: Migrating patterns.
- `/documentation`: Generating specs and notes.

## Anatomy of a Production Prompt

Every prompt in this library follows a specific format:
1. **Persona**: The lens through which the LLM operates.
2. **Context Anchors**: Where to inject files.
3. **Task Definition**: The specific action to take.
4. **Constraints**: What *not* to do.
5. **Output Schema**: The exact expected format.
