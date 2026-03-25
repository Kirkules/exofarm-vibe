class_name FarmGrid
extends Node2D

const CELL_SIZE := 32
const ROWS := 6
const COLS := 8

## Vertical offset applied to dragged piece when Settings.drag_offset is true,
## so the piece appears above the player's finger.
const DRAG_OFFSET_PX := -CELL_SIZE * 2

## Pickup requires either a drag of this many pixels or a hold this many seconds.
const PICKUP_DRAG_THRESHOLD_SQ: float = 16.0 * 16.0
const PICKUP_HOLD_TIME:         float = 0.5
const TAP_DOUBLE_WINDOW:        float = 0.5

const COLOR_EMPTY    := Color(0.18, 0.18, 0.18)
const COLOR_BORDER   := Color(0.08, 0.08, 0.08)
const COLOR_HOVER    := Color(0.25, 0.35, 0.25)
const COLOR_VALID    := Color(0.30, 0.65, 0.30, 0.65)
const COLOR_INVALID  := Color(0.65, 0.25, 0.25, 0.65)
const COLOR_EFFECT         := Color(0.90, 0.75, 0.20, 0.28)
const COLOR_POWER_RANGE    := Color(0.35, 0.70, 1.00, 0.18)  # sufficient network
const COLOR_POWER_WEAK     := Color(0.95, 0.50, 0.20, 0.18)  # insufficient network

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

## Where the currently held piece came from; determines where it goes on a failed drop.
enum HeldOrigin { NONE, GRID, INVENTORY }
var _held_origin:      HeldOrigin = HeldOrigin.NONE
var _held_origin_cell: Vector2i   = Vector2i(-1, -1)  # only valid when _held_origin == GRID
var _held_origin_shape: PieceShape = null              # shape at pickup (pre-rotation)

# _cursor_pos: FarmGrid-local coordinates — used for grid cell snapping and preview.
# _cursor_screen_pos: raw viewport pixel coordinates — used for the held sprite on the
#   CanvasLayer, whose coordinate space is screen pixels (independent of scene position).
var _cursor_pos:        Vector2  = Vector2.ZERO
var _cursor_screen_pos: Vector2  = Vector2.ZERO
# Vector2i(-1, -1) means "no cell" — no clean alternative without Optional types.
var _hovered_cell:      Vector2i = Vector2i(-1, -1)

# ---------------------------------------------------------------------------
# Input-source tracking
# ---------------------------------------------------------------------------
## Which input device is currently driving a drag or pending pickup.
enum InputSource { NONE, MOUSE, TOUCH }

# Active drag: which device is moving the held piece.
var _drag_source:    InputSource = InputSource.NONE
var _drag_touch_idx: int         = -1  # finger index; only meaningful when _drag_source == TOUCH

# Multi-touch: only real touch finger indices (mouse tracked separately via _mouse_held).
var _active_touches: Dictionary = {}  # finger index -> true
var _mouse_held:     bool       = false

# ---------------------------------------------------------------------------
# Pending-pickup threshold tracking
# ---------------------------------------------------------------------------
## Which game object a pending pickup targets.
enum PendingSource { NONE, GRID, INVENTORY }

var _pending_source:    PendingSource = PendingSource.NONE
var _pending_input:     InputSource   = InputSource.NONE
var _pending_touch_idx: int           = -1  # only meaningful when _pending_input == TOUCH
var _pending_screen_pos: Vector2      = Vector2.ZERO
var _pending_timer:      float        = 0.0
var _pending_grid_cell:  Vector2i     = Vector2i(-1, -1)
var _pending_inv_item:   InventoryItem = null

# ---------------------------------------------------------------------------
# Tap-detection (non-moveable fixed buildings)
# ---------------------------------------------------------------------------
## Two taps on the same non-moveable piece within TAP_DOUBLE_WINDOW seconds
## emits piece_double_tapped. Single taps and tap-holds are silently consumed.
enum TapState { NONE, DOWN, WINDOW, LOCKED }
var _tap_state:      TapState    = TapState.NONE
var _tap_piece_id:   int         = -1
var _tap_timer:      float       = 0.0
var _tap_input:      InputSource = InputSource.NONE
var _tap_touch_idx:  int         = -1
var _tap_screen_pos: Vector2     = Vector2.ZERO

