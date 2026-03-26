extends Node2D

@onready var farm_grid:    FarmGrid    = $FarmGrid
@onready var inventory_ui: InventoryUI = $UILayer/InventoryUI
@onready var hud_ui:       HudUI       = $UILayer/HudUI
@onready var _ui_layer:    CanvasLayer = $UILayer

var _inventory: Inventory
## The InventoryItem currently in the air (held by farm_grid).
var _held_item: InventoryItem = null
## Maps piece_id -> InventoryItem for pieces currently on the grid,
## so their name and metadata survive pick-up/put-down cycles.
var _placed_items: Dictionary = {}
## Maps piece_id -> bool: false = building is toggled off by the player.
var _piece_active: Dictionary = {}
## Most recently computed power state. Null until the first piece is placed.
var _power_state: PowerSystem.PowerState = null
## Most recently computed neighbor state. Null until the first piece is placed.
var _neighbor_state: NeighborSystem.NeighborState = null
## Reusable confirmation dialog for risky Next Season actions.
var _confirm_dialog: ConfirmationDialog
## Timer that drives the placeholder simulation phase duration.
var _sim_timer: Timer
var _sim_overlay: SimulationOverlay
var _build_menu: BuildMenu

enum Phase { PLANNING, SIMULATION }
var _phase: Phase = Phase.PLANNING

## Build state for each placed piece.  UNBUILT = placed this planning phase,
## flashing, discarded if dragged off-grid.  BUILT = permanent, cannot move.
enum BuildState { UNBUILT, BUILT }
var _piece_build_state: Dictionary = {}    # piece_id -> BuildState
## Build state carried by the currently held piece.
var _held_build_state: BuildState = BuildState.BUILT
## The pending InventoryItem created for a build-menu selection (not from _inventory).
var _pending_menu_item: InventoryItem = null

## Duration of the placeholder simulation animation (seconds).
const SIMULATION_PLACEHOLDER_DURATION := 2.0
## Construction cost locked in at simulation start, before UNBUILT→BUILT transition
## erases the information. Used by _end_simulation() to correctly charge Matter.
var _sim_construction_cost: int = 0

func _ready() -> void:
	_inventory = Inventory.new(10)
	inventory_ui.set_inventory(_inventory)
	inventory_ui.set_grid_bottom(farm_grid.position.y + farm_grid.get_grid_pixel_size().y)
	farm_grid.set_inventory_control(inventory_ui)
	inventory_ui.item_requested.connect(_on_item_requested)
	farm_grid.piece_picked_up_from_grid.connect(_on_piece_picked_up_from_grid)
	farm_grid.piece_placed_on_grid.connect(_on_piece_placed_on_grid)
	farm_grid.piece_hold_cancelled.connect(_on_piece_hold_cancelled)
	farm_grid.piece_returned_to_grid.connect(_on_piece_returned_to_grid)
	farm_grid.inventory_item_pickup_confirmed.connect(_on_inventory_item_pickup_confirmed)
	hud_ui.next_season_pressed.connect(_on_next_season_pressed)
	_confirm_dialog = ConfirmationDialog.new()
	_confirm_dialog.confirmed.connect(_begin_simulation)
	add_child(_confirm_dialog)
	_sim_timer = Timer.new()
	_sim_timer.one_shot = true
	_sim_timer.timeout.connect(_end_simulation)
	add_child(_sim_timer)
	farm_grid.piece_double_tapped.connect(toggle_piece)

	# Simulation overlay: covers the scenic view + grid area in UILayer space.
	# FarmGrid sits at world y=150 with 192px height; HUD occupies the top strip.
	var overlay_top: float = hud_ui.offset_bottom
	var grid_bottom: float = farm_grid.position.y + farm_grid.get_grid_pixel_size().y
	_sim_overlay = SimulationOverlay.new()
	_sim_overlay.position = Vector2(0.0, overlay_top)
	_sim_overlay.size     = Vector2(270.0, grid_bottom - overlay_top)
	_ui_layer.add_child(_sim_overlay)

	# Build menu — shown below the grid when the inventory is collapsed.
	var viewport_h: float = get_viewport().get_visible_rect().size.y
	_build_menu = BuildMenu.new()
	_build_menu.position = Vector2(0.0, grid_bottom)
	_build_menu.size     = Vector2(270.0, viewport_h - grid_bottom - InventoryUI.COLLAPSED_H)
	_build_menu.building_requested.connect(_on_building_requested)
	_ui_layer.add_child(_build_menu)  # _ready() fires here, initialising _item_list
	_build_menu.set_definitions(_buildable_definitions())
	inventory_ui.state_changed.connect(_on_inventory_state_changed)

	# Pre-place starting buildings directly on the grid (as BUILT).
	_place_starting_buildings()

