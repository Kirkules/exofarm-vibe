class_name GameGrid
extends Node2D

## Base class for all interactive grids in the game.
##
## Owns the polyomino drag model, input state machine, rendering pipeline,
## and drop detection.  Subclasses add grid-specific overlays and item
## acceptance rules via _draw_grid_overlays() and _can_accept_item().
##
## Dimensions are set via rows/cols/cell_size before _ready() runs
## (e.g. in a subclass _ready() before calling super._ready()).
##
## Locking hierarchy (most to least restrictive):
##   grid_active = false  → fully dormant: no input, no visual feedback
##   planning_locked = true → visible and rendered, but all input blocked
##   (both are typically set via EventBus signals, not imperatively)

## Default dimensions — subclasses override before super._ready().
var rows:      int = 6
var cols:      int = 8
var cell_size: int = 32

## Offset applied to the dragged piece when Settings.drag_offset is true.
## Expressed as cell-unit multipliers; actual offset = multiplier * cell_size.
const DRAG_OFFSET_CELLS := Vector2(-1.0, -1.5)

const PICKUP_DRAG_THRESHOLD_SQ: float = 16.0 * 16.0
const PICKUP_HOLD_TIME:         float = 0.5
const TAP_DOUBLE_WINDOW:        float = 0.5

## Cell colour vars — subclasses may reassign in their _ready() to theme the grid.
var color_empty:   Color = Color(0.18, 0.18, 0.18)
var color_border:  Color = Color(0.08, 0.08, 0.08)
var color_hover:   Color = Color(0.25, 0.35, 0.25)
var color_valid:   Color = Color(0.30, 0.65, 0.30, 0.65)
var color_invalid: Color = Color(0.65, 0.25, 0.25, 0.65)

# Piece fill colours cycle by piece_id for visual distinction.
const PIECE_COLORS: Array[Color] = [
	Color(0.40, 0.60, 0.90),
	Color(0.90, 0.60, 0.28),
	Color(0.55, 0.88, 0.38),
	Color(0.90, 0.38, 0.60),
	Color(0.68, 0.48, 0.92),
]

var grid_data: GridData

var _held_shape: PieceShape = null
var has_held_piece: bool:
	get: return _held_shape != null

## Where the currently held piece came from; determines behaviour on failed drop.
enum HeldOrigin { NONE, GRID, INVENTORY }
var _held_origin:       HeldOrigin = HeldOrigin.NONE
var _held_origin_cell:  Vector2i   = Vector2i(-1, -1)
var _held_origin_shape: PieceShape = null

# _cursor_pos: grid-local coordinates — used for cell snapping and preview.
# _cursor_screen_pos: raw viewport pixels — used for the held sprite on the CanvasLayer.
var _cursor_pos:        Vector2  = Vector2.ZERO
var _cursor_screen_pos: Vector2  = Vector2.ZERO
var _hovered_cell:      Vector2i = Vector2i(-1, -1)

# ---------------------------------------------------------------------------
# Input-source tracking
# ---------------------------------------------------------------------------
enum InputSource { NONE, MOUSE, TOUCH }

var _drag_source:    InputSource = InputSource.NONE
var _drag_touch_idx: int         = -1

var _active_touches: Dictionary = {}
var _mouse_held:     bool       = false

# ---------------------------------------------------------------------------
# Pending-pickup threshold tracking
# ---------------------------------------------------------------------------
enum PendingSource { NONE, GRID, INVENTORY }

var _pending_source:     PendingSource = PendingSource.NONE
var _pending_input:      InputSource   = InputSource.NONE
var _pending_touch_idx:  int           = -1
var _pending_screen_pos: Vector2       = Vector2.ZERO
var _pending_timer:      float         = 0.0
var _pending_grid_cell:  Vector2i      = Vector2i(-1, -1)
var _pending_inv_item:   InventoryItem = null

# ---------------------------------------------------------------------------
# Tap-detection (non-moveable fixed pieces)
# ---------------------------------------------------------------------------
enum TapState { NONE, DOWN, WINDOW, LOCKED }
var _tap_state:      TapState    = TapState.NONE
var _tap_piece_id:   int         = -1
var _tap_timer:      float       = 0.0
var _tap_input:      InputSource = InputSource.NONE
var _tap_touch_idx:  int         = -1
var _tap_screen_pos: Vector2     = Vector2.ZERO

