Update all five code map sections. Runs each section's update command in sequence, processing pending changes from hooks. Use this after a large refactor that touches multiple areas of the codebase at once, or to fully sync all sections.

## Instructions

Run each of the following update commands in sequence:

1. /update-class-inventory
2. /update-dep-graph
3. /update-override-map
4. /update-autoload-map
5. /update-input-map

Each command will use its pending file if non-empty (fast path), or fall back to a full re-scan if the pending file is absent or empty.

After all five complete, report a one-line summary per section (classes found, dependency edges, virtual methods, autoload accesses, input handlers), and flag any sections where significant changes were detected.
