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

enum Phase { PLANNING, SIMULATION }
var _phase: Phase = Phase.PLANNING

## Duration of the placeholder simulation animation (seconds).
const SIMULATION_PLACEHOLDER_DURATION := 2.0

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

	# Seed inventory with starting buildings and test pieces.
	for def: PlaceableDefinition in _starting_placeables():
		_inventory.add(InventoryItem.new(def.display_name, def.slot_size, def))

func _starting_placeables() -> Array[PlaceableDefinition]:
	var result: Array[PlaceableDefinition] = []

	# Solar Rig — produces energy each season.
	var solar_shape: PieceShape = PieceShape.new()
	solar_shape.color = Color(0.95, 0.80, 0.20)
	solar_shape.label = "SOL"
	var solar_rig: BuildingDefinition = BuildingDefinition.new()
	solar_rig.display_name = "Solar Rig"
	solar_rig.shape = solar_shape
	solar_rig.moveable = false
	solar_rig.energy_production = 10
	solar_rig.power_range = 3
	result.append(solar_rig)

	# Matter Manipulator — produces matter each season.
	var matter_shape: PieceShape = PieceShape.new()
	matter_shape.color = Color(0.45, 0.75, 0.55)
	matter_shape.label = "MAT"
	var matter_manip: BuildingDefinition = BuildingDefinition.new()
	matter_manip.display_name = "Matter Manipulator"
	matter_manip.shape = matter_shape
	matter_manip.moveable = false
	matter_manip.matter_production = 5
	matter_manip.power_draw = 2
	result.append(matter_manip)

	# Placeholder test pieces (to be replaced by proper definitions in later phases).
	var l_shape: PieceShape = PieceShape.new()
	l_shape.offsets = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1)]
	l_shape.color = Color(0.40, 0.60, 0.90)
	l_shape.effect_range = 2
	var l_piece: PlaceableDefinition = PlaceableDefinition.new()
	l_piece.display_name = "L-Piece"
	l_piece.shape = l_shape.with_centered_origin()
	result.append(l_piece)

	var crop_shape: PieceShape = PieceShape.new()
	crop_shape.color = Color(0.55, 0.88, 0.38)
	crop_shape.effect_range = 1
	var crop_plot: PlaceableDefinition = PlaceableDefinition.new()
	crop_plot.display_name = "Crop Plot"
	crop_plot.shape = crop_shape
	result.append(crop_plot)
	result.append(crop_plot)  # two copies

	return result

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
	var def: PlaceableDefinition = item.data as PlaceableDefinition
	var pr: int = (def as BuildingDefinition).power_range if def is BuildingDefinition else 0
	farm_grid.set_held_power_range(pr)

func _on_piece_picked_up_from_grid(piece_id: int, _shape: PieceShape) -> void:
	_held_item = _placed_items.get(piece_id, null)
	_placed_items.erase(piece_id)
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
	farm_grid.set_piece_moveable(piece_id, true)
	farm_grid.set_piece_toggleable(piece_id, def is BuildingDefinition)
	farm_grid.set_held_power_range(0)
	_recompute_power()

func _on_piece_hold_cancelled(_shape: PieceShape) -> void:
	if _held_item:
		_inventory.add(_held_item)
		_held_item = null
	farm_grid.set_held_power_range(0)

