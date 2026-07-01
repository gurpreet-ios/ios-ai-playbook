#!/usr/bin/env python3
"""
Build the paid product: a single styled PDF of the full handbook.

Pipeline: handbook/*.md  ->  one styled HTML  ->  PDF (via headless Chrome).

Usage:
    python3 tools/build-book-pdf.py

Output:
    dist-book/the-senior-ai-engineering-playbook.pdf   (gitignored)

Requirements:
    pip3 install markdown pygments
    Google Chrome installed (used headless for HTML -> PDF).
"""
import os
import re
import glob
import html
import subprocess
import sys

import markdown
from pygments.formatters import HtmlFormatter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HANDBOOK = os.path.join(ROOT, "handbook")
OUT_DIR = os.path.join(ROOT, "dist-book")
HTML_PATH = os.path.join(OUT_DIR, "book.html")
PDF_PATH = os.path.join(OUT_DIR, "the-senior-ai-engineering-playbook.pdf")

BOOK_TITLE = "The Senior AI Engineering Playbook"
BOOK_SUBTITLE = "The definitive handbook for AI-native software engineering"
BOOK_AUTHOR = "Gurpreet Singh"

CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"


def slugify(text):
    s = re.sub(r"[^\w\s-]", "", text.lower()).strip()
    return re.sub(r"[\s_-]+", "-", s)


def first_h1(md_text):
    for line in md_text.splitlines():
        m = re.match(r"^#\s+(.+?)\s*$", line)
        if m:
            return m.group(1).strip()
    return None


def strip_frontmatter(md_text):
    if md_text.startswith("---"):
        m = re.match(r"^---\r?\n.*?\r?\n---\r?\n?", md_text, re.DOTALL)
        if m:
            return md_text[m.end():]
    return md_text


def build():
    os.makedirs(OUT_DIR, exist_ok=True)
    chapters = sorted(glob.glob(os.path.join(HANDBOOK, "*.md")))
    if not chapters:
        sys.exit("No handbook chapters found.")

    toc_items = []
    body_parts = []
    for path in chapters:
        with open(path, encoding="utf-8") as f:
            raw = strip_frontmatter(f.read())
        title = first_h1(raw) or os.path.basename(path)
        anchor = "ch-" + slugify(title)
        toc_items.append((title, anchor))

        # Convert markdown. codehilite -> pygments classes; guess_lang off for speed.
        md = markdown.Markdown(
            extensions=["fenced_code", "codehilite", "tables", "toc", "sane_lists"],
            extension_configs={"codehilite": {"guess_lang": False, "css_class": "codehilite"}},
        )
        chapter_html = md.convert(raw)
        body_parts.append(
            f'<section class="chapter" id="{anchor}">\n{chapter_html}\n</section>'
        )

    toc_html = "\n".join(
        f'<li><a href="#{a}">{html.escape(t)}</a></li>' for t, a in toc_items
    )
    pygments_css = HtmlFormatter(style="friendly").get_style_defs(".codehilite")

    doc = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>{html.escape(BOOK_TITLE)}</title>
<style>
@page {{ size: A4; margin: 22mm 20mm; }}
* {{ box-sizing: border-box; }}
body {{
  font-family: "Iowan Old Style", "Palatino Linotype", Georgia, serif;
  font-size: 11pt; line-height: 1.6; color: #1a1a2e; margin: 0;
}}
h1, h2, h3, h4 {{ font-family: -apple-system, "Helvetica Neue", Arial, sans-serif; color: #16213e; line-height: 1.25; }}
h1 {{ font-size: 22pt; margin: 0 0 .4em; }}
h2 {{ font-size: 16pt; margin: 1.6em 0 .5em; border-bottom: 1px solid #e0e0ec; padding-bottom: .2em; }}
h3 {{ font-size: 13pt; margin: 1.2em 0 .4em; }}
p {{ margin: 0 0 .8em; }}
a {{ color: #3a3a8c; text-decoration: none; }}
blockquote {{ margin: 1em 0; padding: .4em 1em; border-left: 3px solid #6c63ff; background: #f6f6fb; color: #333; font-style: italic; }}
code {{ font-family: "SF Mono", "JetBrains Mono", Menlo, Consolas, monospace; font-size: 9.5pt; }}
:not(pre) > code {{ background: #f0f0f6; padding: .1em .35em; border-radius: 3px; }}
pre {{ background: #f7f7fb; border: 1px solid #e6e6f0; border-radius: 6px; padding: .8em 1em; overflow-x: auto; font-size: 9pt; line-height: 1.45; page-break-inside: avoid; }}
table {{ border-collapse: collapse; width: 100%; margin: 1em 0; font-size: 9.5pt; }}
th, td {{ border: 1px solid #ddd; padding: .4em .6em; text-align: left; }}
th {{ background: #f2f2f8; }}
img {{ max-width: 100%; }}

/* Title page */
.title-page {{ height: 100vh; display: flex; flex-direction: column; justify-content: center; align-items: center; text-align: center; page-break-after: always; }}
.title-page .big {{ font-size: 34pt; font-weight: 800; color: #16213e; max-width: 80%; line-height: 1.15; }}
.title-page .sub {{ font-size: 14pt; color: #555; margin-top: 1em; max-width: 70%; }}
.title-page .author {{ margin-top: 3em; font-size: 12pt; color: #333; letter-spacing: .05em; }}
.title-page .rule {{ width: 60px; height: 4px; background: #6c63ff; margin: 1.4em 0; }}

/* TOC */
.toc {{ page-break-after: always; }}
.toc h2 {{ border: 0; }}
.toc ol {{ line-height: 2; padding-left: 1.4em; }}
.toc a {{ color: #16213e; }}

.chapter {{ page-break-before: always; }}
.chapter:first-of-type {{ page-break-before: avoid; }}
</style>
</head>
<body>
  <div class="title-page">
    <div class="big">{html.escape(BOOK_TITLE)}</div>
    <div class="rule"></div>
    <div class="sub">{html.escape(BOOK_SUBTITLE)}</div>
    <div class="author">{html.escape(BOOK_AUTHOR)}</div>
  </div>

  <nav class="toc">
    <h2>Contents</h2>
    <ol>
      {toc_html}
    </ol>
  </nav>

  <style>{pygments_css}</style>
  {''.join(body_parts)}
</body>
</html>
"""
    with open(HTML_PATH, "w", encoding="utf-8") as f:
        f.write(doc)
    print(f"Wrote HTML: {HTML_PATH} ({len(doc)//1024} KB)")

    if not os.path.exists(CHROME):
        sys.exit(f"Chrome not found at {CHROME}; cannot render PDF.")

    cmd = [
        CHROME, "--headless=new", "--disable-gpu", "--no-sandbox",
        "--no-pdf-header-footer",
        f"--print-to-pdf={PDF_PATH}",
        "--print-to-pdf-no-header",
        f"file://{HTML_PATH}",
    ]
    subprocess.run(cmd, check=True, timeout=180,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    size = os.path.getsize(PDF_PATH) / 1024
    print(f"Wrote PDF:  {PDF_PATH} ({size:.0f} KB)")


if __name__ == "__main__":
    build()
