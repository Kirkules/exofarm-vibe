Update `.claude/code_map_overrides.md` using pending changes tracked by hooks.

## Instructions

### Fast path (pending file exists and is non-empty)

1. Read `.claude/pending_override-map.md`.
2. For each entry:
   - **EDIT**: apply the change lines directly to the code map:
     - `+extends Name` / `-extends Name` → update the subclass relationship; re-check which virtual rows the class now participates in
     - `+input: handler_name` / `-input: handler_name` → add/remove from the built-in virtual overrides table
     - `+override: method_name` / `-override: method_name` → add/remove ✓ from the project-virtual override table for the source class
   - **NEW**: read the new source file; add it to whichever table rows are relevant
   - **DELETE**: remove the class from all table rows
   - **RENAME**: update path and class name in all table rows and section headers
   - **REREAD**: re-read only the named source file; update its rows in both tables
3. Truncate `.claude/pending_override-map.md` to empty.
4. Update the "Last updated" date.
5. Report: entries processed, table cells changed.

### Full re-scan fallback (no pending file, or explicitly requested)

1. Find project-defined virtual methods: funcs in base classes with empty bodies (`pass`) or documented as overridable. Check all base classes — not just GameGrid. Look for patterns like virtual stubs or comments indicating override intent.

2. For each virtual method found, check all subclasses (anything that `extends` the base class, directly or transitively) to see if they declare a `func` with the same name.

3. For Godot built-in virtual methods (`_ready`, `_process`, `_draw`, `_input`, `_unhandled_input`, `_notification`, `_init`), check every project class and note whether the override is non-trivial (not just a `super()` call or a pass).

4. Format:
   - A section per base class listing its virtual methods and a table showing which subclasses override each
   - A table for Godot built-in virtual overrides: rows = classes, columns = built-in methods; ✓ if non-trivially implemented, — if absent

5. Add a Notes section for any non-obvious override behavior (e.g. a subclass intentionally suppressing base behavior).

6. Update "Last updated" date and report: any new virtual methods, any new or removed overrides.