# Recorded on every press so begin_pending_inventory_hold() can claim it.
var _last_touch_idx: int     = -1   # last real touch finger index; -1 = none yet
var _last_input_pos: Vector2 = Vector2.ZERO  # position of last press (touch or mouse)

var has_pending_pickup: bool:
	get: return _pending_input != InputSource.NONE

# Sprites: one per placed piece, plus one that follows the cursor while holding.
var _piece_sprites:      Dictionary = {}  # piece_id -> Sprite2D
var _piece_label_hints:  Dictionary = {}  # piece_id -> String (display name for label)
var _piece_moveable:     Dictionary = {}  # piece_id -> bool (false = fixed, cannot be picked up)
var _piece_toggleable:   Dictionary = {}  # piece_id -> bool (true = double-tap fires piece_double_tapped)
var _held_sprite:        Sprite2D   = null
var _held_label:         Label      = null
var _held_label_hint:    String     = ""
# Dedicated CanvasLayer above all UI so the dragged sprite renders on top.
var _held_sprite_layer: CanvasLayer = null

# Set by game.gd so drop detection can test whether the sprite overlaps the panel.
var _inventory_control: Control = null

# Power range overlay data. Each entry: {row, col, range, sufficient}.
# Repopulated by game.gd after every grid change via set_power_overlay().
var _power_sources: Array = []
# Power range of the currently held piece (0 = none). Set by game.gd on pickup.
var _held_power_range: int = 0

## When false, all player input is ignored (e.g. during season simulation).
var planning_active: bool = true

signal piece_picked_up_from_grid(piece_id: int, shape: PieceShape)
signal piece_placed_on_grid(piece_id: int)
## Emitted when a piece from the inventory is released without a valid grid placement.
signal piece_hold_cancelled(shape: PieceShape)
## Emitted when a piece originally from the grid snaps back to its previous position.
signal piece_returned_to_grid(piece_id: int)
## Emitted when the drag/hold threshold is met for an inventory item pending pickup.
signal inventory_item_pickup_confirmed(item: InventoryItem)
## Emitted when a non-moveable building is double-tapped (two taps within TAP_DOUBLE_WINDOW).
signal piece_double_tapped(piece_id: int)

func _ready() -> void:
	grid_data = GridData.new(ROWS, COLS)

	# Place the held sprite on a CanvasLayer above all other layers (including UILayer)
	# so it is never obscured by the inventory panel.
	_held_sprite_layer = CanvasLayer.new()
	_held_sprite_layer.layer = 100
	add_child(_held_sprite_layer)

	_held_sprite = Sprite2D.new()
	_held_sprite.centered = false
	_held_sprite.visible = false
	_held_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_held_sprite_layer.add_child(_held_sprite)

	_held_label = Label.new()
	_held_label.size = Vector2(CELL_SIZE, CELL_SIZE)
	_held_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_held_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_held_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_held_label.visible = false
	_held_label.add_theme_font_size_override("font_size", 8)
	_held_label.add_theme_color_override("font_color", Color.WHITE)
	_held_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	_held_label.add_theme_constant_override("shadow_offset_x", 1)
	_held_label.add_theme_constant_override("shadow_offset_y", 1)
	_held_sprite_layer.add_child(_held_label)

func _process(delta: float) -> void:
	if not planning_active:
		return
	if _pending_input != InputSource.NONE:
		_pending_timer += delta
		if _pending_timer >= PICKUP_HOLD_TIME:
			_confirm_pending()
	if _tap_state != TapState.NONE:
		_tap_timer += delta
		if _tap_state == TapState.DOWN and _tap_timer >= PICKUP_HOLD_TIME:
			_clear_tap()  # tap-hold: no-op for now
		elif _tap_state == TapState.WINDOW and _tap_timer >= TAP_DOUBLE_WINDOW:
			_clear_tap()  # single-tap window expired, no action
		elif _tap_state == TapState.LOCKED and _tap_timer >= PICKUP_HOLD_TIME:
			_clear_tap()  # safety escape in case release was never delivered

# ---------------------------------------------------------------------------
# Drawing
# ---------------------------------------------------------------------------

func _draw() -> void:
	_draw_cells()
	_draw_power_overlays()
	_draw_effect_overlays()
	if _held_shape:
		_draw_placement_preview()

