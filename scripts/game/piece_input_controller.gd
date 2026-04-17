class_name PieceInputController
extends Node

## Owns all drag/input state and routing for piece interactions across all grids.
## Grids registered as pickup sources are fully passive — they do not process input.
##
## Usage:
##   register_pickup_source(grid)             — grid can be picked up from
##   register_drop_target(grid, priority)     — grid can receive drops (higher priority checked first)
##   begin_inventory_drag(shape, payload, hint) — start an inventory-origin drag
##   set_held_payload(payload)                — called by manager in pickup_confirmed handler
##   set_held_discardable(bool)               — UNBUILT pieces: emit piece_released on no-drop
##   cancel_drag()                            — cancel any in-progress drag (panel close)
##   set_inventory_control(c)                 — for drag indicator and inventory-drop detection

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Emitted when drag threshold is met and a piece is lifted.
## Grid origin: piece_id = the lifted piece, payload = null (manager calls set_held_payload after).
## Inventory origin: piece_id = -1, payload = item from begin_inventory_drag.
signal pickup_confirmed(origin: Object, piece_id: int, shape: PieceShape, payload: Variant)

## Emitted when a held piece successfully lands on a registered drop target.
signal piece_placed(origin: Object, target: Object, piece_id: int, payload: Variant)

## Emitted when a GRID-origin held piece snaps back to its original cell.
signal piece_returned(origin: Object, piece_id: int, payload: Variant)

## Emitted when a held piece is released with no valid drop target and no snap-back
## (inventory origin, discardable grid origin, or grid origin over inventory).
signal piece_released(origin: Object, payload: Variant, com: Vector2)

## Emitted every _process frame while a piece is being dragged.
## cursor_screen is the effective drag position in screen coordinates (drag offset applied).
signal drag_moved(cursor_screen: Vector2, shape: PieceShape, payload: Variant)

## Emitted when a drag ends (piece placed, returned, or released).
signal drag_ended()

## Emitted on double-tap of a toggleable piece.
signal piece_double_tapped(origin: Object, piece_id: int)

## Emitted when a held-press exceeds the long-press threshold on a non-moveable piece.
signal piece_long_pressed(origin: Object, piece_id: int)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

const PICKUP_DRAG_THRESHOLD_SQ: float = 16.0 * 16.0
const PICKUP_HOLD_TIME:         float = 0.5
const TAP_DOUBLE_WINDOW:        float = 0.5
## Drag offset in cell-unit multipliers: (col_offset, row_offset).
const DRAG_OFFSET_CELLS:        Vector2 = Vector2(-1.0, -1.5)
const DEFAULT_CELL_SIZE:        int = 32

# ---------------------------------------------------------------------------
# Registration state
# ---------------------------------------------------------------------------

## Registered pickup sources (GameGrid instances) in insertion order.
var _pickup_sources: Array[Object] = []

## Drop targets sorted by priority descending.
## Each entry: {"source": Object, "priority": int}
var _drop_targets: Array = []

# ---------------------------------------------------------------------------
# Input-source tracking
# ---------------------------------------------------------------------------

enum InputSource { NONE, MOUSE, TOUCH }

var _drag_source:       InputSource = InputSource.NONE
var _drag_touch_idx:    int         = -1
var _active_touches:    Dictionary  = {}
var _mouse_held:        bool        = false
var _last_touch_idx:    int         = -1
var _last_input_pos:    Vector2     = Vector2.ZERO
var _cursor_screen_pos: Vector2     = Vector2.ZERO

# ---------------------------------------------------------------------------
# Pending-pickup state
# ---------------------------------------------------------------------------

enum PendingType { NONE, GRID, INVENTORY }

var _pending_type:       PendingType = PendingType.NONE
var _pending_input:      InputSource = InputSource.NONE
var _pending_touch_idx:  int         = -1
var _pending_screen_pos: Vector2     = Vector2.ZERO
var _pending_timer:      float       = 0.0
## Grid for GRID-type pending; null for INVENTORY-type.
var _pending_source_obj: Object      = null
var _pending_grid_cell:  Vector2i    = Vector2i(-1, -1)
## Shape stored during INVENTORY-type pending (cleared on confirm or cancel).
var _pending_inv_shape:  PieceShape  = null

