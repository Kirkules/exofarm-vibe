class_name KitchenManager
extends Node

## Manages all per-cafeteria KitchenGrid instances and their item state.
## Call setup() once from game.gd _ready(); call sync() after any grid placement change.

var _inventory:    Inventory
var _inventory_ui: InventoryUI
var _ui_layer:     CanvasLayer
var _grid_bottom:  float

## Maps cafeteria piece_id -> KitchenGrid.
var _kitchen_grids: Dictionary = {}
## Maps cafeteria piece_id -> {kitchen_piece_id -> InventoryItem}.
var _kitchen_placed_items: Dictionary = {}
## piece_id of the cafeteria whose kitchen grid is currently open (-1 = none).
var _active_cafeteria_id: int = -1
## Currently held item (picked up from a kitchen grid).
var _held_item: InventoryItem = null
## Known recipes propagated to every KitchenGrid.
var _known_recipes: Array[RecipeDefinition] = []

## Emitted when a held item is released and returns to inventory (not placed on a grid).
signal item_returned_to_inventory(item: InventoryItem, from_screen: Vector2)


func setup(inventory: Inventory, inventory_ui: InventoryUI,
		ui_layer: CanvasLayer, grid_bottom: float) -> void:
	_inventory    = inventory
	_inventory_ui = inventory_ui
	_ui_layer     = ui_layer
	_grid_bottom  = grid_bottom


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
	kg.set_grid_active(true)  # merge_grid_opened only deactivates others; must activate explicitly
	EventBus.merge_grid_opened.emit(kg)

## Close the currently open kitchen grid.
func close() -> void:
	if _active_cafeteria_id == -1:
		return
	var kg: KitchenGrid = _kitchen_grids.get(_active_cafeteria_id, null) as KitchenGrid
	if kg != null:
		kg.visible = false
	_active_cafeteria_id = -1
	EventBus.merge_grid_closed.emit()

## Route an inventory item hold to the active kitchen grid.
## Returns true if the hold was accepted (caller should not route to farm grid).
func route_inventory_hold(item: InventoryItem) -> bool:
	if _active_cafeteria_id == -1:
		return false
	var kg: KitchenGrid = _kitchen_grids.get(_active_cafeteria_id, null) as KitchenGrid
	if kg == null or kg.has_held_piece or kg.has_pending_pickup:
		return false
	kg.begin_pending_inventory_hold(item)
	return true

## Try to place item at the nearest empty active slot to screen_pos.
## Returns true if placed successfully.
func try_place_item(item: InventoryItem, screen_pos: Vector2) -> bool:
	if _active_cafeteria_id == -1:
		return false
	var kg: KitchenGrid = _kitchen_grids.get(_active_cafeteria_id, null) as KitchenGrid
	if kg == null:
		return false
	var def: PlaceableDefinition = item.data as PlaceableDefinition
	if def == null \
			or not (PlaceableDefinition.GridType.KITCHEN_GRID in def.allowed_grids) \
			or PlaceableDefinition.GridType.FARM_GRID in def.allowed_grids:
		return false
	if not kg.get_full_screen_rect().has_point(screen_pos):
		return false
	var best_cell: Vector2i = _find_nearest_empty_cell(kg, screen_pos)
	if best_cell == Vector2i(-1, -1):
		return false
	# Temporarily set _held_item so _on_piece_placed registers it in _kitchen_placed_items.
	_held_item = item
	var piece_id: int = kg.place_piece_at(def.shape, best_cell.x, best_cell.y, item.display_name)
	_held_item = null
	return piece_id != -1

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
## Used by _end_simulation to consume only the ingredients that were actually crafted.
func consume_specific_items(piece_ids: Array[int]) -> void:
	for cid: int in _kitchen_placed_items:
		var kg: KitchenGrid    = _kitchen_grids.get(cid, null) as KitchenGrid
		var items: Dictionary  = _kitchen_placed_items[cid] as Dictionary
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
	kg.set_inventory_control(_inventory_ui)
	_kitchen_placed_items[cafeteria_id] = {}
	var cid: int = cafeteria_id
	kg.inventory_item_pickup_confirmed.connect(
		func(item: InventoryItem) -> void: _on_inventory_item_pickup_confirmed(kg, item))
	kg.piece_placed_on_grid.connect(
		func(pid: int) -> void: _on_piece_placed(cid, pid))
	kg.piece_picked_up_from_grid.connect(
		func(pid: int, shape: PieceShape) -> void: _on_piece_picked_up(kg, cid, pid, shape))
	kg.piece_released.connect(
		func(pos: Vector2) -> void: _on_piece_released(pos))
	kg.piece_returned_to_grid.connect(
		func(pid: int) -> void: _on_piece_placed(cid, pid))
	kg.piece_ejected.connect(
		func(pid: int) -> void: _on_piece_ejected(cid, pid))
	_ui_layer.add_child(kg)
	_ui_layer.move_child(_inventory_ui, _ui_layer.get_child_count() - 1)
	_kitchen_grids[cafeteria_id] = kg
	kg.set_recipes(_known_recipes)
	kg.set_capacity(slots)