var _last_touch_idx: int     = -1
var _last_input_pos: Vector2 = Vector2.ZERO

var has_pending_pickup: bool:
	get: return _pending_input != InputSource.NONE

# ---------------------------------------------------------------------------
# Piece sprite / display tracking
# ---------------------------------------------------------------------------
var _piece_sprites:     Dictionary = {}  # piece_id -> Sprite2D
var _piece_label_hints: Dictionary = {}  # piece_id -> String
var _piece_moveable:    Dictionary = {}  # piece_id -> bool
var _piece_toggleable:  Dictionary = {}  # piece_id -> bool
var _piece_flashing:    Dictionary = {}  # piece_id -> bool
var _flash_time:        float      = 0.0
var _held_sprite:       Sprite2D   = null
var _held_label:        Label      = null
var _held_label_hint:   String     = ""
var _held_sprite_layer: CanvasLayer = null

# ---------------------------------------------------------------------------
# Drop-target detection
# ---------------------------------------------------------------------------
## Set by game.gd so CoM-over-inventory detection works for drop routing.
var _inventory_control: Control = null

## When false, the held piece cannot be placed on this grid — skip preview
## and placement attempt.  Set by game.gd after pickup confirmation.
var _held_can_place: bool = true

## When true, a GRID-origin held piece that fails to place emits piece_released
## instead of snapping back.  Set by game.gd when picking up an UNBUILT piece
## (which should be discardable by dropping off-grid, not forced back).
var _held_discardable: bool = false

# ---------------------------------------------------------------------------
# Locking
# ---------------------------------------------------------------------------
## When false, the grid is fully dormant: no input processed, no visual
## feedback (hover/preview suppressed), cells render in neutral style.
var grid_active: bool = true

## When true, all input is blocked but the grid renders normally (pieces,
## overlays visible).  Used during season simulation.
var planning_locked: bool = false


# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
signal piece_picked_up_from_grid(piece_id: int, shape: PieceShape)
signal piece_placed_on_grid(piece_id: int)
signal piece_returned_to_grid(piece_id: int)
signal inventory_item_pickup_confirmed(item: InventoryItem)
signal piece_double_tapped(piece_id: int)
signal piece_long_pressed(piece_id: int)
## Emitted when a held INVENTORY-origin piece is released without landing on
## this grid.  com_screen_pos is the sprite CoM in screen coordinates.
## game.gd routes the item to another grid, inventory, or discards it.
signal piece_released(com_screen_pos: Vector2)

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	grid_data = GridData.new(rows, cols)
	EventBus.simulation_started.connect(func() -> void: set_planning_locked(true))
	EventBus.simulation_ended.connect(func() -> void: set_planning_locked(false))
	EventBus.log_overlay_opened.connect(func() -> void: set_planning_locked(true))
	EventBus.log_overlay_closed.connect(func() -> void: set_planning_locked(false))
	EventBus.merge_grid_opened.connect(func(grid: GameGrid) -> void:
		if grid != self:
			set_grid_active(false)
	)
	EventBus.merge_grid_closed.connect(_on_merge_grid_closed)

	_held_sprite_layer = CanvasLayer.new()
	_held_sprite_layer.layer = 100
	add_child(_held_sprite_layer)

	_held_sprite = Sprite2D.new()
	_held_sprite.centered = false
	_held_sprite.visible = false
	_held_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_held_sprite_layer.add_child(_held_sprite)

	_held_label = _make_label(cell_size)
	_held_label.visible = false
	_held_sprite_layer.add_child(_held_label)


