class_name SettlerManager
extends Node

## Manages one SettlerFoodGrid per settler and the settler assignment panel.
## Call setup() once from game.gd _ready(). Call open()/close() to show/hide the panel.

var _inventory:    Inventory
var _inventory_ui: InventoryUI
var _ui_layer:     CanvasLayer
var _hud_ui:       HudUI

## One SettlerFoodGrid per settler (parallel to GameState.settlers).
var _settler_grids: Array[SettlerFoodGrid] = []
## One dict per settler: kitchen piece_id -> InventoryItem for assigned meal.
var _settler_placed_items: Array[Dictionary] = []
## Currently held item (picked up from a settler food slot).
var _held_item: InventoryItem = null

var _panel_open: bool = false

## Emitted whenever a meal is assigned to or removed from a settler slot.
signal assignments_changed


func setup(inventory: Inventory, inventory_ui: InventoryUI,
		ui_layer: CanvasLayer, hud_ui: HudUI) -> void:
	_inventory    = inventory
	_inventory_ui = inventory_ui
	_ui_layer     = ui_layer
	_hud_ui       = hud_ui


# ---------------------------------------------------------------------------
# Public query API
# ---------------------------------------------------------------------------

func is_open() -> bool:
	return _panel_open

## Combined screen rect of the panel + all visible settler grids.
## Used by game.gd to detect outside-panel taps.
func open_screen_rect() -> Rect2:
	if not _panel_open:
		return Rect2()
	var r: Rect2 = _hud_ui.settler_tooltip_screen_rect()
	for g: SettlerFoodGrid in _settler_grids:
		if g.visible:
			r = r.merge(g.get_screen_rect())
	return r

## Returns true if settler at index has a meal assigned in their food slot.
func has_meal_assigned(settler_idx: int) -> bool:
	if settler_idx >= _settler_placed_items.size():
		return false
	return (_settler_placed_items[settler_idx] as Dictionary).size() > 0


## Number of living settlers who have a meal assigned in their food slot.
func assigned_meal_count() -> int:
	var count: int = 0
	for i: int in _settler_grids.size():
		if i < GameState.settlers.size() \
				and GameState.settlers[i].health == Settler.Health.DEAD:
			continue
		if has_meal_assigned(i):
			count += 1
	return count


# ---------------------------------------------------------------------------
# Public mutation API
# ---------------------------------------------------------------------------

func open() -> void:
	if _panel_open:
		return
	_panel_open = true
	_sync_grids()
	_hud_ui.show_settler_panel()
	_position_grids()

func close() -> void:
	if not _panel_open:
		return
	_panel_open = false
	_hud_ui.hide_settler_panel()
	for g: SettlerFoodGrid in _settler_grids:
		g.visible = false
		g.set_grid_active(false)
	EventBus.merge_grid_closed.emit()

func toggle() -> void:
	if _panel_open:
		close()
	else:
		open()

## Route an inventory item hold to the first available settler grid.
## Returns true if accepted. Only routes items that allow SETTLER_GRID.
func route_inventory_hold(item: InventoryItem) -> bool:
	var def: PlaceableDefinition = item.data as PlaceableDefinition
	if def == null or not (PlaceableDefinition.GridType.SETTLER_GRID in def.allowed_grids):
		return false
	for g: SettlerFoodGrid in _settler_grids:
		if g.grid_data.get_piece_count() > 0:
			continue
		if g.has_held_piece or g.has_pending_pickup:
			continue
		g.begin_pending_inventory_hold(item)
		return true
	return false

## Try to place item in the settler food slot that screen_pos lands on.
## Returns true if placed. Slot must be empty and item must allow SETTLER_GRID.
func try_place_item(item: InventoryItem, screen_pos: Vector2) -> bool:
	var def: PlaceableDefinition = item.data as PlaceableDefinition
	if def == null or not (PlaceableDefinition.GridType.SETTLER_GRID in def.allowed_grids):
		return false
	for i: int in _settler_grids.size():
		var g: SettlerFoodGrid = _settler_grids[i]
		if not g.visible:
			continue
		if not g.get_screen_rect().has_point(screen_pos):
			continue
		if g.grid_data.get_piece_count() > 0:
			return false  # slot occupied
		_held_item = item
		var pid: int = g.place_piece_at(def.shape, 1, 1, item.display_name)
		_held_item = null
		return pid != -1
	return false

## Remove all assigned meals and add them back to inventory.
## Returns the number of meals consumed (for simulation log).
func consume_assigned_meals() -> int:
	var count: int = 0
	for i: int in _settler_grids.size():
		var items: Dictionary      = _settler_placed_items[i] as Dictionary
		var g: SettlerFoodGrid     = _settler_grids[i]
		for pid: int in items.keys():
			g.remove_piece(pid)
			count += 1
		items.clear()
	return count


# ---------------------------------------------------------------------------
# Internal
# ---------------------------------------------------------------------------

