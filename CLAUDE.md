# ExoFarm — CLAUDE.md

Quick-start context for Claude Code working on this project.

---

## Project Summary

**ExoFarm** is a single-player roguelike grid-based farm settlement builder built in
Godot 4.6.1. Players manage a small crew of human settlers on an exoplanet across
a finite number of seasons (~15), ending in a "viability report" score.

Tone: cozy pioneering optimism, mild survival tension. Not desperate survival — think
optimistic science expedition, not post-apocalyptic.

Each run is a fresh start on a new exoplanet. Earth hub persists between runs.

Organizing body: **SEED** — Survival and Emigration Expedition Dispatch. FTL travel
exists but caused irreversible climate change on Earth, making new planets necessary.

---

## Current Focus

**Phase 1 complete. Currently in Phase 2 (Season Simulation).**

Recently completed:
- GridType enum (`FARM_GRID`, `KITCHEN_GRID`) on `PlaceableDefinition`; crop output
  items restricted to `KITCHEN_GRID` (not droppable on farm grid, but still draggable)
- `CropProductionDefinition` inserted between `BuildingDefinition` and `GreenhouseDefinition`;
  holds `tend_interval` and `tend_per_yield`
- Real-time 15s settler labor animation: ColorRect sprites walk Solar Rig↔greenhouses at
  2 grid-units/sec; `tend_per_yield` arrivals yield one crop item
- Season progress bar (16px above grid) with elapsed-time label; SimulationOverlay removed
- Live log overlay between HUD and progress bar: shows last 6 entries as they occur
- Outcome log with timestamps, color-coded values, and per-entry label/value layout;
  accessible via "log" button below Next Season; cleared at start of each simulation
- SettlerHealth enum (FED, STARVING, DEAD); DEAD settlers skip food; starvation kills
- Construction cost (matter_cost=1 per greenhouse) deducted before Nutrient Paste at sim start
- UNBUILT/BUILT building state machine; starting buildings pre-placed as BUILT
- Cafeteria building (1×2, amber, `matter_cost=2`, `power_draw=1`, `merge_slots=12`);
  KitchenPanel overlay (3×4 grid) opened by 0.5s long-press on Cafeteria, closed by
  tapping outside; KITCHEN_GRID items drag to/from inventory↔panel; farm grid fully
  blocked while panel is open (`_block_grid_interaction`); items consumed at season end
  if cafeteria powered; `piece_dropped_on_kitchen_panel` signal carries CoM screen pos
  so items land in the nearest empty slot, not just the first one

Next up:
- [ ] **Grid refactor** — extract `GameGrid` base class from `farm_grid.gd`; replace
  `KitchenPanel` (Control) with `KitchenGrid` (GameGrid subclass); signal-driven locking
  via EventBus; runtime-configurable grid dimensions; inactive cells in GridData.
  Full design in `GRID_REFACTOR_PLAN.md`.
- [ ] Playback speed controls (1×, 2×, 3×, 5×)
- [ ] Morale calculation and bar UI
- [ ] Meal item crafting and consumption
- [ ] Inventory overflow → broken down to Matter at sim start

---

## Tech Stack and Architecture

