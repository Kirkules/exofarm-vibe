# ExoFarm — PieceInputController Refactor Design

## Problem

`GameGrid` conflates three distinct concerns:

1. **Input and drag lifecycle** — detecting presses, managing pending/drag/tap state machines, routing pieces on release
2. **Grid state and rendering** — cell occupancy, piece sprites, placement preview, draw pipeline
3. **Cross-grid coordination** — notifying siblings to deactivate, communicating with inventory panel, signalling managers

This mixing has caused recurring bugs: grids must deactivate siblings during drag to suppress input bleed; panel-close mid-drag requires careful cleanup (and we got it wrong for the kitchen); cross-grid hover feedback requires an external workaround (`_candidate_cell`); placement routing is duplicated between `game.gd` and each manager. Every new grid interaction adds surface area to an already-overloaded class.

---

## Goals

- A single `PieceInputController` node owns all drag input and routing. One place to read, one place to fix.
- Grids are passive: they expose a query/mutation API and render their own state. They do not process input events.
- Drag state (what is held, from where, current CoM, drag source) lives in exactly one object.
- Cross-grid hover, snap-back animation, and mid-drag panel close become straightforward.
- No grid needs to know about sibling grids or whether it is "active".

## Non-Goals

- Changing `GridData` (cell occupancy model stays unchanged)
- Changing the simulation controller or game loop
- Changing manager ownership of per-grid item semantics (which InventoryItem is in which slot)

---

## Proposed Architecture

### PieceInputController

