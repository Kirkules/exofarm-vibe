class_name SettlerManager
extends Node

## Manages one SettlerFoodGrid per settler and the settler assignment panel.
## Call setup() once from game.gd _ready(). Call open()/close() to show/hide the panel.

var _inventory:    Inventory
var _inventory_ui: InventoryUI
var _ui_layer:     CanvasLayer
var _hud_ui:       HudUI
var _farm_grid:    GameGrid
var _pic:          PieceInputController

## One SettlerFoodGrid per settler (parallel to GameState.settlers).
var _settler_grids: Array[SettlerFoodGrid] = []
## One dict per settler: piece_id -> InventoryItem for assigned meal.
var _settler_placed_items: Array[Dictionary] = []

var _panel_open: bool = false

## Two-flag drag tracking for inventory-origin drags.
## _pending: set before begin_inventory_drag, cleared in pickup_confirmed.
## _active:  set in pickup_confirmed, cleared when drag ends.
var _pending_inventory_drag: bool = false
var _active_inventory_drag:  bool = false

## Emitted whenever a meal is assigned to or removed from a settler slot.
signal assignments_changed
## Emitted when a held item is released and returns to inventory without an intentional drop target.
signal item_returned_to_inventory(item: InventoryItem, from_screen: Vector2)
## Emitted when a held item snaps back to its original settler food slot.
## to_screen is the center of the target slot in screen space.
signal item_snap_back_to_grid(item: InventoryItem, from_screen: Vector2, to_screen: Vector2)


func setup(inventory: Inventory, inventory_ui: InventoryUI,
		ui_layer: CanvasLayer, hud_ui: HudUI, farm_grid: GameGrid,
		pic: PieceInputController) -> void:
	_inventory    = inventory
	_inventory_ui = inventory_ui
	_ui_layer     = ui_layer
	_hud_ui       = hud_ui
	_farm_grid    = farm_grid
	_pic          = pic
	_pic.pickup_confirmed.connect(_on_pickup_confirmed)
	_pic.piece_placed.connect(_on_piece_placed)
	_pic.piece_released.connect(_on_piece_released)


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

## Returns the InventoryItem assigned to the settler's food slot, or null if empty.
func get_assigned_meal(settler_idx: int) -> InventoryItem:
	if settler_idx >= _settler_placed_items.size():
		return null
	var items: Dictionary = _settler_placed_items[settler_idx] as Dictionary
	if items.is_empty():
		return null
	return items.values()[0] as InventoryItem

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
	call_deferred("_position_grids")

## Re-position food grid overlays after the settler panel layout changes.
## Called deferred (by game.gd) so VBoxContainer layout settles first.
func reposition_grids() -> void:
	if _panel_open:
		_position_grids()

func close() -> void:
	if not _panel_open:
		return
	_pic.cancel_drag()  # handles any in-flight drag; piece_released cleans up state
	_panel_open = false
	_hud_ui.hide_settler_panel()
	for g: SettlerFoodGrid in _settler_grids:
		g.visible = false
		g.set_grid_active(false)
		_pic.unregister_pickup_source(g)
		_pic.unregister_drop_target(g)
	_pending_inventory_drag = false
	_active_inventory_drag  = false
	if _farm_grid != null:
		_farm_grid.set_grid_active(true)
		_pic.register_pickup_source(_farm_grid)

func toggle() -> void:
	if _panel_open:
		close()
	else:
		open()

## Route an inventory item hold to the settler panel.
## Returns true if accepted. Only routes items that allow SETTLER_GRID.
func route_inventory_hold(item: InventoryItem) -> bool:
	if not _panel_open:
		return false
	var def: PlaceableDefinition = item.data as PlaceableDefinition
	if def == null or not (PlaceableDefinition.GridType.SETTLER_GRID in def.allowed_grids):
		return false
	_pending_inventory_drag = true
	_pic.begin_inventory_drag(def.shape, item, item.display_name)
	return true

## Remove all assigned meals and add them back to inventory.
## Returns the number of meals consumed (for simulation log).
func consume_assigned_meals() -> int:
	var count: int = 0
	for i: int in _settler_grids.size():
		var items: Dictionary  = _settler_placed_items[i] as Dictionary
		var g: SettlerFoodGrid = _settler_grids[i]
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
	g.setup_pic(_pic)
	_ui_layer.add_child(g)
	_ui_layer.move_child(_inventory_ui, _ui_layer.get_child_count() - 1)
	_settler_grids.append(g)