## Builds starting building definitions and places them directly on the grid.
func _place_starting_buildings() -> void:
	var solar_shape: PieceShape = PieceShape.new()
	solar_shape.color = Color(0.95, 0.80, 0.20)
	solar_shape.label = "SOL"
	var solar_rig: BuildingDefinition = BuildingDefinition.new()
	solar_rig.display_name = "Solar Rig"
	solar_rig.shape = solar_shape
	solar_rig.moveable = false
	solar_rig.energy_production = 10
	solar_rig.power_range = 3

	var matter_shape: PieceShape = PieceShape.new()
	matter_shape.color = Color(0.45, 0.75, 0.55)
	matter_shape.label = "MAT"
	var matter_manip: BuildingDefinition = BuildingDefinition.new()
	matter_manip.display_name = "Matter Manipulator"
	matter_manip.shape = matter_shape
	matter_manip.moveable = false
	matter_manip.matter_production = 5
	matter_manip.power_draw = 2

	# Place each building by temporarily setting _held_item so _on_piece_placed_on_grid
	# registers it correctly, then call place_piece_at which emits the signal.
	for entry: Array in [
		[solar_rig,    3, 3],
		[matter_manip, 3, 4],
	]:
		var def: BuildingDefinition = entry[0]
		var row: int                = entry[1]
		var col: int                = entry[2]
		_held_item = InventoryItem.new(def.display_name, 1, def)
		farm_grid.place_piece_at(def.shape, row, col, def.display_name)
		# _held_item cleared by _on_piece_placed_on_grid

## Returns the definitions available in the build menu this run.
func _buildable_definitions() -> Array[PlaceableDefinition]:
	var result: Array[PlaceableDefinition] = []

	# --- Crop item definitions (harvested produce; not placed on the farm grid) ---

	var wheat_item_shape: PieceShape = PieceShape.new()
	wheat_item_shape.color = Color(1.0, 0.92, 0.40)  # brighter gold than the greenhouse
	wheat_item_shape.cell_style = PieceShape.CellStyle.CIRCLE
	var wheat_item: PlaceableDefinition = PlaceableDefinition.new()
	wheat_item.display_name = "Wheat"  # auto-label: "WHE"
	wheat_item.shape = wheat_item_shape

	var tomato_item_shape: PieceShape = PieceShape.new()
	tomato_item_shape.color = Color(0.95, 0.35, 0.25)  # brighter red
	tomato_item_shape.cell_style = PieceShape.CellStyle.CIRCLE
	var tomato_item: PlaceableDefinition = PlaceableDefinition.new()
	tomato_item.display_name = "Tomato"  # auto-label: "TOM"
	tomato_item.shape = tomato_item_shape

	var eggplant_item_shape: PieceShape = PieceShape.new()
	eggplant_item_shape.color = Color(0.65, 0.25, 0.85)  # brighter purple
	eggplant_item_shape.cell_style = PieceShape.CellStyle.CIRCLE
	var eggplant_item: PlaceableDefinition = PlaceableDefinition.new()
	eggplant_item.display_name = "Eggplant"  # auto-label: "EGG"
	eggplant_item.shape = eggplant_item_shape

	# --- Greenhouse definitions (crop-producing grid pieces) ---

	var wheat_gh_shape: PieceShape = PieceShape.new()
	wheat_gh_shape.color = Color(0.95, 0.85, 0.30)  # muted gold
	wheat_gh_shape.label = "WGH"
	var wheat_gh: GreenhouseDefinition = GreenhouseDefinition.new()
	wheat_gh.display_name = "Wheat Greenhouse"
	wheat_gh.shape = wheat_gh_shape
	wheat_gh.matter_cost = 1
	wheat_gh.power_draw = 1
	wheat_gh.yield_per_season = 1
	wheat_gh.output_item = wheat_item
	result.append(wheat_gh)

	var tomato_gh_shape: PieceShape = PieceShape.new()
	tomato_gh_shape.color = Color(0.90, 0.28, 0.20)  # muted red
	tomato_gh_shape.label = "TGH"
	var tomato_gh: GreenhouseDefinition = GreenhouseDefinition.new()
	tomato_gh.display_name = "Tomato Greenhouse"
	tomato_gh.shape = tomato_gh_shape
	tomato_gh.matter_cost = 1
	tomato_gh.power_draw = 1
	tomato_gh.yield_per_season = 1
	tomato_gh.output_item = tomato_item
	result.append(tomato_gh)

	var eggplant_gh_shape: PieceShape = PieceShape.new()
	eggplant_gh_shape.color = Color(0.50, 0.15, 0.65)  # muted purple
	eggplant_gh_shape.label = "EGH"
	var eggplant_gh: GreenhouseDefinition = GreenhouseDefinition.new()
	eggplant_gh.display_name = "Eggplant Greenhouse"
	eggplant_gh.shape = eggplant_gh_shape
	eggplant_gh.matter_cost = 1
	eggplant_gh.power_draw = 1
	eggplant_gh.yield_per_season = 1
	eggplant_gh.output_item = eggplant_item
	result.append(eggplant_gh)

	return result

