class_name BuildingManager
extends Node

## Owns all farm grid interaction state: placed items, build states, power/neighbor state,
## held-piece tracking, and the build menu connection.
## Emits signals so game.gd can react without this class needing HUD or KitchenManager refs.

## Build state for each placed piece.
enum BuildState { UNBUILT, BUILT }

## Emitted after recompute_power(); game.gd uses this to update HUD and sync kitchen grids.
signal power_changed(placed: Dictionary)
## Emitted when a held piece is released off the farm grid without landing on it.
signal piece_released_off_farm(item: InventoryItem, build_state: BuildState, com_screen_pos: Vector2)
## Emitted when a long-press is detected on a placed Cafeteria.
signal cafeteria_long_pressed(piece_id: int)
## Emitted after a farm grid piece is picked up (so game.gd can close the kitchen grid).
signal piece_picked_up_from_farm()

var _farm_grid: FarmGrid
var _inventory:  Inventory

## Maps piece_id -> InventoryItem for pieces currently on the farm grid.
var _placed_items:      Dictionary = {}
## Maps piece_id -> BuildState.
var _piece_build_state: Dictionary = {}
## Maps piece_id -> bool: false = toggled off by the player.
var _piece_active:      Dictionary = {}

var _power_state:    PowerSystem.PowerState       = null
var _neighbor_state: NeighborSystem.NeighborState = null

## Item currently being dragged (set on pickup/build-menu hold; cleared on place/release).
var _held_item:        InventoryItem = null
var _held_build_state: BuildState    = BuildState.BUILT
## The pending item created for a build-menu selection (not from _inventory).
var _pending_menu_item: InventoryItem = null

## piece_id of the Solar Rig; needed by SimulationController for settler dispatch.
var _solar_rig_piece_id: int = -1


func setup(farm_grid: FarmGrid, inventory: Inventory) -> void:
	_farm_grid = farm_grid
	_inventory  = inventory
	farm_grid.inventory_item_pickup_confirmed.connect(_on_inventory_item_pickup_confirmed)
	farm_grid.piece_picked_up_from_grid.connect(_on_piece_picked_up_from_grid)
	farm_grid.piece_placed_on_grid.connect(_on_piece_placed_on_grid)
	farm_grid.piece_released.connect(_on_piece_released)
	farm_grid.piece_returned_to_grid.connect(_on_piece_returned_to_grid)
	farm_grid.piece_double_tapped.connect(toggle_piece)
	farm_grid.piece_long_pressed.connect(_on_piece_long_pressed)


# ---------------------------------------------------------------------------
# Public query API
# ---------------------------------------------------------------------------

func solar_rig_piece_id() -> int:
	return _solar_rig_piece_id

## Read-only reference to the placed items dict (piece_id -> InventoryItem).
func placed_items() -> Dictionary:
	return _placed_items

## Read-only reference to the build states dict (piece_id -> BuildState).
func build_states() -> Dictionary:
	return _piece_build_state

## Most recently computed power state; null until first placement.
func power_state() -> PowerSystem.PowerState:
	return _power_state

func compute_construction_cost() -> int:
	var cost: int = 0
	for piece_id: int in _placed_items:
		if _piece_build_state.get(piece_id, BuildState.BUILT) != BuildState.UNBUILT:
			continue
		var def: PlaceableDefinition = _placed_items[piece_id].data as PlaceableDefinition
		if def != null:
			cost += def.matter_cost
	return cost

func compute_matter_production() -> int:
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
func food_is_powered() -> bool:
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

## Returns true if any active BUILT Cafeteria on the grid is powered.
func cafeteria_is_powered() -> bool:
	if _power_state == null:
		return false
	for piece_id: int in _placed_items:
		if not _piece_active.get(piece_id, true):
			continue
		if _piece_build_state.get(piece_id, BuildState.BUILT) != BuildState.BUILT:
			continue
		if not _placed_items[piece_id].data is CafeteriaDefinition:
			continue
		if _power_state.is_powered(piece_id):
			return true
	return false

## Builds the entry list for the Energy HUD tooltip.
func build_energy_entries() -> Array:
	var entries: Array = []
	for piece_id: int in _placed_items:
		if not _piece_active.get(piece_id, true):
			continue
		var item: InventoryItem      = _placed_items[piece_id]
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
## food: result dict from game.gd's _compute_food_state().
func build_matter_entries(food: Dictionary) -> Array:
	var entries: Array = []
	for piece_id: int in _placed_items:
		if not _piece_active.get(piece_id, true):
			continue
		var item: InventoryItem      = _placed_items[piece_id]
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


# ---------------------------------------------------------------------------
# Public mutation API
# ---------------------------------------------------------------------------

