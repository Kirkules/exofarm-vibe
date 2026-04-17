class_name KitchenManager
extends Node

## Manages all per-cafeteria KitchenGrid instances and their item state.
## Call setup() once from game.gd _ready(); call sync() after any grid placement change.

var _inventory:    Inventory
var _inventory_ui: InventoryUI
var _ui_layer:     CanvasLayer
var _grid_bottom:  float
var _farm_grid:    GameGrid
var _pic:          PieceInputController

## Maps cafeteria piece_id -> KitchenGrid.
var _kitchen_grids: Dictionary = {}
## Maps cafeteria piece_id -> {kitchen_piece_id -> InventoryItem}.
var _kitchen_placed_items: Dictionary = {}
## piece_id of the cafeteria whose kitchen grid is currently open (-1 = none).
var _active_cafeteria_id: int = -1
## Known recipes propagated to every KitchenGrid.
var _known_recipes: Array[RecipeDefinition] = []

## Two-flag drag tracking for inventory-origin drags.
## _pending: set before begin_inventory_drag, cleared in pickup_confirmed.
## _active:  set in pickup_confirmed, cleared when drag ends.
var _pending_inventory_drag: bool = false
var _active_inventory_drag:  bool = false

## Emitted when a held item is released and returns to inventory (not placed on a grid).
signal item_returned_to_inventory(item: InventoryItem, from_screen: Vector2)


func setup(inventory: Inventory, inventory_ui: InventoryUI,
		ui_layer: CanvasLayer, grid_bottom: float, farm_grid: GameGrid,
		pic: PieceInputController) -> void:
	_inventory    = inventory
	_inventory_ui = inventory_ui
	_ui_layer     = ui_layer
	_grid_bottom  = grid_bottom
	_farm_grid    = farm_grid
	_pic          = pic
	_pic.pickup_confirmed.connect(_on_pickup_confirmed)
	_pic.piece_placed.connect(_on_piece_placed)
	_pic.piece_returned.connect(_on_piece_returned)
	_pic.piece_released.connect(_on_piece_released)


# ---------------------------------------------------------------------------
# Public query API
# ---------------------------------------------------------------------------

func is_open() -> bool:
	return _active_cafeteria_id != -1

func active_cafeteria_id() -> int:
	return _active_cafeteria_id

## Returns the full screen rect (including header) of the active kitchen grid.
## Returns Rect2() if no kitchen grid is open.
func open_screen_rect() -> Rect2:
	if _active_cafeteria_id == -1:
		return Rect2()
	var kg: KitchenGrid = _kitchen_grids.get(_active_cafeteria_id, null) as KitchenGrid
	return kg.get_full_screen_rect() if kg != null else Rect2()

## Propagate known recipes to all existing and future KitchenGrids.
func set_recipes(recipes: Array[RecipeDefinition]) -> void:
	_known_recipes = recipes
	for cid: int in _kitchen_grids:
		(_kitchen_grids[cid] as KitchenGrid).set_recipes(recipes)

## Returns the KitchenGrid for a given cafeteria piece_id, or null if none.
func kitchen_grid_for(cafeteria_id: int) -> KitchenGrid:
	return _kitchen_grids.get(cafeteria_id, null) as KitchenGrid

## Total number of items currently stored across all kitchen grids.
func food_item_count() -> int:
	var count: int = 0
	for cid: int in _kitchen_placed_items:
		count += (_kitchen_placed_items[cid] as Dictionary).size()
	return count


# ---------------------------------------------------------------------------
# Public mutation API
# ---------------------------------------------------------------------------

## Sync kitchen grids to match placed BUILT cafeterias.
## placed_items: piece_id -> InventoryItem; build_states: piece_id -> BuildingManager.BuildState.
func sync(placed_items: Dictionary, build_states: Dictionary) -> void:
	var built_cafeterias: Dictionary = {}  # piece_id -> slot count
	for piece_id: int in placed_items:
		if build_states.get(piece_id, BuildingManager.BuildState.BUILT) != BuildingManager.BuildState.BUILT:
			continue
		var def: PlaceableDefinition = placed_items[piece_id].data as PlaceableDefinition
		if def is CafeteriaDefinition:
			built_cafeterias[piece_id] = (def as CafeteriaDefinition).merge_slots
	# Tear down grids whose cafeteria is no longer present.
	for cid: int in _kitchen_grids.keys():
		if not built_cafeterias.has(cid):
			teardown(cid)
	# Create grids for new cafeterias; update capacity for existing ones.
	for cid: int in built_cafeterias:
		if _kitchen_grids.has(cid):
			(_kitchen_grids[cid] as KitchenGrid).set_capacity(built_cafeterias[cid])
		else:
			_create_grid_for(cid, built_cafeterias[cid])

