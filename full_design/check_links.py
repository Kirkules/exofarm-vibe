#!/usr/bin/env python3
"""Validate cross-reference links across full_design/*.md.

Every [text](NN_filename.md#anchor) link is checked against the actual
headings in the target file. Anchors use standard GitHub/CommonMark
slugification: lowercase, strip non-alphanumeric/hyphen/space characters,
then replace spaces with hyphens.

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


def main():
    anchors_in_file = {}
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
    sys.exit(1 if broken else 0)


if __name__ == "__main__":
    main()
