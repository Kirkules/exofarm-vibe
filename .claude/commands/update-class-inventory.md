Re-scan all project `.gd` files (excluding `addons/`, `tests/`) and rebuild `.claude/code_map_classes.md`.

## Instructions

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
5. Update the "Last updated" date at the top.
6. Report: total class count, any classes added or removed since last update.