func _draw_cells() -> void:
	for row in range(1, ROWS + 1):
		for col in range(1, COLS + 1):
			var rect: Rect2 = _cell_rect(row, col)
			var val: int = grid_data.get_cell(row, col)
			var color: Color
			if Vector2i(row, col) == _hovered_cell and val == 0:
				color = COLOR_HOVER
			else:
				color = COLOR_EMPTY

			draw_rect(rect, color)
			draw_rect(rect, COLOR_BORDER, false)

func _draw_power_overlays() -> void:
	# Preview for the currently held piece, anchored to the snapped cursor position.
	if _held_power_range > 0 and _held_shape != null:
		var origin: Vector2i = _pos_to_cell(_effective_cursor_pos())
		if origin != Vector2i(-1, -1):
			var preview: Color = Color(COLOR_POWER_RANGE.r, COLOR_POWER_RANGE.g, COLOR_POWER_RANGE.b, 0.28)
			for r: int in range(1, ROWS + 1):
				for c: int in range(1, COLS + 1):
					if absi(origin.x - r) + absi(origin.y - c) <= _held_power_range:
						draw_rect(_cell_rect(r, c), preview)
	# Permanent overlays for placed power sources.
	for src: Dictionary in _power_sources:
		var color: Color = COLOR_POWER_RANGE if src["sufficient"] else COLOR_POWER_WEAK
		var row: int = src["row"]
		var col: int = src["col"]
		var range_val: int = src["range"]
		for r: int in range(1, ROWS + 1):
			for c: int in range(1, COLS + 1):
				if absi(row - r) + absi(col - c) <= range_val:
					draw_rect(_cell_rect(r, c), color)

func _draw_effect_overlays() -> void:
	if not _held_shape or _held_shape.effect_range <= 0:
		return
	var origin: Vector2i = _pos_to_cell(_effective_cursor_pos())
	if origin == Vector2i(-1, -1):
		return
	# Collect the cells the piece would occupy at this cursor position.
	var piece_cells: Array[Vector2i] = []
	for offset: Vector2i in _held_shape.offsets:
		piece_cells.append(Vector2i(origin.x + offset.x, origin.y + offset.y))
	# Highlight empty cells within effect_range of any piece cell, excluding
	# the piece's own would-be cells (covered by the placement preview).
	for row: int in range(1, ROWS + 1):
		for col: int in range(1, COLS + 1):
			var cell: Vector2i = Vector2i(row, col)
			if piece_cells.has(cell):
				continue
			if grid_data.get_cell(row, col) != 0:
				continue
			for pc: Vector2i in piece_cells:
				if absi(row - pc.x) + absi(col - pc.y) <= _held_shape.effect_range:
					draw_rect(_cell_rect(row, col), COLOR_EFFECT)
					break

func _draw_placement_preview() -> void:
	var origin: Vector2i = _pos_to_cell(_effective_cursor_pos())
	if origin == Vector2i(-1, -1):
		return
	var valid: bool = grid_data.can_place(_held_shape, origin.x, origin.y)
	var color: Color = COLOR_VALID if valid else COLOR_INVALID
	for offset: Vector2i in _held_shape.offsets:
		var r: int = origin.x + offset.x
		var c: int = origin.y + offset.y
		if grid_data.is_in_bounds(r, c):
			draw_rect(_cell_rect(r, c), color)