## Recompute power and neighbor state, update GameState energy, emit power_changed.
func recompute_power() -> void:
	var placed: Dictionary = _build_placed_dict()
	_power_state    = PowerSystem.compute(placed)
	_neighbor_state = NeighborSystem.compute(placed)
	GameState.energy_capacity = _power_state.total_pool()
	GameState.energy          = GameState.energy_capacity - _power_state.total_draw()
	_refresh_overlays(placed)
	power_changed.emit(placed)

## Toggle a placed building on/off and recompute power.
func toggle_piece(piece_id: int) -> void:
	var now_active: bool = not _piece_active.get(piece_id, true)
	_piece_active[piece_id] = now_active
	_farm_grid.set_piece_active_visual(piece_id, now_active)
	recompute_power()

## Begin a farm-grid hold for an item coming from the build menu.
func begin_build_menu_hold(def: PlaceableDefinition) -> void:
	if _farm_grid.has_held_piece or _farm_grid.has_pending_pickup:
		return
	_pending_menu_item = InventoryItem.new(def.display_name, 1, def)
	_farm_grid.begin_pending_inventory_hold(_pending_menu_item)

## Begin a farm-grid hold for an item coming from inventory.
func begin_inventory_hold(item: InventoryItem) -> void:
	if _farm_grid.has_held_piece or _farm_grid.has_pending_pickup:
		return
	_farm_grid.begin_pending_inventory_hold(item)

## Place a building directly on the grid as BUILT (used for starting buildings).
## Returns the assigned piece_id.
func place_at_built(shape: PieceShape, row: int, col: int, item: InventoryItem) -> int:
	_held_item = item
	var piece_id: int = _farm_grid.place_piece_at(shape, row, col, item.display_name)
	_held_item = null
	return piece_id

## Set the Solar Rig piece_id (called by game.gd after place_at_built for the solar rig).
func set_solar_rig_piece_id(piece_id: int) -> void:
	_solar_rig_piece_id = piece_id

## Transition all UNBUILT pieces to BUILT. Returns log entries for each built building.
## Called by game.gd at simulation start (before power recompute).
func transition_unbuilt_to_built() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for piece_id: int in _placed_items:
		if _piece_build_state.get(piece_id, BuildState.BUILT) != BuildState.UNBUILT:
			continue
		var def: PlaceableDefinition = _placed_items[piece_id].data as PlaceableDefinition
		if def != null and def.matter_cost > 0:
			entries.append({
				"label":       "Constructed %s:" % def.display_name,
				"value":       "-%d Matter" % def.matter_cost,
				"label_color": "",
				"value_color": "#ee8800",
			})
		_piece_build_state[piece_id] = BuildState.BUILT
		_farm_grid.set_piece_flashing(piece_id, false)
		_farm_grid.set_piece_toggleable(piece_id, def is BuildingDefinition)
	# Lock all pieces against movement for the simulation phase.
	for piece_id: int in _placed_items:
		var def: PlaceableDefinition = _placed_items[piece_id].data as PlaceableDefinition
		_farm_grid.set_piece_moveable(piece_id, false if def is BuildingDefinition else (def.moveable if def else true))
	return entries


# ---------------------------------------------------------------------------
# Internal
# ---------------------------------------------------------------------------

func _build_placed_dict() -> Dictionary:
	var placed: Dictionary = {}
	for piece_id: int in _placed_items:
		var info: Dictionary = _farm_grid.grid_data.get_piece_info(piece_id)
		if info.is_empty():
			continue
		var is_built: bool = _piece_build_state.get(piece_id, BuildState.BUILT) == BuildState.BUILT
		var shape: PieceShape = info["shape"] as PieceShape
		var cells: Array[Vector2i] = []
		for offset: Vector2i in shape.offsets:
			cells.append(Vector2i(info["row"] + offset.x, info["col"] + offset.y))
		placed[piece_id] = {
			"row":    info["row"],
			"col":    info["col"],
			"cells":  cells,
			"def":    _placed_items[piece_id].data,
			"active": is_built and _piece_active.get(piece_id, true),
		}
	return placed

func _refresh_overlays(placed: Dictionary) -> void:
	var power_sources: Array  = []
	var effect_sources: Array = []
	for piece_id: int in placed:
		var entry: Dictionary    = placed[piece_id]
		if not entry["active"]:
			continue
		var def: PlaceableDefinition = entry["def"] as PlaceableDefinition
		if def == null or def.shape == null:
			continue
		if def is BuildingDefinition:
			var bdef: BuildingDefinition = def as BuildingDefinition
			if bdef.power_range > 0:
				var net_idx: int    = _power_state.piece_network_idx.get(piece_id, -1)
				var sufficient: bool = net_idx != -1 \
					and (_power_state.networks[net_idx] as PowerSystem.Network).is_sufficient()
				power_sources.append({
					"row":        entry["row"],
					"col":        entry["col"],
					"range":      bdef.power_range,
					"sufficient": sufficient,
				})
		if def.shape.effect_range > 0:
			effect_sources.append({
				"row":   entry["row"],
				"col":   entry["col"],
				"range": def.shape.effect_range,
			})
	_farm_grid.set_power_overlay(power_sources)
	_farm_grid.set_effect_overlay(effect_sources)


