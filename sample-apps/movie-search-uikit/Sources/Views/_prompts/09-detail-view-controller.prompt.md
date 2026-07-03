# 09 – MovieDetailViewController Prompt

> Companion prompt document for `Views/MovieDetailViewController.swift`.

**Interview clock:** ~0:48 · **Time to type:** ~50 seconds

---

## What you say to the interviewer first

> "Detail screen renders a movie the ViewModel already has — no refetch, no
> loading state. The only live state is the favorite star, which is bound to a
> Box so the button can't drift from UserDefaults."

---

## Prompt

```text
Create Views/MovieDetailViewController.swift.

final class MovieDetailViewController: UIViewController, injected with
MovieDetailViewModel and ImageLoading via init.

Layout — UIScrollView + vertical UIStackView (spacing 16, 16pt margins,
stack width pinned to the scroll view's frameLayoutGuide):
- posterImageView: aspectFill, cornerRadius 12, secondarySystemBackground
  placeholder with an SF Symbol "film", height = width × 1.5 (2:3 one-sheet
  ratio). accessibilityLabel "Poster for <title>".
- titleLabel: .title1 preferred font, multiline.
- metadataLabel: .subheadline, secondaryLabel color (viewModel.metadataText).
- overviewLabel: .body, multiline (viewModel.overviewText).
All fonts via preferredFont(forTextStyle:) with
adjustsFontForContentSizeCategory = true.

Favorite:
- UIBarButtonItem star as rightBarButtonItem.
- bind viewModel.isFavorite → swap "star"/"star.fill" and set
  accessibilityLabel "Add to favorites"/"Remove from favorites".
- tap → viewModel.toggleFavorite(). The tap handler must NOT set the icon
  directly — the binding renders it.

Poster loading: a stored Task awaiting imageLoader.image(from:), checked for
cancellation before assigning, cancelled in deinit.

navigationItem.largeTitleDisplayMode = .never.
```

---

## Key Constraints Enforced

| # | Constraint | Why |
|---|-----------|-----|
| 1 | Tap handler never mutates the star icon | Unidirectional: event → ViewModel → store → binding → render. |
| 2 | Image task cancelled in `deinit` | Pop the screen mid-download and nothing dangles. |
| 3 | Stack width pinned to `frameLayoutGuide` | The scroll view scrolls vertically only — the classic Auto Layout scroll-view trap. |
| 4 | Dynamic Type everywhere | `.cursorrules` rule 8; hardcoded sizes fail the a11y review. |
| 5 | No refetch on the detail screen | The search result already carries everything; a spinner here is invented latency. |

---

## What to Review in the Output

- [ ] `guard !Task.isCancelled` before the image assignment.
- [ ] Favorite accessibilityLabel flips with state (VoiceOver hears the action, not the icon name).
- [ ] Placeholder shows for movies without a poster URL — no blank rectangle.
