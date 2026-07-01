# Chapter 13: iOS System Integration

> "An app that only exists when it is open on the screen is not an iOS app. It is a web page."

Modern iOS development requires deep integration with the operating system. Users expect your app to surface data on their Lock Screen, update them dynamically via the Dynamic Island, and sync silently in the background.

AI struggles with system integration because it requires orchestrating multiple targets (e.g., the Main App and a Widget Extension) and sharing data across deeply isolated process boundaries.

---

## 1. Widgets & App Extensions

### Definition
Home Screen and Lock Screen widgets written in SwiftUI using the `WidgetKit` framework. 

### The Architecture Challenge
Widgets run in a completely separate process from your main app. If your AI generates a widget that tries to read from a standard `UserDefaults.standard` or an in-memory Singleton, it will fail silently.

### AI Prompting Strategy
You must explicitly command the AI to cross the process boundary using App Groups.
* **Senior Prompt:** "Generate a `Widget` using `WidgetKit`. **CRITICAL:** Do not use standard UserDefaults. You must read the widget data from the shared App Group container `group.com.company.app`. Read the data from a shared JSON file written to that group's FileManager directory."

---

## 2. Live Activities & Dynamic Island

### Definition
Real-time, glanceable updates on the Lock Screen and Dynamic Island using `ActivityKit`.

### Tradeoffs
- **Pros:** Incredible user engagement for time-sensitive events (Uber rides, sports scores).
- **Cons:** Extremely strict payload size limits (4KB) and update frequency limits.

### AI Prompting Strategy
* **Senior Prompt:** "Implement a Live Activity for a 'Delivery Tracker'. Define the `ActivityAttributes`. Ensure the Dynamic Island views (expanded, compact leading, compact trailing, and minimal) all use highly constrained layouts. Do not use complex imagery that exceeds the 4KB payload limit."

---

## 3. Push Notifications & Deep Links

### Definition
Waking the app up remotely (`UNUserNotificationCenter`) and routing the user to a specific screen based on a URL scheme or Universal Link.

### AI Prompting Strategy
The AI is very good at parsing JSON payloads, but bad at injecting that payload into your View hierarchy. 
* **Senior Prompt:** "Write the `UNUserNotificationCenterDelegate` to handle incoming push notifications. When the user taps the notification, extract the `order_id` from the `userInfo` dictionary. Pass this ID into our `AppRouter` class via deep link URL so the UI can navigate to the Order Details screen."

---

## 4. Background Tasks

### Definition
Executing code when the app is suspended (e.g., syncing a database at 3 AM) using `BGTaskScheduler`.

### AI Prompting Strategy
Background tasks have strict time limits (usually ~30 seconds) before the OS kills your app.
* **Senior Prompt:** "Implement a `BGAppRefreshTask`. You must wrap the execution logic in a `Task`. You MUST handle task expiration gracefully by listening to `task.expirationHandler` and canceling the ongoing network request immediately if triggered."

---

## 5. VisionOS (Spatial Computing)

### Definition
Developing for the Apple Vision Pro using `visionOS`. While it uses SwiftUI, the Z-axis (depth), Volumes, and Immersive Spaces completely alter the interaction paradigm.

### AI Prompting Strategy
LLMs trained before 2024 have very little knowledge of VisionOS. You must use RAG (Context Engineering) to feed them the latest Apple documentation.
* **Senior Prompt:** "We are building a visionOS app. Attached is the documentation for `ImmersiveSpace` and `RealityView`. Generate a SwiftUI view that opens an `ImmersiveSpace` and places a 3D `ModelEntity` at coordinate (0, 1.5, -2)."

---

By mastering these system integrations, you elevate your app from a basic utility to a first-class citizen in the Apple ecosystem. In the accompanying `ios/AIPlaybookSampleApp`, we provide runnable examples of how to share state across these tricky process boundaries.
