---
title: "Chapter 28: Agentic AI & RAG Deep Dives"
---

> "A Senior AI Engineer doesn't just prompt an LLM; they orchestrate systems of agents that can read the company's entire knowledge base before writing a single line of code."

Until this point, we have focused on **Context Engineering**—manually curating the context window by dropping specific files into your prompt. This works for small features, but it fails at enterprise scale. You cannot manually attach 50 microservice repositories to an AI prompt.

To scale AI engineering, you must move from *Prompting* to *Agents* and *RAG*.

## Retrieval-Augmented Generation (RAG)

**RAG** is the automated form of context engineering. Instead of you finding the files, the AI searches a vector database of your company's documentation, codebase, and Jira tickets, pulls the relevant context, and *augments* its prompt before generating an answer.

### Why RAG is Mandatory for Enterprise
LLMs are trained on the public internet up to a certain cutoff date. They know *nothing* about:
1. Your company's proprietary authentication protocol.
2. The undocumented quirk in your legacy billing system.
3. Your internal UI component library.

If you ask an LLM to build a new screen without RAG, it will hallucinate a standard UI component. If you ask an LLM connected to RAG, it will first search your design system documentation and use your proprietary `CompanyPrimaryButton`.

### Implementing Basic RAG
A typical RAG pipeline looks like this:
1. **Ingestion:** Run a script that chunks all your `.md` and `.swift` files into smaller blocks.
2. **Embedding:** Convert those text blocks into vector embeddings (arrays of numbers) using an embedding model (see the [Model Landscape appendix](/handbook/appendix-model-landscape/) for current options).
3. **Storage:** Store these vectors in a Vector Database (like Pinecone, Weaviate, or pgvector).
4. **Retrieval:** When an engineer asks a question, embed the question, search the Vector DB for the most similar chunks, and inject those chunks into the LLM's system prompt.

## Custom Agents

While RAG provides *knowledge*, Agents provide *action*. An agent is an LLM running in a loop with access to **Tools** (functions it can execute).

### The Tool-Calling Paradigm
Modern frontier models are fine-tuned for tool calling. You provide a JSON schema describing your functions, and the model decides when to call them.

**Example Tool: `search_jira`**
```json
{
  "name": "search_jira",
  "description": "Searches Jira for a specific ticket ID to find the acceptance criteria.",
  "parameters": {
    "type": "object",
    "properties": {
      "ticket_id": { "type": "string" }
    },
    "required": ["ticket_id"]
  }
}
```

### The Orchestration Loop
When you build an Agent, you put the LLM in a `while` loop:
1. User provides a goal: "Fix the bug in ticket PROJ-123."
2. **Agent Thought:** "I don't know what PROJ-123 is. I need to call `search_jira`."
3. **Action:** The system executes the API call to Jira.
4. **Observation:** The API returns the ticket details: "The login button is misaligned on iOS 17."
5. **Agent Thought:** "Now I need to find the login screen code. I will call `search_codebase`."
6. This loops until the agent reaches a final conclusion.

## Model Context Protocol (MCP)

Building custom agents from scratch is tedious. The **Model Context Protocol (MCP)**, pioneered by Anthropic, standardizes how AI IDEs (like Cursor, Windsurf, or Claude Desktop) talk to your local tools.

Instead of building a massive custom AI platform for your company, you can write a simple Node.js or Python MCP server that exposes your internal APIs. 

### The `doc-mcp-server` Example
In this repository, we have included a runnable MCP server in the `tools/doc-mcp-server/` directory. It exposes three tools to any compatible AI client:
- `list_adrs`
- `read_adr`
- `search_docs`

By connecting your AI IDE to this local server, your AI assistant can now dynamically read your Architecture Decision Records without you ever needing to copy-paste them into the chat window. This is the future of context engineering.