func _on_building_requested(def: PlaceableDefinition) -> void:
	if farm_grid.has_held_piece or farm_grid.has_pending_pickup:
		return
	_pending_menu_item = InventoryItem.new(def.display_name, 1, def)
	farm_grid.begin_pending_inventory_hold(_pending_menu_item)

func _on_inventory_state_changed(collapsed: bool) -> void:
	_build_menu.visible = collapsed

func _unhandled_input(event: InputEvent) -> void:
	# Phase 0: Enter/space rotates the held piece clockwise.
	if event.is_action_pressed("ui_accept"):
		farm_grid.rotate_held_cw()

func _on_item_requested(item: InventoryItem) -> void:
	if farm_grid.has_held_piece or farm_grid.has_pending_pickup:
		return
	if item.data is PlaceableDefinition:
		farm_grid.begin_pending_inventory_hold(item)

func _on_inventory_item_pickup_confirmed(item: InventoryItem) -> void:
	_held_item = item
	_inventory.remove(item)
	# Items selected from the build menu (not _inventory) start UNBUILT.
	_held_build_state = BuildState.UNBUILT if item == _pending_menu_item else BuildState.BUILT
	_pending_menu_item = null
	var def: PlaceableDefinition = item.data as PlaceableDefinition
	var pr: int = (def as BuildingDefinition).power_range if def is BuildingDefinition else 0
	farm_grid.set_held_power_range(pr)

func _on_piece_picked_up_from_grid(piece_id: int, _shape: PieceShape) -> void:
	_held_item = _placed_items.get(piece_id, null)
	_held_build_state = _piece_build_state.get(piece_id, BuildState.BUILT)
	_placed_items.erase(piece_id)
	_piece_build_state.erase(piece_id)
	_piece_active.erase(piece_id)
	if _held_item:
		farm_grid.set_held_hint(_held_item.display_name)
		var def: PlaceableDefinition = _held_item.data as PlaceableDefinition
		var pr: int = (def as BuildingDefinition).power_range if def is BuildingDefinition else 0
		farm_grid.set_held_power_range(pr)
	_recompute_power()

func _on_piece_placed_on_grid(piece_id: int) -> void:
	if _held_item:
		_placed_items[piece_id] = _held_item
	_held_item = null
	var def: PlaceableDefinition = (_placed_items[piece_id].data if _placed_items.has(piece_id) else null) as PlaceableDefinition
	_piece_build_state[piece_id] = _held_build_state
	var is_unbuilt: bool = _held_build_state == BuildState.UNBUILT
	_held_build_state = BuildState.BUILT  # reset for next placement
	farm_grid.set_piece_moveable(piece_id, is_unbuilt or (def != null and def.moveable))
	farm_grid.set_piece_toggleable(piece_id, def is BuildingDefinition and not is_unbuilt)
	farm_grid.set_piece_flashing(piece_id, is_unbuilt)
	farm_grid.set_held_power_range(0)
	_recompute_power()