func _process(delta: float) -> void:
	_flash_time = fmod(_flash_time + delta, 0.5)
	for piece_id: int in _piece_flashing:
		if _piece_flashing[piece_id] and _piece_sprites.has(piece_id):
			var alpha: float = 0.75 + 0.25 * cos(TAU * _flash_time / 0.5)
			_piece_sprites[piece_id].modulate = Color(1.0, 1.0, 1.0, alpha)
	if not grid_active or planning_locked:
		return
	if _pending_input != InputSource.NONE:
		_pending_timer += delta
		if _pending_timer >= PICKUP_HOLD_TIME:
			_confirm_pending()
	if _tap_state != TapState.NONE:
		_tap_timer += delta
		if _tap_state == TapState.DOWN and _tap_timer >= PICKUP_HOLD_TIME:
			var long_piece_id: int = _tap_piece_id
			_clear_tap()
			piece_long_pressed.emit(long_piece_id)
		elif _tap_state == TapState.WINDOW and _tap_timer >= TAP_DOUBLE_WINDOW:
			_clear_tap()
		elif _tap_state == TapState.LOCKED and _tap_timer >= PICKUP_HOLD_TIME:
			_clear_tap()

# ---------------------------------------------------------------------------
# Drawing
# ---------------------------------------------------------------------------

func _draw() -> void:
	_draw_cells()
	if grid_active:
		_draw_grid_overlays()
		if not planning_locked and _held_shape:
			_draw_placement_preview()


## Override in subclasses to draw grid-specific overlays (power ranges, etc.).
## Called by _draw() whenever grid_active is true, before placement preview.
func _draw_grid_overlays() -> void:
	pass


## Override in subclasses to block placement on specific cells (e.g. inactive slots).
## Called before attempting grid_data.place_piece; return false to reject.
func _can_place_at_cell(_cell: Vector2i) -> bool:
	return true


func _draw_cells() -> void:
	for row: int in range(1, rows + 1):
		for col: int in range(1, cols + 1):
			var rect: Rect2 = _cell_rect(row, col)
			var val: int    = grid_data.get_cell(row, col)
			var color: Color
			if grid_active and not planning_locked \
					and Vector2i(row, col) == _hovered_cell and val == 0 \
					and (_held_shape == null or _held_can_place):
				color = color_hover
			else:
				color = color_empty
			draw_rect(rect, color)
			draw_rect(rect, color_border, false)


func _draw_placement_preview() -> void:
	if not _held_can_place:
		return
	var origin: Vector2i = _pos_to_cell(_effective_cursor_pos())
	if origin == Vector2i(-1, -1):
		return
	var valid: bool  = grid_data.can_place(_held_shape, origin.x, origin.y) \
		and _can_place_at_cell(origin)
	var color: Color = color_valid if valid else color_invalid
	for offset: Vector2i in _held_shape.offsets:
		var r: int = origin.x + offset.x
		var c: int = origin.y + offset.y
		if grid_data.is_in_bounds(r, c):
			draw_rect(_cell_rect(r, c), color)