# ---------------------------------------------------------------------------
# Held state
# ---------------------------------------------------------------------------

var _held_shape:        PieceShape = null
var _held_origin:       Object     = null   # source grid, or null for inventory origin
var _held_origin_cell:  Vector2i   = Vector2i(-1, -1)
var _held_origin_shape: PieceShape = null   # pre-rotation shape for snap-back
var _held_payload:      Variant    = null
var _held_label_hint:   String     = ""
var _held_discardable:  bool       = false
var _active_cell_size:  int        = DEFAULT_CELL_SIZE

# ---------------------------------------------------------------------------
# Tap-detection state
# ---------------------------------------------------------------------------

enum TapState { NONE, DOWN, WINDOW, LOCKED }

var _tap_state:      TapState    = TapState.NONE
var _tap_piece_id:   int         = -1
var _tap_origin:     Object      = null
var _tap_timer:      float       = 0.0
var _tap_input:      InputSource = InputSource.NONE
var _tap_touch_idx:  int         = -1
var _tap_screen_pos: Vector2     = Vector2.ZERO

# ---------------------------------------------------------------------------
# Held sprite
# ---------------------------------------------------------------------------

var _held_sprite_layer: CanvasLayer = null
var _held_sprite:       Sprite2D    = null
var _held_label:        Label       = null

# ---------------------------------------------------------------------------
# Inventory control (for drag indicator and over-inventory detection)
# ---------------------------------------------------------------------------

var _inventory_control: Control = null


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	_held_sprite_layer       = CanvasLayer.new()
	_held_sprite_layer.layer = 100
	add_child(_held_sprite_layer)

	_held_sprite                = Sprite2D.new()
	_held_sprite.centered       = false
	_held_sprite.visible        = false
	_held_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_held_sprite_layer.add_child(_held_sprite)

	_held_label         = _make_label(DEFAULT_CELL_SIZE)
	_held_label.visible = false
	_held_sprite_layer.add_child(_held_label)


func _process(delta: float) -> void:
	# Pending timer — confirm pickup on hold threshold.
	if _pending_type != PendingType.NONE and _pending_input != InputSource.NONE:
		_pending_timer += delta
		if _pending_timer >= PICKUP_HOLD_TIME:
			_confirm_pending()

	# Tap timer.
	if _tap_state != TapState.NONE:
		_tap_timer += delta
		if _tap_state == TapState.DOWN and _tap_timer >= PICKUP_HOLD_TIME:
			var long_pid: int    = _tap_piece_id
			var long_origin: Object = _tap_origin
			_clear_tap()
			piece_long_pressed.emit(long_origin, long_pid)
		elif _tap_state == TapState.WINDOW and _tap_timer >= TAP_DOUBLE_WINDOW:
			_clear_tap()
		elif _tap_state == TapState.LOCKED and _tap_timer >= PICKUP_HOLD_TIME:
			_clear_tap()

	# Emit drag_moved and update inventory drop indicator.
	if _held_shape != null:
		var eff_pos: Vector2 = _effective_cursor_screen_pos()
		drag_moved.emit(eff_pos, _held_shape, _held_payload)
		if _inventory_control != null and _inventory_control.has_method("set_drag_pos"):
			var com: Vector2 = _held_sprite_com()
			if _inventory_control.get_global_rect().has_point(com):
				_inventory_control.set_drag_pos(com)
			else:
				_inventory_control.clear_drag()


# ---------------------------------------------------------------------------
# Registration API
# ---------------------------------------------------------------------------

func register_pickup_source(source: Object) -> void:
	if source in _pickup_sources:
		return
	_pickup_sources.append(source)


func unregister_pickup_source(source: Object) -> void:
	_pickup_sources.erase(source)


func register_drop_target(source: Object, priority: int = 0) -> void:
	for entry: Dictionary in _drop_targets:
		if entry["source"] == source:
			entry["priority"] = priority
			_sort_drop_targets()
			return
	_drop_targets.append({"source": source, "priority": priority})
	_sort_drop_targets()


func unregister_drop_target(source: Object) -> void:
	for i: int in range(_drop_targets.size() - 1, -1, -1):
		if (_drop_targets[i] as Dictionary)["source"] == source:
			_drop_targets.remove_at(i)
			return


