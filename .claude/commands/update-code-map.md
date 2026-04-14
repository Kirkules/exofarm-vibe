Regenerate all five code map sections. Use this after a large refactor that touches multiple areas of the codebase at once.

## Instructions

Run each of the following update commands in sequence:

1. /update-class-inventory
2. /update-dep-graph
3. /update-override-map
4. /update-autoload-map
5. /update-input-map

After all five complete, report a one-line summary per section (classes found, dependency edges, virtual methods, autoload accesses, input handlers), and flag any sections where significant changes were detected.
