Update `.claude/code_map_deps.md` using pending changes tracked by hooks.

## Instructions

### Fast path (pending file exists and is non-empty)

1. Read `.claude/pending_dep-graph.md`.
2. For each entry:
   - **EDIT**: apply the change lines directly to the code map:
     - `+dep: ClassName` → add an edge from the source class to ClassName (check first — skip if already present)
     - `-dep: ClassName` → remove the edge from the source class to ClassName
     - `+extends Name` → add "extends Name" edge for the source class
     - `-extends Name` → remove that extends edge
     - `+class_name Name` / `-class_name Name` → rename the node entry header
   - **NEW**: read the new source file in full; add its dependency edges
   - **DELETE**: remove the source class node and all its outgoing edges from the graph
   - **RENAME**: find all occurrences of the old path; update path and class name references
   - **REREAD**: re-read only the named source file; rebuild its edge list
3. After processing all entries, update the Notes section (leaf nodes, high fan-in/out) if edges changed.
4. Truncate `.claude/pending_dep-graph.md` to empty.
5. Update the "Last updated" date.
6. Report: entries processed, edges added or removed.

### Full re-scan fallback (no pending file, or explicitly requested)

1. Build project class allowlist: `grep -rh "^class_name " scenes/ scripts/ --include="*.gd" | awk '{print $2}'`
2. For each file in `scenes/` and `scripts/`, find all references to allowlisted classes:
   - Variable type annotations: `var x: ClassName`
   - Function parameter types and return types
   - Instantiation: `ClassName.new()`
   - Static access: `ClassName.method()` or `ClassName.CONSTANT`
   - `extends ClassName`
3. Include autoloads (GameState, EventBus, Catalog, Settings) as project classes.
4. Format: adjacency list, one class per line:
```
ClassName →
  RefA, RefB, RefC
```
5. Add a Notes section identifying: leaf nodes (no outgoing edges), high fan-in nodes (referenced by many), high fan-out nodes (references many).
6. Update "Last updated" date and report: total edge count, edges added or removed since last update.
