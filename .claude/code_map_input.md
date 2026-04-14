# ExoFarm Input Handler Map

Which classes implement Godot input methods, what they handle, and whether they consume events.
Last updated: 2026-04-11

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

### GameGrid._input(event) — `scripts/grid/game_grid.gd`
Priority: fires after HudUI._input; inherited by FarmGrid, KitchenGrid, SettlerFoodGrid
Handles:
- `InputEventMouseMotion` → update held sprite position
- `InputEventMouseButton` press → start tap/hold pending; release → place or return piece
- `InputEventScreenTouch` press/release → same as mouse button
- `InputEventScreenDrag` → update held sprite position (touch)
Consumes: NO — does not call `set_input_as_handled()`; suppresses internally via `planning_locked` and `grid_active` flags
Note: when `planning_locked = true` or `grid_active = false`, the handler exits early with no effect

### Game._unhandled_input(event) — `scenes/game/game.gd`
Priority: lowest (fires after all _input handlers)
Handles:
- `InputEventMouseButton` / `InputEventScreenTouch` press outside open KitchenGrid or settler panel → close it
- `ui_accept` action → confirm dialog shortcut
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
1. HudUI._input()           — consumes log-related events; blocks lower handlers from seeing them
2. GameGrid._input()        — handles grid drag/tap; does not consume; guards via flags
3. Game._unhandled_input()  — catches outside-press panel dismissals
```

---

## Notes

- `planning_locked` is the primary mechanism for disabling grid input during simulation, log overlay open, and merge grid open — driven by EventBus signals (see `.claude/signal_graph.md`)
- `grid_active = false` is a finer-grained per-instance lock used during cross-slot drag in the settler panel to suppress hover bleed on sibling grids
- Adding a new full-screen overlay that should block grid input: emit `EventBus.merge_grid_opened` (or a new EventBus signal) to set `planning_locked = true` on all GameGrid instances
- Adding a new input handler: place it in `_input` if it needs to fire before GUI; use `_unhandled_input` if it should only fire when nothing else consumed the event
