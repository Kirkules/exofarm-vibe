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
- GridType enum (`FARM_GRID`, `KITCHEN_GRID`, `SETTLER_GRID`) on `PlaceableDefinition`;
  crop items restricted to `KITCHEN_GRID`; meals restricted to `KITCHEN_GRID`+`SETTLER_GRID`
- `CropProductionDefinition` inserted between `BuildingDefinition` and `GreenhouseDefinition`;
  holds `tend_interval` and `tend_per_yield`
- Real-time 15s settler labor animation: ColorRect sprites walk Solar Rig↔greenhouses at
  2 grid-units/sec; `tend_per_yield` arrivals yield one crop item
- Season progress bar (16px above grid) with elapsed-time label; SimulationOverlay removed
- Live log overlay between HUD and progress bar: shows last 6 entries as they occur
- Outcome log with timestamps, color-coded values, and per-entry label/value layout;
  accessible via "log" button below Next Season; cleared at start of each simulation
- SettlerHealth enum (FED, STARVING, DEAD); DEAD settlers skip food; starvation kills
- Construction cost deducted before Nutrient Paste at sim start; UNBUILT/BUILT state machine
- Cafeteria (1×2, amber); `KitchenGrid` (GameGrid subclass, 3×4) opened by long-press;
  per-cafeteria grids; KITCHEN_GRID items route to nearest empty slot at drop CoM
- "Skip simulation" button compresses remaining time to 0.5s for fast playtesting
- Grid refactor complete: `GameGrid` base class; signal-driven sim locking via EventBus;
  `KitchenGrid` replaces `KitchenPanel`; `interaction_blocked` removed
- `game.gd` split into `BuildingManager`, `KitchenManager`, `SimulationController`;
  `game.gd` is now a thin orchestrator
- `SettlerManager` + `SettlerFoodGrid`: per-settler 1×1 meal-assignment slots shown as
  a panel overlay (tap settler label to open/close); items draggable across slots;
  `assignments_changed` signal refreshes HUD; sibling grids deactivated during any drag
  to suppress hover bleed; `set_held_discardable(true)` on pickup enables cross-slot drag
- `RecipeDefinition` populated: {2 Wheat}→Pasta, {2 Tomato}→Tomato Sauce,
  {1 Pasta+1 Tomato Sauce+1 Eggplant}→3 Pasta alla Norma (MealDefinition, SETTLER_GRID)
- `_refresh_food_hud()` helper in game.gd shared by `power_changed` and
  `assignments_changed` so Matter HUD/tooltip updates on meal assignment changes
- `Settler` class replaces parallel `settler_names`/`settler_health` arrays in GameState;
  owns `Health` enum and `morale: int`
- Per-settler morale: formula = `0 - dead_count + food_delta` (fresh each season);
  shown inline in settler tooltip as "Alice (fed) Content (+0)"; morale breakdown
  expandable by tapping the morale label (one settler at a time)
- Morale affects simulation: positive morale → settler does `1 + morale` consecutive
  tasks per trip; negative morale → skip budget of `-morale`, 50% skip chance per
  greenhouse arrival until budget exhausted
- `_find_nearest_available_task` / `_claim_task` / `_send_agent_to_task` in
  `SimulationController` prevent race conditions and route settlers to closest task;
  `settler_dispatched` released at task completion (not on Solar Rig return)
- Outcome log refactored: scrollable via grab-to-scroll (`ScrollContainer` + `gui_input`);
  informational scroll indicator (4px ColorRect, auto-hides after 1s); fills viewport
  height below HUD; dismissed by tapping outside or tapping log button again

Next up:
- [ ] Playback speed controls (1×, 2×, 3×, 5×)
- [ ] Inventory overflow → broken down to Matter at sim start
- [ ] End-of-run score / viability report (morale contributes here)

---

## Tech Stack and Architecture