func _on_piece_hold_cancelled(_shape: PieceShape) -> void:
	# UNBUILT pieces (from build menu or picked up off grid) are discarded on drop.
	if _held_build_state != BuildState.UNBUILT and _held_item:
		_inventory.add(_held_item)
	_held_item = null
	_held_build_state = BuildState.BUILT
	farm_grid.set_held_power_range(0)

func _on_piece_returned_to_grid(piece_id: int) -> void:
	if _held_item:
		_placed_items[piece_id] = _held_item
	_held_item = null
	var def: PlaceableDefinition = (_placed_items[piece_id].data if _placed_items.has(piece_id) else null) as PlaceableDefinition
	_piece_build_state[piece_id] = _held_build_state
	var is_unbuilt: bool = _held_build_state == BuildState.UNBUILT
	_held_build_state = BuildState.BUILT
	farm_grid.set_piece_moveable(piece_id, is_unbuilt or (def != null and def.moveable))
	farm_grid.set_piece_toggleable(piece_id, def is BuildingDefinition and not is_unbuilt)
	farm_grid.set_piece_flashing(piece_id, is_unbuilt)
	farm_grid.set_held_power_range(0)
	_recompute_power()

## Toggle a placed building on or off and recompute power.
func toggle_piece(piece_id: int) -> void:
	var now_active: bool = not _piece_active.get(piece_id, true)
	_piece_active[piece_id] = now_active
	farm_grid.set_piece_active_visual(piece_id, now_active)
	_recompute_power()

func _recompute_power() -> void:
	var placed: Dictionary = _build_placed_dict()
	_power_state    = PowerSystem.compute(placed)
	_neighbor_state = NeighborSystem.compute(placed)
	# Energy capacity = total power pool from all placed sources.
	# During planning, energy is always at full capacity (nothing spent yet).
	GameState.energy_capacity = _power_state.total_pool()
	GameState.energy = GameState.energy_capacity - _power_state.total_draw()
	# Compute food and matter projection for HUD.
	var food: Dictionary    = _compute_food_state()
	var paste_produced: int    = food["paste_produced"]
	var matter_prod: int       = food["matter_prod"]
	var construction_cost: int = food["construction_cost"]
	var matter_net: int        = matter_prod - construction_cost - paste_produced
	hud_ui.set_settler_projected_health(food["projected_health"])
	hud_ui.refresh_matter(GameState.matter + matter_net, matter_net)
	hud_ui.refresh_energy_tooltip(_build_energy_entries())
	hud_ui.refresh_matter_tooltip(GameState.matter, _build_matter_entries(food))
	hud_ui.refresh()
	_refresh_overlays(placed)

## Returns the total Matter construction cost of all UNBUILT pieces on the grid.
## Deducted from Matter at season confirmation, before Nutrient Paste production.
func _compute_construction_cost() -> int:
	var cost: int = 0
	for piece_id: int in _placed_items:
		if _piece_build_state.get(piece_id, BuildState.BUILT) != BuildState.UNBUILT:
			continue
		var def: PlaceableDefinition = _placed_items[piece_id].data as PlaceableDefinition
		if def != null:
			cost += def.matter_cost
	return cost

## Returns the Matter that would be produced this season given the current grid layout.
## Buildings with power_draw > 0 only produce if powered.
func _compute_matter_production() -> int:
	var matter_prod: int = 0
	for piece_id: int in _placed_items:
		if not _piece_active.get(piece_id, true):
			continue
		var def: PlaceableDefinition = _placed_items[piece_id].data as PlaceableDefinition
		if not def is BuildingDefinition:
			continue
		var bdef: BuildingDefinition = def as BuildingDefinition
		if bdef.power_draw > 0 and (_power_state == null or not _power_state.is_powered(piece_id)):
			continue
		matter_prod += bdef.matter_production
	return matter_prod

## Returns true if any active placed building with matter_production > 0 is powered.
func _food_is_powered() -> bool:
	if _power_state == null:
		return false
	for piece_id: int in _placed_items:
		if not _piece_active.get(piece_id, true):
			continue
		var def: PlaceableDefinition = _placed_items[piece_id].data as PlaceableDefinition
		if not def is BuildingDefinition:
			continue
		var bdef: BuildingDefinition = def as BuildingDefinition
		if bdef.matter_production > 0 and _power_state.is_powered(piece_id):
			return true
	return false

