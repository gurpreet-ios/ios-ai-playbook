# 10 – Reusable Components Prompt

> Companion prompt document for `Views/Components/MovieCell.swift` and
> `Views/Components/EmptyStateView.swift`.

**Interview clock:** ~0:53 · **Time to type:** ~45 seconds

---

## What you say to the interviewer first

> "Two components: the result cell and one placeholder view reused for idle,
> empty, and error. The cell is where async image loading meets cell reuse —
> I'll cancel the task in prepareForReuse so a fast scroll can't paint a stale
> poster into a recycled cell. That race is the whole reason the loader takes
> a per-cell task instead of exposing a UIImageView extension."

---

## Prompt

```text
Create the Views/Components layer.

1. MovieCell.swift — final class MovieCell: UICollectionViewCell.
   Layout: 48×72 poster thumbnail (cornerRadius 6, aspectFill,
   secondarySystemBackground) on the leading edge; vertical stack of
   titleLabel (.headline, 2 lines) and subtitleLabel (.subheadline,
   secondaryLabel, "2021 · ★ 7.8") centered vertically beside it.

   configure(with movie: Movie, imageLoader: ImageLoading):
   - set texts (fallback "Year unknown")
   - set an SF Symbol "film" placeholder immediately
   - if posterURL exists, store a Task that awaits the loader and assigns
     the image only if !Task.isCancelled
   - make the cell one accessibility element: label
     "<title>, <year>, rated <x> out of 10", traits .button.

   prepareForReuse(): cancel + nil the task, nil the image. This is the
   review point — a reused cell must never show the previous movie's poster.

2. EmptyStateView.swift — final class EmptyStateView: UIView.
   Centered vertical stack: SF Symbol icon (tertiaryLabel, largeTitle scale),
   title (.headline), multiline message (.subheadline, secondaryLabel).
   configure(title:message:systemImage:) sets content and a combined
   accessibilityLabel. Used as the collection view's backgroundView.

Dynamic Type via preferredFont(forTextStyle:) throughout.
```

---

## Key Constraints Enforced

| # | Constraint | Why |
|---|-----------|-----|
| 1 | Task cancelled in `prepareForReuse` | The stale-poster race is *the* async-image-in-cells bug. |
| 2 | Placeholder set before the async load | No layout jump, no empty rectangle on slow networks. |
| 3 | Cell is one a11y element | VoiceOver reads "Dune, 2021, rated 7.8 out of 10" — not three fragments. |
| 4 | Loader injected per `configure` | The cell owns cancellation; the loader stays cache-only and reusable. |
| 5 | One `EmptyStateView` for three states | Idle/empty/error differ by copy, not by view hierarchy. |

---

## What to Review in the Output

- [ ] `prepareForReuse` calls `super`, cancels the task, and clears the image.
- [ ] The task captures `self` weakly.
- [ ] No `NSAttributedString` rating theatrics — plain text, Dynamic Type safe.
