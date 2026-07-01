---
title: "AI Architecture Breakdown: Instagram"
---

## Core Challenge
Infinite scrolling performance, massive image caching, and optimistic UI updates (liking a post).

## The Blueprint (AI Prompting Sequence)

### 1. The Image Pipeline
*Never decode images on the main thread.*
**Prompt:** "Generate an `ImageCache` actor. It should download images, downsample them to the requested bounding box on a background thread using `CGImageSourceCreateThumbnailAtIndex`, and cache the result in memory (NSCache) and on disk."

### 2. The Pagination Engine
**Prompt:** "Generate a `FeedRepository`. Implement cursor-based pagination. When the user scrolls to the 5th-to-last item, fetch the next page using the `next_cursor` token. Ensure duplicate posts are filtered out."

### 3. Optimistic UI Updates
**Prompt:** "When the user likes a post, immediately toggle the heart icon to red and increment the local like count in the view's state. Then, fire the network request in the background. If the request fails, revert the local state and show a toast error."

### 4. The Feed UI
**Prompt:** "Generate the feed using SwiftUI's `LazyVStack`. Ensure that the cell views are strictly isolated; a like on Cell #1 must NOT trigger a re-render of Cell #2."