func _sort_drop_targets() -> void:
	_drop_targets.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return (a["priority"] as int) > (b["priority"] as int))


# ---------------------------------------------------------------------------
# Public API (called by managers and game.gd)
# ---------------------------------------------------------------------------

## Begin a drag for an item coming from inventory or the build menu.
## shape: the piece shape; payload: opaque data (InventoryItem); hint: display name.
## Initialises pending state; actual pickup fires on drag/hold threshold.
func begin_inventory_drag(shape: PieceShape, payload: Variant, hint: String = "") -> void:
	if _pending_type != PendingType.NONE or _held_shape != null:
		return
	_pending_inv_shape  = shape
	_held_payload       = payload
	_held_label_hint    = hint
	_pending_type       = PendingType.INVENTORY
	_pending_timer      = 0.0
	_pending_source_obj = null
	if _mouse_held:
		_pending_input      = InputSource.MOUSE
		_pending_screen_pos = _last_input_pos
	elif _last_touch_idx != -1 and _active_touches.has(_last_touch_idx):
		_pending_input     = InputSource.TOUCH
		_pending_touch_idx = _last_touch_idx
		_pending_screen_pos = _last_input_pos
	# If no active input: _pending_input stays NONE; confirmed on next press.


## Associate an opaque payload with the currently held piece.
## Call in the pickup_confirmed handler for GRID-origin pickups.
func set_held_payload(payload: Variant) -> void:
	_held_payload = payload


## When true, a GRID-origin held piece emits piece_released on no-drop instead of snapping back.
## Call after pickup_confirmed for UNBUILT pieces or cross-slot drags.
func set_held_discardable(discardable: bool) -> void:
	_held_discardable = discardable


## Update the display name hint on the held sprite.
func set_held_hint(hint: String) -> void:
	_held_label_hint = hint
	if _held_label != null and _held_shape != null:
		_held_label.text = _held_shape.get_label(_held_label_hint)


## Rotate the currently held piece 90 degrees clockwise.
func rotate_held_cw() -> void:
	if _held_shape != null:
		_held_shape = _held_shape.rotated_cw()
		_show_held_sprite(_held_shape)


## Cancel any in-progress drag. Snaps back GRID-origin pieces; emits piece_released for others.
func cancel_drag() -> void:
	_cancel_pending()
	_clear_tap()
	if _held_shape == null:
		return
	if _held_origin != null and _held_origin is GameGrid:
		var grid: GameGrid = _held_origin as GameGrid
		var piece_id: int = grid.place_piece_at(
			_held_origin_shape, _held_origin_cell.x, _held_origin_cell.y, _held_label_hint)
		if piece_id != -1:
			var origin: Object   = _held_origin
			var payload: Variant = _held_payload
			_clear_held()
			piece_returned.emit(origin, piece_id, payload)
			drag_ended.emit()
			if _inventory_control != null and _inventory_control.has_method("clear_drag"):
				_inventory_control.clear_drag()
			return
	# Inventory origin or snap-back placement failed.
	var com: Vector2     = _held_sprite_com()
	var origin: Object   = _held_origin
	var payload: Variant = _held_payload
	_clear_held()
	piece_released.emit(origin, payload, com)
	drag_ended.emit()
	if _inventory_control != null and _inventory_control.has_method("clear_drag"):
		_inventory_control.clear_drag()


## Set the inventory panel control for drag-position indicator and drop detection.
func set_inventory_control(c: Control) -> void:
	_inventory_control = c


