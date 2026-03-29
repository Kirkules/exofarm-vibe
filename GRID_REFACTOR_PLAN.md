# Grid UI Refactor — Plan

## Goal

Extract a `GameGrid` base class from `farm_grid.gd` so that every interactive grid in
the game (farm grid, kitchen merge grid, future crafting/storage grids) shares the same
polyomino drag model, rendering pipeline, and interaction feel. Grids self-manage their
locked/unlocked state via EventBus signals rather than being controlled imperatively from
`game.gd`.

---

## Guiding principles

1. **One drag model everywhere.** All items (buildings AND food/craft items) are
   polyominos. Every grid uses the same hold-to-pick-up, drag-to-position, release-to-place
   loop that the farm grid uses today.

2. **Grids are self-contained.** Each grid owns its own input state machine, rendering,
   and drop detection. No grid needs a reference to another grid. `game.gd` is a coordinator
   of signals, not a puppeteer of state.

3. **Signal-driven toggles.** Grids subscribe to `EventBus` signals to self-lock
   (simulation running, another grid open, etc.). `game.gd` emits events; grids react.
   No more imperative `farm_grid.planning_active = false` calls.

4. **Uniform external interface.** Every grid exposes the same signal set and the same
   small public API. `game.gd` connects to them identically regardless of grid type.

---

## Architecture

### GameGrid (new base class — extends Node2D)

Owns everything that is grid-type-agnostic:

**Grid state**
- `grid_data: GridData` — wrapped internally (rows/cols/cell_size set by subclass constants)
- Sparse piece registry (piece_id → item, build_state, moveable, toggleable)

**Input state machine** (lifted verbatim from farm_grid)
- `TapState` enum, `PendingSource` enum, `InputSource` enum
- All `_pending_*`, `_tap_*`, `_held_*`, `_drag_*` vars
- `_input()` handler — mouse + multi-touch, hold threshold, drag threshold
- `begin_pending_inventory_hold(item)` — external entry point
- `rotate_held_cw()`, `hold_piece()`, `release_held()`

**Rendering** (lifted from farm_grid)
- `_draw()` — cells, borders, hover highlight, placement preview (valid/invalid), held sprite + label
- Colour constants exposed as `@export` vars so subclasses/game.gd can theme them without overriding

**Drop resolution**
- `_held_sprite_com() -> Vector2` — CoM in screen space
- `_sprite_com_over_rect(rect: Rect2) -> bool` — generic helper
- On release: emits `piece_released(item, com_screen_pos)` if CoM is not over this grid;
  `game.gd` routes to the correct target

**Locking / blocking**
- `planning_locked: bool` — blocks all input when true (replaces `planning_active`)
- `interaction_blocked: bool` — blocks grid-pickup/tap only; inventory-hold drag still works
  (replaces `_block_grid_interaction`)
- Both toggled via EventBus signals (see below)

**Virtual / overridable hooks**
- `_can_accept_item(item: InventoryItem) -> bool` — subclass filters by GridType
- `_on_piece_placed(piece_id: int)` — subclass post-placement logic
- `_draw_overlays()` — called at end of `_draw()` for subclass-specific overlays

**Signals (uniform across all grids)**
```
piece_placed_on_grid(piece_id: int, item: InventoryItem)
piece_picked_up_from_grid(piece_id: int, item: InventoryItem)
piece_hold_cancelled(item: InventoryItem, build_state: BuildState)
piece_returned_to_grid(piece_id: int)
piece_released(item: InventoryItem, com_screen_pos: Vector2)   ← new; replaces piece_dropped_on_kitchen_panel
piece_long_pressed(piece_id: int)
tap_confirmed(piece_id: int)                                   ← existing piece_tapped_on_grid
```

---

### FarmGrid (extends GameGrid)

Adds farm-specific concerns only:
- Power range overlay (`_draw_overlays()`)
- Effect/neighbor overlay (`_draw_overlays()`)
- `_can_accept_item`: accepts `FARM_GRID` items only
- `_on_piece_placed`: calls `_sync_kitchen_panel()`, `_recompute_power()` via signals to game.gd
- Subscribes to `EventBus.merge_grid_opened` → sets `interaction_blocked = true`
- Subscribes to `EventBus.merge_grid_closed` → sets `interaction_blocked = false`

---

### KitchenGrid (extends GameGrid — replaces KitchenPanel Control)

A proper GameGrid with a 3×4 layout; items are 1×1 polyominos:
- `ROWS = 4`, `COLS = 3`, matching cell size and colors of today's KitchenPanel
- `_can_accept_item`: accepts `KITCHEN_GRID` items only
- `set_capacity(n)` — marks slots beyond n as inactive (darker color, no interaction)
- `get_items() -> Array[InventoryItem]` — used by simulation for food counting
- No longer borrows farm_grid's drag engine — has its own (inherited from GameGrid)
- Subscribes to `EventBus.simulation_started` → `planning_locked = true`

