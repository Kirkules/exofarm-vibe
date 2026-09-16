#!/usr/bin/env python3
"""Data-integrity checks for full_design/data/*.csv, driven by schema.csv.

This is the CRUD-safety net for a folder of plain CSVs standing in for a
real database: nothing here enforces a foreign key automatically the way a
real DB would, so this script is what makes manual edits (by either of us,
in LibreOffice or a text editor) safe — run it after any edit that adds,
removes, or renames a row, the same way check_links.py gets run after a doc
edit.

Three independent checks:
  1. Row shape — every row has the header's field count (see
     build_values.py's check_row_shape, reused here).
  2. Design status vocabulary — every 'Design status' cell is one of
     TBD / Illustrative / Needs Balancing / Balanced <N>, or blank.
  3. Foreign keys — driven by schema.csv's Role column. A role of the form
     "[Key +] FK -> table.csv[ (Column)]" is a hard error if any referencing
     value has no matching row in the target table/column (defaulting to
     the same column name if none given). A role of
     "[Key +] Soft reference -> ..." is checked the same way but reported
     as a warning, never a hard failure — these are known-unenforceable by
     design (see each one's own Notes in schema.csv for why).

     Two conventions the Role-text parser understands specially:
       - "(self-referential)" means the target column is this table's own
         plain "Key"-role column, not a literal column named
         "self-referential".
       - "table.csv (Column) or table2.csv (Column2)" (multiple targets
         joined by "or") is checked only against the first target — a rare
         case, currently just one column
         (exploration_task_escalations.csv's Unlocks).
     A Role the parser can't confidently read, or whose target table/column
     doesn't exist, is skipped with a printed notice rather than crashing
     the run.

Run from anywhere; paths are resolved relative to this script's directory:
    python3 full_design/data/check_data.py
Exits 1 if any row-shape problem, invalid Design status, or hard FK
violation is found. Soft-reference mismatches print but never affect the
exit code.
"""
import csv
import glob
import os
import re
import sqlite3
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from build_values import FormulaError, check_row_shape, read_grid

DIR = os.path.dirname(os.path.abspath(__file__))
SCHEMA_PATH = os.path.join(DIR, "schema.csv")

VALID_STATUS_RE = re.compile(r"^(TBD|Illustrative|Needs Balancing|Balanced \d+)$")

ROLE_RE = re.compile(
    r"(?P<key>Key)?\s*\+?\s*(?P<kind>FK|Soft reference)\s*->\s*"
    r"(?P<table>[\w.]+\.csv)"
    r"(?:\s*\((?P<col>[^)]+)\))?"
)


def source_csvs():
    """Every hand-authored source CSV in the folder, excluding generated
    *.values.csv output and schema.csv itself (checked separately)."""
    return sorted(
        p for p in glob.glob(os.path.join(DIR, "*.csv"))
        if not p.endswith(".values.csv") and os.path.basename(p) != "schema.csv"
    )


# ---------------------------------------------------------------- 1. shape
def check_all_row_shapes():
    problems = []
    for path in source_csvs() + [SCHEMA_PATH]:
        try:
            check_row_shape(read_grid(path))
        except FormulaError as e:
            problems.append(f"{os.path.basename(path)}: {e}")
    return problems


# ---------------------------------------------------------- 2. status vocab
def check_design_status(path):
    grid = read_grid(path)
    if not grid or "Design status" not in grid[0]:
        return []
    idx = grid[0].index("Design status")
    problems = []
    for i, row in enumerate(grid[1:], start=2):
        if not row:
            continue
        val = row[idx].strip()
        if val and not VALID_STATUS_RE.match(val):
            problems.append(f"{os.path.basename(path)} row {i}: invalid Design status {val!r}")
    return problems


