Re-scan all project `.gd` files (excluding `addons/`, `tests/`) and rebuild `.claude/code_map_overrides.md`.

## Instructions

1. Find project-defined virtual methods: funcs in base classes with empty bodies (`pass`) or documented as overridable. Check all base classes — not just GameGrid. Look for patterns like virtual stubs or comments indicating override intent.

2. For each virtual method found, check all subclasses (anything that `extends` the base class, directly or transitively) to see if they declare a `func` with the same name.

3. For Godot built-in virtual methods (`_ready`, `_process`, `_draw`, `_input`, `_unhandled_input`, `_notification`, `_init`), check every project class and note whether the override is non-trivial (not just a `super()` call or a pass).

4. Format:
   - A section per base class listing its virtual methods and a table showing which subclasses override each
   - A table for Godot built-in virtual overrides: rows = classes, columns = built-in methods; ✓ if non-trivially implemented, — if absent

5. Add a Notes section for any non-obvious override behavior (e.g. a subclass intentionally suppressing base behavior).

6. Update "Last updated" date and report: any new virtual methods, any new or removed overrides.