func _sync_grids() -> void:
	var count: int = GameState.settlers.size()
	while _settler_grids.size() < count:
		_add_grid(_settler_grids.size())
	while _settler_grids.size() > count:
		_remove_last_grid()
	while _settler_placed_items.size() < _settler_grids.size():
		_settler_placed_items.append({})

func _add_grid(idx: int) -> void:
	var g: SettlerFoodGrid = SettlerFoodGrid.new()
	g.visible = false
	g.z_index = 101  # above _settler_tooltip z_index=100
	g.set_inventory_control(_inventory_ui)
	var i: int = idx  # capture for closures
	g.inventory_item_pickup_confirmed.connect(
		func(item: InventoryItem) -> void: _on_inventory_pickup(g, i, item))
	g.piece_placed_on_grid.connect(
		func(pid: int) -> void: _on_piece_placed(i, pid))
	g.piece_picked_up_from_grid.connect(
		func(pid: int, shape: PieceShape) -> void: _on_piece_picked_up(g, i, pid, shape))
	g.piece_released.connect(
		func(pos: Vector2) -> void: _on_piece_released(pos))
	g.piece_returned_to_grid.connect(
		func(pid: int) -> void: _on_piece_returned(i, pid))
	_ui_layer.add_child(g)
	_ui_layer.move_child(_inventory_ui, _ui_layer.get_child_count() - 1)
	_settler_grids.append(g)

func _remove_last_grid() -> void:
	var g: SettlerFoodGrid  = _settler_grids.pop_back()
	var items: Dictionary   = _settler_placed_items.pop_back() as Dictionary
	for item: Variant in items.values():
		_inventory.add(item as InventoryItem)
	_ui_layer.remove_child(g)
	g.queue_free()

func _position_grids() -> void:
	# Lock farm grid (and all other grids) the same way KitchenManager does.
	if not _settler_grids.is_empty():
		EventBus.merge_grid_opened.emit(_settler_grids[0])
	var rects: Array[Rect2] = _hud_ui.get_settler_slot_screen_rects()
	for i: int in mini(_settler_grids.size(), rects.size()):
		_settler_grids[i].position = rects[i].position
		_settler_grids[i].visible  = true
		_settler_grids[i].set_grid_active(true)

## Deactivate every visible settler grid except `dragging`. Prevents sibling
## grids from reacting to the raw cursor position while an item is being held.
func _deactivate_other_grids(dragging: SettlerFoodGrid) -> void:
	for g: SettlerFoodGrid in _settler_grids:
		if g != dragging and g.visible:
			g.set_grid_active(false)

## Re-activate every visible settler grid (called when a drag completes).
func _reactivate_all_grids() -> void:
	if not _panel_open:
		return
	for g: SettlerFoodGrid in _settler_grids:
		if g.visible:
			g.set_grid_active(true)


# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------

func _on_inventory_pickup(g: SettlerFoodGrid, _idx: int, item: InventoryItem) -> void:
	_held_item = item
	_inventory.remove(item)
	var def: PlaceableDefinition = item.data as PlaceableDefinition
	var can_place: bool = def != null \
		and PlaceableDefinition.GridType.SETTLER_GRID in def.allowed_grids
	g.set_held_can_place(can_place)
	_deactivate_other_grids(g)

func _on_piece_placed(idx: int, piece_id: int) -> void:
	var items: Dictionary = _settler_placed_items[idx] as Dictionary
	if _held_item:
		items[piece_id] = _held_item
	_held_item = null
	_reactivate_all_grids()
	assignments_changed.emit()

func _on_piece_picked_up(g: SettlerFoodGrid, idx: int, piece_id: int, _shape: PieceShape) -> void:
	var items: Dictionary = _settler_placed_items[idx] as Dictionary
	_held_item = items.get(piece_id, null) as InventoryItem
	items.erase(piece_id)
	if _held_item:
		g.set_held_hint(_held_item.display_name)
	# Allow cross-slot drag: emit piece_released instead of snapping back when
	# the piece fails to land on this grid. SettlerManager routes via try_place_item.
	g.set_held_discardable(true)
	_deactivate_other_grids(g)
	assignments_changed.emit()

func _on_piece_released(com_screen_pos: Vector2) -> void:
	var item: InventoryItem = _held_item
	_held_item = null
	if item == null:
		return
	# Try to land on a different settler slot before returning to inventory.
	if try_place_item(item, com_screen_pos):
		return  # _on_piece_placed will re-activate all grids
	_inventory.add(item)
	_reactivate_all_grids()
	assignments_changed.emit()

func _on_piece_returned(idx: int, piece_id: int) -> void:
	var items: Dictionary = _settler_placed_items[idx] as Dictionary
	if _held_item:
		items[piece_id] = _held_item
	_held_item = null
	_reactivate_all_grids()
	assignments_changed.emit()
