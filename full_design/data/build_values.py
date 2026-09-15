#!/usr/bin/env python3
"""Evaluate formulas in full_design/data/*.csv, writing *.values.csv.

Workflow: every table lives as a source `<name>.csv` — the only file either
of us hand-edits, opened directly in LibreOffice Calc. A cell may contain a
literal spreadsheet formula (e.g. "=B2*2"); this script evaluates every such
cell and writes a plain, fully-computed `<name>.values.csv` next to it. Only
the generated *.values.csv files are ever read back into the design docs or
by Claude — never the formula source directly, and never by hand.

*.values.csv is gitignored and regenerated on demand; only the source CSVs
and this script are committed.

Supported formula subset (deliberately small — anything needing more than
this should just be a plain authored value instead):
  - Arithmetic: + - * / ( ) and unary minus
  - Cell references: A2, B3, ... (column letters, 1-based row matching the
    CSV's own row numbering, i.e. row 1 is the header row)
  - Ranges for SUM/MIN/MAX: A2:A10
  - Functions: SUM, MIN, MAX, ROUND(value, digits), CEILING(value[, sig]),
    FLOOR(value[, sig]), IF(cond, then, else)
  - Comparisons inside IF: = < > <= >= <>

Run from anywhere; paths are resolved relative to this script's directory:
    python3 full_design/data/build_values.py
"""
import csv
import glob
import os
import re
import sys

DIR = os.path.dirname(os.path.abspath(__file__))

TOKEN_RE = re.compile(r"""
    \s*(?:
        (?P<num>\d+\.\d+|\d+)
      | (?P<ref>[A-Z]+\d+)
      | (?P<str>"[^"]*")
      | (?P<op><=|>=|<>|[+\-*/()<>=,:])
      | (?P<name>[A-Z]+)
    )
""", re.VERBOSE)


class FormulaError(Exception):
    pass


def col_to_index(col):
    """'A' -> 0, 'B' -> 1, ... 'AA' -> 26, ..."""
    idx = 0
    for ch in col:
        idx = idx * 26 + (ord(ch) - ord("A") + 1)
    return idx - 1


def parse_ref(ref):
    m = re.match(r"([A-Z]+)(\d+)", ref)
    col, row = m.group(1), int(m.group(2))
    return row - 1, col_to_index(col)  # 0-based (row, col) into the grid


class Tokenizer:
    def __init__(self, text):
        self.tokens = []
        pos = 0
        while pos < len(text):
            m = TOKEN_RE.match(text, pos)
            if not m or m.end() == pos:
                if text[pos:].strip() == "":
                    break
                raise FormulaError(f"unexpected character at {pos!r} in {text!r}")
            pos = m.end()
            for kind, val in m.groupdict().items():
                if val is not None:
                    self.tokens.append((kind, val))
                    break
        self.i = 0

    def peek(self):
        return self.tokens[self.i] if self.i < len(self.tokens) else (None, None)

    def next(self):
        tok = self.peek()
        self.i += 1
        return tok

    def expect(self, val):
        kind, tokval = self.next()
        if tokval != val:
            raise FormulaError(f"expected {val!r}, got {tokval!r}")