## Open the kitchen grid for a specific cafeteria piece_id.
func open(cafeteria_piece_id: int) -> void:
	var kg: KitchenGrid = _kitchen_grids.get(cafeteria_piece_id, null) as KitchenGrid
	if kg == null:
		return
	_active_cafeteria_id = cafeteria_piece_id
	kg.visible = true
	kg.set_grid_active(true)
	if _farm_grid != null:
		_farm_grid.set_grid_active(false)
		_pic.unregister_pickup_source(_farm_grid)
	_pic.register_pickup_source(kg)
	_pic.register_drop_target(kg, 1)

## Close the currently open kitchen grid.
func close() -> void:
	if _active_cafeteria_id == -1:
		return
	_pic.cancel_drag()  # handles any in-flight drag; piece_released/_on_piece_released cleans up
	var kg: KitchenGrid = _kitchen_grids.get(_active_cafeteria_id, null) as KitchenGrid
	if kg != null:
		kg.visible = false
		kg.set_grid_active(false)
		_pic.unregister_pickup_source(kg)
		_pic.unregister_drop_target(kg)
	_active_cafeteria_id    = -1
	_pending_inventory_drag = false
	_active_inventory_drag  = false
	if _farm_grid != null:
		_farm_grid.set_grid_active(true)
		_pic.register_pickup_source(_farm_grid)

## Route an inventory item hold to the active kitchen grid.
## Returns true if the hold was accepted (caller should not route elsewhere).
func route_inventory_hold(item: InventoryItem) -> bool:
	if _active_cafeteria_id == -1:
		return false
	var def: PlaceableDefinition = item.data as PlaceableDefinition
	if def == null or not (PlaceableDefinition.GridType.KITCHEN_GRID in def.allowed_grids):
		return false
	if PlaceableDefinition.GridType.FARM_GRID in def.allowed_grids:
		return false  # farm-grid items do not route to the kitchen
	_pending_inventory_drag = true
	_pic.begin_inventory_drag(def.shape, item, item.display_name)
	return true

## Remove all items from all kitchen grids (called at simulation end when cafeteria powered).
func consume_all_items() -> void:
	for cid: int in _kitchen_placed_items:
		var kg: KitchenGrid = _kitchen_grids.get(cid, null) as KitchenGrid
		for pid: int in (_kitchen_placed_items[cid] as Dictionary).keys():
			if kg != null:
				kg.remove_piece(pid)
				kg.on_item_removed(pid)
		(_kitchen_placed_items[cid] as Dictionary).clear()

## Remove only the specified piece_ids from whichever kitchen grids own them.
## Items not found in any grid are silently ignored.
func consume_specific_items(piece_ids: Array[int]) -> void:
	for cid: int in _kitchen_placed_items:
		var kg: KitchenGrid   = _kitchen_grids.get(cid, null) as KitchenGrid
		var items: Dictionary = _kitchen_placed_items[cid] as Dictionary
		for pid: int in piece_ids:
			if not items.has(pid):
				continue
			items.erase(pid)
			if kg != null:
				kg.remove_piece(pid)
				kg.on_item_removed(pid)

## Eject all items from the given cafeteria's grid to inventory, then remove and free it.
func teardown(cafeteria_id: int) -> void:
	if _active_cafeteria_id == cafeteria_id:
		close()
	var items: Dictionary = _kitchen_placed_items.get(cafeteria_id, {}) as Dictionary
	for item: Variant in items.values():
		_inventory.add(item as InventoryItem)
	_kitchen_placed_items.erase(cafeteria_id)
	var kg: KitchenGrid = _kitchen_grids.get(cafeteria_id, null) as KitchenGrid
	if kg != null:
		_ui_layer.remove_child(kg)
		kg.queue_free()
	_kitchen_grids.erase(cafeteria_id)


# ---------------------------------------------------------------------------
# Internal
# ---------------------------------------------------------------------------

