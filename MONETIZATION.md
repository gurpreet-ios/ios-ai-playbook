# Distribution: community-first

> **Status (2026-07-04):** The teaser-site + paid-PDF plan is retired before launch. The repo is **fully open** — handbook, prompts, skills, ADRs, sample apps, everything. Distribution now runs community-first: post where iOS engineers are, capture the audience in a newsletter, build the repo into the community home. Monetization is deferred until the audience exists. (The old paid-PDF model is preserved in this file's git history, pre-2026-07-04.)

## Why the pivot

Two structured reviews of this project reached the same diagnosis from different angles:

1. **Distribution, not product, is the binding constraint.** The paywall was ~90% built while the audience was 0% built. A $49 PDF sold into zero traffic produces zero sales *and zero information*.
2. **The email list is the compounding asset.** Whatever gets monetized later — a paid tier, a polished edition, courses — is sold to a list, not to strangers. Building the list is the prerequisite, not the alternative.
3. **A community also answers the open product questions** (do readers run the artifacts or just read? which chapters land?) that no amount of solo planning could.

## The model

| Layer | Role |
| :-- | :-- |
| **GitHub repo (fully open)** | The product and the community home. Stars/issues/PRs are the engagement surface. |
| **Substack newsletter** | The owned capture point — one standalone-value post per week, drafted in [`newsletter/`](newsletter/README.md), each sourced from a strong chapter and linking back to the repo. |
| **Posting channels** | Where the audience actually is: r/iOSProgramming, r/swift, Swift Forums, Hacker News, X iOS-dev circles. Substack captures; it does not distribute. |

## Forcing functions

Deliberate guardrails so "building an audience" doesn't become open-ended deferral:

- **Cadence:** one post per week. Post 001 publishes by **2026-07-11**.
- **Checkpoint:** **2026-10-04** (90 days) — review subscribers, open rate, repo stars/traffic, and decide the monetization move with data.
- **Quality gate:** the verification work (skills test harness, freshness badges, link-checker) matters *more* with an open repo — public readers run things and report failures publicly.

## Deferred monetization options

Decided at the checkpoint, not before: paid newsletter tier · polished/typeset edition · sponsorship · courses/workshops. The PDF pipeline is retained for that future:

```bash
pip3 install markdown pygments        # one-time
python3 tools/build-book-pdf.py
# -> dist-book/the-senior-ai-engineering-playbook.pdf  (~152 pages, gitignored)
```

## The site (reworked 2026-07-04 — fully open)

The paywall is gone from [`site/`](site/): the pricing page is deleted, all 38 chapters + the Model Landscape appendix are published, and the homepage CTAs are read/star/subscribe. Chapters are synced from `handbook/` by a repeatable script — **run it after any handbook change**:

```bash
python3 tools/sync-site-chapters.py    # handbook/*.md -> site/src/content/docs/handbook/
npm run build --prefix site
```

The script injects Starlight `title` frontmatter and rewrites links (chapter-to-chapter → site URLs; links out of `handbook/` → GitHub). Do not hand-edit files under `site/src/content/docs/handbook/` — they are generated.

Two placeholders remain before deploy:
1. `https://YOUR-SUBSTACK.substack.com` in `site/src/content/docs/index.mdx` — replace once the Substack exists.
2. `site:` in `site/astro.config.mjs` — set the real domain (enables sitemap + canonical URLs).

## Build & deploy the site (unchanged mechanics)

```bash
npm install --prefix site
npm run build --prefix site      # -> site/dist/
```

Set `site: 'https://your-domain'` in [`site/astro.config.mjs`](site/astro.config.mjs) before deploying (sitemap + canonical URLs). Deploy `site/dist/` to any static host.

**Troubleshooting:** if `astro build`/`dev` hangs with no output, the `site/node_modules` install wedged — fix with `rm -rf site/node_modules site/package-lock.json && npm install --prefix site`.
