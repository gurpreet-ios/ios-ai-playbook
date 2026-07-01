# Monetization: teaser site + paid PDF

The playbook is sold as a **downloadable PDF** via [Lemon Squeezy](https://lemonsqueezy.com)
(merchant-of-record — handles global VAT/sales tax and file delivery). The public
Astro Starlight site in [`site/`](site/) is a **free teaser funnel**: it ships only a
landing page, a pricing page, and the first three chapters as a sample. The full
content lives in the top-level content folders and is compiled into the PDF product.

## Why this split

The Starlight site is statically generated — every page it publishes is fully readable
in the browser. So the paid content is deliberately **excluded from the public build**
rather than "hidden" client-side (which is trivially bypassable). Buyers get the
complete material as the PDF.

## What's free vs paid

| | Location | In public site? |
|---|---|---|
| Landing page | `site/src/content/docs/index.mdx` | ✅ Free |
| Pricing page | `site/src/content/docs/pricing.mdx` | ✅ Free |
| Sample chapters 0–2 | `site/src/content/docs/handbook/0[0-2]-*.md` | ✅ Free |
| Everything else (ch. 3–29, prompts, ADRs, breakdowns, interview playbooks, sample apps, templates) | top-level `handbook/`, `prompts/`, `adrs/`, … | ❌ Paid (PDF only) |

To change which chapters are free, add/remove files under
`site/src/content/docs/handbook/` (copy them from the top-level `handbook/`).

## The paid product (PDF)

Generate the book with:

```bash
pip3 install markdown pygments        # one-time
python3 tools/build-book-pdf.py
# -> dist-book/the-senior-ai-engineering-playbook.pdf  (gitignored)
```

- Source: all of `handbook/*.md` (see [`tools/build-book-pdf.py`](tools/build-book-pdf.py)).
- Pipeline: Markdown → styled HTML → PDF via headless Google Chrome.
- Current output: ~82 pages, title page, table of contents, syntax-highlighted code.
- To include prompts/ADRs/etc. in the PDF, extend the `chapters` glob in the script.

Upload the generated PDF as the deliverable file on your Lemon Squeezy product.

## Wire up checkout (Lemon Squeezy)

1. Create the product in Lemon Squeezy and upload the PDF as the delivered file.
2. Copy its **Buy link** (`https://YOUR-STORE.lemonsqueezy.com/buy/<product-id>`).
3. Replace the two `REPLACE-WITH-PRODUCT-ID` placeholders in:
   - `site/src/content/docs/pricing.mdx`
   - (the homepage links to `/pricing/`, so it needs no direct checkout URL)
4. Optional overlay checkout (modal instead of new tab): append `?embed=1` to the buy
   link, keep `class="lemonsqueezy-button"`, and load `https://assets.lemonsqueezy.com/lemon.js`
   once in a shared `<head>`. See the comment block at the bottom of `pricing.mdx`.

Update the price (`$49`) in `pricing.mdx` and `index.mdx` if you change it.

## Build & deploy the teaser site

```bash
npm install --prefix site
npm run build --prefix site      # -> site/dist/ (6 pages)
```

Before deploying, set `site: 'https://your-domain'` in
[`site/astro.config.mjs`](site/astro.config.mjs) to enable sitemap + canonical URLs
(currently emits a harmless "Sitemap … requires the `site` option" warning).

Deploy `site/dist/` to any static host (Netlify, Vercel, Cloudflare Pages, GitHub Pages).

## Troubleshooting

- **`astro build`/`dev` hangs with no output:** the `site/node_modules` install can wedge
  (importing `vite` blocks), usually after a build is killed mid-flight. Fix:
  `rm -rf site/node_modules site/package-lock.json && npm install --prefix site`.
