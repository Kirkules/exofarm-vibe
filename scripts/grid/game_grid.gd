class_name GameGrid
extends Node2D

## Base class for all interactive grids in the game.
##
## Owns grid state, piece sprites, and the draw pipeline.
## Input and drag lifecycle are handled entirely by PieceInputController.
## Register this grid with PieceInputController via register_pickup_source /
## register_drop_target, then call setup_pic() so hover signals are wired.
##
## Dimensions are set via rows/cols/cell_size before _ready() runs
## (e.g. in a subclass _ready() before calling super._ready()).
##
## Visual locking:
##   grid_active = false    → fully dormant: no hover, no preview, no drop acceptance
##   planning_locked = true → visible and rendered, but hover/preview suppressed

## Default dimensions — subclasses override before super._ready().
var rows:      int = 6
var cols:      int = 8
var cell_size: int = 32

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

## Cell highlighted under the cursor when not dragging (plain hover).
var _hovered_cell:  Vector2i = Vector2i(-1, -1)
## Cell and shape set during an active drag (placement preview source).
var _hover_cell:    Vector2i = Vector2i(-1, -1)
var _hover_shape:   PieceShape = null


# ---------------------------------------------------------------------------
# Piece sprite / display tracking
# ---------------------------------------------------------------------------
var _piece_sprites:     Dictionary = {}  # piece_id -> Sprite2D
var _piece_label_hints: Dictionary = {}  # piece_id -> String
var _piece_moveable:    Dictionary = {}  # piece_id -> bool
var _piece_toggleable:  Dictionary = {}  # piece_id -> bool
var _piece_flashing:    Dictionary = {}  # piece_id -> bool
var _flash_time:        float      = 0.0

# ---------------------------------------------------------------------------
# Locking — visual gates only (input routing lives in PieceInputController)
# ---------------------------------------------------------------------------
## When false, the grid is dormant: no hover rendering, no drop acceptance.
var grid_active: bool = true

## When true, input is blocked but the grid renders normally.
var planning_locked: bool = false

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
signal piece_placed_on_grid(piece_id: int)
## Emitted by lift_piece() when PIC picks up a piece from this grid.
signal piece_lifted_from_grid(piece_id: int)


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	grid_data = GridData.new(rows, cols)
	EventBus.simulation_started.connect(func() -> void: set_planning_locked(true))
	EventBus.simulation_ended.connect(func() -> void: set_planning_locked(false))
	EventBus.log_overlay_opened.connect(func() -> void: set_planning_locked(true))
	EventBus.log_overlay_closed.connect(func() -> void: set_planning_locked(false))


func _process(delta: float) -> void:
	_flash_time = fmod(_flash_time + delta, 0.5)
	for piece_id: int in _piece_flashing:
		if _piece_flashing[piece_id] and _piece_sprites.has(piece_id):
			var alpha: float = 0.75 + 0.25 * cos(TAU * _flash_time / 0.5)
			_piece_sprites[piece_id].modulate = Color(1.0, 1.0, 1.0, alpha)


## Wire this grid to a PieceInputController for hover and drag feedback.
## Call once from game.gd / manager after registration.
func setup_pic(pic: PieceInputController) -> void:
	pic.drag_moved.connect(_on_drag_moved)
	pic.drag_ended.connect(clear_hover)


# ---------------------------------------------------------------------------
# Drawing
# ---------------------------------------------------------------------------

func _draw() -> void:
	_draw_cells()
	if grid_active:
		_draw_grid_overlays()
		if not planning_locked and _hover_shape != null:
			_draw_placement_preview()


## Override in subclasses to draw grid-specific overlays (power ranges, etc.).
func _draw_grid_overlays() -> void:
	pass


## Override in subclasses to block placement on specific cells (e.g. inactive slots).
func _can_place_at_cell(_cell: Vector2i) -> bool:
	return true


func _draw_cells() -> void:
	for row: int in range(1, rows + 1):
		for col: int in range(1, cols + 1):
			var rect: Rect2  = _cell_rect(row, col)
			var val: int     = grid_data.get_cell(row, col)
			var color: Color
			if grid_active and not planning_locked \
					and Vector2i(row, col) == _hovered_cell and val == 0 \
					and _hover_shape == null:
				color = color_hover
			else:
				color = color_empty
			draw_rect(rect, color)
			draw_rect(rect, color_border, false)