# ---------------------------------------------------------------------------
# Input handling
# ---------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_cursor_screen_pos = event.position
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			if _pending_type != PendingType.NONE and _pending_input == InputSource.MOUSE:
				var dist_sq: float = event.position.distance_squared_to(_pending_screen_pos)
				if dist_sq >= PICKUP_DRAG_THRESHOLD_SQ:
					_confirm_pending()
			elif _held_shape != null:
				if _drag_source == InputSource.NONE:
					_drag_source = InputSource.MOUSE
			elif _tap_state == TapState.DOWN and _tap_input == InputSource.MOUSE:
				var dist_sq: float = event.position.distance_squared_to(_tap_screen_pos)
				if dist_sq >= PICKUP_DRAG_THRESHOLD_SQ:
					_clear_tap()
		_update_held_sprite_pos()
		if _held_shape == null:
			_update_all_cursor_hover(event.position)
		_redraw_grids()

	elif event is InputEventMouseButton:
		_cursor_screen_pos = event.position
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_mouse_held     = true
				_last_input_pos = event.position
				_handle_input_press(InputSource.MOUSE, -1, event.position, _active_touches.is_empty())
			else:
				_mouse_held = false
				_handle_input_release(InputSource.MOUSE, -1)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and _held_shape != null:
			rotate_held_cw()
		_redraw_grids()

	elif event is InputEventScreenTouch:
		if event.pressed:
			_active_touches[event.index] = true
			_last_touch_idx = event.index
			_last_input_pos = event.position
			if _held_shape != null and _active_touches.size() > 1:
				rotate_held_cw()
				return
			_cursor_screen_pos = event.position
			_handle_input_press(InputSource.TOUCH, event.index, event.position, true)
		else:
			_active_touches.erase(event.index)
			_handle_input_release(InputSource.TOUCH, event.index)
		_redraw_grids()

	elif event is InputEventScreenDrag:
		if _pending_type != PendingType.NONE and _pending_input == InputSource.TOUCH \
				and event.index == _pending_touch_idx:
			_cursor_screen_pos = event.position
			var dist_sq: float = event.position.distance_squared_to(_pending_screen_pos)
			if dist_sq >= PICKUP_DRAG_THRESHOLD_SQ:
				_confirm_pending()
			_redraw_grids()
		elif _drag_source == InputSource.NONE and _held_shape != null:
			_drag_source    = InputSource.TOUCH
			_drag_touch_idx = event.index
			_cursor_screen_pos = event.position
			_update_held_sprite_pos()
			_redraw_grids()
		elif _drag_source == InputSource.TOUCH and event.index == _drag_touch_idx:
			_cursor_screen_pos = event.position
			_update_held_sprite_pos()
			_redraw_grids()
		elif _tap_state == TapState.DOWN and _tap_input == InputSource.TOUCH \
				and event.index == _tap_touch_idx:
			var dist_sq: float = event.position.distance_squared_to(_tap_screen_pos)
			if dist_sq >= PICKUP_DRAG_THRESHOLD_SQ:
				_clear_tap()


func _handle_input_press(source: InputSource, idx: int, screen_pos: Vector2, allow_tap: bool) -> void:
	if _held_shape != null:
		_drag_source = source
		if source == InputSource.TOUCH:
			_drag_touch_idx = idx
		return

	# Assign input source to a waiting inventory pending hold.
	if _pending_type == PendingType.INVENTORY and _pending_input == InputSource.NONE:
		_pending_input      = source
		_pending_screen_pos = screen_pos
		if source == InputSource.TOUCH:
			_pending_touch_idx = idx
		return

	if _pending_type != PendingType.NONE:
		return

	# Hit-test registered pickup sources.
	for src_obj: Object in _pickup_sources:
		if not (src_obj is GameGrid):
			continue
		var grid: GameGrid = src_obj as GameGrid
		if not grid.grid_active or grid.planning_locked:
			continue
		if not grid.get_screen_rect().has_point(screen_pos):
			continue
		var cell: Vector2i = _screen_to_cell(grid, screen_pos)
		var cell_val: int  = grid.grid_data.get_cell(cell.x, cell.y) \
			if cell != Vector2i(-1, -1) else 0
		if cell_val > 0 and grid.is_piece_moveable(cell_val):
			_pending_type       = PendingType.GRID
			_pending_input      = source
			_pending_screen_pos = screen_pos
			_pending_timer      = 0.0
			_pending_source_obj = grid
			_pending_grid_cell  = cell
			if source == InputSource.TOUCH:
				_pending_touch_idx = idx
			if grid.is_piece_toggleable(cell_val) and allow_tap:
				_start_tap_down(grid, cell_val, source, screen_pos, idx)
			break
		elif cell_val > 0 and allow_tap:
			_start_tap_down(grid, cell_val, source, screen_pos, idx)
			break


