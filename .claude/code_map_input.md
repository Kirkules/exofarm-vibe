# ExoFarm Input Handler Map

Which classes implement Godot input methods, what they handle, and whether they consume events.
Last updated: 2026-04-17

---

## Class-Level Input Handlers

### HudUI._input(event) — `scenes/game/ui/hud_ui.gd`
Priority: highest (fires before GUI processing)
Handles:
- `InputEventMouseButton` / `InputEventScreenTouch` within log panel rect → scroll drag tracking
- Release within log panel rect → end scroll
- Press outside log panel rect (when log open) → dismiss log
Consumes: YES — calls `set_input_as_handled()` for all events within the log rect and outside-press dismiss
Why `_input` and not `gui_input`: HudUI's own node rect is only ~52px tall; `gui_input` on a child of HudUI only fires within that rect, leaving the lower screen area (where the log panel lives) unblocked

### PieceInputController._input(event) — `scripts/game/piece_input_controller.gd`
Priority: fires after HudUI._input
Handles:
- `InputEventMouseMotion` → update held sprite position; cursor hover on registered grids
- `InputEventMouseButton` press → hit-test registered pickup sources, start pending; release → place or snap-back or release
- `InputEventMouseButton` right press (while holding) → rotate held piece CW
- `InputEventScreenTouch` press/release → same as mouse button; second touch while holding → rotate CW
- `InputEventScreenDrag` → update held sprite position (touch)
Consumes: NO — does not call `set_input_as_handled()`; guards via `grid_active` and `planning_locked` on each grid
Note: only registered pickup sources are hit-tested; grids not registered are invisible to input

### Game._unhandled_input(event) — `scenes/game/game.gd`
Priority: lowest (fires after all _input handlers)
Handles:
- `InputEventMouseButton` / `InputEventScreenTouch` press outside open KitchenGrid or settler panel → close it
- `ui_accept` action → `_pic.rotate_held_cw()`
Consumes: YES — calls `set_input_as_handled()`

---

## Inline gui_input Connections

These are `gui_input` signal connections wired inside `HudUI._build_ui()` and `HudUI._show_settler_tooltip()`.
They fire only within their own node's rect.

| Node | Event | Effect |
|------|-------|--------|
| `_energy_label` | tap (press + release) | toggle energy tooltip |
| `_matter_label` | tap | toggle matter tooltip |
| `_settler_label` | tap | emit `settler_label_tapped` signal |
| `morale_lbl` (per settler) | tap | expand morale breakdown for that settler |
| `expand_margin` (per settler) | tap | collapse morale breakdown |

---

## Input Priority Order

```
1. HudUI._input()                  — consumes log-related events; blocks lower handlers
2. PieceInputController._input()   — handles all piece drag/tap; does not consume
3. Game._unhandled_input()         — catches outside-press panel dismissals
```

---

## Notes

- `planning_locked` disables piece interactions during simulation and log overlay — set via EventBus signals on all GameGrid instances (see `.claude/signal_graph.md`)
- `grid_active = false` is used by managers to exclude a grid from input while a different panel is open (e.g. farm grid locked while Kitchen or Settler panel is open)
- PIC registers/unregisters grids dynamically; only `grid_active = true` grids are hit-tested
- Adding a new full-screen overlay that should block piece input: emit `EventBus.simulation_started` equivalent, or call `set_planning_locked(true)` on affected grids directly
- Adding a new input handler: place it in `_input` if it needs to fire before GUI; use `_unhandled_input` if it should only fire when nothing else consumed the event