func _draw_placement_preview() -> void:
	if _hover_cell == Vector2i(-1, -1) or _hover_shape == null:
		return
	var valid: bool  = grid_data.can_place(_hover_shape, _hover_cell.x, _hover_cell.y) \
		and _can_place_at_cell(_hover_cell)
	var color: Color = color_valid if valid else color_invalid
	for offset: Vector2i in _hover_shape.offsets:
		var r: int = _hover_cell.x + offset.x
		var c: int = _hover_cell.y + offset.y
		if grid_data.is_in_bounds(r, c):
			draw_rect(_cell_rect(r, c), color)


# ---------------------------------------------------------------------------
# Hover — driven by PieceInputController signals
# ---------------------------------------------------------------------------

## Called by PIC on cursor motion when not dragging.
func update_cursor_hover(screen_pos: Vector2) -> void:
	if not grid_active or planning_locked:
		if _hovered_cell != Vector2i(-1, -1):
			_hovered_cell = Vector2i(-1, -1)
			queue_redraw()
		return
	var local_pos: Vector2 = to_local(screen_pos)
	var col: int = int(floorf(local_pos.x / float(cell_size))) + 1
	var row: int = int(floorf(local_pos.y / float(cell_size))) + 1
	var new_cell: Vector2i
	if grid_data.is_in_bounds(row, col):
		new_cell = Vector2i(row, col)
	else:
		new_cell = Vector2i(-1, -1)
	if new_cell != _hovered_cell:
		_hovered_cell = new_cell
		queue_redraw()


## Called when PIC emits drag_moved. Updates placement preview state.
func _on_drag_moved(cursor_screen: Vector2, shape: PieceShape, _payload: Variant) -> void:
	if not grid_active:
		if _hover_cell != Vector2i(-1, -1) or _hover_shape != null:
			_hover_cell  = Vector2i(-1, -1)
			_hover_shape = null
			queue_redraw()
		return
	var local_pos: Vector2 = to_local(cursor_screen)
	var col: int = int(floorf(local_pos.x / float(cell_size))) + 1
	var row: int = int(floorf(local_pos.y / float(cell_size))) + 1
	var new_cell: Vector2i
	if grid_data.is_in_bounds(row, col):
		new_cell = Vector2i(row, col)
	else:
		new_cell = Vector2i(-1, -1)
	var changed: bool = new_cell != _hover_cell or shape != _hover_shape
	_hover_cell  = new_cell
	_hover_shape = shape
	if changed:
		queue_redraw()


## Clear placement preview (connected to PIC.drag_ended in setup_pic()).
func clear_hover() -> void:
	var had_hover: bool = _hover_cell != Vector2i(-1, -1) or _hover_shape != null
	_hover_cell  = Vector2i(-1, -1)
	_hover_shape = null
	if had_hover:
		queue_redraw()


# ---------------------------------------------------------------------------
# Drop acceptance — override in subclasses for type / capacity filtering
# ---------------------------------------------------------------------------

## Try to place a held piece on this grid at the best cell near cursor_screen.
## cursor_screen: effective drag position in screen coordinates (drag offset applied).
## payload: opaque value from PIC (InventoryItem in current usage).
## hint: display name for the placed piece label.
## Returns the new piece_id, or -1 if this grid does not accept the drop.
func try_receive_drop(cursor_screen: Vector2, shape: PieceShape,
		_payload: Variant, hint: String) -> int:
	if not grid_active or planning_locked:
		return -1
	var local_pos: Vector2 = to_local(cursor_screen)
	var col: int = int(floorf(local_pos.x / float(cell_size))) + 1
	var row: int = int(floorf(local_pos.y / float(cell_size))) + 1
	var cell: Vector2i
	if grid_data.is_in_bounds(row, col):
		cell = Vector2i(row, col)
	else:
		return -1
	if not _can_place_at_cell(cell):
		return -1
	if not grid_data.can_place(shape, cell.x, cell.y):
		return -1
	var piece_id: int = grid_data.place_piece(shape, cell.x, cell.y)
	if piece_id == -1:
		return -1
	_piece_label_hints[piece_id] = hint
	_create_piece_sprite(piece_id, shape, cell)
	piece_placed_on_grid.emit(piece_id)
	queue_redraw()
	return piece_id


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Remove a piece from the grid and return its shape (called by PIC on pickup).
## Returns null if the piece does not exist.
func lift_piece(piece_id: int) -> PieceShape:
	var info: Dictionary = grid_data.get_piece_info(piece_id)
	if info.is_empty():
		return null
	var shape: PieceShape = info["shape"] as PieceShape
	grid_data.remove_piece(piece_id)
	_remove_piece_sprite(piece_id)
	piece_lifted_from_grid.emit(piece_id)
	queue_redraw()
	return shape


