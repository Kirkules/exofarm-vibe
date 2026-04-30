# ExoFarm Class Inventory

Authoritative list of all project classes (excludes `addons/`, `tests/`).
Last updated: 2026-04-28

---

## Orchestrator

### Game (no class_name) — `scenes/game/game.gd` extends Node2D
Thin scene root. Wires all managers/UI; owns Phase enum, food state computation, simulation begin/end.
Creates: BuildingManager, KitchenManager, SettlerManager, SimulationController, BuildMenu, Inventory
Key private methods: `_compute_food_state()`, `_refresh_food_hud()`, `_begin_simulation()`, `_end_simulation()`

---

## Managers

### PieceInputController — `scripts/game/piece_input_controller.gd` extends Node
Owns all drag/input state and routing for piece interactions across all grids.
Grids are passive; managers register/unregister via the registration API.
Constants: PICKUP_DRAG_THRESHOLD_SQ, PICKUP_HOLD_TIME, DRAG_OFFSET_CELLS, DEFAULT_CELL_SIZE
Enum: PendingType { NONE, GRID, INVENTORY }
Public API:
  register_pickup_source(source)
  unregister_pickup_source(source)
  register_drop_target(source, priority=0)
  unregister_drop_target(source)
  begin_inventory_drag(shape, payload, hint="")
  set_held_payload(payload)
  set_held_discardable(discardable)
  set_held_hint(hint)
  rotate_held_cw()
  cancel_drag()
  set_inventory_control(c)
Signals: pickup_confirmed(origin, piece_id, shape, payload),
         piece_placed(origin, target, piece_id, payload),
         piece_returned(origin, piece_id, payload),
         piece_released(origin, payload, com),
         drag_moved(cursor_screen, shape, payload),
         drag_ended(),
         piece_double_tapped(origin, piece_id),
         piece_long_pressed(origin, piece_id)

### BuildingManager — `scenes/game/building_manager.gd` extends Node
Farm grid interaction: piece placement, build states, power/neighbor computation.
Enum: `BuildState { UNBUILT, BUILT }`
Public API:
  setup(farm_grid, inventory, pic)
  placed_items() → Dictionary              ## piece_id → InventoryItem
  build_states() → Dictionary             ## piece_id → BuildState
  power_state() → PowerSystem.PowerState
  compute_construction_cost() → int
  compute_matter_production() → int
  food_is_powered() → bool
  cafeteria_is_powered() → bool
  build_energy_entries() → Array
  build_matter_entries(food) → Array
  recompute_power()
  toggle_piece(piece_id)
  begin_build_menu_hold(def)
  begin_inventory_hold(item)
  place_at_built(shape, row, col, item) → int
  set_solar_rig_piece_id(piece_id)
  transition_unbuilt_to_built() → Array[Dictionary]
Signals: power_changed(placed), piece_released_off_farm(item, build_state, com_screen_pos),
         cafeteria_long_pressed(piece_id), piece_picked_up_from_farm()

### KitchenManager — `scenes/game/kitchen_manager.gd` extends Node
Manages per-cafeteria KitchenGrid instances, item routing, recipe state.
Public API:
  setup(inventory, inventory_ui, ui_layer, grid_bottom, farm_grid, pic)
  is_open() → bool
  active_cafeteria_id() → int
  open_screen_rect() → Rect2
  set_recipes(recipes)
  kitchen_grid_for(cafeteria_id) → KitchenGrid
  food_item_count() → int
  sync(placed_items, build_states)
  open(cafeteria_piece_id)
  close()
  route_inventory_hold(item) → bool
  consume_all_items()
  consume_specific_items(piece_ids)
  teardown(cafeteria_id)
Signals: item_returned_to_inventory(item, from_screen)

### SettlerManager — `scenes/game/settler_manager.gd` extends Node
Manages per-settler SettlerFoodGrid instances, meal assignment, cross-slot drag.
Public API:
  setup(inventory, inventory_ui, ui_layer, hud_ui, farm_grid, pic)
  is_open() → bool
  open_screen_rect() → Rect2
  get_assigned_meal(settler_idx) → InventoryItem
  has_meal_assigned(settler_idx) → bool
  assigned_meal_count() → int
  open()
  reposition_grids()
  close()
  toggle()
  route_inventory_hold(item) → bool
  consume_assigned_meals() → int
Signals: assignments_changed(), item_returned_to_inventory(item, from_screen),
         item_snap_back_to_grid(item, from_screen, to_screen)

### SimulationController — `scenes/game/simulation_controller.gd` extends Node
15s simulation timer, settler/greenhouse animation, live log overlay, progress bar, playback speed slider.
Constants: SIMULATION_DURATION=15.0, LOG_COLOR_GAIN/LOSS/DEATH/ITEM
Public API:
  setup(farm_grid, inventory, ui_layer, hud_ui)
  is_running() → bool
  get_log() → Array[Dictionary]
  get_crafted_ingredient_ids() → Array[int]
  begin(placed_items, power_state, solar_rig_piece_id, cafeteria_craft_queue={})
  skip()
  add_log_entry(base)   ## stamps timestamp + pushes to live overlay — never append to log directly
  end_cleanup()
