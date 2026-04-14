Re-scan all project `.gd` files (excluding `addons/`, `tests/`) and rebuild `.claude/code_map_autoloads.md`.

## Instructions

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
