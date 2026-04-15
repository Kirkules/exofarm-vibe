Update `.claude/code_map_classes.md` using pending changes tracked by hooks.

## Instructions

### Fast path (pending file exists and is non-empty)

1. Read `.claude/pending_class-inventory.md`.
2. For each entry:
   - **EDIT**: apply the change lines directly to the code map:
     - `+func ...` → add that line to the target class's Public API list (check first — skip if already present)
     - `-func ...` → remove that line from the target class's Public API list
     - `+signal ...` / `-signal ...` → add/remove from Signals line
     - `+class_name ...` / `-class_name ...` → update the class header
     - `+extends ...` / `-extends ...` → update the "extends" in the class header
   - **NEW**: read the new source file in full; add a new class entry in the appropriate layer section
   - **DELETE**: remove the entire entry for that file from the code map
   - **RENAME**: find all occurrences of the old path in the code map and replace with the new path
   - **REREAD**: re-read only the named source file; update its class entry in full
3. After processing all entries, truncate `.claude/pending_class-inventory.md` to empty.
4. Update the "Last updated" date.
5. Report: entries processed, changes applied.

### Full re-scan fallback (no pending file, or explicitly requested)

1. List all .gd files in `scenes/` and `scripts/`.
2. For each file, extract:
   - `class_name` (if declared) and `extends`
   - File path relative to project root
   - All `func` declarations without a leading `_` (public), plus any with `##` doc comments
   - `signal` declarations
   - `enum` declarations and key named constants
   - Infer a one-line purpose from class name, doc comments, and content
3. Organize output by layer: Orchestrator → Managers → UI → Grid → Sprite → Inventory → Resources → Systems → Autoloads.
4. Format per entry:
```
### ClassName — `path/to/file.gd` extends ParentClass
One-line purpose.
[Enum/Constant: ...] (if noteworthy)
Public API:
  method1(args) → ReturnType
  method2(args)
Signals: signal1(args), signal2
```
5. Update the "Last updated" date.
6. Report: total class count, any classes added or removed since last update.