# ---------------------------------------------------------------------------
# Input
# ---------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if not planning_active:
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
				if _held_shape:
					_drag_source = InputSource.MOUSE
				elif _pending_source == PendingSource.INVENTORY and _pending_input == InputSource.NONE:
					# begin_pending_inventory_hold set source before _input ran.
					_pending_input      = InputSource.MOUSE
					_pending_screen_pos = event.position
				elif _pending_input == InputSource.NONE:
					var cell: Vector2i = _pos_to_cell(_cursor_pos)
					var cell_val: int = grid_data.get_cell(cell.x, cell.y) if cell != Vector2i(-1, -1) else 0
					if cell_val > 0 and _piece_moveable.get(cell_val, true):
						_pending_input      = InputSource.MOUSE
						_pending_screen_pos = event.position
						_pending_timer      = 0.0
						_pending_source     = PendingSource.GRID
						_pending_grid_cell  = cell
						if _piece_toggleable.get(cell_val, false) and _active_touches.is_empty():
							_start_tap_down(cell_val, InputSource.MOUSE, event.position, -1)
					elif cell_val > 0 and _active_touches.is_empty():
						_start_tap_down(cell_val, InputSource.MOUSE, event.position, -1)
			else:
				_mouse_held = false
				if _drag_source == InputSource.MOUSE:
					_drag_source = InputSource.NONE
					if _held_shape:
						_try_place_or_return()
				elif _pending_input == InputSource.MOUSE:
					if _pending_source == PendingSource.GRID and _pending_grid_cell != Vector2i(-1, -1):
						var cv: int = grid_data.get_cell(_pending_grid_cell.x, _pending_grid_cell.y)
						if cv > 0 and _tap_piece_id == cv:
							if _tap_state == TapState.DOWN:
								_tap_state = TapState.WINDOW
								_tap_timer = 0.0
							elif _tap_state == TapState.LOCKED:
								_clear_tap()
					_cancel_pending()
				elif _pending_source == PendingSource.INVENTORY and _pending_input == InputSource.NONE:
					_cancel_pending()
				elif _held_shape and _drag_source == InputSource.NONE:
					_try_place_or_return()
				elif _tap_state == TapState.DOWN and _tap_input == InputSource.MOUSE:
					_tap_state = TapState.WINDOW
					_tap_timer = 0.0
				elif _tap_state == TapState.LOCKED and _tap_input == InputSource.MOUSE:
					_clear_tap()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and _held_shape:
			rotate_held_cw()
		queue_redraw()

	elif event is InputEventScreenTouch:
		if event.pressed:
			_active_touches[event.index] = true
			_last_touch_idx = event.index
			_last_input_pos = event.position

			# Second finger while holding a piece: rotate, don't pick up or place.
			if _held_shape and _active_touches.size() > 1:
				rotate_held_cw()
				return

			_cursor_screen_pos = event.position
			_cursor_pos        = to_local(event.position)

			if _held_shape:
				# Confirmed hold (e.g. after inventory confirm + redrag); claim finger.
				_drag_source    = InputSource.TOUCH
				_drag_touch_idx = event.index
			elif _pending_source == PendingSource.INVENTORY and _pending_input == InputSource.NONE:
				# begin_pending_inventory_hold set source before _input ran (GUI-first ordering).
				_pending_input      = InputSource.TOUCH
				_pending_touch_idx  = event.index
				_pending_screen_pos = event.position
			elif _pending_input == InputSource.NONE:
				var cell: Vector2i = _pos_to_cell(_cursor_pos)
				var cell_val: int = grid_data.get_cell(cell.x, cell.y) if cell != Vector2i(-1, -1) else 0
				if cell_val > 0 and _piece_moveable.get(cell_val, true):
					_pending_input      = InputSource.TOUCH
					_pending_touch_idx  = event.index
					_pending_screen_pos = event.position
					_pending_timer      = 0.0
					_pending_source     = PendingSource.GRID
					_pending_grid_cell  = cell
					if _piece_toggleable.get(cell_val, false):
						_start_tap_down(cell_val, InputSource.TOUCH, event.position, event.index)
				elif cell_val > 0:
					_start_tap_down(cell_val, InputSource.TOUCH, event.position, event.index)
		else:
			_active_touches.erase(event.index)
			if _drag_source == InputSource.TOUCH and event.index == _drag_touch_idx:
				_drag_source    = InputSource.NONE
				_drag_touch_idx = -1
				if _held_shape:
					_try_place_or_return()
			elif _pending_input == InputSource.TOUCH and event.index == _pending_touch_idx:
				if _pending_source == PendingSource.GRID and _pending_grid_cell != Vector2i(-1, -1):
					var cv: int = grid_data.get_cell(_pending_grid_cell.x, _pending_grid_cell.y)
					if cv > 0 and _tap_piece_id == cv:
						if _tap_state == TapState.DOWN:
							_tap_state     = TapState.WINDOW
							_tap_timer     = 0.0
							_tap_touch_idx = -1
						elif _tap_state == TapState.LOCKED:
							_clear_tap()
				_cancel_pending()
			elif _pending_source == PendingSource.INVENTORY and _pending_input == InputSource.NONE:
				# Finger released before _input claimed it (GUI-first, very fast tap).
				_cancel_pending()
			elif _held_shape and _drag_source == InputSource.NONE:
				# Held (confirmed) but no drag finger claimed yet; treat as tap-release.
				_try_place_or_return()
			elif _tap_state == TapState.DOWN and _tap_input == InputSource.TOUCH and event.index == _tap_touch_idx:
				_tap_state     = TapState.WINDOW
				_tap_timer     = 0.0
				_tap_touch_idx = -1
			elif _tap_state == TapState.LOCKED and _tap_input == InputSource.TOUCH and event.index == _tap_touch_idx:
				_clear_tap()
		queue_redraw()

	elif event is InputEventScreenDrag:
		if _pending_input == InputSource.TOUCH and event.index == _pending_touch_idx:
			# Always update cursor so sprite appears at the right spot on confirm.
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
	_clear_tap()  # a hold/drag pickup cancels any concurrent tap detection
	match _pending_source:
		PendingSource.GRID:
			var cell: Vector2i = _pending_grid_cell
			var val: int = grid_data.get_cell(cell.x, cell.y)
			if val > 0:
				var info: Dictionary = grid_data.get_piece_info(val)
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
				_held_sprite.texture = PieceSpriteGenerator.generate(shape, shape.color)
				_held_sprite.visible = true
				_held_label.text    = shape.get_label(_held_label_hint)
				_held_label.visible = true
				_update_held_sprite_pos()
				emit_signal("piece_picked_up_from_grid", val, shape)
		PendingSource.INVENTORY:
			if _pending_inv_item != null:
				var shape: PieceShape = (_pending_inv_item.data as PlaceableDefinition).shape
				_held_shape      = shape
				_held_origin     = HeldOrigin.INVENTORY
				_held_label_hint = _pending_inv_item.display_name
				_drag_source    = _pending_input
				_drag_touch_idx = _pending_touch_idx
				_held_sprite.texture = PieceSpriteGenerator.generate(shape, shape.color)
				_held_sprite.visible = true
				_held_label.text    = shape.get_label(_held_label_hint)
				_held_label.visible = true
				_update_held_sprite_pos()
				emit_signal("inventory_item_pickup_confirmed", _pending_inv_item)

	_pending_source    = PendingSource.NONE
	_pending_input     = InputSource.NONE
	_pending_touch_idx = -1
	_pending_timer     = 0.0
	_pending_inv_item  = null
	_pending_grid_cell = Vector2i(-1, -1)
	queue_redraw()

