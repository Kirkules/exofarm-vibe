Re-scan all project `.gd` files (excluding `addons/`) for signal declarations, `.emit()` calls, and `.connect()` calls, then rebuild `.claude/signal_graph.md` as a directed graph.

## Instructions

1. Search for signal declarations: `grep -rn "^signal " scenes/ scripts/ --include="*.gd"`
2. Search for `.emit()` calls: `grep -rn "\.emit(" scenes/ scripts/ --include="*.gd"`
3. Search for `.connect()` calls: `grep -rn "\.connect(" scenes/ scripts/ --include="*.gd"`
4. Search for EventBus usages: `grep -rn "EventBus\." scenes/ scripts/ --include="*.gd"`

Then rewrite `.claude/signal_graph.md` with:
- **Direct Signals** section: grouped by emitting class; each entry is `Signal.name(args) [emitter instance] → [receiver].[handler]`
- **EventBus Signals** section: split into Emitters subsection and Receivers subsection
- **EventBus Stubs** section: signals declared in `event_bus.gd` with no active `.emit()` or `.connect()` in the rest of the codebase
- **Notes** section: any non-obvious wiring patterns (closures, dynamic connections, etc.)

Format rules (optimized for Claude readability):
- Use fenced code blocks for the graph adjacency lists
- Annotate closure-wired connections with `[closure per X]`
- Mark internal (same-class) connections with `[internal]`
- Update the "Last updated" date at the top

After rewriting the file, report a one-line summary: how many signals total, how many EventBus signals, how many stub signals, how many changes in non-obvious wiring patterns.