Signals: finished()

---

## UI

### HudUI — `scenes/game/ui/hud_ui.gd` extends Control
Top HUD bar: energy, matter, settler count, next season button, tooltips, outcome log overlay.
Constants: BASE_HEIGHT=52
Public API:
  set_simulation_active(v)
  show_settler_panel() / hide_settler_panel()
  settler_tooltip_screen_rect() → Rect2
  get_settler_slot_screen_rects() → Array[Rect2]
  refresh_energy_tooltip(entries)
  refresh_matter_tooltip(stored, entries)
  set_settler_projected_morale(projected, breakdown)
  set_settler_projected_health(projected)
  refresh_matter(projected, delta)
  refresh()
  refresh_log(entries)
Signals: next_season_pressed(), settler_label_tapped(), settler_panel_layout_changed()

### InventoryUI — `scenes/game/ui/inventory_ui.gd` extends Control
Collapsible inventory panel anchored to screen bottom.
Constants: COLLAPSED_H=48, FULL_H=400, ROW_H=36
Enum: PanelState { COLLAPSED, PARTIAL, FULL }
Public API:
  set_inventory(inv)
  set_grid_bottom(y)
  refresh_layout()
Signals: item_requested(item), state_changed(collapsed)

### BuildMenu — `scenes/game/ui/build_menu.gd` extends Control
Build menu listing placeable definitions; created programmatically (no .tscn).
Constants: ROW_H=36
Public API:
  set_definitions(defs)
Signals: building_requested(def)

### SimulationOverlay — `scenes/game/ui/simulation_overlay.gd` extends Control
Legacy stub — currently unused.

---

## Grid

### GameGrid — `scripts/grid/game_grid.gd` extends Node2D
Base grid class: passive renderer. All drag/input state owned by PieceInputController.
Key properties: rows, cols, cell_size, grid_data, grid_active, planning_locked
Public API:
  setup_pic(pic)
  lift_piece(piece_id) → PieceShape
  try_receive_drop(cursor_screen, shape, payload, hint) → int
  place_piece_at(shape, row, col, hint="") → int
  remove_piece(piece_id)
  update_cursor_hover(screen_pos)
  clear_hover()
  is_piece_moveable(piece_id) → bool
  is_piece_toggleable(piece_id) → bool
  set_piece_moveable(piece_id, moveable)
  set_piece_toggleable(piece_id, toggleable)
  set_piece_flashing(piece_id, flashing)
  set_piece_active_visual(piece_id, active)
  set_grid_active(active)
  set_planning_locked(locked)
  get_screen_rect() → Rect2
  get_grid_pixel_size() → Vector2
Virtual (override in subclasses — see .claude/code_map_overrides.md):
  _draw_grid_overlays()
  _can_place_at_cell(cell) → bool
Signals: piece_placed_on_grid(piece_id), piece_lifted_from_grid(piece_id)

### FarmGrid — `scenes/game/grid/farm_grid.gd` extends GameGrid
Farm grid subclass; power/effect range overlays; enforces FARM_GRID type filter on drops.
Public API:
  try_receive_drop(cursor_screen, shape, payload, hint) → int
  set_power_overlay(sources)
  set_effect_overlay(sources)
  set_held_power_range(power_range)

### KitchenGrid — `scenes/game/ui/kitchen_grid.gd` extends GameGrid
3×4 modal overlay grid for cafeteria; tracks recipe groups, handles merge/eject; enforces KITCHEN_GRID type filter.
Created programmatically (no .tscn); one instance per placed BUILT Cafeteria.
Constants: KITCHEN_ROWS=4, KITCHEN_COLS=3, KITCHEN_CELL_SIZE=40, HEADER_H=32
Public API:
  try_receive_drop(cursor_screen, shape, payload, hint) → int
  get_full_screen_rect() → Rect2
  set_recipes(recipes)
  on_item_placed(piece_id, def)
  on_item_removed(piece_id)
  get_complete_recipe_groups() → Array[Dictionary]
  set_capacity(cap)
Signals: piece_ejected(piece_id)

### SettlerFoodGrid — `scenes/game/ui/settler_food_grid.gd` extends GameGrid
1×1 per-settler meal assignment slot; shows "paste" placeholder when empty; enforces SETTLER_GRID type filter.
Constants: SLOT_SIZE=40
Public API:
  try_receive_drop(cursor_screen, shape, payload, hint) → int

### GridData — `scripts/grid/grid_data.gd` extends RefCounted
Pure grid state: cell occupancy, piece placement/removal, bounds checking. No rendering.
Public API:
  is_in_bounds(row, col) → bool
  get_cell(row, col) → int
  set_impassable(row, col)
  can_place(shape, origin_row, origin_col) → bool
  place_piece(shape, origin_row, origin_col) → int   ## returns assigned piece_id
  remove_piece(piece_id) → bool
  get_piece_info(piece_id) → Dictionary
  get_all_piece_ids() → Array
  get_piece_count() → int