# ---------------------------------------------------------------------------
# Farm grid signal handlers
# ---------------------------------------------------------------------------

func _on_inventory_item_pickup_confirmed(item: InventoryItem) -> void:
	_held_item = item
	_inventory.remove(item)
	_held_build_state  = BuildState.UNBUILT if item == _pending_menu_item else BuildState.BUILT
	_pending_menu_item = null
	var def: PlaceableDefinition = item.data as PlaceableDefinition
	var can_place: bool = def == null or PlaceableDefinition.GridType.FARM_GRID in def.allowed_grids
	_farm_grid.set_held_can_place(can_place)
	var pr: int = (def as BuildingDefinition).power_range if def is BuildingDefinition else 0
	_farm_grid.set_held_power_range(pr)

func _on_piece_picked_up_from_grid(piece_id: int, _shape: PieceShape) -> void:
	_held_item        = _placed_items.get(piece_id, null)
	_held_build_state = _piece_build_state.get(piece_id, BuildState.BUILT)
	_placed_items.erase(piece_id)
	_piece_build_state.erase(piece_id)
	_piece_active.erase(piece_id)
	if _held_item:
		_farm_grid.set_held_hint(_held_item.display_name)
		var def: PlaceableDefinition = _held_item.data as PlaceableDefinition
		var pr: int = (def as BuildingDefinition).power_range if def is BuildingDefinition else 0
		_farm_grid.set_held_power_range(pr)
	_farm_grid.set_held_discardable(_held_build_state == BuildState.UNBUILT)
	recompute_power()
	piece_picked_up_from_farm.emit()

func _on_piece_placed_on_grid(piece_id: int) -> void:
	if _held_item:
		_placed_items[piece_id] = _held_item
	_held_item = null
	var def: PlaceableDefinition = (_placed_items[piece_id].data \
		if _placed_items.has(piece_id) else null) as PlaceableDefinition
	# Reject items that don't belong on the farm grid.
	if def != null and not (PlaceableDefinition.GridType.FARM_GRID in def.allowed_grids):
		_farm_grid.remove_piece(piece_id)
		_inventory.add(_placed_items[piece_id])
		_placed_items.erase(piece_id)
		_piece_build_state.erase(piece_id)
		_farm_grid.set_held_power_range(0)
		return
	_piece_build_state[piece_id] = _held_build_state
	var is_unbuilt: bool = _held_build_state == BuildState.UNBUILT
	_held_build_state = BuildState.BUILT
	_farm_grid.set_piece_moveable(piece_id, is_unbuilt if def is BuildingDefinition else (def != null and def.moveable))
	_farm_grid.set_piece_toggleable(piece_id, def is BuildingDefinition and not is_unbuilt)
	_farm_grid.set_piece_flashing(piece_id, is_unbuilt)
	_farm_grid.set_held_power_range(0)
	recompute_power()

func _on_piece_released(com_screen_pos: Vector2) -> void:
	var item: InventoryItem     = _held_item
	var build_state: BuildState = _held_build_state
	_held_item        = null
	_held_build_state = BuildState.BUILT
	_farm_grid.set_held_power_range(0)
	if item == null:
		return
	piece_released_off_farm.emit(item, build_state, com_screen_pos)

func _on_piece_returned_to_grid(piece_id: int) -> void:
	if _held_item:
		_placed_items[piece_id] = _held_item
	_held_item = null
	var def: PlaceableDefinition = (_placed_items[piece_id].data \
		if _placed_items.has(piece_id) else null) as PlaceableDefinition
	_piece_build_state[piece_id] = _held_build_state
	var is_unbuilt: bool = _held_build_state == BuildState.UNBUILT
	_held_build_state = BuildState.BUILT
	_farm_grid.set_piece_moveable(piece_id, is_unbuilt if def is BuildingDefinition else (def != null and def.moveable))
	_farm_grid.set_piece_toggleable(piece_id, def is BuildingDefinition and not is_unbuilt)
	_farm_grid.set_piece_flashing(piece_id, is_unbuilt)
	_farm_grid.set_held_power_range(0)
	recompute_power()

func _on_piece_long_pressed(piece_id: int) -> void:
	var item: InventoryItem = _placed_items.get(piece_id, null)
	if item == null or not item.data is CafeteriaDefinition:
		return
	cafeteria_long_pressed.emit(piece_id)
