Update `.claude/code_map_input.md` using pending changes tracked by hooks.

## Instructions

### Fast path (pending file exists and is non-empty)

1. Read `.claude/pending_input-map.md`.
2. For each entry:
   - **EDIT**: apply the change lines directly to the code map:
     - `+input: handler_name` → add a new entry for the source class in the class-level handlers section; read the function body from the source file to fill in details (InputEvent types, consume behavior, purpose)
     - `-input: handler_name` → remove the source class's handler entry
   - **NEW**: read the new source file; check for any input handler implementations; add entries if found
   - **DELETE**: remove all input handler entries for this file's class
   - **RENAME**: update the class name in any handler entries
   - **REREAD**: re-read only the named source file; rebuild its input handler entries
3. After processing, re-evaluate the priority order section if any handlers were added or removed.
4. Truncate `.claude/pending_input-map.md` to empty.
5. Update the "Last updated" date.
6. Report: entries processed, handlers added or removed.

### Full re-scan fallback (no pending file, or explicitly requested)

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
