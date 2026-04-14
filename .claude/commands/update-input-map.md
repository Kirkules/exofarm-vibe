Re-scan all project `.gd` files (excluding `addons/`, `tests/`) and rebuild `.claude/code_map_input.md`.

## Instructions

1. Find all class-level input handler implementations:
   ```
   grep -rn "^func _input\|^func _unhandled_input\|^func _gui_input" scenes/ scripts/ --include="*.gd"
   ```
2. For each handler found, read the function body and determine:
   - Which `InputEvent` subclasses it responds to
   - Whether it calls `set_input_as_handled()` or `accept_event()`
   - Its primary purpose in one sentence
   - Its effective priority relative to other handlers (note: `_input` fires before `_unhandled_input`; both fire before `gui_input` on the same node)
3. Find all inline `gui_input.connect(` calls to identify dynamically wired gui_input handlers:
   ```
   grep -rn "gui_input.connect" scenes/ scripts/ --include="*.gd"
   ```
   For each, note the node, the event handled, and the effect.
4. Document the effective input priority order across all handlers.
5. Add a Notes section for any non-obvious input routing decisions (e.g. why a particular handler uses `_input` vs `gui_input`).
6. Update "Last updated" date and report: any new handlers found, any removed.
