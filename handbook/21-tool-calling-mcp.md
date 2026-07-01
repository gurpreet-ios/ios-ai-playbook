# Chapter 21: Tool Calling & MCP (Model Context Protocol)

> "An LLM that can only output text is a toy. An LLM that can trigger functions, query databases, and read design files is a system."

The final evolutionary step of an AI-native engineer is mastering how to give AI agents access to the outside world. This is done through **Tool Calling** and the **Model Context Protocol (MCP)**.

---

## 1. Tool Calling (Function Calling)

### Definition
Instead of the LLM generating a conversational response, you provide it with a JSON Schema of a function you have in your codebase. If the LLM decides it needs to use that function to fulfill a user request, it outputs a structured JSON object matching the schema. Your app parses that JSON, executes the local function, and returns the result back to the LLM.

### Example: The Weather App
1. **User asks:** *"Do I need an umbrella in Tokyo today?"*
2. **LLM realizes:** It doesn't know the current weather.
3. **LLM Tool Call:** It outputs `{"function": "get_weather", "arguments": {"location": "Tokyo", "date": "today"}}`.
4. **Your App:** Parses this JSON, hits the OpenWeather API, and gets `{"condition": "rain"}`.
5. **Your App to LLM:** Sends the API result back.
6. **LLM to User:** *"Yes, it is currently raining in Tokyo. You will need an umbrella."*

### Why Senior Engineers Must Know This
Tool calling is the foundation of Agentic workflows. If you want to build an AI that can auto-refund a user's Stripe transaction, you don't teach the AI how to use Stripe's HTTP API. You build a local `refundTransaction(userId:)` function and expose it to the LLM as a tool.

---

## 2. MCP (Model Context Protocol)

### Definition
Introduced by Anthropic, the Model Context Protocol (MCP) is an open standard that standardizes how AI models connect to data sources. 

Before MCP, if you wanted your AI IDE to be able to read your Figma files, your Jira tickets, and your AWS logs, you had to write custom API integrations for all three, and the IDE vendor had to explicitly support them.

MCP creates a universal plug-and-play standard.

### How It Works
1. **MCP Servers:** Lightweight programs that expose data or tools. You can run a `Figma MCP Server`, a `Postgres MCP Server`, and a `GitHub MCP Server`.
2. **MCP Clients:** Your IDE (like Cursor, Claude Desktop, or Windsurf) acts as the client.
3. **The Connection:** The client connects to the servers. Now, you can open your IDE and type: *"Look at the Figma file for the Login Screen (via Figma MCP), check if the backend API for `/login` is live (via Postman MCP), and write the SwiftUI code for it."*

### The Impact on Architecture
MCP shifts the burden of context-gathering away from the human.
Instead of downloading a Figma image, copying the CSS tokens, and pasting them into the IDE prompt, you simply point the IDE to the MCP server.

### Writing Your Own MCP Server
As a Senior Engineer, you will often need to write custom MCP servers for your company's proprietary data.
- **Example:** An `InternalAnalyticsMCP`. You can prompt your IDE: *"Check our internal analytics to see which screen crashes the most, then navigate to that file and propose a fix."*

By mastering Tool Calling and MCP, you stop treating AI as a chatbot and start treating it as a highly capable operating system.