class Evaluator:
    """Evaluates one CSV's formulas, resolving cross-cell references lazily
    with memoization and cycle detection."""

    def __init__(self, grid):
        self.grid = grid  # list of list of raw string cells
        self.cache = {}
        self.in_progress = set()

    def cell_value(self, row, col):
        if row >= len(self.grid) or col >= len(self.grid[row]):
            return 0
        if (row, col) in self.cache:
            return self.cache[(row, col)]
        if (row, col) in self.in_progress:
            raise FormulaError(f"circular reference at row {row+1}, col {col+1}")
        raw = self.grid[row][col]
        if raw.startswith("="):
            self.in_progress.add((row, col))
            try:
                value = self.eval_formula(raw[1:])
            finally:
                self.in_progress.discard((row, col))
        else:
            value = to_number_or_str(raw)
        self.cache[(row, col)] = value
        return value

    def eval_formula(self, text):
        tok = Tokenizer(text)
        result = self.parse_expr(tok)
        if tok.peek() != (None, None):
            raise FormulaError(f"trailing tokens in formula: {text!r}")
        return result

    # Recursive-descent: expr -> term (('+'|'-') term)*
    def parse_expr(self, tok):
        value = self.parse_term(tok)
        while tok.peek()[1] in ("+", "-", "=", "<", ">", "<=", ">=", "<>"):
            op = tok.next()[1]
            rhs = self.parse_term(tok)
            value = apply_op(op, value, rhs)
        return value

    def parse_term(self, tok):
        value = self.parse_factor(tok)
        while tok.peek()[1] in ("*", "/"):
            op = tok.next()[1]
            rhs = self.parse_factor(tok)
            value = apply_op(op, value, rhs)
        return value

    def parse_factor(self, tok):
        kind, val = tok.peek()
        if val == "-":
            tok.next()
            return -self.parse_factor(tok)
        if val == "(":
            tok.next()
            value = self.parse_expr(tok)
            tok.expect(")")
            return value
        if kind == "num":
            tok.next()
            return float(val) if "." in val else int(val)
        if kind == "str":
            tok.next()
            return val[1:-1]
        if kind == "ref":
            tok.next()
            row, col = parse_ref(val)
            return self.cell_value(row, col)
        if kind == "name":
            return self.parse_function(tok)
        raise FormulaError(f"unexpected token {val!r}")

    def parse_function(self, tok):
        name = tok.next()[1]
        tok.expect("(")
        args = []
        if tok.peek()[1] != ")":
            args.append(self.parse_range_or_expr(tok))
            while tok.peek()[1] == ",":
                tok.next()
                args.append(self.parse_range_or_expr(tok))
        tok.expect(")")
        flat = []
        for a in args:
            flat.extend(a) if isinstance(a, list) else flat.append(a)
        return call_function(name, flat)

    def parse_range_or_expr(self, tok):
        kind, val = tok.peek()
        if kind == "ref":
            save = tok.i
            tok.next()
            if tok.peek()[1] == ":":
                tok.next()
                _, end_ref = tok.next()
                r1, c1 = parse_ref(val)
                r2, c2 = parse_ref(end_ref)
                return [
                    self.cell_value(r, c)
                    for r in range(min(r1, r2), max(r1, r2) + 1)
                    for c in range(min(c1, c2), max(c1, c2) + 1)
                ]
            tok.i = save
        return self.parse_expr(tok)


def to_number_or_str(raw):
    raw = raw.strip()
    if raw == "":
        return ""
    try:
        return int(raw)
    except ValueError:
        pass
    try:
        return float(raw)
    except ValueError:
        return raw


def apply_op(op, a, b):
    if op == "+":
        return a + b
    if op == "-":
        return a - b
    if op == "*":
        return a * b
    if op == "/":
        return a / b
    if op == "=":
        return a == b
    if op == "<>":
        return a != b
    if op == "<":
        return a < b
    if op == ">":
        return a > b
    if op == "<=":
        return a <= b
    if op == ">=":
        return a >= b
    raise FormulaError(f"unknown operator {op!r}")


def call_function(name, args):
    if name == "SUM":
        return sum(args)
    if name == "MIN":
        return min(args)
    if name == "MAX":
        return max(args)
    if name == "ROUND":
        value, digits = args
        return round(value, int(digits))
    if name == "CEILING":
        import math
        sig = args[1] if len(args) > 1 else 1
        return math.ceil(args[0] / sig) * sig
    if name == "FLOOR":
        import math
        sig = args[1] if len(args) > 1 else 1
        return math.floor(args[0] / sig) * sig
    if name == "IF":
        cond, then, otherwise = args
        return then if cond else otherwise
    raise FormulaError(f"unsupported function {name!r}")


def format_value(value):
    if isinstance(value, bool):
        return "TRUE" if value else "FALSE"
    if isinstance(value, float) and value.is_integer():
        return str(int(value))
    return str(value)


def process_file(path):
    with open(path, newline="", encoding="utf-8") as f:
        grid = list(csv.reader(f))
    evaluator = Evaluator(grid)
    out_grid = []
    for r, row in enumerate(grid):
        out_row = []
        for c, cell in enumerate(row):
            if cell.strip().startswith("="):
                out_row.append(format_value(evaluator.cell_value(r, c)))
            else:
                out_row.append(cell)
        out_grid.append(out_row)

    out_path = path[: -len(".csv")] + ".values.csv"
    with open(out_path, "w", newline="", encoding="utf-8") as f:
        csv.writer(f, lineterminator="\n").writerows(out_grid)
    return out_path


def main():
    sources = [
        p
        for p in glob.glob(os.path.join(DIR, "*.csv"))
        if not p.endswith(".values.csv")
    ]
    if not sources:
        print("No source CSVs found in", DIR)
        return
    for path in sorted(sources):
        try:
            out_path = process_file(path)
        except FormulaError as e:
            print(f"FORMULA ERROR in {os.path.basename(path)}: {e}")
            sys.exit(1)
        print(f"{os.path.basename(path)} -> {os.path.basename(out_path)}")


if __name__ == "__main__":
    main()
