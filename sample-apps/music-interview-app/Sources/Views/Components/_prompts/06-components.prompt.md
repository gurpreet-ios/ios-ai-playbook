# Prompt 6 — Shared Components

> Used after the screens existed and review flagged duplicated artwork
> placeholders (same shape, same accessibility modifiers) in
> `LibraryView` and `NowPlayingView`.

Extract the duplicated album-art placeholder into a reusable component:

- `TrackArtworkView` in `Sources/Views/Components/`, taking the track
  title (optional — `nil` renders the "No Album Art" state) and a
  corner radius with a sensible default.
- The component owns its accessibility: `accessibilityLabel` derived
  from the title, plus the `.isImage` trait — call sites must not need
  to remember these.
- Layout concerns that differ per call site (frame, aspect ratio,
  shadow, padding) stay AT the call site; the component renders only
  the artwork surface.
- Rewire `LibraryView` and `NowPlayingView` to use it. No visual change:
  this is a pure extraction, and the snapshot suite must agree.