## Computes the projected food and Nutrient Paste state for the upcoming season end.
## Dead settlers are skipped; construction cost is deducted before paste is produced.
## Keys: matter_prod, construction_cost, food_items, paste_needed, paste_produced,
##       projected_health (Array[int] parallel to settler_names), deaths.
## Pass construction_cost_override >= 0 to use a pre-computed cost (used in simulation
## after the UNBUILT→BUILT transition has already run).
func _compute_food_state(construction_cost_override: int = -1) -> Dictionary:
	var matter_prod: int       = _compute_matter_production()
	var construction_cost: int = construction_cost_override if construction_cost_override >= 0 \
		else _compute_construction_cost()
	var food_items: int        = 0  # placeholder until food items are introduced
	var living: int            = GameState.settler_count  # non-DEAD
	var paste_needed: int      = maxi(0, living - food_items)
	var paste_produced: int    = 0
	if paste_needed > 0 and _food_is_powered():
		var matter_avail: int = maxi(0, GameState.matter + matter_prod - construction_cost)
		paste_produced = mini(paste_needed, matter_avail)
	# Allocate food to living settlers in list order; project each settler's outcome.
	var food_remaining: int = food_items + paste_produced
	var projected_health: Array[int] = []
	var deaths: int = 0
	for i: int in GameState.settler_names.size():
		var current: int = GameState.settler_health[i]
		if current == GameState.SettlerHealth.DEAD:
			projected_health.append(GameState.SettlerHealth.DEAD)
		elif food_remaining > 0:
			projected_health.append(GameState.SettlerHealth.FED)
			food_remaining -= 1
		else:
			projected_health.append(GameState.SettlerHealth.DEAD)
			deaths += 1
	return {
		"matter_prod":       matter_prod,
		"construction_cost": construction_cost,
		"food_items":        food_items,
		"paste_needed":      paste_needed,
		"paste_produced":    paste_produced,
		"projected_health":  projected_health,
		"deaths":            deaths,
	}

## Builds the entry list for the Energy HUD tooltip.
## Each entry: {name: String, delta: int} — positive = produced, negative = drawn.
func _build_energy_entries() -> Array:
	var entries: Array = []
	for piece_id: int in _placed_items:
		if not _piece_active.get(piece_id, true):
			continue
		var item: InventoryItem = _placed_items[piece_id]
		var def: PlaceableDefinition = item.data as PlaceableDefinition
		if not def is BuildingDefinition:
			continue
		var bdef: BuildingDefinition = def as BuildingDefinition
		if bdef.energy_production > 0:
			entries.append({"name": item.display_name, "delta": bdef.energy_production})
		if bdef.power_draw > 0 and _power_state != null and _power_state.is_powered(piece_id):
			entries.append({"name": item.display_name, "delta": -bdef.power_draw})
	return entries

## Builds the entry list for the Matter HUD tooltip.
## Each entry: {name: String, delta: int} — positive = produced, negative = consumed.
func _build_matter_entries(food: Dictionary) -> Array:
	var entries: Array = []
	for piece_id: int in _placed_items:
		if not _piece_active.get(piece_id, true):
			continue
		var item: InventoryItem = _placed_items[piece_id]
		var def: PlaceableDefinition = item.data as PlaceableDefinition
		if not def is BuildingDefinition:
			continue
		var bdef: BuildingDefinition = def as BuildingDefinition
		if bdef.matter_production > 0:
			if bdef.power_draw == 0 or (_power_state != null and _power_state.is_powered(piece_id)):
				entries.append({"name": item.display_name, "delta": bdef.matter_production})
	var construction: int = food["construction_cost"]
	if construction > 0:
		entries.append({"name": "Construction", "delta": -construction})
	var paste: int = food["paste_produced"]
	if paste > 0:
		entries.append({"name": "Nutrient Paste", "delta": -paste})
	return entries