# ---------------------------------------------------------------------------
# Input
# ---------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if not grid_active or planning_locked:
		return

	if event is InputEventMouseMotion:
		_cursor_screen_pos = event.position
		_cursor_pos = to_local(event.position)
		_hovered_cell = _pos_to_cell(_cursor_pos)
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			if _pending_input == InputSource.MOUSE:
				_hovered_cell = _pos_to_cell(_effective_cursor_pos())
				var dist_sq: float = event.position.distance_squared_to(_pending_screen_pos)
				if dist_sq >= PICKUP_DRAG_THRESHOLD_SQ:
					_confirm_pending()
			elif _held_shape:
				if _drag_source == InputSource.NONE:
					_drag_source = InputSource.MOUSE
				_hovered_cell = _pos_to_cell(_effective_cursor_pos())
			elif _tap_state == TapState.DOWN and _tap_input == InputSource.MOUSE:
				var dist_sq: float = event.position.distance_squared_to(_tap_screen_pos)
				if dist_sq >= PICKUP_DRAG_THRESHOLD_SQ:
					_clear_tap()
		_update_held_sprite_pos()
		queue_redraw()

	elif event is InputEventMouseButton:
		_cursor_screen_pos = event.position
		_cursor_pos = to_local(event.position)
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_mouse_held     = true
				_last_input_pos = event.position
				_handle_input_press(InputSource.MOUSE, -1, event.position, _active_touches.is_empty())
			else:
				_mouse_held = false
				_handle_input_release(InputSource.MOUSE, -1)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and _held_shape:
			rotate_held_cw()
		queue_redraw()

	elif event is InputEventScreenTouch:
		if event.pressed:
			_active_touches[event.index] = true
			_last_touch_idx = event.index
			_last_input_pos = event.position
			if _held_shape and _active_touches.size() > 1:
				rotate_held_cw()
				return
			_cursor_screen_pos = event.position
			_cursor_pos        = to_local(event.position)
			_handle_input_press(InputSource.TOUCH, event.index, event.position, true)
		else:
			_active_touches.erase(event.index)
			_handle_input_release(InputSource.TOUCH, event.index)
		queue_redraw()

	elif event is InputEventScreenDrag:
		if _pending_input == InputSource.TOUCH and event.index == _pending_touch_idx:
			_cursor_screen_pos = event.position
			_cursor_pos = to_local(event.position)
			_hovered_cell = _pos_to_cell(_effective_cursor_pos())
			var dist_sq: float = event.position.distance_squared_to(_pending_screen_pos)
			if dist_sq >= PICKUP_DRAG_THRESHOLD_SQ:
				_confirm_pending()
			queue_redraw()
		elif _drag_source == InputSource.NONE and _held_shape:
			_drag_source    = InputSource.TOUCH
			_drag_touch_idx = event.index
			_cursor_screen_pos = event.position
			_cursor_pos = to_local(event.position)
			_hovered_cell = _pos_to_cell(_effective_cursor_pos())
			_update_held_sprite_pos()
			queue_redraw()
		elif _drag_source == InputSource.TOUCH and event.index == _drag_touch_idx:
			_cursor_screen_pos = event.position
			_cursor_pos = to_local(event.position)
			_hovered_cell = _pos_to_cell(_effective_cursor_pos())
			_update_held_sprite_pos()
			queue_redraw()
		elif _tap_state == TapState.DOWN and _tap_input == InputSource.TOUCH and event.index == _tap_touch_idx:
			var dist_sq: float = event.position.distance_squared_to(_tap_screen_pos)
			if dist_sq >= PICKUP_DRAG_THRESHOLD_SQ:
				_clear_tap()

# ---------------------------------------------------------------------------
# Pending-pickup confirmation / cancellation
# ---------------------------------------------------------------------------

func _confirm_pending() -> void:
	_clear_tap()
	match _pending_source:
		PendingSource.GRID:
			var cell: Vector2i = _pending_grid_cell
			var val: int = grid_data.get_cell(cell.x, cell.y)
			if val > 0:
				var info: Dictionary  = grid_data.get_piece_info(val)
				var shape: PieceShape = info["shape"]
				grid_data.remove_piece(val)
				_remove_piece_sprite(val)
				_held_shape        = shape
				_held_origin       = HeldOrigin.GRID
				_held_origin_cell  = Vector2i(info["row"], info["col"])
				_held_origin_shape = shape
				_held_label_hint   = _piece_label_hints.get(val, "")
				_drag_source    = _pending_input
				_drag_touch_idx = _pending_touch_idx
				_show_held_sprite(shape)
				emit_signal("piece_picked_up_from_grid", val, shape)
		PendingSource.INVENTORY:
			if _pending_inv_item != null:
				var shape: PieceShape = (_pending_inv_item.data as PlaceableDefinition).shape
				_held_shape      = shape
				_held_origin     = HeldOrigin.INVENTORY
				_held_label_hint = _pending_inv_item.display_name
				_drag_source    = _pending_input
				_drag_touch_idx = _pending_touch_idx
				_show_held_sprite(shape)
				emit_signal("inventory_item_pickup_confirmed", _pending_inv_item)

	_cancel_pending()
	queue_redraw()


func _cancel_pending() -> void:
	_pending_source    = PendingSource.NONE
	_pending_input     = InputSource.NONE
	_pending_touch_idx = -1
	_pending_timer     = 0.0
	_pending_inv_item  = null
	_pending_grid_cell = Vector2i(-1, -1)


