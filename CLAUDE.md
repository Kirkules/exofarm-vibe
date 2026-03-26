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
- Greenhouse yield logic: powered BUILT greenhouses add crop items to inventory each season
- GreenhouseDefinition (renamed from CropDefinition); extends BuildingDefinition (power_draw=1)
- SettlerHealth enum (FED, STARVING, DEAD); DEAD settlers skip food; starvation kills
- Construction cost (matter_cost=1 per greenhouse) deducted before Nutrient Paste at sim start
- UNBUILT/BUILT building state machine; starting buildings pre-placed as BUILT

Next up (Phase 2):
- [ ] Animated simulation playback with outcome log
- [ ] Playback speed controls (1×, 2×, 3×, 5×)
- [ ] Morale calculation and bar UI
- [ ] Cafeteria building: merge space + consumption area
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
| `scripts/systems/power_system.gd` | Union-find power network; `is_powered(piece_id)` |
| `scripts/systems/neighbor_system.gd` | Manhattan-distance neighbor effect engine |
| `scripts/autoloads/game_state.gd` | Singleton: season, settler_names/health, energy, matter |
| `scripts/autoloads/catalog.gd` | Known designs/recipes (meta-progression) |
| `scripts/autoloads/event_bus.gd` | Global signal bus |
| `scripts/resources/placeable_definition.gd` | Base resource; GridType enum; allowed_grids |
| `scripts/resources/building_definition.gd` | Extends PlaceableDefinition; power fields |
| `scripts/resources/greenhouse_definition.gd` | Extends BuildingDefinition; yield_per_season, output_item |

### Resource Hierarchy

```
PlaceableDefinition          ← crop items, generic placeables
  └── BuildingDefinition     ← Solar Rig, Matter Manipulator, etc.
        └── GreenhouseDefinition  ← Wheat/Tomato/Eggplant Greenhouses
```

### Grid System

- 8×6 grid, 32×32px cells, (row, col) 1-indexed, (1,1) = top-left
- Polyomino shapes: list of (row, col) offsets from origin; origin = touch anchor + rotation pivot
- 90° CW rotation: `(r, c) → (c, -r)`, then renormalize to min=(0,0)
- `piece_id` is an int assigned by `grid_data`; used as key in all piece dictionaries

### Simulation Flow

1. Player presses "Go to Season N"
2. Confirmation dialog (if starvation risk)
3. `_begin_simulation()`: capture construction cost, transition UNBUILT→BUILT, lock grid
4. 2-second placeholder delay (animation TBD)
5. `_end_simulation()`: deduct construction Matter, run food simulation, apply greenhouse
   yield, update `GameState`, unlock grid

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
- Animated simulation playback and outcome log (currently a 2-second placeholder)
- Playback speed controls (1×/2×/3×/5×)
- Inventory overflow: items beyond capacity broken down into Matter at sim start
- Morale: calculation logic + bar UI with projected delta display
- Cafeteria building: merge space + consumption slots UI
- Meal item crafting and consumption logic

### Design Decisions Deferred
- `KITCHEN_GRID` items (Wheat, Tomato, Eggplant) are currently draggable but have no
  valid drop target — they return to inventory on release. Cafeteria/merge space UI
  is the intended destination (Phase 2+).
- `neighbor_system.gd` computes effects but they are not yet applied to simulation output
- Save/load stubs exist in `GameState` but are not implemented

### Behavior Notes
- Starting buildings (Solar Rig, Matter Manipulator) placed BUILT at (3,3) and (3,4);
  `moveable=false`; not selectable
- UNBUILT buildings flash at 0.5s period; discarded if dropped off-grid
- Drag offset while holding: 1 grid-space left, 0.5 grid-space down from touch point
- Matter Manipulator must be powered for Nutrient Paste to be produced
- Construction cost captured before UNBUILT→BUILT transition in `_begin_simulation()`
  (otherwise `_compute_construction_cost()` returns 0 — the buildings are already BUILT)

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

### Piece Visuals
- Buildings/structures: square cells
- Crop/food items: circle cells (`CellStyle.CIRCLE` in `PieceShape`)
- Sprites are procedurally generated (no texture files yet); art pass is Phase 5