# --------------------------------------------------------- 3. foreign keys
def parse_schema():
    """Returns (tables, keys):
    tables: {table_basename: {column: role_text}}
    keys:   {table_basename: the column whose Role is the bare 'Key'} —
            used to resolve a "(self-referential)" target.
    """
    grid = read_grid(SCHEMA_PATH)
    header, rows = grid[0], grid[1:]
    ti, ci, ri = header.index("Table"), header.index("Column"), header.index("Role")
    tables, keys = {}, {}
    for row in rows:
        if not row:
            continue
        table, column, role = row[ti], row[ci], row[ri]
        tables.setdefault(table, {})[column] = role
        if role.strip() == "Key" and table not in keys:
            keys[table] = column
    return tables, keys


def load_csv_table(conn, name, loaded):
    if name in loaded:
        return True
    path = os.path.join(DIR, name)
    if not os.path.exists(path):
        return False
    grid = read_grid(path)
    if not grid:
        loaded.add(name)
        return True
    header, data = grid[0], grid[1:]
    cols = ", ".join(f'"{c}" TEXT' for c in header)
    conn.execute(f'CREATE TABLE "{name}" ({cols})')
    ph = ", ".join("?" * len(header))
    conn.executemany(f'INSERT INTO "{name}" VALUES ({ph})', [r for r in data if r])
    loaded.add(name)
    return True


def check_foreign_keys():
    tables, keys = parse_schema()
    conn = sqlite3.connect(":memory:")
    loaded = set()
    errors, warnings, skipped = [], [], []

    on_disk = {os.path.basename(p) for p in source_csvs()}
    undocumented = on_disk - set(tables)
    for name in sorted(undocumented):
        skipped.append(f"{name}: on disk but has no schema.csv entry (not checked)")

    for table, columns in tables.items():
        if not load_csv_table(conn, table, loaded):
            skipped.append(f"{table}: in schema.csv but not found on disk")
            continue
        for column, role in columns.items():
            m = ROLE_RE.search(role)
            if not m:
                continue  # plain Key / Value column, nothing to check
            kind = m.group("kind")
            target_table = m.group("table")
            target_col = m.group("col") or column
            if target_col.strip().lower() == "self-referential":
                target_col = keys.get(table, column)
            if not load_csv_table(conn, target_table, loaded):
                skipped.append(f"{table}.{column}: target table {target_table} not found")
                continue
            try:
                bad = [
                    r[0] for r in conn.execute(
                        f'SELECT DISTINCT "{column}" FROM "{table}" '
                        f"WHERE \"{column}\" IS NOT NULL AND \"{column}\" != '' "
                        f'AND "{column}" NOT IN '
                        f'(SELECT "{target_col}" FROM "{target_table}")'
                    ).fetchall()
                ]
            except sqlite3.OperationalError as e:
                skipped.append(f"{table}.{column}: {e}")
                continue
            if bad:
                label = f"{table}.{column} -> {target_table}.{target_col}: {bad}"
                (errors if kind == "FK" else warnings).append(label)
    return errors, warnings, skipped


def main():
    ok = True

    shape_problems = check_all_row_shapes()
    print(f"Row-shape problems: {len(shape_problems)}")
    for p in shape_problems:
        print(" ", p)
    ok &= not shape_problems

    status_problems = []
    for path in source_csvs():
        status_problems += check_design_status(path)
    print(f"Invalid Design status values: {len(status_problems)}")
    for p in status_problems:
        print(" ", p)
    ok &= not status_problems

    errors, warnings, skipped = check_foreign_keys()
    print(f"Foreign-key violations (hard): {len(errors)}")
    for e in errors:
        print(" ", e)
    print(f"Soft-reference mismatches (warning only): {len(warnings)}")
    for w in warnings:
        print(" ", w)
    if skipped:
        print(f"Skipped (unparseable/unresolvable — not a failure): {len(skipped)}")
        for s in skipped:
            print(" ", s)
    ok &= not errors

    print()
    print("ALL CHECKS CLEAN" if ok else "ISSUES FOUND ABOVE")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