func _handle_input_release(source: InputSource, idx: int) -> void:
	if _drag_source == source and (source == InputSource.MOUSE or idx == _drag_touch_idx):
		_drag_source = InputSource.NONE
		if source == InputSource.TOUCH:
			_drag_touch_idx = -1
		if _held_shape != null:
			_try_place_or_return()
		return

	if _pending_input == source and (source == InputSource.MOUSE or idx == _pending_touch_idx):
		if _pending_type == PendingType.GRID and _pending_grid_cell != Vector2i(-1, -1):
			var grid: GameGrid = _pending_source_obj as GameGrid
			if grid != null:
				var cv: int = grid.grid_data.get_cell(_pending_grid_cell.x, _pending_grid_cell.y)
				if cv > 0 and _tap_piece_id == cv:
					if _tap_state == TapState.DOWN:
						_tap_state = TapState.WINDOW
						_tap_timer = 0.0
						if source == InputSource.TOUCH:
							_tap_touch_idx = -1
					elif _tap_state == TapState.LOCKED:
						_clear_tap()
		_cancel_pending()
		return

	if _pending_type == PendingType.INVENTORY and _pending_input == InputSource.NONE:
		_cancel_pending()
		return

	if _held_shape != null and _drag_source == InputSource.NONE:
		_try_place_or_return()
		return

	if _tap_state == TapState.DOWN and _tap_input == source \
			and (source == InputSource.MOUSE or idx == _tap_touch_idx):
		_tap_state = TapState.WINDOW
		_tap_timer = 0.0
		if source == InputSource.TOUCH:
			_tap_touch_idx = -1
		return

	if _tap_state == TapState.LOCKED and _tap_input == source \
			and (source == InputSource.MOUSE or idx == _tap_touch_idx):
		_clear_tap()


# ---------------------------------------------------------------------------
# Pending confirmation / cancellation
# ---------------------------------------------------------------------------

func _confirm_pending() -> void:
	_clear_tap()
	match _pending_type:
		PendingType.GRID:
			var grid: GameGrid = _pending_source_obj as GameGrid
			if grid == null:
				_cancel_pending()
				return
			var cell: Vector2i = _pending_grid_cell
			var val: int       = grid.grid_data.get_cell(cell.x, cell.y)
			if val > 0:
				var shape: PieceShape = grid.lift_piece(val)
				if shape != null:
					_active_cell_size  = grid.cell_size
					_held_shape        = shape
					_held_origin       = grid
					_held_origin_cell  = cell
					_held_origin_shape = shape
					_drag_source       = _pending_input
					_drag_touch_idx    = _pending_touch_idx
					_show_held_sprite(shape)
					_cancel_pending()
					pickup_confirmed.emit(grid, val, shape, null)
					return
			_cancel_pending()

		PendingType.INVENTORY:
			if _pending_inv_shape != null:
				var shape: PieceShape = _pending_inv_shape
				_active_cell_size  = DEFAULT_CELL_SIZE
				_held_shape        = shape
				_held_origin       = null
				_held_origin_cell  = Vector2i(-1, -1)
				_held_origin_shape = null
				_drag_source       = _pending_input
				_drag_touch_idx    = _pending_touch_idx
				var saved_payload: Variant = _held_payload
				_cancel_pending()
				_held_payload = saved_payload  # restore after _cancel_pending clears it
				_show_held_sprite(shape)
				pickup_confirmed.emit(null, -1, shape, _held_payload)
				return
			_cancel_pending()


func _cancel_pending() -> void:
	if _pending_type == PendingType.INVENTORY:
		_held_payload = null
	_pending_type       = PendingType.NONE
	_pending_input      = InputSource.NONE
	_pending_touch_idx  = -1
	_pending_timer      = 0.0
	_pending_source_obj = null
	_pending_grid_cell  = Vector2i(-1, -1)
	_pending_inv_shape  = null


# ---------------------------------------------------------------------------
# Drop routing
# ---------------------------------------------------------------------------

