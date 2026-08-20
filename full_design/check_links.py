#!/usr/bin/env python3
"""Validate cross-reference links across full_design/*.md.

Every [text](NN_filename.md#anchor) link is checked against the actual
headings in the target file. Anchors use standard GitHub/CommonMark
slugification: lowercase, strip non-alphanumeric/hyphen/space characters,
then replace spaces with hyphens.

Also flags duplicate headings *within the same level* of a single document
(e.g. two "### Open Questions" in one file) — these collapse to the same
slug, so any link intending the second occurrence would silently resolve
to the first (or fail, depending on how it's written) rather than erroring
loudly. Checked one level at a time, top-down (#, then ##, then ###), not
across levels — a level-2 and level-3 heading sharing text is out of scope
for now.

Run from anywhere; paths are resolved relative to this script's directory:
    python3 full_design/check_links.py
"""
import re
import glob
import os
import sys

DIR = os.path.dirname(os.path.abspath(__file__))


def slugify(text):
    text = text.lower()
    text = re.sub(r"[^a-z0-9\- ]", "", text)
    return text.replace(" ", "-")


def find_duplicate_headings(path):
    """Return {level: [duplicate heading texts]} for headings repeated
    within the same level (#, ##, or ###) in this file. Cross-level
    collisions (a level-2 and level-3 heading sharing text) are out of
    scope by design — checked one level at a time, top-down."""
    by_level = {1: [], 2: [], 3: []}
    for line in open(path):
        m = re.match(r"^(#{1,3})\s+(.*)", line)
        if m:
            by_level[len(m.group(1))].append(m.group(2).strip())

    dups = {}
    for level in (1, 2, 3):
        seen = set()
        level_dups = []
        for text in by_level[level]:
            if text in seen and text not in level_dups:
                level_dups.append(text)
            seen.add(text)
        if level_dups:
            dups[level] = level_dups
    return dups


def main():
    anchors_in_file = {}
    duplicate_headings = {}
    for path in glob.glob(os.path.join(DIR, "*.md")):
        fname = os.path.basename(path)
        if fname == "DESIGN_TODO.md":
            continue
        anchors = set()
        for line in open(path):
            m = re.match(r"^(#{1,3})\s+(.*)", line)
            if m:
                anchors.add(slugify(m.group(2).strip()))
        anchors_in_file[fname] = anchors
        dups = find_duplicate_headings(path)
        if dups:
            duplicate_headings[fname] = dups

    broken = []
    for path in glob.glob(os.path.join(DIR, "*.md")):
        fname = os.path.basename(path)
        text = open(path).read()
        for m in re.finditer(r"\]\((0[0-9]_[a-z_]+\.md)#([a-z0-9\-]+)\)", text):
            target_file, anchor = m.group(1), m.group(2)
            if target_file not in anchors_in_file:
                broken.append((fname, target_file, anchor, "file not found"))
            elif anchor not in anchors_in_file[target_file]:
                broken.append((fname, target_file, anchor, "anchor not found"))

    print("Broken links:", len(broken))
    for b in broken:
        print(b)

    dup_count = sum(len(lv) for f in duplicate_headings.values() for lv in f.values())
    print("Duplicate headings (same level, needing to be collapsed/renamed):", dup_count)
    for fname, by_level in duplicate_headings.items():
        for level, texts in by_level.items():
            for text in texts:
                print((fname, "#" * level, text))

    sys.exit(1 if (broken or duplicate_headings) else 0)


if __name__ == "__main__":
    main()