## Place on grid if valid; otherwise snap back (GRID origin) or emit piece_released
## (INVENTORY origin) so game.gd can route the item to another target.
func _try_place_or_return() -> void:
	if _held_can_place:
		var cell: Vector2i = _pos_to_cell(_effective_cursor_pos())
		if cell != Vector2i(-1, -1) and _can_place_at_cell(cell):
			var shape_to_place: PieceShape = _held_shape
			var piece_id: int = grid_data.place_piece(shape_to_place, cell.x, cell.y)
			if piece_id != -1:
				_piece_label_hints[piece_id] = _held_label_hint
				_held_shape = null
				_held_sprite.visible = false
				_held_label.visible  = false
				_held_label_hint     = ""
				_create_piece_sprite(piece_id, shape_to_place, cell)
				_clear_held_origin()
				emit_signal("piece_placed_on_grid", piece_id)
				queue_redraw()
				return

	# Didn't place on this grid.
	# GRID-origin pieces snap back unless: (a) they're discardable, or (b) the CoM
	# is over the inventory panel (player is explicitly returning the item to inventory).
	if _held_origin == HeldOrigin.GRID and not _held_discardable \
			and not _sprite_com_over_inventory():
		# Snap back to the cell it came from.
		_return_held_to_grid()
	else:
		# INVENTORY origin, discardable GRID origin, or GRID origin over inventory
		# — emit for game.gd to route.
		var com: Vector2 = _held_sprite_com()
		_held_shape = null
		_held_sprite.visible = false
		_held_label.visible  = false
		_held_label_hint     = ""
		_clear_held_origin()
		emit_signal("piece_released", com)
		queue_redraw()


## Re-place the held piece at its original grid cell using its pre-rotation shape.
func _return_held_to_grid() -> void:
	var shape: PieceShape = _held_origin_shape
	var cell: Vector2i    = _held_origin_cell
	var hint: String      = _held_label_hint
	_held_shape          = null
	_held_sprite.visible = false
	_held_label.visible  = false
	_held_label_hint     = ""
	var piece_id: int = grid_data.place_piece(shape, cell.x, cell.y)
	if piece_id != -1:
		_piece_label_hints[piece_id] = hint
		_create_piece_sprite(piece_id, shape, cell)
		_clear_held_origin()
		emit_signal("piece_returned_to_grid", piece_id)
	else:
		_clear_held_origin()
		# Cells unexpectedly occupied — fall back to piece_released for routing.
		emit_signal("piece_released", Vector2.ZERO)
	queue_redraw()


func _clear_held_origin() -> void:
	_held_origin        = HeldOrigin.NONE
	_held_origin_cell   = Vector2i(-1, -1)
	_held_discardable   = false
	_held_origin_shape = null

# ---------------------------------------------------------------------------
# Drop-target detection
# ---------------------------------------------------------------------------

## Screen-space centre of mass of the currently held sprite.
## Returns Vector2.ZERO if no shape is held.
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
		(sum_col / float(n) + 0.5) * cell_size,
		(sum_row / float(n) + 0.5) * cell_size
	)


## Returns true if the sprite's CoM is over the inventory panel.
func _sprite_com_over_inventory() -> bool:
	if _inventory_control == null or _held_shape == null:
		return false
	return _inventory_control.get_global_rect().has_point(_held_sprite_com())

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Begin holding a piece (programmatic — skips threshold). Treats origin as inventory.
func hold_piece(shape: PieceShape, hint: String = "") -> void:
	_held_can_place  = true
	_held_shape      = shape
	_held_origin     = HeldOrigin.INVENTORY
	_held_label_hint = hint
	_drag_source     = InputSource.NONE
	_show_held_sprite(shape)
	queue_redraw()


## Called by game.gd when the player presses an inventory item.
## Records a pending inventory pickup; confirmed once drag/hold threshold is met.
func begin_pending_inventory_hold(item: InventoryItem) -> void:
	if _pending_input != InputSource.NONE or _held_shape != null:
		return
	_pending_inv_item = item
	_pending_source   = PendingSource.INVENTORY
	_pending_timer    = 0.0
	if _mouse_held:
		_pending_input      = InputSource.MOUSE
		_pending_screen_pos = _last_input_pos
	elif _last_touch_idx != -1 and _active_touches.has(_last_touch_idx):
		_pending_input      = InputSource.TOUCH
		_pending_touch_idx  = _last_touch_idx
		_pending_screen_pos = _last_input_pos


