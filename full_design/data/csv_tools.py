#!/usr/bin/env python3
"""Shared helper for authoring full_design/data/*.csv correctly.

The failure mode this exists to prevent: hand-typing a CSV row as raw text
and forgetting to quote a field that contains a comma. That's exactly what
corrupted a row of techachievement_catalog.csv when it was first authored —
build_values.py's row-length check caught it, but only because the shift
happened to change the field count; a trailing empty field can absorb the
shift and leave the count unchanged, which no downstream check can then
tell apart from a correct row. The fix is upstream: never hand-type a row
as text at all.

Usage — always build rows as a plain list of field values (no manual
comma-joining, no manual quoting) and write them through this:

    from csv_tools import write_csv
    write_csv("full_design/data/foo.csv",
              ["Entry", "Tier", "Category", "Design status", "Notes"],
              [["Widget (small, cheap)", "0", "Fabrication", "TBD", ""],
               ["Widget (large)", "1", "Fabrication", "TBD", ""]])

csv.writer (QUOTE_MINIMAL) quotes any field containing a comma, a double
quote, or a newline automatically — there is no quoting decision to get
wrong. Never construct a CSV row by joining strings with "," directly.
"""
import csv


def write_csv(path, header, rows):
    """Write header + rows to path as a correctly-quoted CSV.

    Every row must have the same number of fields as header — mismatches
    are almost always a sign a row was built wrong (e.g. a field
    accidentally split into two), so this fails loudly rather than writing
    a silently-misaligned file.
    """
    width = len(header)
    for i, row in enumerate(rows, start=1):
        if len(row) != width:
            raise ValueError(
                f"row {i} has {len(row)} fields, expected {width} "
                f"(header: {header}): {row!r}"
            )
    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f, lineterminator="\n")
        writer.writerow(header)
        writer.writerows(rows)