func _try_place_or_return() -> void:
	var cursor: Vector2 = _effective_cursor_screen_pos()
	# Try each registered drop target in priority order.
	for entry: Dictionary in _drop_targets:
		var target: Object = entry["source"]
		if not (target is GameGrid):
			continue
		var grid: GameGrid = target as GameGrid
		var piece_id: int  = grid.try_receive_drop(cursor, _held_shape, _held_payload, _held_label_hint)
		if piece_id != -1:
			var origin: Object   = _held_origin
			var payload: Variant = _held_payload
			_clear_held()
			piece_placed.emit(origin, grid, piece_id, payload)
			drag_ended.emit()
			if _inventory_control != null and _inventory_control.has_method("clear_drag"):
				_inventory_control.clear_drag()
			return

	# No target accepted — snap back or release.
	var over_inventory: bool = _inventory_control != null \
		and _inventory_control.get_global_rect().has_point(_held_sprite_com())
	if _held_origin != null and _held_origin is GameGrid \
			and not _held_discardable and not over_inventory:
		_snap_back_to_origin()
	else:
		var com: Vector2     = _held_sprite_com()
		var origin: Object   = _held_origin
		var payload: Variant = _held_payload
		_clear_held()
		piece_released.emit(origin, payload, com)
		drag_ended.emit()
		if _inventory_control != null and _inventory_control.has_method("clear_drag"):
			_inventory_control.clear_drag()


func _snap_back_to_origin() -> void:
	var grid: GameGrid    = _held_origin as GameGrid
	var shape: PieceShape = _held_origin_shape
	var cell: Vector2i    = _held_origin_cell
	var hint: String      = _held_label_hint
	var origin: Object    = _held_origin
	var payload: Variant  = _held_payload
	_play_snapback_anim(shape, cell, grid)
	_clear_held()
	var piece_id: int = grid.place_piece_at(shape, cell.x, cell.y, hint)
	if piece_id != -1:
		piece_returned.emit(origin, piece_id, payload)
	else:
		piece_released.emit(origin, payload, Vector2.ZERO)
	drag_ended.emit()
	if _inventory_control != null and _inventory_control.has_method("clear_drag"):
		_inventory_control.clear_drag()


func _play_snapback_anim(shape: PieceShape, cell: Vector2i, grid: GameGrid) -> void:
	var bb: Rect2i        = shape.get_bounding_rect()
	var dest_local: Vector2 = Vector2(
		(cell.y + bb.position.y - 1) * float(grid.cell_size),
		(cell.x + bb.position.x - 1) * float(grid.cell_size)
	)
	var dest_screen: Vector2 = grid.to_global(dest_local)
	var anim: Sprite2D       = Sprite2D.new()
	anim.centered            = false
	anim.texture             = _held_sprite.texture
	anim.texture_filter      = CanvasItem.TEXTURE_FILTER_NEAREST
	anim.position            = _held_sprite.position
	anim.modulate            = Color(1.0, 1.0, 1.0, 0.6)
	_held_sprite_layer.add_child(anim)
	var tween: Tween = create_tween()
	tween.tween_property(anim, "position", dest_screen, 0.13)
	tween.parallel().tween_property(anim, "modulate:a", 0.0, 0.13)
	tween.tween_callback(anim.queue_free)


# ---------------------------------------------------------------------------
# Tap-detection helpers
# ---------------------------------------------------------------------------

func _start_tap_down(origin: Object, piece_id: int, source: InputSource,
		screen_pos: Vector2, touch_idx: int) -> void:
	if _tap_state == TapState.WINDOW and _tap_piece_id == piece_id:
		piece_double_tapped.emit(origin, piece_id)
		_tap_state      = TapState.LOCKED
		_tap_timer      = 0.0
		_tap_input      = source
		_tap_touch_idx  = touch_idx
		_tap_origin     = origin
	elif (_tap_state == TapState.DOWN and _tap_piece_id == piece_id) \
			or _tap_state == TapState.LOCKED:
		pass
	else:
		_tap_state      = TapState.DOWN
		_tap_piece_id   = piece_id
		_tap_timer      = 0.0
		_tap_input      = source
		_tap_touch_idx  = touch_idx
		_tap_screen_pos = screen_pos
		_tap_origin     = origin


func _clear_tap() -> void:
	_tap_state      = TapState.NONE
	_tap_piece_id   = -1
	_tap_timer      = 0.0
	_tap_input      = InputSource.NONE
	_tap_touch_idx  = -1
	_tap_screen_pos = Vector2.ZERO
	_tap_origin     = null