- **Engine:** Godot 4.6.1, GDScript only (no C#)
- **Target:** Android portrait (270×600 base, 4× integer scaling on Pixel 7a)
- **Tests:** GUT plugin (`tests/unit/`); pure logic only, no UI tests

### Key Files

| File | Role |
|------|------|
| `scenes/game/game.gd` | Central game controller; owns grid↔inventory↔HUD wiring, simulation flow |
| `scenes/game/grid/farm_grid.gd` | Grid input, piece hold/drag/drop, sprites, overlays |
| `scripts/grid/grid_data.gd` | Grid state (pure logic, no rendering) |
| `scripts/grid/piece_shape.gd` | Polyomino shape + rotation; `CellStyle` enum (SQUARE/CIRCLE) |
| `scripts/pieces/piece_sprite_generator.gd` | Generates piece textures procedurally |
| `scripts/inventory/inventory.gd` | Inventory data model |
| `scenes/game/ui/inventory_ui.gd` | Inventory panel UI |
| `scenes/game/ui/hud_ui.gd` | Top HUD (Energy, Matter, Settlers, Next Season button, tooltips) |
| `scenes/game/ui/build_menu.gd` | Build menu below inventory |
| `scenes/game/ui/kitchen_panel.gd` | 3×4 merge-slot overlay; opened by long-pressing Cafeteria |
| `scripts/systems/power_system.gd` | Union-find power network; `is_powered(piece_id)` |
| `scripts/systems/neighbor_system.gd` | Manhattan-distance neighbor effect engine |
| `scripts/autoloads/game_state.gd` | Singleton: season, settler_names/health, energy, matter |
| `scripts/autoloads/catalog.gd` | Known designs/recipes (meta-progression) |
| `scripts/autoloads/event_bus.gd` | Global signal bus |
| `scripts/resources/placeable_definition.gd` | Base resource; GridType enum; allowed_grids |
| `scripts/resources/building_definition.gd` | Extends PlaceableDefinition; power fields |
| `scripts/resources/crop_production_definition.gd` | Extends BuildingDefinition; tend_interval, tend_per_yield |
| `scripts/resources/greenhouse_definition.gd` | Extends CropProductionDefinition; output_item |
| `scripts/resources/cafeteria_definition.gd` | Extends BuildingDefinition; merge_slots |

### Resource Hierarchy

```
PlaceableDefinition              ← crop items, generic placeables
  └── BuildingDefinition         ← Solar Rig, Matter Manipulator, Cafeteria
        ├── CafeteriaDefinition  ← merge_slots
        └── CropProductionDefinition  ← tend_interval, tend_per_yield
              └── GreenhouseDefinition    ← Wheat/Tomato/Eggplant Greenhouses
```

**No `.tres` resource files exist.** All building and item definitions are created
programmatically in `game.gd:_buildable_definitions()` and `_place_starting_buildings()`.

### Screen Layout (270×600 portrait)

```
y=0      ┌─────────────────┐  HudUI (~52px, anchored top)
         │  HUD            │
y≈52     ├─────────────────┤  Live log overlay (sim only)
         │  scenic view    │
y≈126    ├─────────────────┤  Progress bar (16px, sim only)
y=150    ├─────────────────┤  FarmGrid Node2D at position (7, 150)
         │  8×6 grid       │  256×192px (8 cols × 32px, 6 rows × 32px)
y=342    ├─────────────────┤  grid_bottom = 150 + 192 = 342
         │  BuildMenu      │  height = viewport_h − grid_bottom − InventoryUI.COLLAPSED_H
y=552    ├─────────────────┤  InventoryUI collapsed header (48px)
y=600    └─────────────────┘
```

`KitchenPanel` is a modal overlay on the farm grid (not below it). It is sized
`(270, KitchenPanel.PANEL_H)` (~216px) and positioned so its bottom aligns with
`grid_bottom` (top ≈ y=126). It does not shift any other UI elements.

`InventoryUI` is anchored to the bottom of the screen (anchor_top=1, anchor_bottom=1,
offset_top=−48). Its PARTIAL height = `viewport_h − grid_bottom − 8`.

### Grid System

- 8×6 grid, 32×32px cells, (row, col) 1-indexed, (1,1) = top-left
- Polyomino shapes: list of (row, col) offsets from origin; origin = touch anchor + rotation pivot
- 90° CW rotation: `(r, c) → (c, -r)`, then renormalize to min=(0,0)
- `piece_id` is an int assigned by `grid_data`; used as key in all piece dictionaries

### Piece Placement Signal Flow

```
build menu tap     → _on_building_requested(def) → farm_grid.begin_pending_inventory_hold
inventory tap      → _on_item_requested(item)    → farm_grid.begin_pending_inventory_hold
kitchen slot hold  → item_held(item)             → _on_kitchen_item_held
                       sets _held_from_kitchen=true, calls begin_pending_inventory_hold

farm_grid drag confirmed → _on_inventory_item_pickup_confirmed
                            • if _held_from_kitchen: remove from kitchen panel
                            • else: remove from inventory
                            • sets farm_grid._held_can_place_on_farm_grid based on allowed_grids
farm_grid drop on grid   → piece_placed_on_grid → _on_piece_placed_on_grid
                            • KITCHEN_GRID-only items: removed, returned to inventory
                            • other items: registered in _placed_items, power recomputed
farm_grid drop on kitchen → piece_dropped_on_kitchen_panel(shape, com_screen_pos)
                            → _on_piece_dropped_on_kitchen_panel
                            • KITCHEN_GRID items: find_nearest_empty_slot(com), add_item_at
                            • others: returned to inventory
farm_grid drop off-grid  → piece_hold_cancelled → _on_piece_hold_cancelled
                            • UNBUILT: discarded; BUILT: returned to inventory
farm_grid pickup         → piece_picked_up_from_grid → _on_piece_picked_up_from_grid
                            • erases from _placed_items, recomputes power; closes kitchen panel
farm_grid snap back      → piece_returned_to_grid → _on_piece_returned_to_grid
non-moveable 0.5s hold   → piece_long_pressed(piece_id) → _on_piece_long_pressed
                            • if CafeteriaDefinition: _open_kitchen_panel()
```

`_sync_kitchen_panel()` is called after every placed/picked-up/returned event.
`_recompute_power()` is called after every placement change; it calls `_compute_food_state()`
and refreshes all HUD projections.

**Key game.gd state dicts** (all keyed by `piece_id: int`):
- `_placed_items` — piece_id → InventoryItem (survives pick-up/put-down)
- `_piece_build_state` — piece_id → BuildState (UNBUILT / BUILT)
- `_piece_active` — piece_id → bool (toggle state; default true)

`_build_placed_dict()` builds the dict for PowerSystem/NeighborSystem; UNBUILT pieces
are included but have `"active": false`, so they don't participate in power.

### Simulation Flow

1. Player presses "Go to Season N"
2. Confirmation dialog (if starvation risk)
3. `_begin_simulation()`: clear log, capture construction cost, transition UNBUILT→BUILT,
   log construction entries, initialize `_greenhouse_states`, start 15s timer + live log overlay
4. `_process(delta)`: advance `_sim_elapsed`, update progress bar, tick greenhouses + settlers;
   settlers walk Solar Rig→greenhouse at 2 grid-units/sec; each arrival is a tend; on
   `tend_per_yield` tends the greenhouse yields one crop item
5. `_end_simulation()`: log/apply Matter prod → log/consume kitchen items → log/apply
   Nutrient Paste → log deaths → update GameState → push log to HUD → unlock grid
   Note: `_power_state` is NOT recomputed inside `_begin_simulation()` after UNBUILT→BUILT,
   so newly-BUILT buildings don't participate in power until the next planning phase.

### Simulation Log Format

Each entry dict: `{"label": String, "value": String, "label_color": String,
"value_color": String, "timestamp": float}`. Colors: `#88ee88` gain, `#ee8800` loss,
`#ee4444` death, `#eeee88` item. Pass through `_add_log_entry(base)` — never append
to `_sim_log` directly (it stamps timestamp and pushes to live overlay).

### _compute_food_state() return keys

`matter_prod`, `construction_cost`, `food_items` (from kitchen panel if cafeteria
powered, else 0), `paste_needed`, `paste_produced`, `projected_health` (Array[int]),
`deaths`. Called with `construction_cost_override >= 0` in `_end_simulation` to use the
pre-transition cost (captured before UNBUILT→BUILT runs).

### Power System

- Only BUILT buildings participate (`active = is_built AND toggle_state`)
- Union-find groups power sources into networks; shared pool per network
- Binary powered/unpowered per consuming building (no partial power)
- Players toggle buildings off (double-tap fixed building) to manage shortfalls

---

## Code Style and Naming Conventions

**Always use explicit type annotations on every `var` declaration.** This is non-negotiable.

```gdscript
# Correct
var count: int = 0
var names: Array[String] = []
var item: InventoryItem = null

# Wrong
var count = 0
var names = []
```

**Use enums instead of integer sentinels** for any discrete multi-valued variable.

```gdscript
# Correct
enum BuildState { UNBUILT, BUILT }
var _held_build_state: BuildState = BuildState.BUILT

# Wrong
var _held_build_state: int = 0  # 0 = BUILT, 1 = UNBUILT
```

**Typed Array assignment from Dictionary requires `.assign()` not `=`:**

```gdscript
# Correct — GDScript 4 requires this for typed arrays
GameState.settler_health.assign(food["projected_health"])

# Wrong — silently fails, typed array is unchanged
GameState.settler_health = food["projected_health"]
```

**Other conventions:**
- Scene scripts co-located with their `.tscn` files; pure logic in `scripts/`
- Private helpers prefixed with `_`; public API has doc comments (`##`)
- Signals named `past_tense_verb` (e.g. `piece_placed_on_grid`, `next_season_pressed`)
- Resource subclasses use `class_name`; autoloads are singletons accessed by name
- No magic number sentinels — prefer enums or named constants

---

## Game Story Summary

**Premise:** A second technological revolution produced FTL travel but irreversibly
accelerated climate change on Earth (~300 years to uninhabitable). SEED was created
to find a new home for humanity. ExoFarm's runs are SEED's advance scout missions:
small settler teams assessing whether humans could farm and live on a candidate planet.

**Each run:** 3–4 named settlers, fresh start on a new exoplanet, max 15 seasons.
Score = "viability report" — how livable is this planet for a larger colony?

**Meta-progression:** Discovering a new resource type in a run causes Earth designers
to develop new designs using it, unlocking them permanently for future runs.

**Agriculture path split:**
- *Advanced Greenhouse* — larger enclosed structures; suited for hostile atmospheres
- *Local Agriculture* — hybridize Earth crops with native flora; suited for hospitable
  atmospheres with scarce building materials
Both paths use the Cafeteria for meal crafting.

---

## Known Issues and Current TODOs

### Pending Features (Phase 2)
- Playback speed controls (1×/2×/3×/5×)
- Inventory overflow: items beyond capacity broken down into Matter at sim start
- Morale: calculation logic + bar UI with projected delta display
- Meal item crafting and consumption logic

### Design Decisions Deferred
- `KITCHEN_GRID` items (Wheat, Tomato, Eggplant): dragging them onto the farm grid
  rejects and returns to inventory. Drag-to-kitchen-panel is the only route in.
- `neighbor_system.gd` computes effects but they are not yet applied to simulation output
- Save/load stubs exist in `GameState` but are not implemented
- `_power_state` is not recomputed after UNBUILT→BUILT in `_begin_simulation()`, so
  buildings placed in season N don't participate in power until season N+1

### Behavior Notes
- Starting buildings (Solar Rig, Matter Manipulator) placed BUILT at (3,3) and (3,4);
  `moveable=false`; not selectable
- UNBUILT buildings flash at 0.5s period; discarded if dropped off-grid
- Drag offset while holding: 1 grid-space left, 0.5 grid-space down from touch point
- Matter Manipulator must be powered for Nutrient Paste to be produced
- Construction cost captured before UNBUILT→BUILT transition in `_begin_simulation()`
  (otherwise `_compute_construction_cost()` returns 0 — the buildings are already BUILT)
- `BuildingDefinition` comment says "non-moveable by default" but the *code* does NOT set
  `moveable=false`; explicitly set it when defining buildings from the build menu
- `BuildMenu`, `KitchenPanel`, progress bar, and live log are all created programmatically
  in `game.gd:_ready()` — no `.tscn` counterparts; use `_ui_layer.add_child()`
- KitchenPanel is a modal overlay (~216px tall); long-press (0.5s) on a placed Cafeteria
  opens it; any new press outside the panel or inventory closes it (`_unhandled_input`)
- `_block_grid_interaction` on `farm_grid` blocks all grid pickup/tap while kitchen panel
  is open; inventory-hold drag still works (claimed before the blocked branch)
- `_held_from_kitchen: bool` in `game.gd` — set true when a drag starts from the kitchen
  panel; causes `_on_inventory_item_pickup_confirmed` to remove from panel not inventory
- KitchenPanel: COLS=3, ROWS=4, PANEL_H≈216; sparse `_items` array (null=empty slot);
  `find_nearest_empty_slot(global_pos)` returns closest empty slot to drop CoM;
  `add_item_at(item, slot_idx)` places at a specific slot

---

## Design Choices

### Numbers Stay Small
Human-readable quantities at all times. Basic crop: 1 unit/season. Starting Matter
production: 5/season. End-of-run production ceiling: ~100/season. Never thousands.

### Units Unspecified
Don't label quantities with units in UI. Let players infer real-world equivalents.

### Planning Phase Always Reversible
All decisions during planning can be undone until "Proceed to Next Season" is confirmed.
This is a core design guarantee — never break it.

### Inventory as Workspace
The inventory is the off-grid holding area. No separate workspace. Items removed from
the grid go to inventory; items placed on the grid come from inventory (or build menu).

### GridType for Item Routing
`PlaceableDefinition.GridType` enum (`FARM_GRID`, `KITCHEN_GRID`) controls which grids
accept each item. Items are always draggable; rejection happens at drop time, not pickup.
New grid UIs should add a new `GridType` value and enforce it at their drop handler.

### Power is Binary
Buildings are fully powered or dormant. No partial power. Players manage shortfalls by
toggling buildings off (double-tap). No automatic rationing.

### UNBUILT vs. BUILT
Buildings placed from the build menu start UNBUILT (flashing). They transition to BUILT
at season confirmation, incurring their `matter_cost` at that point. BUILT buildings
are fixed (`moveable=false`) and toggleable (double-tap). UNBUILT buildings can be moved
or discarded; if dropped off-grid they are removed, not returned to inventory.

### Sprite CoM as Authoritative Position
The visual center of mass of a dragged sprite is its authoritative location for all
practical purposes (drop-target detection, grid snapping, hover highlighting). Never
use the raw tap/cursor position for these decisions. The CoM is computed as
`_effective_cursor_screen_pos() + (avg_offset + 0.5) * CELL_SIZE` where
`_effective_cursor_screen_pos()` already incorporates the drag offset setting.
This keeps visual and logical position in agreement regardless of drag-offset settings.

### Piece Visuals
- Buildings/structures: square cells
- Crop/food items: circle cells (`CellStyle.CIRCLE` in `PieceShape`)
- Sprites are procedurally generated (no texture files yet); art pass is Phase 5