- **Engine:** Godot 4.6.1, GDScript only (no C#)
- **Target:** Android portrait (270×600 base, 4× integer scaling on Pixel 7a)
- **Tests:** GUT plugin (`tests/unit/`); pure logic only, no UI tests

### Key Files

| File | Role |
|------|------|
| `scenes/game/game.gd` | Thin orchestrator: owns `Phase`, `_compute_food_state()`, `_refresh_food_hud()`, `_begin/_end_simulation()`, wires managers |
| `scenes/game/building_manager.gd` | Farm grid interaction, placement state, power/neighbor, build states, `BuildState` enum |
| `scenes/game/kitchen_manager.gd` | All per-cafeteria `KitchenGrid` instances, item state, open/close/sync |
| `scenes/game/simulation_controller.gd` | Simulation timer, progress bar, live log, greenhouse/settler animation |
| `scenes/game/settler_manager.gd` | Per-settler `SettlerFoodGrid` instances; open/close/toggle; `assignments_changed` signal; cross-slot drag |
| `scenes/game/grid/farm_grid.gd` | Grid input, piece hold/drag/drop, sprites, overlays |
| `scenes/game/ui/kitchen_grid.gd` | `GameGrid` subclass (3×4, 40px cells); inactive cells; `piece_ejected` signal |
| `scenes/game/ui/settler_food_grid.gd` | `GameGrid` subclass (1×1, 40px); "paste" placeholder; reactivates on merge_grid_closed only when visible |
| `scripts/grid/game_grid.gd` | Base grid class; signal-driven planning lock; `_on_merge_grid_closed()` virtual |
| `scripts/grid/grid_data.gd` | Grid state (pure logic, no rendering) |
| `scripts/grid/piece_shape.gd` | Polyomino shape + rotation; `CellStyle` enum (SQUARE/CIRCLE) |
| `scripts/pieces/piece_sprite_generator.gd` | Generates piece textures procedurally |
| `scripts/inventory/inventory.gd` | Inventory data model |
| `scenes/game/ui/inventory_ui.gd` | Inventory panel UI |
| `scenes/game/ui/hud_ui.gd` | Top HUD (Energy, Matter, Settlers, Next Season/Skip button, tooltips) |
| `scenes/game/ui/build_menu.gd` | Build menu below inventory |
| `scripts/systems/power_system.gd` | Union-find power network; `is_powered(piece_id)` |
| `scripts/systems/neighbor_system.gd` | Manhattan-distance neighbor effect engine |
| `scripts/autoloads/game_state.gd` | Singleton: season, `settlers: Array[Settler]`, energy, matter |
| `scripts/resources/settler.gd` | `class_name Settler extends RefCounted`; `Health` enum; `name`, `health`, `morale` |
| `scripts/autoloads/catalog.gd` | Known designs/recipes (meta-progression) |
| `scripts/autoloads/event_bus.gd` | Global signal bus |
| `scripts/resources/placeable_definition.gd` | Base resource; GridType enum; allowed_grids |
| `scripts/resources/building_definition.gd` | Extends PlaceableDefinition; power fields |
| `scripts/resources/crop_production_definition.gd` | Extends BuildingDefinition; tend_interval, tend_per_yield |
| `scripts/resources/greenhouse_definition.gd` | Extends CropProductionDefinition; output_item |
| `scripts/resources/cafeteria_definition.gd` | Extends BuildingDefinition; merge_slots |
| `scripts/resources/meal_definition.gd` | Extends PlaceableDefinition; `morale_modifier: int` |
| `scripts/resources/recipe_definition.gd` | ingredients (PlaceableDefinition→int multiset), output_item (PlaceableDefinition), output_count, labor_cost |

### Resource Hierarchy

```
PlaceableDefinition              ← crop items, intermediate ingredients, generic placeables
  ├── MealDefinition             ← Pasta alla Norma (KITCHEN_GRID + SETTLER_GRID)
  └── BuildingDefinition         ← Solar Rig, Matter Manipulator, Cafeteria
        ├── CafeteriaDefinition  ← merge_slots
        └── CropProductionDefinition  ← tend_interval, tend_per_yield
              └── GreenhouseDefinition    ← Wheat/Tomato/Eggplant Greenhouses
```

**No `.tres` resource files exist.** All building and item definitions are created
programmatically in `game.gd:_create_item_defs()` and `_buildable_definitions()` and
`_place_starting_buildings()`. Item defs are shared instance vars so recipe ingredient
Dictionary keys match placed item `.data` references. `_recipe_definitions()` returns
the three current recipes passed to `kitchen_manager.set_recipes()`.

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

`KitchenGrid` is a modal overlay on the farm grid (not below it). It is sized
`(KITCHEN_COLS × KITCHEN_CELL_SIZE, KITCHEN_ROWS × KITCHEN_CELL_SIZE)` (120×160px) and
positioned so its bottom aligns with `grid_bottom`. It does not shift any other UI elements.
One `KitchenGrid` node exists per placed BUILT Cafeteria; `KitchenManager.sync()` creates
and tears them down as cafeterias are placed/removed.

`InventoryUI` is anchored to the bottom of the screen (anchor_top=1, anchor_bottom=1,
offset_top=−48). Its PARTIAL height = `viewport_h − grid_bottom − 8`.

### Grid System

- 8×6 grid, 32×32px cells, (row, col) 1-indexed, (1,1) = top-left
- Polyomino shapes: list of (row, col) offsets from origin; origin = touch anchor + rotation pivot
- 90° CW rotation: `(r, c) → (c, -r)`, then renormalize to min=(0,0)
- `piece_id` is an int assigned by `grid_data`; used as key in all piece dictionaries

### Piece Placement Signal Flow

```
build menu tap   → game._on_building_requested(def)  → building_manager.begin_build_menu_hold
inventory tap    → game._on_item_requested(item)
                    • settler panel open: settler_manager.route_inventory_hold(item)
                    • kitchen open:       kitchen_manager.route_inventory_hold(item)
                    • else:               building_manager.begin_inventory_hold(item)

building_manager internal (farm_grid signals → BuildingManager handlers):
  inventory_item_pickup_confirmed → remove from inventory; set held state
  piece_placed_on_grid  → register in _placed_items; KITCHEN_GRID-only items rejected back
                           to inventory; recompute_power() → power_changed.emit()
  piece_released        → emit piece_released_off_farm(item, build_state, com_screen_pos)
  piece_returned_to_grid → restore _placed_items; recompute_power() → power_changed.emit()
  piece_picked_up_from_grid → erase from _placed_items; recompute_power();
                               emit piece_picked_up_from_farm()
  piece_long_pressed    → if CafeteriaDefinition: emit cafeteria_long_pressed(piece_id)

game.gd handles BuildingManager signals:
  power_changed         → _on_power_changed(): _refresh_food_hud() + kitchen_manager.sync()
  piece_released_off_farm → route SETTLER_GRID items to settler_manager.try_place_item();
                             route KITCHEN_GRID items to kitchen_manager.try_place_item();
                             UNBUILT: discard; else: return to inventory
  piece_picked_up_from_farm → kitchen_manager.close()
  cafeteria_long_pressed → settler_manager.close(); kitchen_manager.open(piece_id)
                            [guarded: no-op in SIMULATION]

settler_manager (SettlerFoodGrid signals wired per-settler via closures):
  inventory_item_pickup_confirmed → remove from inventory; set _held_item;
                                    _deactivate_other_grids(g)
  piece_placed_on_grid  → register in _settler_placed_items[i]; _reactivate_all_grids()
  piece_picked_up_from_grid → erase from _settler_placed_items[i];
                               set_held_discardable(true) for cross-slot drag;
                               _deactivate_other_grids(g)
  piece_released        → try_place_item on sibling slots; else return to inventory;
                          _reactivate_all_grids()
  piece_returned_to_grid → restore _settler_placed_items[i]; _reactivate_all_grids()
  assignments_changed   → game._refresh_food_hud() (updates Matter HUD + tooltip)

kitchen_manager (KitchenGrid signals wired per-cafeteria via closures):
  inventory_item_pickup_confirmed → remove from inventory; set _held_item
  piece_placed_on_grid  → register in _kitchen_placed_items[cid]
  piece_picked_up_from_grid → erase from _kitchen_placed_items[cid]
  piece_released        → return _held_item to inventory
  piece_returned_to_grid → restore _kitchen_placed_items[cid]
  piece_ejected         → return item to inventory (capacity reduction)
```

**Key state dicts in BuildingManager** (all keyed by `piece_id: int`):
- `_placed_items` — piece_id → InventoryItem (survives pick-up/put-down)
- `_piece_build_state` — piece_id → `BuildState` (UNBUILT / BUILT)
- `_piece_active` — piece_id → bool (toggle state; default true)

`BuildState` enum lives in `BuildingManager`; referenced externally as `BuildingManager.BuildState`.
`_build_placed_dict()` (internal to BuildingManager) builds the dict for PowerSystem/NeighborSystem;
UNBUILT pieces have `"active": false`, so they don't participate in power.

### Simulation Flow

1. Player presses "Go to Season N" → `game._on_next_season_pressed()`
2. Confirmation dialog (if starvation risk)
3. `game._begin_simulation()`:
   - `kitchen_manager.close()` + `settler_manager.close()`
   - Capture `_sim_construction_cost = building_manager.compute_construction_cost()`
   - `building_manager.transition_unbuilt_to_built()` → returns per-building log entries
   - `simulation_controller.begin(placed_items, power_state, solar_rig_piece_id)`
     — clears log, builds greenhouse states, starts 15s timer, shows progress bar + live log
   - Add construction log entries via `simulation_controller.add_log_entry()`
4. `SimulationController._process(delta)`: advances elapsed, updates progress bar,
   ticks greenhouses + settlers; settlers walk Solar Rig→greenhouse at 2 grid-units/sec;
   each arrival is a tend; on `tend_per_yield` tends the greenhouse yields one crop item.
   Player can press "Skip simulation" → `simulation_controller.skip()` (compresses to 0.5s)
5. Timer fires → `simulation_controller.finished` → `game._end_simulation()`:
   - log/apply Matter prod → log/consume kitchen items → log settler meal consumption
     (`settler_manager.consume_assigned_meals()`) → log/apply Nutrient Paste
   - log deaths → update GameState → push log to HUD → `simulation_controller.end_cleanup()`
   - `building_manager.recompute_power()` → `power_changed` → HUD update + kitchen sync
   Note: power_state is NOT recomputed after UNBUILT→BUILT in `_begin_simulation()`, so
   newly-BUILT buildings don't participate in power until the next planning phase.

### Simulation Log Format

Each entry dict: `{"label": String, "value": String, "label_color": String,
"value_color": String, "timestamp": float}`. Colors defined as constants on
`SimulationController`: `LOG_COLOR_GAIN`, `LOG_COLOR_LOSS`, `LOG_COLOR_DEATH`, `LOG_COLOR_ITEM`.
Always call `simulation_controller.add_log_entry(base)` — never append to the log directly
(it stamps timestamp and pushes to live overlay).

### _compute_food_state() return keys

Lives in `game.gd`; calls `building_manager`, `kitchen_manager`, and `settler_manager` for inputs.
Keys: `matter_prod`, `construction_cost`, `food_items` (from `settler_manager.assigned_meal_count()`),
`paste_needed`, `paste_produced`, `projected_health` (Array[int] parallel to settler_names), `deaths`.
Distribution: settlers with a meal assigned (`settler_manager.has_meal_assigned(i)`) are FED from
their meal; remaining living settlers draw from Nutrient Paste; those without paste die.
Pass `construction_cost_override >= 0` in `_end_simulation` to use the pre-transition cost
(captured before UNBUILT→BUILT runs).

`_refresh_food_hud()` is a shared helper called by both `_on_power_changed` and
`settler_manager.assignments_changed` to keep Matter HUD/tooltip in sync.

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
- End-of-run score / viability report (morale contributes)

### Design Decisions Deferred
- `KITCHEN_GRID` items (Wheat, Tomato, Eggplant): dragging them onto the farm grid
  rejects and returns to inventory. Drag-to-kitchen-panel is the only route in.
- `neighbor_system.gd` computes effects but they are not yet applied to simulation output
- Save/load stubs exist in `GameState` but are not implemented
- `_power_state` is not recomputed after UNBUILT→BUILT in `_begin_simulation()`, so
  buildings placed in season N don't participate in power until season N+1

### Behavior Notes
- Starting buildings (Solar Rig, Matter Manipulator) placed BUILT at (3,3) and (3,4);
  `moveable=false`; not selectable; placed via `building_manager.place_at_built()`
- UNBUILT buildings flash at 0.5s period; discarded if dropped off-grid
- Drag offset while holding: 1 grid-space left, 0.5 grid-space down from touch point
- Matter Manipulator must be powered for Nutrient Paste to be produced
- Construction cost captured before UNBUILT→BUILT transition in `_begin_simulation()`
  (otherwise `compute_construction_cost()` returns 0 — the buildings are already BUILT)
- `BuildingManager` enforces moveability by type: `BuildingDefinition` pieces are moveable
  when UNBUILT and fixed when BUILT; non-building placeables use `def.moveable`. Do NOT
  set `moveable=false` on building definitions — it has no effect.
- `BuildMenu`, `KitchenGrid` nodes, progress bar, and live log are all created
  programmatically — no `.tscn` counterparts; use `_ui_layer.add_child()`
- `KitchenGrid`: long-press (0.5s) on a placed BUILT Cafeteria opens it; any new press
  outside it closes it (`game._unhandled_input`); `planning_locked` (set by EventBus
  `merge_grid_opened/closed`) blocks farm grid interaction while a kitchen grid is open
- `KitchenManager._find_nearest_empty_cell(kg, screen_pos)` finds the closest active
  empty slot to the drop CoM; used by `try_place_item()` for off-grid drops
- `BuildState` enum lives in `BuildingManager`; `BuildingManager.BuildState.UNBUILT/BUILT`
- Settler panel: opened by tapping the settler count label in HUD; `SettlerFoodGrid` nodes
  on the same `_ui_layer` at z_index=101 (above the settler tooltip at z_index=100);
  positioned via math from `_settler_tooltip.global_position + offset` (not layout queries)
- Settler cross-slot drag: `set_held_discardable(true)` on GRID pickup; sibling grids
  deactivated (`set_grid_active(false)`) during drag to suppress hover bleed; reactivated
  in all `_on_piece_placed/released/returned` handlers
- Morale formula (computed fresh each season in `_compute_food_state()`):
  `morale = 0 - dead_count + food_delta` where `food_delta = meal.morale_modifier` if
  settler has a meal assigned, else `-1` for Nutrient Paste; dead settlers get morale=0
- Simulation morale effects: `tasks_limit = 1 + max(0, morale)` consecutive tasks per trip
  from Solar Rig; `skips_remaining = max(0, -morale)` skip budget per season initialized
  in `SimulationController.begin()`; 50% skip chance per greenhouse arrival while budget > 0
- `_find_nearest_available_task(from_pos)` scans all unclaimed ready greenhouses+cafeterias;
  `_claim_task(task)` sets `settler_dispatched=true` atomically; `_send_agent_to_task(agent,
  from_pos, task)` redirects agent in place for consecutive tasks; `settler_dispatched`
  released at task completion (not Solar Rig return)
- Outcome log panel: `Panel` + `ScrollContainer` (PRESET_FULL_RECT, `SCROLL_MODE_SHOW_NEVER`)
  + `_log_vbox`; fills viewport height from `offset_bottom` down; grab-to-scroll via
  `gui_input` on ScrollContainer; 4px `ColorRect` indicator shown on drag, hidden 1s
  after last scroll via one-shot Timer; dismissed in `_input` override on outside press

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

### Math-Based UI Positioning
Prefer computing screen positions mathematically from known layout constants (e.g.
`_settler_tooltip.global_position + Vector2(panel_w - slot_size, i * slot_size)`) over
querying `Control.get_global_rect()` or `get_global_position()` on individual child
nodes. Child Control layout cascades (VBoxContainer row placement, HBoxContainer
distribution, etc.) may not be complete even one frame after nodes are added, making
runtime queries unreliable. Math-based positioning is deterministic, frame-independent,
and easier to reason about. Use `get_global_rect()` only when the target node's position
is explicitly assigned (not layout-driven) and you need its size, or when there is no
reasonable closed-form alternative.

### Piece Visuals
- Buildings/structures: square cells
- Crop/food items: circle cells (`CellStyle.CIRCLE` in `PieceShape`)
- Sprites are procedurally generated (no texture files yet); art pass is Phase 5