func _on_piece_returned_to_grid(piece_id: int) -> void:
	if _held_item:
		_placed_items[piece_id] = _held_item
	_held_item = null
	var def: PlaceableDefinition = (_placed_items[piece_id].data if _placed_items.has(piece_id) else null) as PlaceableDefinition
	farm_grid.set_piece_moveable(piece_id, true)
	farm_grid.set_piece_toggleable(piece_id, def is BuildingDefinition)
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
	var paste_produced: int = food["paste_produced"]
	var matter_prod: int    = food["matter_prod"]
	hud_ui.set_settler_fed_count(food["fed_count"])
	hud_ui.refresh_matter(GameState.matter + matter_prod - paste_produced, matter_prod - paste_produced)
	hud_ui.refresh()
	_refresh_overlays(placed)

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
## Keys: matter_prod, food_items, paste_needed, paste_produced, fed_count, deaths.
## fed_count settlers (first in settler_names order) will survive; the rest starve.
## Paste is only made if needed and if a powered food-producing building exists.
## Available Matter for paste is calculated after other Matter usages (currently none).
func _compute_food_state() -> Dictionary:
	var matter_prod: int  = _compute_matter_production()
	var food_items: int   = 0  # placeholder until food items are introduced
	var paste_needed: int = maxi(0, GameState.settler_count - food_items)
	var paste_produced: int = 0
	if paste_needed > 0 and _food_is_powered():
		var matter_avail: int = GameState.matter + matter_prod  # after other usages (none yet)
		paste_produced = mini(paste_needed, maxi(0, matter_avail))
	var fed_count: int = mini(GameState.settler_count, food_items + paste_produced)
	return {
		"matter_prod":    matter_prod,
		"food_items":     food_items,
		"paste_needed":   paste_needed,
		"paste_produced": paste_produced,
		"fed_count":      fed_count,
		"deaths":         GameState.settler_count - fed_count,
	}

func _refresh_overlays(placed: Dictionary) -> void:
	var sources: Array = []
	for piece_id: int in placed:
		var entry: Dictionary = placed[piece_id]
		if not entry["active"]:
			continue
		if not entry["def"] is BuildingDefinition:
			continue
		var bdef: BuildingDefinition = entry["def"] as BuildingDefinition
		if bdef.power_range <= 0:
			continue
		var net_idx: int = _power_state.piece_network_idx.get(piece_id, -1)
		var sufficient: bool = net_idx != -1 \
			and (_power_state.networks[net_idx] as PowerSystem.Network).is_sufficient()
		sources.append({
			"row":       entry["row"],
			"col":       entry["col"],
			"range":     bdef.power_range,
			"sufficient": sufficient,
		})
	farm_grid.set_power_overlay(sources)

func _build_placed_dict() -> Dictionary:
	var placed: Dictionary = {}
	for piece_id: int in _placed_items:
		var info: Dictionary = farm_grid.grid_data.get_piece_info(piece_id)
		if info.is_empty():
			continue
		placed[piece_id] = {
			"row":    info["row"],
			"col":    info["col"],
			"def":    _placed_items[piece_id].data,
			"active": _piece_active.get(piece_id, true),
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
	_phase = Phase.SIMULATION
	# Lock buildings in place; other pieces remain moveable for next planning phase.
	for piece_id: int in _placed_items:
		var def: PlaceableDefinition = _placed_items[piece_id].data as PlaceableDefinition
		farm_grid.set_piece_moveable(piece_id, def.moveable if def else true)
	farm_grid.set_planning_active(false)
	hud_ui.set_simulation_active(true)
	_sim_overlay.visible = true
	_sim_timer.start(SIMULATION_PLACEHOLDER_DURATION)

## Called when the simulation timer fires. Compute season outcomes and return to planning.
func _end_simulation() -> void:
	# Compute food state before applying changes (power state is still valid from planning).
	var food: Dictionary    = _compute_food_state()
	var deaths: int         = food["deaths"]
	var paste_produced: int = food["paste_produced"]
	# Apply matter: production first, then paste consumption.
	GameState.matter += food["matter_prod"]
	GameState.matter  = maxi(0, GameState.matter - paste_produced)
	# Apply deaths: starving settlers die (removed from the end of the list, matching UI order).
	GameState.settler_count = maxi(0, GameState.settler_count - deaths)
	for _i: int in range(deaths):
		if not GameState.settler_names.is_empty():
			GameState.settler_names.remove_at(GameState.settler_names.size() - 1)
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