## Directly place a piece on the grid without going through the hold flow.
## Emits piece_placed_on_grid so game.gd can register the piece normally.
## Returns the new piece_id, or -1 if the position is occupied or out of bounds.
func place_piece_at(shape: PieceShape, row: int, col: int, hint: String = "") -> int:
	if not grid_data.can_place(shape, row, col):
		return -1
	var piece_id: int = grid_data.place_piece(shape, row, col)
	_piece_label_hints[piece_id] = hint
	_create_piece_sprite(piece_id, shape, Vector2i(row, col))
	piece_placed_on_grid.emit(piece_id)
	queue_redraw()
	return piece_id


## Rotate the currently held piece 90 degrees clockwise.
func rotate_held_cw() -> void:
	if _held_shape:
		_held_shape = _held_shape.rotated_cw()
		_show_held_sprite(_held_shape)
		queue_redraw()


## Cancel hold and return the held shape (or null if nothing was held).
## Does not emit any signal; caller is responsible for disposing the shape.
func cancel_hold() -> PieceShape:
	var shape: PieceShape = _held_shape
	_held_shape          = null
	_drag_source         = InputSource.NONE
	_drag_touch_idx      = -1
	_held_sprite.visible = false
	_held_label.visible  = false
	_held_label_hint     = ""
	_clear_held_origin()
	queue_redraw()
	return shape


## Update the display name hint for the currently held piece.
func set_held_hint(hint: String) -> void:
	_held_label_hint = hint
	if _held_label and _held_shape:
		_held_label.text = _held_shape.get_label(_held_label_hint)


## Remove a placed piece from the grid and destroy its sprite.
func remove_piece(piece_id: int) -> void:
	grid_data.remove_piece(piece_id)
	_remove_piece_sprite(piece_id)
	queue_redraw()


## Mark a placed piece as fixed (false) or moveable (true).
func set_piece_moveable(piece_id: int, moveable: bool) -> void:
	_piece_moveable[piece_id] = moveable


## Mark a placed piece as toggleable (double-tap fires piece_double_tapped).
func set_piece_toggleable(piece_id: int, toggleable: bool) -> void:
	_piece_toggleable[piece_id] = toggleable


## Enable or disable the UNBUILT flash pulse on a piece.
func set_piece_flashing(piece_id: int, flashing: bool) -> void:
	_piece_flashing[piece_id] = flashing
	if not flashing and _piece_sprites.has(piece_id):
		_piece_sprites[piece_id].modulate = Color.WHITE


## Dim (active=false) or restore (active=true) a placed piece sprite.
func set_piece_active_visual(piece_id: int, active: bool) -> void:
	if _piece_sprites.has(piece_id):
		_piece_sprites[piece_id].modulate = Color(1, 1, 1, 1) if active else Color(0.35, 0.35, 0.35, 0.7)


## Provide the inventory panel Control so drop detection can test sprite overlap.
func set_inventory_control(c: Control) -> void:
	_inventory_control = c


## When true, a GRID-origin held piece that fails to place emits piece_released
## instead of snapping back.
## Call with true after picking up an UNBUILT piece.
## Automatically reset to false when the hold ends.
## Call this after piece_picked_up_from_grid if the manager wants to route the
## release elsewhere (e.g. cross-slot settler drag).
func set_held_discardable(discardable: bool) -> void:
	_held_discardable = discardable


## Set whether the currently held piece can be placed on this grid.
## When false, placement preview is hidden and grid drops are skipped.
func set_held_can_place(can_place: bool) -> void:
	_held_can_place = can_place
	queue_redraw()


## Enable or disable all input and visual feedback.
## Cancels any in-progress pending pickup or tap when set to false.
func set_grid_active(active: bool) -> void:
	grid_active = active
	if not active:
		_cancel_pending()
		_clear_tap()
	queue_redraw()