---

## Sprite

### PieceSpriteGenerator — `scripts/pieces/piece_sprite_generator.gd`
Static utility class; procedurally generates piece textures. No instance needed.
Constants: CELL_PX=32, PADDING=4, BEVEL=2
Public API (all static):
  generate(shape, base_color) → ImageTexture
  generate_icon(shape, base_color) → ImageTexture
  origin_offset(shape) → Vector2

---

## Inventory

### Inventory — `scripts/inventory/inventory.gd` extends RefCounted
Inventory data model: ordered list of InventoryItems with slot-based capacity tracking.
Public API:
  slots_used() → int
  is_over_capacity() → bool
  get_items() → Array[InventoryItem]
  item_count() → int
  add(item) → bool
  remove(item) → bool
  send_to_top(item)
  send_to_bottom(item)
Signals: changed()

### InventoryItem — `scripts/inventory/inventory_item.gd` extends RefCounted
Lightweight item wrapper. Properties: display_name: String, slot_size: int, data: Variant
(data typically holds a PlaceableDefinition reference)

---

## Resources

### PlaceableDefinition — `scripts/resources/placeable_definition.gd` extends Resource
Base for all placeable items/buildings. Enum: GridType { FARM_GRID, KITCHEN_GRID, SETTLER_GRID }
Properties: display_name, shape: PieceShape, slot_size, moveable, matter_cost, allowed_grids

### BuildingDefinition — `scripts/resources/building_definition.gd` extends PlaceableDefinition
Adds power fields. Properties: energy_production, matter_production, power_range, power_draw

### CafeteriaDefinition — `scripts/resources/cafeteria_definition.gd` extends BuildingDefinition
Adds: merge_slots: int

### CropProductionDefinition — `scripts/resources/crop_production_definition.gd` extends BuildingDefinition
Adds: tend_interval: float, tend_per_yield: int

### GreenhouseDefinition — `scripts/resources/greenhouse_definition.gd` extends CropProductionDefinition
Adds: output_item: PlaceableDefinition

### MealDefinition — `scripts/resources/meal_definition.gd` extends PlaceableDefinition
Adds: morale_modifier: int

### RecipeDefinition — `scripts/resources/recipe_definition.gd` extends Resource
Properties: ingredients: Dictionary (PlaceableDefinition→int multiset), output_item: PlaceableDefinition,
            output_count: int, labor_cost: float

### PieceShape — `scripts/grid/piece_shape.gd` extends Resource
Polyomino shape definition. Enum: CellStyle { SQUARE, CIRCLE }
Properties: offsets: Array[Vector2i], color, effect_range, label, cell_style
Public API:
  get_cell_count() → int
  rotated_cw() → PieceShape
  rotated_ccw() → PieceShape
  get_all_rotations() → Array
  with_centered_origin() → PieceShape
  get_bounding_rect() → Rect2i
  get_label(hint="") → String

### Settler — `scripts/resources/settler.gd` extends RefCounted
Per-settler data. Enum: Health { FED, STARVING, DEAD }
Properties: name: String, health: Health, morale: int

---

## Systems

### PowerSystem — `scripts/systems/power_system.gd`
Static utility; union-find power network computation. No instantiation needed.
Inner classes:
  Network — source_ids, pool, draw; is_sufficient() → bool
  PowerState — networks, piece_network_idx, piece_powered;
               total_pool() → int, total_draw() → int, is_powered(piece_id) → bool
Public API (static): compute(placed) → PowerSystem.PowerState

### NeighborSystem — `scripts/systems/neighbor_system.gd`
Static utility; Manhattan-distance neighbor effect computation. No instantiation needed.
Inner class:
  NeighborState — neighbors, in_range_of;
                  get_neighbors(piece_id) → Array, get_in_range_of(piece_id) → Array,
                  has_neighbors(piece_id) → bool
Public API (static): compute(placed) → NeighborSystem.NeighborState

---

## Autoloads

### GameState — `scripts/autoloads/game_state.gd` (singleton)
Global game state. Properties: season: int, settlers: Array[Settler], settler_count (read-only),
energy_capacity: int, energy: int, matter: int
Methods: save(), load_save() (stubs — not yet implemented)

### EventBus — `scripts/autoloads/event_bus.gd` (singleton)
Global signal bus. Full connection map: `.claude/signal_graph.md`

### Catalog — `scripts/autoloads/catalog.gd` (singleton)
Meta-progression unlock registry. Currently a stub with no active implementation.

### Settings — `scripts/autoloads/settings.gd` (singleton)
User preferences. Properties: drag_offset: bool, master_volume, sfx_volume, music_volume
Methods: save_settings(), load_settings()