func _remove_last_grid() -> void:
	var g: SettlerFoodGrid = _settler_grids.pop_back()
	var items: Dictionary  = _settler_placed_items.pop_back() as Dictionary
	for item: Variant in items.values():
		_inventory.add(item as InventoryItem)
	_pic.unregister_pickup_source(g)
	_pic.unregister_drop_target(g)
	_ui_layer.remove_child(g)
	g.queue_free()

func _position_grids() -> void:
	if _farm_grid != null:
		_farm_grid.set_grid_active(false)
		_pic.unregister_pickup_source(_farm_grid)
	var rects: Array[Rect2] = _hud_ui.get_settler_slot_screen_rects()
	for i: int in mini(_settler_grids.size(), rects.size()):
		_settler_grids[i].position = rects[i].position
		_settler_grids[i].visible  = true
		_settler_grids[i].set_grid_active(true)
		_pic.register_pickup_source(_settler_grids[i])
		_pic.register_drop_target(_settler_grids[i], 1)

## Returns the settler index for a given SettlerFoodGrid, or -1 if not found.
func _settler_idx_for_grid(g: SettlerFoodGrid) -> int:
	if g == null:
		return -1
	return _settler_grids.find(g)


# ---------------------------------------------------------------------------
# PIC signal handlers
# ---------------------------------------------------------------------------

func _on_pickup_confirmed(origin: Object, piece_id: int, _shape: PieceShape,
		payload: Variant) -> void:
	# Grid-origin pickup from one of our settler food grids.
	var idx: int = _settler_idx_for_grid(origin as SettlerFoodGrid)
	if idx != -1:
		var items: Dictionary   = _settler_placed_items[idx] as Dictionary
		var item: InventoryItem = items.get(piece_id, null) as InventoryItem
		items.erase(piece_id)
		_pic.set_held_payload(item)
		_pic.set_held_discardable(true)  # cross-slot drag: release if no target accepts
		if item != null:
			_pic.set_held_hint(item.display_name)
		assignments_changed.emit()
		return
	# Inventory-origin drag owned by this manager.
	if origin == null and _pending_inventory_drag:
		_inventory.remove(payload as InventoryItem)
		_pending_inventory_drag = false
		_active_inventory_drag  = true


func _on_piece_placed(origin: Object, target: Object, piece_id: int,
		payload: Variant) -> void:
	var idx: int = _settler_idx_for_grid(target as SettlerFoodGrid)
	if idx == -1:
		return
	var item: InventoryItem = payload as InventoryItem
	if item != null:
		var items: Dictionary = _settler_placed_items[idx] as Dictionary
		items[piece_id] = item
	if _active_inventory_drag:
		_active_inventory_drag = false
	assignments_changed.emit()


func _on_piece_released(origin: Object, payload: Variant, com: Vector2) -> void:
	var idx: int = _settler_idx_for_grid(origin as SettlerFoodGrid)
	if idx == -1 and not _active_inventory_drag:
		return
	_active_inventory_drag = false
	var item: InventoryItem = payload as InventoryItem
	if item == null:
		assignments_changed.emit()
		return
	# Grid-origin: snap back to original slot unless the user dropped on inventory.
	if idx != -1 and not _inventory_ui.has_active_drop_target():
		var from_grid: SettlerFoodGrid = origin as SettlerFoodGrid
		if from_grid.grid_data.get_piece_count() == 0:
			var def: PlaceableDefinition = item.data as PlaceableDefinition
			if def != null:
				var pid: int = from_grid.place_piece_at(def.shape, 1, 1, item.display_name)
				if pid != -1:
					(_settler_placed_items[idx] as Dictionary)[pid] = item
					var slot_center: Vector2 = from_grid.position \
						+ Vector2(SettlerFoodGrid.SLOT_SIZE, SettlerFoodGrid.SLOT_SIZE) * 0.5
					item_snap_back_to_grid.emit(item, com, slot_center)
					assignments_changed.emit()
					return
	# Return to inventory.
	_inventory.move_group_before(item, _inventory_ui.get_drop_ref_item())
	if not _inventory_ui.has_active_drop_target():
		item_returned_to_inventory.emit(item, com)
	assignments_changed.emit()