func _cancel_pending() -> void:
	_pending_source    = PendingSource.NONE
	_pending_input     = InputSource.NONE
	_pending_touch_idx = -1
	_pending_timer     = 0.0
	_pending_inv_item  = null
	_pending_grid_cell = Vector2i(-1, -1)

## Place on grid if valid; otherwise snap back to origin (grid or inventory).
func _try_place_or_return() -> void:
	# Use the sprite's center of mass to decide inventory vs grid. This correctly
	# handles drag offset: the cursor may be over the inventory while the sprite
	# (and the highlighted grid cell) are above it, or vice versa.
	var com_over_inv: bool = _sprite_com_over_inventory()
	if not com_over_inv:
		var cell: Vector2i = _pos_to_cell(_effective_cursor_pos())
		if cell != Vector2i(-1, -1):
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
	# CoM over inventory, or no valid grid placement — send to inventory or snap back.
	if com_over_inv or _held_origin == HeldOrigin.INVENTORY:
		var shape: PieceShape = _held_shape
		_held_shape = null
		_held_sprite.visible = false
		_held_label.visible  = false
		_held_label_hint     = ""
		_clear_held_origin()
		emit_signal("piece_hold_cancelled", shape)
		queue_redraw()
	else:
		_return_held_to_grid()

## Re-place the held piece at its original grid cell using its pre-rotation shape.
func _return_held_to_grid() -> void:
	var shape: PieceShape  = _held_origin_shape
	var cell: Vector2i     = _held_origin_cell
	var hint: String       = _held_label_hint
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
		# Cells unexpectedly occupied — fall back to inventory.
		_clear_held_origin()
		emit_signal("piece_hold_cancelled", shape)
	queue_redraw()

func _clear_held_origin() -> void:
	_held_origin       = HeldOrigin.NONE
	_held_origin_cell  = Vector2i(-1, -1)
	_held_origin_shape = null