# ---------------------------------------------------------------------------
# Held state helpers
# ---------------------------------------------------------------------------

func _clear_held() -> void:
	_held_shape        = null
	_held_origin       = null
	_held_origin_cell  = Vector2i(-1, -1)
	_held_origin_shape = null
	_held_payload      = null
	_held_discardable  = false
	_held_label_hint   = ""
	_drag_source       = InputSource.NONE
	_drag_touch_idx    = -1
	if _held_sprite != null:
		_held_sprite.visible = false
	if _held_label != null:
		_held_label.visible = false


# ---------------------------------------------------------------------------
# Coordinate helpers
# ---------------------------------------------------------------------------

## Convert a screen position to the grid-local cell it falls on.
func _screen_to_cell(grid: GameGrid, screen_pos: Vector2) -> Vector2i:
	var local_pos: Vector2 = grid.to_local(screen_pos)
	var col: int = int(floorf(local_pos.x / float(grid.cell_size))) + 1
	var row: int = int(floorf(local_pos.y / float(grid.cell_size))) + 1
	if grid.grid_data.is_in_bounds(row, col):
		return Vector2i(row, col)
	return Vector2i(-1, -1)


func _drag_offset_vec() -> Vector2:
	if Settings.drag_offset and _held_shape != null:
		return Vector2(
			DRAG_OFFSET_CELLS.x * float(_active_cell_size),
			DRAG_OFFSET_CELLS.y * float(_active_cell_size)
		)
	return Vector2.ZERO


func _effective_cursor_screen_pos() -> Vector2:
	return _cursor_screen_pos + _drag_offset_vec()


## Screen-space centre of mass of the held sprite.
func _held_sprite_com() -> Vector2:
	if _held_shape == null:
		return Vector2.ZERO
	var n: int         = _held_shape.offsets.size()
	var sum_col: float = 0.0
	var sum_row: float = 0.0
	for offset: Vector2i in _held_shape.offsets:
		sum_col += float(offset.y)
		sum_row += float(offset.x)
	return _effective_cursor_screen_pos() + Vector2(
		(sum_col / float(n) + 0.5) * float(_active_cell_size),
		(sum_row / float(n) + 0.5) * float(_active_cell_size)
	)


# ---------------------------------------------------------------------------
# Sprite helpers
# ---------------------------------------------------------------------------

func _show_held_sprite(shape: PieceShape) -> void:
	_held_sprite.texture = PieceSpriteGenerator.generate(shape, shape.color)
	_held_sprite.visible = true
	_held_label.text     = shape.get_label(_held_label_hint)
	_held_label.visible  = true
	_update_held_sprite_pos()


func _update_held_sprite_pos() -> void:
	if _held_shape == null:
		return
	var origin: Vector2   = _effective_cursor_screen_pos()
	_held_sprite.position = origin + PieceSpriteGenerator.origin_offset(_held_shape)
	_held_label.position  = origin


func _make_label(sz: int) -> Label:
	var lbl: Label = Label.new()
	lbl.size = Vector2(sz, sz)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	return lbl


# ---------------------------------------------------------------------------
# Grid notification helpers
# ---------------------------------------------------------------------------

## Push cursor hover position to all registered grids (non-drag state).
func _update_all_cursor_hover(screen_pos: Vector2) -> void:
	var seen: Array = []
	for src: Object in _pickup_sources:
		if src is GameGrid and not (src in seen):
			(src as GameGrid).update_cursor_hover(screen_pos)
			seen.append(src)
	for entry: Dictionary in _drop_targets:
		var target: Object = entry["source"]
		if target is GameGrid and not (target in seen):
			(target as GameGrid).update_cursor_hover(screen_pos)
			seen.append(target)


## Request a redraw from all registered grids.
func _redraw_grids() -> void:
	var seen: Array = []
	for src: Object in _pickup_sources:
		if src is GameGrid and not (src in seen):
			(src as GameGrid).queue_redraw()
			seen.append(src)
	for entry: Dictionary in _drop_targets:
		var target: Object = entry["source"]
		if target is GameGrid and not (target in seen):
			(target as GameGrid).queue_redraw()
			seen.append(target)
