# Appendix: The Model Landscape

> **This appendix is deliberately the only place in the playbook where concrete model names appear.** Chapter prose uses capability language ("a frontier long-context model", "a small open-weight model") because model names age in months while the engineering advice does not. When the landscape shifts, bump this one file.

_Last updated: July 2026._

## Capability tiers (the vocabulary the chapters use)

| Tier | What it means | Current examples |
| :-- | :-- | :-- |
| **Frontier models** | Highest reasoning ability, strong tool calling, long (up to million-token) context. The default for code generation, review, and agentic loops. | Anthropic Claude (Opus/Sonnet tiers, and the Claude 5 family), OpenAI GPT / o-series, Google Gemini Pro tiers |
| **Fast/cheap models** | Lower latency and cost; good for summarization, classification, routing, commit messages. | Anthropic Haiku tier, OpenAI mini variants, Gemini Flash tiers |
| **Open-weight models** | Downloadable weights; run on your own hardware for data sovereignty or offline use. | Meta Llama family, DeepSeek, Mistral, Qwen |
| **Embedding models** | Turn text into vectors for RAG retrieval (Chapter 28). | OpenAI `text-embedding-3` family, Voyage, Cohere Embed, open-weight alternatives (e.g., BGE) |
| **On-device models** | Run on the iPhone/Mac itself; private and free at inference time, but far smaller. | Apple's Foundation Models (Apple Intelligence), Core ML-converted open-weight models |

## How to choose (rules that don't age)

1. **Code generation and review:** use a frontier model. The cost difference is noise next to the cost of reviewing bad code.
2. **High-volume, low-stakes tasks** (summaries, labels, routing): use a fast/cheap model and measure the failure rate before assuming you need more.
3. **Data can't leave the building:** open-weight on your infra, or a VPC deployment of a managed model (Chapter 29).
4. **Inside the iOS app itself:** prefer on-device first for privacy and offline behavior; fall back to a server-side frontier model for heavy reasoning.
5. **Never hardcode a model name in your codebase.** Route through a config/gateway so upgrades are a one-line change (Chapter 29's Hybrid Gateway).

## Keeping this page honest

When you update this table: change the date above, and check that chapter references still hold ([Ch 3](03-context-engineering.md) context windows, [Ch 28](28-rag-and-custom-agents.md) embeddings and tool calling, [Ch 29](29-llm-deployment-architecture.md) deployment tiers).
