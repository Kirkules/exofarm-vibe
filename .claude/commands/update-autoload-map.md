Update `.claude/code_map_autoloads.md` using pending changes tracked by hooks.

## Instructions

### Fast path (pending file exists and is non-empty)

1. Read `.claude/pending_autoload-map.md`.
2. For each entry:
   - **EDIT**: apply the change lines directly to the code map:
     - `+autoload: Name.property` → add a row to the appropriate autoload's table for the source class (check first — skip if already present). Infer access type (read/write/emit/connect) from context if visible in the pending entry; otherwise mark as "read" and note it may need verification.
     - `-autoload: Name.property` → remove the corresponding row from the autoload table
   - **NEW**: read the new source file; scan for all autoload accesses and add rows
   - **DELETE**: remove all rows in all autoload tables that reference this file's class
   - **RENAME**: update the class name column in any rows referencing the old path
   - **REREAD**: re-read only the named source file; rebuild all its rows across all autoload tables
3. Truncate `.claude/pending_autoload-map.md` to empty.
4. Update the "Last updated" date.
5. Report: entries processed, rows added or removed.

### Full re-scan fallback (no pending file, or explicitly requested)

1. Search for all accesses to each autoload:
   ```
   grep -rn "GameState\." scenes/ scripts/ --include="*.gd"
   grep -rn "EventBus\." scenes/ scripts/ --include="*.gd"
   grep -rn "Catalog\." scenes/ scripts/ --include="*.gd"
   grep -rn "Settings\." scenes/ scripts/ --include="*.gd"
   ```
2. For each access, determine:
   - Which class file it is in
   - Which property or method/signal is accessed
   - The operation type: read, write, emit, or connect
3. Format: one section per autoload with a table — Class | Property/Signal | Access type
4. For EventBus, note that full signal connection details are in `.claude/signal_graph.md`; summarize which classes emit vs. connect here.
5. Add a Notes section for any non-obvious ownership or mutation patterns (e.g. which class is the sole writer of a given property).
6. Update "Last updated" date and report: any new accesses, any removed accesses since last update.
