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

**Phase 1 complete. Phase 2 (Season Simulation) is underway:** core sim loop, settler labor animation, morale system, cafeteria/kitchen grid, meal assignment, and outcome log are all implemented.

Next up:
- [ ] Playback speed controls (1×, 2×, 3×, 5×)
- [ ] End-of-run score / viability report (morale contributes here)

---

## Code Map

Five reference documents mapping project code structure. Read relevant section(s) before design consideration, code planning, or structural changes. Run the corresponding update command after changes. Use `/update-code-map` to regenerate all five at once.

**Prefer targeted reads over whole-file reads.** When looking up implementation details, use Grep to locate the relevant lines and Read only that section. Only read a whole file if the code map and targeted search are genuinely insufficient. The code map exists precisely to make whole-file reads unnecessary in most cases.

| Section | File | Update Command | Read When |
|---------|------|----------------|-----------|
| Class Inventory | `.claude/code_map_classes.md` | `/update-class-inventory` | Adding/renaming classes or changing public API |
| Dependency Graph | `.claude/code_map_deps.md` | `/update-dep-graph` | Adding/changing cross-class references |
| Virtual/Override Map | `.claude/code_map_overrides.md` | `/update-override-map` | Adding virtual methods or subclass overrides |
| Autoload Access Map | `.claude/code_map_autoloads.md` | `/update-autoload-map` | Adding/changing GameState, EventBus, Catalog, or Settings access |
| Input Handler Map | `.claude/code_map_input.md` | `/update-input-map` | Adding or modifying input handling in any class |

---

## Signal Graph

Full directed graph of all signal connections: **[`.claude/signal_graph.md`](.claude/signal_graph.md)**

**For any task or question involving signals** (adding, removing, rewiring, debugging, or reasoning about signal flow): read `.claude/signal_graph.md` first. After adding, removing, or rewiring a signal, run `/update-signal-graph`.

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


### Power System

- Only BUILT buildings participate (`active = is_built AND toggle_state`)
- Union-find groups power sources into networks; shared pool per network
- Binary powered/unpowered per consuming building (no partial power)
- Players toggle buildings off (double-tap fixed building) to manage shortfalls

---

## Code Style and Naming Conventions

**Always use explicit type annotations on every `var` declaration.** This is non-negotiable.

**Use enums instead of integer sentinels** for any discrete multi-valued variable; use named constants for any other magic numbers.

**Typed Array assignment from Dictionary requires `.assign()` not `=`:**

```gdscript
# Correct — GDScript 4 requires this for typed arrays
GameState.settler_health.assign(food["projected_health"])

# Wrong — silently fails, typed array is unchanged
GameState.settler_health = food["projected_health"]
```

**Every script file must declare `class_name`**, even if it is not referenced by other files. This is required for code map tooling to correctly identify project-defined types. **Exception: autoload singletons** (`GameState`, `EventBus`, `Catalog`, `Settings`) must not declare `class_name` — Godot registers their node name as a global and a matching `class_name` causes a conflict. The hook tooling accounts for this by seeding the allowlist from the config's `autoloads` list.

**Use `git mv` to rename source files**, not plain `mv`. This ensures rename detection works correctly in the code map tracking hooks.

**Other conventions:**
- Scene scripts co-located with their `.tscn` files; pure logic in `scripts/`
- Private helpers prefixed with `_`; public API has doc comments (`##`)
- Signals named `past_tense_verb` (e.g. `piece_placed_on_grid`, `next_season_pressed`)
- Resource subclasses use `class_name`; autoloads are singletons accessed by name

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

### Design Decisions Deferred
- `KITCHEN_GRID` items (Wheat, Tomato, Eggplant): dragging them onto the farm grid
  rejects and returns to inventory. Drag-to-kitchen-panel is the only route in.
- `neighbor_system.gd` computes effects but they are not yet applied to simulation output
- Save/load stubs exist in `GameState` but are not implemented
- `_power_state` is not recomputed after UNBUILT→BUILT in `_begin_simulation()`, so
  buildings placed in season N don't participate in power until season N+1

### Behavior Notes
- Starting buildings (Solar Rig, Matter Manipulator) placed BUILT via `building_manager.place_at_built()`
- Drag offset while holding: 1 grid-space left, 0.5 grid-space down from touch point
- Matter Manipulator must be powered for Nutrient Paste to be produced
- Construction cost captured before UNBUILT→BUILT transition in `_begin_simulation()`
  (otherwise `compute_construction_cost()` returns 0 — the buildings are already BUILT)
- Do NOT set `moveable=false` on `BuildingDefinition` resources — it has no effect;
  `BuildingManager` enforces moveability by type (UNBUILT=moveable, BUILT=fixed)
- `BuildMenu`, `KitchenGrid` nodes, progress bar, and live log are all created
  programmatically — no `.tscn` counterparts; use `_ui_layer.add_child()`
- Settler cross-slot drag: `set_held_discardable(true)` on GRID pickup; sibling grids
  deactivated (`set_grid_active(false)`) during drag to suppress hover bleed
- Morale formula (fresh each season): `morale = 0 - dead_count + food_delta` where
  `food_delta = meal.morale_modifier` if meal assigned, else `-1`; dead settlers get morale=0
- Simulation morale effects: `tasks_limit = 1 + max(0, morale)` consecutive tasks per trip;
  `skips_remaining = max(0, -morale)` skip budget; 50% skip chance per arrival while budget > 0
- `settler_dispatched` is released at task completion, not on Solar Rig return
- Log overlay input handled in `HudUI._input()` (fires before GUI processing) — necessary
  because `gui_input` on a child of HudUI only fires within HudUI's own ~52px rect

---

## Design Choices

### Numbers Stay Small
Quantities stay human-readable and directly calculable at all times. Never let numbers
grow to a scale where players estimate by feel rather than reason exactly. Design new
mechanics with this in mind.

### Units Unspecified
Don't label quantities with units in UI. Let players infer real-world equivalents.

### Planning Phase Always Reversible
All in-game decisions made during a season's planning phase can be undone until
"Proceed to Next Season" is confirmed. This is a core design guarantee — never break it.

### Inventory as Workspace
The inventory is the sole off-grid holding area — there is no separate workspace.

### GridType for Item Routing
`PlaceableDefinition.GridType` enum (`FARM_GRID`, `KITCHEN_GRID`) controls which grids
accept each item. Items are always draggable; rejection happens at drop time, not pickup.
New grid UIs should add a new `GridType` value and enforce it at their drop handler.

### Sprite CoM as Authoritative Position
The visual center of mass of a dragged sprite is its authoritative position for
drop-target detection, grid snapping, and hover highlighting. Never use the raw
tap/cursor position for these decisions.

### Math-Based UI Positioning
Prefer computing screen positions mathematically from known layout constants over
querying `Control.get_global_rect()` or `get_global_position()` on child nodes.
Layout cascades (VBox/HBox distribution) may not be complete even one frame after
nodes are added, making runtime queries unreliable.

