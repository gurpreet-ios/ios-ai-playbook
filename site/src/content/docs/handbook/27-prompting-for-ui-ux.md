---
title: "Chapter 27: Prompting for UI/UX"
---

> "AI is terrible at reading your mind. If you say 'make it look good', you will get a generic, flat, blue interface. You must prompt for specific aesthetics."

As a beginner, you might not know the exact SwiftUI modifiers to create a "glassmorphism" effect or a fluid spring animation. The good news is, you don't need to know the modifiers. You just need to know the *design vocabulary*.

If you give the AI the right design vocabulary, it will translate that into the correct SwiftUI code (e.g., `.background(.ultraThinMaterial)`, `.animation(.spring(response: 0.3, dampingFraction: 0.6))`).

## The Aesthetic Vocabulary

Instead of saying "make it pretty," use these specific prompt keywords:

### 1. Glassmorphism (The Modern Apple Look)
This creates the frosted glass effect seen in Control Center and modern iOS apps.
* **Prompt Phrase:** *"Apply a glassmorphism effect to this card."* or *"Use Apple's ultra-thin materials and a subtle drop shadow."*
* **What the AI writes:** `.background(.ultraThinMaterial)`, `.shadow(radius: 10)`

### 2. Neumorphism (Soft UI)
This creates soft, extruded plastic looks (though less common in iOS 18, it's a specific style).
* **Prompt Phrase:** *"Style this button using neumorphism. It should look like it's extruding from the background using a light shadow on the top left and a dark shadow on the bottom right."*

### 3. Fluid Animations (The "Bouncy" Feel)
By default, AI uses `.animation(.default)`, which looks stiff and robotic. Apple's modern interfaces feel fluid and physics-based.
* **Prompt Phrase:** *"Make the transition fluid and bouncy. Use a custom spring animation with a low damping fraction, rather than a linear or default animation."*
* **What the AI writes:** `.animation(.spring(response: 0.4, dampingFraction: 0.5, blendDuration: 0))`

### 4. Haptic Feedback (Physical Feel)
AI often forgets that phones have vibration motors.
* **Prompt Phrase:** *"Add haptic feedback to this button tap. Use a light impact generator for selection, and a heavy impact generator for confirmation."*
* **What the AI writes:** `UIImpactFeedbackGenerator(style: .light).impactOccurred()`

### 5. Semantic Colors (Dark Mode Support)
If you prompt "Make the background white," your app will look terrible in Dark Mode.
* **Prompt Phrase:** *"Do not hardcode colors. Use semantic iOS colors like `.secondarySystemBackground` and `.label` so it supports Dark Mode natively."*

## The "Hero Animation" Prompt Template

When you want to build a truly impressive screen (like a profile view or a detail screen), use this prompt template to get the AI to generate something that feels like a polished App Store app:

> **The UI/UX Prompt**
> "We are building the `ProfileView`. I want it to feel premium and native to iOS.
> 
> **Aesthetic Requirements:**
> - Use a glassmorphism effect for the background of the user stats card.
> - Ensure all colors are Semantic so Dark Mode works flawlessly.
> - Add a fluid, bouncy spring animation when the user taps the 'Follow' button, scaling it down slightly on press.
> - Include light haptic feedback when the button is tapped.
> - Use `.largeTitle` for the user's name, but ensure the font weight is `.heavy`.
> 
> Write the SwiftUI code for this view."

By learning to speak to the AI like a Designer, you force the AI to write SwiftUI code like a Senior UI Engineer.