## Returns true if the sprite's center of mass is over the inventory panel.
## Each cell's screen center = effective_cursor_screen_pos + (offset + 0.5) * CELL_SIZE,
## so the CoM = effective_cursor_screen_pos + (avg_offset + 0.5) * CELL_SIZE.
func _sprite_com_over_inventory() -> bool:
	if _inventory_control == null or _held_shape == null:
		return false
	var n: int        = _held_shape.offsets.size()
	var sum_col: float = 0.0
	var sum_row: float = 0.0
	for offset: Vector2i in _held_shape.offsets:
		sum_col += float(offset.y)
		sum_row += float(offset.x)
	var com: Vector2 = _effective_cursor_screen_pos() + Vector2(
		(sum_col / float(n) + 0.5) * CELL_SIZE,
		(sum_row / float(n) + 0.5) * CELL_SIZE
	)
	return _inventory_control.get_global_rect().has_point(com)

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Begin holding a piece (programmatic — skips threshold). Treats origin as inventory.
func hold_piece(shape: PieceShape, hint: String = "") -> void:
	_held_shape      = shape
	_held_origin     = HeldOrigin.INVENTORY
	_held_label_hint = hint
	_drag_source     = InputSource.NONE
	_held_sprite.texture = PieceSpriteGenerator.generate(shape, shape.color)
	_held_sprite.visible = true
	_held_label.text    = shape.get_label(hint)
	_held_label.visible = true
	_update_held_sprite_pos()
	queue_redraw()

## Called by game.gd when button_down fires on an inventory item.
## Records a pending inventory pickup; confirmed once the drag/hold threshold is met.
func begin_pending_inventory_hold(item: InventoryItem) -> void:
	if _pending_input != InputSource.NONE or _held_shape != null:
		return
	_pending_inv_item = item
	_pending_source   = PendingSource.INVENTORY
	_pending_timer    = 0.0
	# Claim the input source immediately if _input already processed the press.
	# If _input fires after GUI (platform-dependent ordering), the press handler
	# will claim it instead via the INVENTORY+NONE branch.
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
		_held_sprite.texture = PieceSpriteGenerator.generate(_held_shape, _held_shape.color)
		_update_held_sprite_pos()
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
## Called by game.gd after piece_picked_up_from_grid to supply the item name.
func set_held_hint(hint: String) -> void:
	_held_label_hint = hint
	if _held_label and _held_shape:
		_held_label.text = _held_shape.get_label(_held_label_hint)

## Mark a placed piece as fixed (false) or moveable (true).
## Called by game.gd after piece_placed_on_grid / piece_returned_to_grid.
func set_piece_moveable(piece_id: int, moveable: bool) -> void:
	_piece_moveable[piece_id] = moveable

## Mark a placed piece as toggleable (true = double-tap fires piece_double_tapped).
## Called by game.gd after piece_placed_on_grid / piece_returned_to_grid.
func set_piece_toggleable(piece_id: int, toggleable: bool) -> void:
	_piece_toggleable[piece_id] = toggleable

## Dim (active=false) or restore (active=true) a placed piece sprite.
func set_piece_active_visual(piece_id: int, active: bool) -> void:
	if _piece_sprites.has(piece_id):
		_piece_sprites[piece_id].modulate = Color(1, 1, 1, 1) if active else Color(0.35, 0.35, 0.35, 0.7)

## Provide the inventory panel Control so drop detection can test sprite overlap.
func set_inventory_control(c: Control) -> void:
	_inventory_control = c

## Update the power range overlay. Each entry: {row, col, range, sufficient}.
## Pass an empty array to clear all overlays.
func set_power_overlay(sources: Array) -> void:
	_power_sources = sources
	queue_redraw()

## Set the power range of the currently held piece for preview rendering.
## Call with 0 when the piece is placed, returned, or cancelled.
func set_held_power_range(power_range: int) -> void:
	_held_power_range = power_range
	queue_redraw()

## Returns pixel size of the full grid.
func get_grid_pixel_size() -> Vector2:
	return Vector2(COLS * CELL_SIZE, ROWS * CELL_SIZE)

# ---------------------------------------------------------------------------
# Sprite helpers
# ---------------------------------------------------------------------------

