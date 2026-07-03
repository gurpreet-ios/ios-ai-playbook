#!/usr/bin/env python3
"""
Sync every handbook chapter into the Astro Starlight site.

Since the community-first pivot (see MONETIZATION.md), the full handbook is
published on the site — this script is the one-way sync:

    handbook/*.md  ->  site/src/content/docs/handbook/*.md

Per file it:
  1. extracts the first H1 as Starlight `title` frontmatter (H1 stripped from
     the body — Starlight renders the title itself);
  2. rewrites links: chapter-to-chapter .md links become site URLs
     (/handbook/<slug>/), links escaping the handbook (../prompts/, ../adrs/,
     ../sample-apps/, ...) become GitHub URLs.

Run it after any handbook change that should reach the site:

    python3 tools/sync-site-chapters.py
    npm run build --prefix site
"""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HANDBOOK = os.path.join(ROOT, "handbook")
SITE_DOCS = os.path.join(ROOT, "site", "src", "content", "docs", "handbook")
GITHUB = "https://github.com/gurpreet-ios/ios-ai-playbook"

LINK_RE = re.compile(r"(\]\()([^)\s]+)(\))")


def transform_target(target: str) -> str:
    if target.startswith(("http://", "https://", "#", "mailto:", "/")):
        return target
    anchor = ""
    path = target
    if "#" in path:
        path, frag = path.split("#", 1)
        anchor = "#" + frag
    # Links out of handbook/ -> GitHub (blob for files, tree for dirs)
    if path.startswith("../"):
        rel = path[3:].rstrip("/")
        kind = "blob" if re.search(r"\.[A-Za-z0-9]+$", rel) else "tree"
        return f"{GITHUB}/{kind}/main/{rel}{anchor}"
    # Sibling chapter links -> site URLs
    if path.endswith(".md"):
        return f"/handbook/{path[:-3]}/{anchor}"
    return target


def convert(md_text: str, filename: str) -> str:
    lines = md_text.splitlines()
    title, h1_index = None, None
    for i, line in enumerate(lines):
        m = re.match(r"^#\s+(.+?)\s*$", line)
        if m:
            title, h1_index = m.group(1), i
            break
    if title is None:
        sys.exit(f"{filename}: no H1 found — cannot derive a title.")
    body = "\n".join(lines[h1_index + 1 :]).lstrip("\n")
    body = LINK_RE.sub(lambda m: m.group(1) + transform_target(m.group(2)) + m.group(3), body)
    # json.dumps gives us a YAML-safe double-quoted scalar.
    return f"---\ntitle: {json.dumps(title)}\n---\n\n{body}\n"


def main():
    os.makedirs(SITE_DOCS, exist_ok=True)
    chapters = sorted(f for f in os.listdir(HANDBOOK) if f.endswith(".md"))
    if not chapters:
        sys.exit("No handbook chapters found.")
    stale = set(f for f in os.listdir(SITE_DOCS) if f.endswith(".md")) - set(chapters)
    for name in chapters:
        with open(os.path.join(HANDBOOK, name), encoding="utf-8") as f:
            out = convert(f.read(), name)
        with open(os.path.join(SITE_DOCS, name), "w", encoding="utf-8") as f:
            f.write(out)
    for name in stale:
        os.remove(os.path.join(SITE_DOCS, name))
        print(f"Removed stale: {name}")
    print(f"Synced {len(chapters)} chapters -> {os.path.relpath(SITE_DOCS, ROOT)}")


if __name__ == "__main__":
    main()
