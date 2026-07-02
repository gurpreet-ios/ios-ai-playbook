# ADR 005: Use MCP for Local Tools

## Status
Accepted

## Context
Our AI agents need to read internal documentation, query the design system, and inspect build metadata. Ad-hoc solutions (pasting docs into prompts, one-off shell scripts per IDE) don't compose: every editor/agent pairing needs its own integration, and secrets end up copied into prompt text.

## Decision
We expose internal tools and documentation to AI agents through the **Model Context Protocol (MCP)**. One MCP server per capability (docs search, design tokens, ticket lookup); any MCP-capable client (IDE, terminal agent, CI agent) connects to the same servers.

## Consequences
**Positive:**
- Write the integration once; every agent surface gets it.
- Credentials stay inside the server process instead of the context window.
- Tool responses arrive as structured data the agent can cite, not pasted blobs.

**Negative:**
- Tool results are untrusted input to the model — a poisoned doc page can carry prompt-injection payloads, so servers must sanitize and agents must run with least privilege.
- Another service to version and operate.

## AI Anchor Usage
Reference this ADR when someone proposes a bespoke per-IDE plugin or asks an agent to read docs by pasting them: the answer is "add it to (or use) the MCP server." See `tools/doc-mcp-server/` for the reference implementation.