func _update_held_sprite_pos() -> void:
	if not _held_shape:
		return
	# The held sprite lives on a CanvasLayer whose coordinate space is viewport
	# pixels. Use _cursor_screen_pos (raw event.position) directly — no
	# scene-transform conversion needed.
	var origin: Vector2 = _effective_cursor_screen_pos()
	_held_sprite.position = origin + PieceSpriteGenerator.origin_offset(_held_shape)
	# Label sits over the origin cell (top-left = cursor pos); size matches one cell.
	_held_label.position = origin

func _create_piece_sprite(piece_id: int, shape: PieceShape, origin_cell: Vector2i) -> void:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.texture = PieceSpriteGenerator.generate(shape, shape.color)
	var bb: Rect2i = shape.get_bounding_rect()
	sprite.position = Vector2(
		(origin_cell.y + bb.position.y - 1) * CELL_SIZE,
		(origin_cell.x + bb.position.x - 1) * CELL_SIZE
	)
	# Label sits over the origin cell (offset 0,0) within the sprite's local space.
	var hint: String = _piece_label_hints.get(piece_id, "")
	var text: String = shape.get_label(hint)
	if not text.is_empty():
		var lbl: Label = Label.new()
		lbl.text = text
		# Position label at the origin cell's top-left within sprite-local coords.
		lbl.position = Vector2(-bb.position.y, -bb.position.x) * CELL_SIZE
		lbl.size = Vector2(CELL_SIZE, CELL_SIZE)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.add_theme_font_size_override("font_size", 8)
		lbl.add_theme_color_override("font_color", Color.WHITE)
		lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
		lbl.add_theme_constant_override("shadow_offset_x", 1)
		lbl.add_theme_constant_override("shadow_offset_y", 1)
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

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

## Returns cursor in FarmGrid-local space, with drag offset applied.
## Used for grid cell snapping and placement preview.
func _effective_cursor_pos() -> Vector2:
	if Settings.drag_offset and _held_shape != null:
		return _cursor_pos + Vector2(0, DRAG_OFFSET_PX)
	return _cursor_pos

## Returns cursor in viewport/screen pixels, with drag offset applied.
## Used for positioning the held sprite on the CanvasLayer.
func _effective_cursor_screen_pos() -> Vector2:
	if Settings.drag_offset and _held_shape != null:
		return _cursor_screen_pos + Vector2(0, DRAG_OFFSET_PX)
	return _cursor_screen_pos

func _cell_rect(row: int, col: int) -> Rect2:
	return Rect2(
		(col - 1) * CELL_SIZE + 1,
		(row - 1) * CELL_SIZE + 1,
		CELL_SIZE - 2,
		CELL_SIZE - 2
	)

func _pos_to_cell(pos: Vector2) -> Vector2i:
	var col: int = int(floorf(pos.x / CELL_SIZE)) + 1
	var row: int = int(floorf(pos.y / CELL_SIZE)) + 1
	if grid_data.is_in_bounds(row, col):
		return Vector2i(row, col)
	return Vector2i(-1, -1)

# ---------------------------------------------------------------------------
# Tap-detection helpers
# ---------------------------------------------------------------------------

## Called on every press targeting a non-moveable piece.
## If we are already in WINDOW state for the same piece, emit double-tap and clear.
## Otherwise, start (or restart) the DOWN state for this piece.
func _start_tap_down(piece_id: int, source: InputSource, screen_pos: Vector2, touch_idx: int) -> void:
	if _tap_state == TapState.WINDOW and _tap_piece_id == piece_id:
		emit_signal("piece_double_tapped", piece_id)
		# Transition to LOCKED so the release of THIS press is consumed without
		# starting a new WINDOW state. Two fresh taps are required to retrigger.
		_tap_state      = TapState.LOCKED
		_tap_timer      = 0.0
		_tap_input      = source
		_tap_touch_idx  = touch_idx
	elif (_tap_state == TapState.DOWN and _tap_piece_id == piece_id) or _tap_state == TapState.LOCKED:
		# Another input path (touch or emulated mouse) already claimed this gesture.
		# Ignore regardless of event ordering.
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

## Enable or disable planning input. Disabling cancels any in-progress
## pending-pickup or tap so no stale state carries into simulation.
func set_planning_active(v: bool) -> void:
	planning_active = v
	if not v:
		_cancel_pending()
		_clear_tap()