## Called when EventBus.merge_grid_closed fires. Override to suppress restore (e.g. KitchenGrid).
func _on_merge_grid_closed() -> void:
	set_grid_active(true)


## Block or unblock input for simulation.
## Cancels any in-progress pending pickup or tap when set to true.
func set_planning_locked(locked: bool) -> void:
	planning_locked = locked
	if locked:
		_cancel_pending()
		_clear_tap()
	queue_redraw()



## Returns the screen-space rect of this grid.
func get_screen_rect() -> Rect2:
	return Rect2(
		get_global_transform_with_canvas().get_origin(),
		Vector2(cols * cell_size, rows * cell_size)
	)


## Returns pixel size of the full grid.
func get_grid_pixel_size() -> Vector2:
	return Vector2(cols * cell_size, rows * cell_size)

# ---------------------------------------------------------------------------
# Sprite helpers
# ---------------------------------------------------------------------------

func _make_label(sz: int) -> Label:
	var lbl: Label = Label.new()
	lbl.size = Vector2(sz, sz)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	return lbl


func _show_held_sprite(shape: PieceShape) -> void:
	_held_sprite.texture = PieceSpriteGenerator.generate(shape, shape.color)
	_held_sprite.visible = true
	_held_label.text     = shape.get_label(_held_label_hint)
	_held_label.visible  = true
	_update_held_sprite_pos()


func _update_held_sprite_pos() -> void:
	if not _held_shape:
		return
	var origin: Vector2 = _effective_cursor_screen_pos()
	_held_sprite.position = origin + PieceSpriteGenerator.origin_offset(_held_shape)
	_held_label.position  = origin


func _create_piece_sprite(piece_id: int, shape: PieceShape, origin_cell: Vector2i) -> void:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.texture = PieceSpriteGenerator.generate(shape, shape.color)
	var bb: Rect2i = shape.get_bounding_rect()
	sprite.position = Vector2(
		(origin_cell.y + bb.position.y - 1) * cell_size,
		(origin_cell.x + bb.position.x - 1) * cell_size
	)
	var hint: String = _piece_label_hints.get(piece_id, "")
	var text: String = shape.get_label(hint)
	if not text.is_empty():
		var lbl: Label = _make_label(cell_size)
		lbl.text = text
		lbl.position = Vector2(-bb.position.y, -bb.position.x) * cell_size
		sprite.add_child(lbl)
	add_child(sprite)
	_piece_sprites[piece_id] = sprite


func _remove_piece_sprite(piece_id: int) -> void:
	if _piece_sprites.has(piece_id):
		_piece_sprites[piece_id].queue_free()
		_piece_sprites.erase(piece_id)
	_piece_label_hints.erase(piece_id)
	_piece_moveable.erase(piece_id)
	_piece_toggleable.erase(piece_id)
	_piece_flashing.erase(piece_id)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _drag_offset_vec() -> Vector2:
	if Settings.drag_offset and _held_shape != null:
		return Vector2(-cell_size, -cell_size * 1.5)
	return Vector2.ZERO


func _effective_cursor_pos() -> Vector2:
	return _cursor_pos + _drag_offset_vec()


func _effective_cursor_screen_pos() -> Vector2:
	return _cursor_screen_pos + _drag_offset_vec()


func _cell_rect(row: int, col: int) -> Rect2:
	return Rect2(
		(col - 1) * cell_size + 1,
		(row - 1) * cell_size + 1,
		cell_size - 2,
		cell_size - 2
	)


func _pos_to_cell(pos: Vector2) -> Vector2i:
	var col: int = int(floorf(pos.x / cell_size)) + 1
	var row: int = int(floorf(pos.y / cell_size)) + 1
	if grid_data.is_in_bounds(row, col):
		return Vector2i(row, col)
	return Vector2i(-1, -1)

# ---------------------------------------------------------------------------
# Shared input helpers
# ---------------------------------------------------------------------------