---

### EventBus additions

```gdscript
signal simulation_started()
signal simulation_ended()
signal merge_grid_opened(grid: GameGrid)   # farm_grid blocks itself on receipt
signal merge_grid_closed()
```

---

### game.gd simplifications

**Removed:**
- `farm_grid.set_block_grid_interaction()` calls → replaced by EventBus.merge_grid_opened/closed
- `farm_grid.planning_active = false/true` calls → replaced by EventBus.simulation_started/ended
- `_held_from_kitchen: bool` → no longer needed; each grid owns its own drag origin
- `farm_grid._kitchen_panel_control` reference → removed; game.gd routes via `piece_released`
- `_on_piece_dropped_on_kitchen_panel` → replaced by generic `_on_piece_released`

**Added / simplified:**
- `_on_piece_released(item, com_screen_pos)` — generic handler shared by all grids; checks
  which grid's rect contains the CoM and calls `target_grid.begin_pending_inventory_hold` or
  drops to inventory
- `DragSession` inner struct replacing loose `_held_item`, `_held_build_state`, etc.

---

## Migration plan

This is a significant refactor. Recommended order to minimize breakage:

1. **Extract GameGrid with FarmGrid subclass** — move 95% of farm_grid.gd into GameGrid;
   FarmGrid adds overlays and farm signals. Game should work identically after this step.
   This is the riskiest step; do it first as a standalone commit with thorough testing.

2. **Add EventBus signals + self-locking** — add simulation_started/ended to EventBus;
   GameGrid subscribes; remove imperative locking from game.gd.

3. **Build KitchenGrid as GameGrid subclass** — replace KitchenPanel (Control) with
   KitchenGrid (Node2D, extends GameGrid). Wire it up as a second grid instance in game.gd.
   Update piece_released routing in game.gd to handle both grids.

4. **Clean up game.gd** — remove _held_from_kitchen, collapse held-item state into
   DragSession, connect merge_grid_opened/closed EventBus signals.

---

## Key decisions needed before coding

1. **Coordinate space:** ✅ **Decided.** CoM in screen space for all polyomino drop
   detection — grids, inventory, and any future drop target. `piece_released` carries
   `com_screen_pos: Vector2`; `game.gd` checks it against the screen-space `Rect2` of
   each candidate target. `GameGrid.get_screen_rect() -> Rect2` and a matching
   `InventoryUI.get_screen_rect() -> Rect2` give `game.gd` a uniform way to test all
   targets without special-casing any of them.

2. **KitchenGrid visibility/open-close:** ✅ **Decided.** `game.gd` opens and closes all
   temporary grid spaces. It sets `kitchen_grid.visible`, emits
   `EventBus.merge_grid_opened(grid)` / `EventBus.merge_grid_closed()`, and other grids
   self-lock in response. Grids never need references to each other.

3. **Inactive cells / adjustable grid size:** ✅ **Decided.**

   Two related points:

   **a) Inactive cells are a first-class GridData concept.**
   `GridData` gains an `_inactive` layer (2D bool array, same dimensions as `_cells`).
   Inactive cells block placement and reject items that land on them. If a cell becomes
   inactive while occupied, its item is ejected (returned via signal/return value from
   `set_cell_inactive`). Rendering: inactive cells draw with a distinct style (dimmed,
   no hover). This replaces KitchenPanel's `_capacity` counter entirely — capacity is
   expressed purely as "how many cells are active."

   **b) GameGrid dimensions are runtime-configurable, not compile-time constants.**
   `GameGrid` exposes a `setup(rows: int, cols: int, cell_size: int)` method (or exported
   vars) instead of `const ROWS/COLS`. `GridData` already takes rows/cols at construction;
   GameGrid wraps that. Each subclass sets its default dimensions in `_ready()` but they
   can be changed. This lets grids grow/shrink as the game state changes (e.g. a larger
   cafeteria unlocks more kitchen slots) and ensures FarmGrid, KitchenGrid, and any future
   grids are just instances of the same class with different configuration, not separate
   subclasses purely for sizing purposes.

4. **Item origin for game.gd routing:** ✅ **Decided.** `game.gd` maintains a
   `_drag_source_grid: GameGrid` variable, set at pickup time (either when
   `begin_pending_inventory_hold` is called or when `piece_picked_up_from_grid` fires).
   This follows the existing pattern of `_held_item`, `_held_build_state`, etc.
   `piece_released` does not need to carry source information.
