Re-scan all project `.gd` files (excluding `addons/`, `tests/`) and rebuild `.claude/code_map_deps.md`.

## Instructions

1. For each file in `scenes/` and `scripts/`, find all references to other project-defined classes:
   - Variable type annotations: `var x: ClassName`
   - Function parameter types: `func f(x: ClassName)`
   - Return types: `-> ClassName`
   - Instantiation: `ClassName.new()`
   - Static access: `ClassName.method()` or `ClassName.CONSTANT`
   - `extends ClassName`
2. Exclude Godot built-in types (Node, Control, RefCounted, Resource, Node2D, String, int, float, bool, Array, Dictionary, Vector2, Vector2i, Rect2, Rect2i, Color, Callable, Variant, InputEvent and subclasses, Image, ImageTexture, etc.).
3. Include autoloads (GameState, EventBus, Catalog, Settings) as project classes.
4. Format: adjacency list, one class per line:
```
ClassName →
  RefA, RefB, RefC
```
5. Add a Notes section identifying: leaf nodes (no outgoing edges), high fan-in nodes (referenced by many), high fan-out nodes (references many).
6. Update "Last updated" date and report: total edge count, edges added or removed since last update.
