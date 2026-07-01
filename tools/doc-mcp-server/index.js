import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import fs from "fs/promises";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const playbookRoot = path.resolve(__dirname, "../../..");

const server = new Server(
  {
    name: "doc-mcp-server",
    version: "1.0.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// Tools
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: "list_adrs",
        description: "List all Architecture Decision Records (ADRs) available in the repository.",
        inputSchema: {
          type: "object",
          properties: {},
        },
      },
      {
        name: "read_adr",
        description: "Read the content of a specific Architecture Decision Record (ADR).",
        inputSchema: {
          type: "object",
          properties: {
            filename: {
              type: "string",
              description: "The filename of the ADR to read (e.g., 001-initial-architecture.md).",
            },
          },
          required: ["filename"],
        },
      },
      {
        name: "search_docs",
        description: "Search for a query in the handbook and design-docs directories.",
        inputSchema: {
          type: "object",
          properties: {
            query: {
              type: "string",
              description: "The search query to look for.",
            },
          },
          required: ["query"],
        },
      },
    ],
  };
});

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  if (request.params.name === "list_adrs") {
    try {
      const adrDir = path.join(playbookRoot, "adrs");
      const files = await fs.readdir(adrDir);
      const markdownFiles = files.filter((f) => f.endsWith(".md"));
      return {
        content: [
          {
            type: "text",
            text: `Available ADRs:\n${markdownFiles.join("\n")}`,
          },
        ],
      };
    } catch (error) {
      return {
        content: [
          {
            type: "text",
            text: `Error listing ADRs: ${error.message}`,
          },
        ],
        isError: true,
      };
    }
  }

  if (request.params.name === "read_adr") {
    const filename = request.params.arguments?.filename;
    if (!filename) {
      return {
        content: [{ type: "text", text: "Filename argument is required" }],
        isError: true,
      };
    }
    
    try {
      const adrPath = path.join(playbookRoot, "adrs", filename);
      // Prevent directory traversal
      if (!adrPath.startsWith(path.join(playbookRoot, "adrs"))) {
        throw new Error("Invalid file path");
      }
      
      const content = await fs.readFile(adrPath, "utf-8");
      return {
        content: [{ type: "text", text: content }],
      };
    } catch (error) {
      return {
        content: [
          {
            type: "text",
            text: `Error reading ADR ${filename}: ${error.message}`,
          },
        ],
        isError: true,
      };
    }
  }

  if (request.params.name === "search_docs") {
    const query = request.params.arguments?.query;
    if (!query) {
      return {
        content: [{ type: "text", text: "Query argument is required" }],
        isError: true,
      };
    }

    try {
      const dirsToSearch = ["handbook", "design-docs"];
      let results = "";

      for (const dir of dirsToSearch) {
        const dirPath = path.join(playbookRoot, dir);
        try {
          const files = await fs.readdir(dirPath);
          for (const file of files) {
            if (file.endsWith(".md")) {
              const filePath = path.join(dirPath, file);
              const content = await fs.readFile(filePath, "utf-8");
              if (content.toLowerCase().includes(query.toLowerCase())) {
                results += `Found in ${dir}/${file}\n`;
                // Extract a tiny snippet around the first match
                const index = content.toLowerCase().indexOf(query.toLowerCase());
                const start = Math.max(0, index - 50);
                const end = Math.min(content.length, index + query.length + 50);
                results += `...${content.substring(start, end).replace(/\\n/g, " ")}...\n\n`;
              }
            }
          }
        } catch (e) {
          // Directory might not exist yet, skip
        }
      }

      if (results === "") {
        results = `No matches found for "${query}"`;
      }

      return {
        content: [{ type: "text", text: results }],
      };
    } catch (error) {
      return {
        content: [{ type: "text", text: `Error searching docs: ${error.message}` }],
        isError: true,
      };
    }
  }

  return {
    content: [{ type: "text", text: `Unknown tool: ${request.params.name}` }],
    isError: true,
  };
});

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("Doc MCP Server running on stdio");
}

main().catch((error) => {
  console.error("Fatal error in main():", error);
  process.exit(1);
});