func _refresh_overlays(placed: Dictionary) -> void:
	var power_sources: Array = []
	var effect_sources: Array = []
	for piece_id: int in placed:
		var entry: Dictionary = placed[piece_id]
		if not entry["active"]:
			continue
		var def: PlaceableDefinition = entry["def"] as PlaceableDefinition
		if def == null or def.shape == null:
			continue
		# Power range overlay — buildings only.
		if def is BuildingDefinition:
			var bdef: BuildingDefinition = def as BuildingDefinition
			if bdef.power_range > 0:
				var net_idx: int = _power_state.piece_network_idx.get(piece_id, -1)
				var sufficient: bool = net_idx != -1 \
					and (_power_state.networks[net_idx] as PowerSystem.Network).is_sufficient()
				power_sources.append({
					"row":        entry["row"],
					"col":        entry["col"],
					"range":      bdef.power_range,
					"sufficient": sufficient,
				})
		# Effect-range overlay — any piece with effect_range > 0.
		if def.shape.effect_range > 0:
			effect_sources.append({
				"row":   entry["row"],
				"col":   entry["col"],
				"range": def.shape.effect_range,
			})
	farm_grid.set_power_overlay(power_sources)
	farm_grid.set_effect_overlay(effect_sources)

func _build_placed_dict() -> Dictionary:
	var placed: Dictionary = {}
	for piece_id: int in _placed_items:
		var info: Dictionary = farm_grid.grid_data.get_piece_info(piece_id)
		if info.is_empty():
			continue
		# UNBUILT pieces are not yet constructed; exclude them from power entirely.
		var is_built: bool = _piece_build_state.get(piece_id, BuildState.BUILT) == BuildState.BUILT
		placed[piece_id] = {
			"row":    info["row"],
			"col":    info["col"],
			"def":    _placed_items[piece_id].data,
			"active": is_built and _piece_active.get(piece_id, true),
		}
	return placed

func _on_next_season_pressed() -> void:
	var food: Dictionary = _compute_food_state()
	if food["deaths"] > 0:
		_confirm_dialog.dialog_text = \
			"Not enough food for all settlers.\n%d settler(s) will starve.\n\nProceed anyway?" \
			% food["deaths"]
		_confirm_dialog.popup_centered()
	else:
		_begin_simulation()

## Lock in the grid and start the simulation phase.
func _begin_simulation() -> void:
	# Capture construction cost before UNBUILT→BUILT erases it.
	_sim_construction_cost = _compute_construction_cost()
	_phase = Phase.SIMULATION
	for piece_id: int in _placed_items:
		var def: PlaceableDefinition = _placed_items[piece_id].data as PlaceableDefinition
		# Transition UNBUILT → BUILT: stop flashing, then apply moveable lock.
		if _piece_build_state.get(piece_id, BuildState.BUILT) == BuildState.UNBUILT:
			_piece_build_state[piece_id] = BuildState.BUILT
			farm_grid.set_piece_flashing(piece_id, false)
			farm_grid.set_piece_toggleable(piece_id, def is BuildingDefinition)
		farm_grid.set_piece_moveable(piece_id, def.moveable if def else true)
	farm_grid.set_planning_active(false)
	hud_ui.set_simulation_active(true)
	_sim_overlay.visible = true
	_sim_timer.start(SIMULATION_PLACEHOLDER_DURATION)

## Called when the simulation timer fires. Compute season outcomes and return to planning.
func _end_simulation() -> void:
	# Use construction cost saved before UNBUILT→BUILT transition ran.
	var food: Dictionary    = _compute_food_state(_sim_construction_cost)
	var paste_produced: int = food["paste_produced"]
	# Apply matter: production first, then construction cost, then paste consumption.
	GameState.matter += food["matter_prod"]
	GameState.matter  = maxi(0, GameState.matter - food["construction_cost"])
	GameState.matter  = maxi(0, GameState.matter - paste_produced)
	# Apply settler health outcomes. Use .assign() so the typed Array[int] is updated
	# correctly from the plain Array retrieved from the food Dictionary.
	GameState.settler_health.assign(food["projected_health"])
	GameState.season += 1

	_phase = Phase.PLANNING
	_sim_overlay.visible = false
	farm_grid.set_planning_active(true)
	hud_ui.set_simulation_active(false)
	_recompute_power()
	if GameState.settler_count == 0:
		_on_colony_lost()

func _on_colony_lost() -> void:
	var dlg: AcceptDialog = AcceptDialog.new()
	dlg.title = "Colony Lost"
	dlg.dialog_text = "All settlers have perished.\nThe colony is lost."
	add_child(dlg)
	dlg.popup_centered()