func _create_grid_for(cafeteria_id: int, slots: int) -> void:
	var kg: KitchenGrid = KitchenGrid.new()
	var kg_w: float = KitchenGrid.KITCHEN_COLS * KitchenGrid.KITCHEN_CELL_SIZE
	kg.position = Vector2(
		(270.0 - kg_w) / 2.0,
		_grid_bottom - KitchenGrid.KITCHEN_ROWS * KitchenGrid.KITCHEN_CELL_SIZE)
	kg.visible = false
	_kitchen_placed_items[cafeteria_id] = {}
	var cid: int = cafeteria_id
	kg.piece_ejected.connect(
		func(pid: int) -> void: _on_piece_ejected(cid, pid))
	kg.setup_pic(_pic)
	_ui_layer.add_child(kg)
	_ui_layer.move_child(_inventory_ui, _ui_layer.get_child_count() - 1)
	_kitchen_grids[cafeteria_id] = kg
	kg.set_recipes(_known_recipes)
	kg.set_capacity(slots)

## Returns the cafeteria_id for a given KitchenGrid, or -1 if not found.
func _cafeteria_id_for_grid(kg: KitchenGrid) -> int:
	if kg == null:
		return -1
	for cid: int in _kitchen_grids:
		if _kitchen_grids[cid] == kg:
			return cid
	return -1


# ---------------------------------------------------------------------------
# PIC signal handlers
# ---------------------------------------------------------------------------

func _on_pickup_confirmed(origin: Object, piece_id: int, _shape: PieceShape,
		payload: Variant) -> void:
	# Grid-origin pickup from one of our kitchen grids.
	var cid: int = _cafeteria_id_for_grid(origin as KitchenGrid)
	if cid != -1:
		var kg: KitchenGrid   = origin as KitchenGrid
		var items: Dictionary = _kitchen_placed_items.get(cid, {}) as Dictionary
		var item: InventoryItem = items.get(piece_id, null) as InventoryItem
		items.erase(piece_id)
		kg.on_item_removed(piece_id)
		_pic.set_held_payload(item)
		_pic.set_held_discardable(true)  # can be released to inventory
		if item != null:
			_pic.set_held_hint(item.display_name)
		return
	# Inventory-origin drag owned by this manager.
	if origin == null and _pending_inventory_drag:
		_inventory.remove(payload as InventoryItem)
		_pending_inventory_drag = false
		_active_inventory_drag  = true


func _on_piece_placed(origin: Object, target: Object, piece_id: int,
		payload: Variant) -> void:
	var cid: int = _cafeteria_id_for_grid(target as KitchenGrid)
	if cid == -1:
		return
	var item: InventoryItem = payload as InventoryItem
	var kg: KitchenGrid     = target as KitchenGrid
	var items: Dictionary   = _kitchen_placed_items.get(cid, {}) as Dictionary
	if item != null:
		items[piece_id] = item
		var def: PlaceableDefinition = item.data as PlaceableDefinition
		if def != null:
			kg.on_item_placed(piece_id, def)
	if _active_inventory_drag:
		_active_inventory_drag = false


func _on_piece_returned(origin: Object, piece_id: int, payload: Variant) -> void:
	var cid: int = _cafeteria_id_for_grid(origin as KitchenGrid)
	if cid == -1:
		return
	var item: InventoryItem = payload as InventoryItem
	var kg: KitchenGrid     = origin as KitchenGrid
	var items: Dictionary   = _kitchen_placed_items.get(cid, {}) as Dictionary
	if item != null:
		items[piece_id] = item
		var def: PlaceableDefinition = item.data as PlaceableDefinition
		if def != null:
			kg.on_item_placed(piece_id, def)


func _on_piece_released(origin: Object, payload: Variant, com: Vector2) -> void:
	var cid: int = _cafeteria_id_for_grid(origin as KitchenGrid)
	if cid == -1 and not _active_inventory_drag:
		return
	_active_inventory_drag = false
	var item: InventoryItem = payload as InventoryItem
	if item == null:
		return
	_inventory.move_group_before(item, _inventory_ui.get_drop_ref_item())
	if not _inventory_ui.has_active_drop_target():
		item_returned_to_inventory.emit(item, com)


# ---------------------------------------------------------------------------
# KitchenGrid signal handler
# ---------------------------------------------------------------------------

func _on_piece_ejected(cafeteria_id: int, piece_id: int) -> void:
	var kg: KitchenGrid     = _kitchen_grids.get(cafeteria_id, null) as KitchenGrid
	var items: Dictionary   = _kitchen_placed_items.get(cafeteria_id, {}) as Dictionary
	var item: InventoryItem = items.get(piece_id, null) as InventoryItem
	items.erase(piece_id)
	if item != null:
		_inventory.add(item)
	if kg != null:
		kg.on_item_removed(piece_id)