A `Node` child of the main scene (same level as `game.gd`'s managers). Receives all `_input()` events via Godot's normal propagation — no other node processes input during a drag.

#### State it owns

| Field | Purpose |
|---|---|
| `_drop_targets: Array[Object]` | Ordered list of registered drop targets (priority descending) |
| `_pickup_sources: Array[Object]` | Registered objects that can be picked up from |
| `_held_shape: PieceShape` | Currently dragged shape (null if idle) |
| `_held_origin: Object` | Source the piece came from (grid or inventory); never null during drag |
| `_held_origin_cell: Vector2i` | Cell within origin source (meaningful for grid origins) |
| `_held_origin_shape: PieceShape` | Pre-rotation shape (for snap-back) |
| `_held_payload: Variant` | Opaque payload attached by the pickup handler (e.g. InventoryItem) |
| `_held_sprite: Sprite2D` on CanvasLayer 100 | Rendered drag visual |
| `_pending_*` | Hold-threshold state (0.5s timer, initial position, source) |
| `_tap_*` | Double-tap state machine (for toggleable pieces) |

PieceInputController carries a generic `Variant` payload attached by whoever handles `pickup_confirmed`. It does not interpret the payload — it delivers it unchanged in all subsequent signals. Managers no longer maintain a `_held_item` side-channel.

#### Highlighting via pub/sub

PieceInputController emits two signals every subscriber can react to independently — no registration required:

```gdscript
signal drag_moved(com: Vector2, payload: Variant)  # emitted every _process frame while dragging
signal drag_ended()                                 # emitted on drop or snap-back
```

Grids, inventory, and any future UI element subscribe to `drag_moved` to drive their own highlight state and to `drag_ended` to clear it. PieceInputController does not know who is listening.

#### Drop routing

On release, PieceInputController iterates `_drop_targets` in priority order and calls `can_accept_drop(com, payload)` on each. The first target that returns true receives the drop via `place_piece_at`. If no target accepts, PieceInputController plays the snap-back animation.

Priority is set at registration time and reflects z-order: a higher-z target (e.g. a settler food grid overlaid on the farm) gets a higher priority value and is checked first.

#### Registration API

```gdscript
# Register a source that can be picked up from.
piece_input_controller.register_pickup_source(source: Object)
piece_input_controller.unregister_pickup_source(source: Object)

# Register a target that can receive drops, with z-priority for conflict resolution.
piece_input_controller.register_drop_target(source: Object, priority: int)
piece_input_controller.unregister_drop_target(source: Object)
```

An object can be both a pickup source and a drop target (most grids are both). The inventory is a pickup source only. Unregistering a source or target is how eligibility is controlled — no `set_grid_active` or `set_eligible` needed. When a panel opens, managers unregister ineligible sources/targets; when it closes, they re-register.

#### Signals emitted

| Signal | Replaces |
|---|---|
| `pickup_confirmed(origin: Object, piece_id: int, shape: PieceShape, payload: Variant)` | `piece_picked_up_from_grid` + `inventory_item_pickup_confirmed` |
| `piece_placed(origin: Object, target: Object, piece_id: int, payload: Variant)` | `piece_placed_on_grid` |
| `piece_returned(origin: Object, piece_id: int, payload: Variant)` | `piece_returned_to_grid` |
| `piece_released(origin: Object, payload: Variant, com: Vector2)` | `piece_released` |
| `drag_moved(com: Vector2, payload: Variant)` | `set_candidate_drop` / `_inventory_control.set_drag_pos` |
| `drag_ended()` | `clear_candidate_drop` |
| `piece_double_tapped(origin: Object, piece_id: int)` | `piece_double_tapped` |
| `piece_long_pressed(origin: Object, piece_id: int)` | `piece_long_pressed` |

All signals carry `origin: Object` so managers filter by checking `origin == my_grid` (or `origin == inventory_ui`). No per-source signal connections needed — managers connect to PieceInputController once.

---

### Grid (revised GameGrid)

#### Keeps

- `grid_data: GridData` — cell occupancy
- Piece sprite management (`_piece_sprites`, labels, flash animation)
- Full `_draw()` pipeline — `_draw_cells()`, `_draw_grid_overlays()`, `_draw_placement_preview(hover_cell, shape)`
- `place_piece_at()`, `remove_piece()`, `get_screen_rect()` public API
- `can_accept_drop(com: Vector2, payload: Variant) -> bool` — grid decides its own eligibility; PieceInputController does not filter
- `set_hover(cell: Vector2i)` / `clear_hover()` — pure visual, driven by subscriber to `drag_moved`
- `_can_place_at_cell()` virtual (KitchenGrid uses this for inactive slots)
- `set_piece_moveable`, `set_piece_toggleable`, `set_piece_flashing`, `set_piece_active_visual`

#### Loses

| Removed | Moved to |
|---|---|
| All `_input()` / `_process()` logic | PieceInputController |
| Pending, drag, tap state variables | PieceInputController |
| `_held_sprite`, `_held_sprite_layer` | PieceInputController |
| `grid_active`, `planning_locked`, `set_grid_active()` | Deleted — concept no longer exists |
| `has_held_piece`, `has_pending_pickup` | Deleted — PieceInputController owns this state |
| `_held_can_place`, `_held_discardable` flags | Not needed; routing lives in `can_accept_drop` |
| `set_held_discardable()`, `set_held_can_place()`, `cancel_held_silently()` | Not needed |
| `begin_pending_inventory_hold()` | PieceInputController handles inventory pickup |
| `inventory_item_pickup_confirmed`, `piece_picked_up_from_grid` signals | PieceInputController `pickup_confirmed` |
| `_candidate_cell`, `set_candidate_drop()`, `clear_candidate_drop()` | Grid subscribes to `drag_moved` / `drag_ended` directly |
| `last_release_com`, `get_held_com()` | PieceInputController owns CoM |
| `_held_sprite_com()`, `_effective_cursor_pos()` | PieceInputController |
| EventBus `merge_grid_opened/closed` connections in `_ready()` | Deleted — EventBus signals removed |
| `_on_merge_grid_closed()` virtual method | Deleted |

**Subclass removals:**

`KitchenGrid` loses:
- `_on_merge_grid_closed()` override — only existed to suppress base restore behavior
- `set_grid_active()` override — only existed to gate activation on slot eligibility

`SettlerFoodGrid` loses:
- `_on_merge_grid_closed()` override — only existed to reactivate only-if-visible

**EventBus:**
`merge_grid_opened` and `merge_grid_closed` are removed from `EventBus` entirely. No non-input subscriber exists. The round-trip they implemented (manager emits → all grids react → only the opened grid stays active) is replaced by managers calling `register_drop_target` / `unregister_drop_target` directly on PieceInputController when panels open and close.

`piece_placed_on_grid` and `piece_returned_to_grid` survive on Grid as structural events (piece state changed). PieceInputController emits its own `piece_placed` / `piece_returned` after calling the Grid's placement API; Grid emits its own from `place_piece_at` / `remove_piece` as before.

---

### Impact on Managers

- **No per-source signal connections.** Connect to PieceInputController once; filter by `origin`.
- **No `_deactivate_other_grids` / `_reactivate_all_grids`.** Unregister/re-register with PieceInputController instead.
- **No `_held_item` side-channel.** The payload travels in signals; managers receive it in `piece_placed` and `piece_released` handlers directly.
- **No `set_held_discardable`, `set_held_can_place` calls.** Drop eligibility lives in each grid's `can_accept_drop`.
- **Panel close mid-drag**: call `piece_input_controller.cancel_drag()`. PieceInputController snaps back and emits `piece_released`; manager's handler uses the payload to return the item to inventory or slot.

---

## Migration Strategy (Strangler Fig)

The refactor touches every grid, all three managers, and `game.gd`. Migration proceeds in three phases to keep the game runnable at every step.

- **Phase 1 — Strangler shim:** Create `PieceInputController` alongside the existing `GameGrid`. Route all `_input()` through it, but have it delegate back to grids internally. No behavioral change — this proves the new node exists and receives input correctly.
- **Phase 2 — Manager migration:** Migrate managers one at a time to connect to `PieceInputController` signals. Strip input logic from each grid as its manager migrates.
- **Phase 3 — Dead code removal:** Remove `grid_active`, `planning_locked`, `merge_grid_opened/closed`, `_on_merge_grid_closed`, `has_held_piece`, `has_pending_pickup`, and all other code made obsolete by Phase 2.