## Shared press logic for mouse (idx = -1) and touch.
## allow_tap: pass _active_touches.is_empty() for mouse, true for touch.
func _handle_input_press(source: InputSource, idx: int, screen_pos: Vector2, allow_tap: bool) -> void:
	if _held_shape:
		_drag_source = source
		if source == InputSource.TOUCH:
			_drag_touch_idx = idx
	elif _pending_source == PendingSource.INVENTORY and _pending_input == InputSource.NONE:
		_pending_input      = source
		_pending_screen_pos = screen_pos
		if source == InputSource.TOUCH:
			_pending_touch_idx = idx
	elif _pending_input == InputSource.NONE:
		var cell: Vector2i = _pos_to_cell(_cursor_pos)
		var cell_val: int  = grid_data.get_cell(cell.x, cell.y) if cell != Vector2i(-1, -1) else 0
		if cell_val > 0 and _piece_moveable.get(cell_val, true):
			_pending_input      = source
			_pending_screen_pos = screen_pos
			_pending_timer      = 0.0
			_pending_source     = PendingSource.GRID
			_pending_grid_cell  = cell
			if source == InputSource.TOUCH:
				_pending_touch_idx = idx
			if _piece_toggleable.get(cell_val, false) and allow_tap:
				_start_tap_down(cell_val, source, screen_pos, idx)
		elif cell_val > 0 and allow_tap:
			_start_tap_down(cell_val, source, screen_pos, idx)


## Shared release logic for mouse (idx = -1) and touch.
func _handle_input_release(source: InputSource, idx: int) -> void:
	if _drag_source == source and (source == InputSource.MOUSE or idx == _drag_touch_idx):
		_drag_source = InputSource.NONE
		if source == InputSource.TOUCH:
			_drag_touch_idx = -1
		if _held_shape:
			_try_place_or_return()
	elif _pending_input == source and (source == InputSource.MOUSE or idx == _pending_touch_idx):
		if _pending_source == PendingSource.GRID and _pending_grid_cell != Vector2i(-1, -1):
			var cv: int = grid_data.get_cell(_pending_grid_cell.x, _pending_grid_cell.y)
			if cv > 0 and _tap_piece_id == cv:
				if _tap_state == TapState.DOWN:
					_tap_state = TapState.WINDOW
					_tap_timer = 0.0
					if source == InputSource.TOUCH:
						_tap_touch_idx = -1
				elif _tap_state == TapState.LOCKED:
					_clear_tap()
		_cancel_pending()
	elif _pending_source == PendingSource.INVENTORY and _pending_input == InputSource.NONE:
		_cancel_pending()
	elif _held_shape and _drag_source == InputSource.NONE:
		_try_place_or_return()
	elif _tap_state == TapState.DOWN and _tap_input == source \
			and (source == InputSource.MOUSE or idx == _tap_touch_idx):
		_tap_state = TapState.WINDOW
		_tap_timer = 0.0
		if source == InputSource.TOUCH:
			_tap_touch_idx = -1
	elif _tap_state == TapState.LOCKED and _tap_input == source \
			and (source == InputSource.MOUSE or idx == _tap_touch_idx):
		_clear_tap()


# ---------------------------------------------------------------------------
# Tap-detection helpers
# ---------------------------------------------------------------------------

func _start_tap_down(piece_id: int, source: InputSource, screen_pos: Vector2, touch_idx: int) -> void:
	if _tap_state == TapState.WINDOW and _tap_piece_id == piece_id:
		emit_signal("piece_double_tapped", piece_id)
		_tap_state      = TapState.LOCKED
		_tap_timer      = 0.0
		_tap_input      = source
		_tap_touch_idx  = touch_idx
	elif (_tap_state == TapState.DOWN and _tap_piece_id == piece_id) or _tap_state == TapState.LOCKED:
		pass
	else:
		_tap_state      = TapState.DOWN
		_tap_piece_id   = piece_id
		_tap_timer      = 0.0
		_tap_input      = source
		_tap_touch_idx  = touch_idx
		_tap_screen_pos = screen_pos


func _clear_tap() -> void:
	_tap_state      = TapState.NONE
	_tap_piece_id   = -1
	_tap_timer      = 0.0
	_tap_input      = InputSource.NONE
	_tap_touch_idx  = -1
	_tap_screen_pos = Vector2.ZERO