## Directly place a piece on the grid without going through the hold flow.
## Emits piece_placed_on_grid. Returns piece_id or -1 on failure.
func place_piece_at(shape: PieceShape, row: int, col: int, hint: String = "") -> int:
	if not grid_data.can_place(shape, row, col):
		return -1
	var piece_id: int = grid_data.place_piece(shape, row, col)
	_piece_label_hints[piece_id] = hint
	_create_piece_sprite(piece_id, shape, Vector2i(row, col))
	piece_placed_on_grid.emit(piece_id)
	queue_redraw()
	return piece_id


## Remove a placed piece from the grid and destroy its sprite.
func remove_piece(piece_id: int) -> void:
	grid_data.remove_piece(piece_id)
	_remove_piece_sprite(piece_id)
	queue_redraw()


## Returns true if a piece is moveable (can be picked up by PIC).
func is_piece_moveable(piece_id: int) -> bool:
	return _piece_moveable.get(piece_id, true)


## Returns true if a piece supports double-tap toggle.
func is_piece_toggleable(piece_id: int) -> bool:
	return _piece_toggleable.get(piece_id, false)


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
		_piece_sprites[piece_id].modulate = Color(1, 1, 1, 1) if active \
			else Color(0.35, 0.35, 0.35, 0.7)


## Returns the screen-space rect of this grid.
func get_screen_rect() -> Rect2:
	return Rect2(
		get_global_transform_with_canvas().get_origin(),
		Vector2(cols * cell_size, rows * cell_size)
	)


## Returns pixel size of the full grid.
func get_grid_pixel_size() -> Vector2:
	return Vector2(cols * cell_size, rows * cell_size)


## Enable or disable all input and visual feedback.
func set_grid_active(active: bool) -> void:
	grid_active = active
	if not active:
		_hovered_cell = Vector2i(-1, -1)
		_hover_cell   = Vector2i(-1, -1)
		_hover_shape  = null
	queue_redraw()


## Block or unblock input for simulation.
func set_planning_locked(locked: bool) -> void:
	planning_locked = locked
	if locked:
		_hovered_cell = Vector2i(-1, -1)
		_hover_cell   = Vector2i(-1, -1)
		_hover_shape  = null
	queue_redraw()


# ---------------------------------------------------------------------------
# Sprite helpers
# ---------------------------------------------------------------------------

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


func _create_piece_sprite(piece_id: int, shape: PieceShape, origin_cell: Vector2i) -> void:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.centered       = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.texture        = PieceSpriteGenerator.generate(shape, shape.color)
	var bb: Rect2i        = shape.get_bounding_rect()
	sprite.position       = Vector2(
		(origin_cell.y + bb.position.y - 1) * cell_size,
		(origin_cell.x + bb.position.x - 1) * cell_size
	)
	var hint: String = _piece_label_hints.get(piece_id, "")
	var text: String = shape.get_label(hint)
	if not text.is_empty():
		var lbl: Label = _make_label(cell_size)
		lbl.text     = text
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

func _cell_rect(row: int, col: int) -> Rect2:
	return Rect2(
		(col - 1) * cell_size + 1,
		(row - 1) * cell_size + 1,
		cell_size - 2,
		cell_size - 2
	)
