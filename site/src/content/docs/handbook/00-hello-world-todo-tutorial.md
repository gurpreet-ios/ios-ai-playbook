---
title: "Chapter 0: The \"Hello World\" To-Do App"
---

> "The first step to managing AI is proving you can get it to build something simple without it collapsing under its own weight."

If you are new to iOS development or new to AI code generators, do not start by asking the AI to "Build Spotify." Start here. This tutorial will walk you through building a completely functional To-Do list app with local database persistence, using exactly **three prompts**.

This will teach you the fundamentals of **Context Engineering** and **Constraints**.

## Step 1: The Setup

1. Open Xcode and create a new project. Select "App" and name it `HelloTodo`. Ensure the interface is set to **SwiftUI**.
2. Do **not** check the "Use SwiftData" box. We are going to make the AI write the data layer manually so you understand how to prompt for it.
3. Open your project folder in your AI editor (Cursor, Windsurf, or VSCode with Copilot).
4. Create a file named `.cursorrules` in the root of your project folder and paste this inside:

```markdown
# HelloTodo Global Rules
- Use SwiftUI for all UI.
- Use the `@Observable` macro for ViewModels (Do NOT use `ObservableObject` or `@Published`).
- Use SwiftData for persistence.
- Keep the UI clean, minimalistic, and use Apple's SF Symbols.
```
*Why do this?* Because without rules, the AI might hallucinate older iOS 14 code (like `@StateObject`). We are anchoring it to modern Swift.

## Step 2: The Data Layer (Prompt 1)

Never ask the AI to build the UI and the Database at the same time. Build the foundation first. 

Open a new AI chat and use this prompt:

> **Prompt 1: The Foundation**
> "We are building a To-Do app. 
> 1. Create a SwiftData `@Model` called `TodoItem` with an `id`, `title` (String), `isCompleted` (Bool), and `timestamp` (Date).
> 2. Show me exactly how to configure the `ModelContainer` inside my `HelloTodoApp.swift` file.
> 
> Do not generate any UI yet."

**What you learn here:** You explicitly told the AI *not* to build the UI. By constraining it to just the data model, it writes perfect, bug-free data code.

## Step 3: The Business Logic (Prompt 2)

Now we need a ViewModel to handle the fetching and saving of items.

> **Prompt 2: The Logic**
> "Great. Now, generate a `TodoListViewModel` using the `@Observable` macro. It should take a `ModelContext` in its initializer.
> Provide functions to:
> - Add a new item
> - Toggle an item's `isCompleted` state
> - Delete an item
> 
> Remember our `.cursorrules`: use modern `@Observable`, not `ObservableObject`."

**What you learn here:** We passed the `ModelContext` into the ViewModel via the initializer (Dependency Injection). This is crucial for keeping the architecture clean, as outlined in later chapters of this playbook.

## Step 4: The Interface (Prompt 3)

Now that the Data and Logic are done, the UI is trivial.

> **Prompt 3: The UI**
> "Now, generate the `ContentView.swift`. 
> It should display a `List` of the `TodoItem`s, sorted by timestamp.
> Use the `@Query` macro to fetch the items.
> Add a TextField at the top to add new items, and a swipe-to-delete modifier on the list rows.
> Make the row text strikethrough if `isCompleted` is true."

**What you learn here:** You gave the AI specific UX requirements (swipe-to-delete, strikethrough). Because the database and logic were already written, the AI easily hooks up the SwiftUI modifiers.

## Step 5: Run It!

Hit `Cmd + R` in Xcode. You just built an offline-first iOS app in 3 prompts. 

## The Core Lesson

You did not say: *"Build me a to-do app."*
You said: 
1. *"Build the database."*
2. *"Build the logic."*
3. *"Build the UI."*

This is **Incremental Prompting**. As you move into the advanced chapters of this playbook, you will apply this exact same 3-step mindset to massive Enterprise features involving background networking, CoreLocation, and complex animations. 

**Next Steps:** Proceed to **Chapter 17** to learn what to do when Xcode throws a massive red error during one of these steps.
