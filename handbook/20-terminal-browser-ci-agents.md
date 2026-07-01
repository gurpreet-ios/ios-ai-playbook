# Chapter 20: Terminal, Browser, and CI Agents

> "If you are manually typing `git rebase -i HEAD~4` and resolving merge conflicts by hand, you are competing against a machine that can do it in 4 seconds."

The IDE is just one environment. A Senior AI Engineer deploys agents across the entire software development lifecycle (SDLC).

---

## 1. Terminal Agents

A terminal agent is an LLM with read/write access to your shell. 

### Why Use Them?
- **Complex Git Operations:** Instead of remembering the exact syntax for a sparse checkout or an interactive rebase, you simply command the agent: *"Squash the last 4 commits, reword the first one to say 'feat: user auth', and force push to origin."*
- **DevOps Scripting:** *"Write a bash script that finds all `.png` files in the `assets/` folder, compresses them using `imageoptim`, and outputs a markdown table of the space saved."*
- **Log Parsing:** *"Tail the server logs and grep for any error related to the database connection. Summarize the frequency of the error."*

### Security Warning
Never run a terminal agent as `root`. A hallucinating agent can accidentally run `rm -rf /` or overwrite critical system configurations. Always use a sandboxed user or verify the command before execution.

---

## 2. Browser Agents

Browser agents have the ability to navigate web pages, click elements, extract data, and fill forms. They use Computer Vision or parse the DOM to understand the UI.

### Use Cases for Engineers
- **E2E Testing:** Instead of writing brittle Selenium or Cypress scripts that break every time a CSS class changes, you prompt a Browser Agent: *"Go to `localhost:3000`. Create a new account using the email 'test@test.com'. Verify that the welcome banner appears."* The agent adapts to minor UI changes automatically.
- **Documentation Scraping:** *"Navigate to the Stripe API docs. Scrape the JSON payload schema for the `/v1/charges` endpoint and convert it into a Swift `Codable` struct. Save it to `StripeCharge.swift`."*
- **Visual Regression:** Some browser agents can take a screenshot of your local dev server and compare it against the Figma design, flagging discrepancies in padding or typography.

---

## 3. CI (Continuous Integration) Agents

The holy grail of Agentic Engineering is removing human bottlenecks from the PR review and merge process.

### The Automated Code Reviewer
You can configure a CI agent (using GitHub Actions + an LLM) to run on every Pull Request.
1. It reads the PR diff.
2. It fetches your `.cursorrules` or `adrs/` folder to understand your architectural constraints.
3. It posts inline comments on the PR flagging violations (e.g., *"This PR introduces a CoreData XML file. Per ADR-001, we use SwiftData. Please refactor."*).

### The Auto-Fixer
When a unit test fails in CI, you shouldn't have to pull the branch and fix it locally.
An advanced CI agent will:
1. Detect the failing test.
2. Read the stack trace.
3. Generate a fix.
4. Push a new commit to the PR branch.
5. Re-run the tests.

By deploying agents in the Terminal, Browser, and CI, you scale yourself from a single contributor into a virtual engineering manager leading a team of digital workers.