## Find the nearest active empty cell in a KitchenGrid to a screen position.
## Returns Vector2i(-1, -1) if no empty active cell exists.
func _find_nearest_empty_cell(kg: KitchenGrid, screen_pos: Vector2) -> Vector2i:
	var best: Vector2i = Vector2i(-1, -1)
	var best_dist: float = INF
	for row: int in range(1, KitchenGrid.KITCHEN_ROWS + 1):
		for col: int in range(1, KitchenGrid.KITCHEN_COLS + 1):
			var slot_idx: int = (row - 1) * KitchenGrid.KITCHEN_COLS + (col - 1)
			if slot_idx >= kg._capacity:
				continue
			if kg.grid_data.get_cell(row, col) != 0:
				continue
			var cell_center: Vector2 = kg.position + Vector2(
				(col - 0.5) * KitchenGrid.KITCHEN_CELL_SIZE,
				(row - 0.5) * KitchenGrid.KITCHEN_CELL_SIZE)
			var dist: float = (cell_center - screen_pos).length_squared()
			if dist < best_dist:
				best_dist = dist
				best = Vector2i(row, col)
	return best


# ---------------------------------------------------------------------------
# Kitchen grid signal handlers
# ---------------------------------------------------------------------------

func _on_inventory_item_pickup_confirmed(kg: KitchenGrid, item: InventoryItem) -> void:
	_held_item = item
	_inventory.remove(item)
	var def: PlaceableDefinition = item.data as PlaceableDefinition
	var can_place: bool = def == null or PlaceableDefinition.GridType.KITCHEN_GRID in def.allowed_grids
	kg.set_held_can_place(can_place)

func _on_piece_placed(cafeteria_id: int, piece_id: int) -> void:
	var items: Dictionary = _kitchen_placed_items.get(cafeteria_id, {}) as Dictionary
	if _held_item:
		items[piece_id] = _held_item
		var def: PlaceableDefinition = _held_item.data as PlaceableDefinition
		var kg: KitchenGrid = _kitchen_grids.get(cafeteria_id, null) as KitchenGrid
		if kg != null and def != null:
			kg.on_item_placed(piece_id, def)
	_held_item = null

func _on_piece_picked_up(kg: KitchenGrid, cafeteria_id: int, piece_id: int, _shape: PieceShape) -> void:
	var items: Dictionary = _kitchen_placed_items.get(cafeteria_id, {}) as Dictionary
	_held_item = items.get(piece_id, null) as InventoryItem
	items.erase(piece_id)
	if _held_item:
		kg.set_held_hint(_held_item.display_name)
	kg.on_item_removed(piece_id)

func _on_piece_released(com_screen_pos: Vector2) -> void:
	var item: InventoryItem = _held_item
	_held_item = null
	if item != null:
		_inventory.move_group_before(item, _inventory_ui.get_drop_ref_item())
		if not _inventory_ui.has_active_drop_target():
			item_returned_to_inventory.emit(item, com_screen_pos)

func _on_piece_ejected(cafeteria_id: int, piece_id: int) -> void:
	var kg: KitchenGrid    = _kitchen_grids.get(cafeteria_id, null) as KitchenGrid
	var items: Dictionary  = _kitchen_placed_items.get(cafeteria_id, {}) as Dictionary
	var item: InventoryItem = items.get(piece_id, null) as InventoryItem
	items.erase(piece_id)
	if item != null:
		_inventory.add(item)
	if kg != null:
		kg.on_item_removed(piece_id)
