class_name FarmGrid
extends Node2D

const CELL_SIZE := 32
const ROWS := 6
const COLS := 8

## Vertical offset applied to dragged piece when Settings.drag_offset is true,
## so the piece appears above the player's finger.
const DRAG_OFFSET_PX := -CELL_SIZE * 2

const COLOR_EMPTY    := Color(0.18, 0.18, 0.18)
const COLOR_BORDER   := Color(0.08, 0.08, 0.08)
const COLOR_HOVER    := Color(0.25, 0.35, 0.25)
const COLOR_VALID    := Color(0.30, 0.65, 0.30, 0.65)
const COLOR_INVALID  := Color(0.65, 0.25, 0.25, 0.65)

# Piece fill colours cycle by piece_id for visual distinction.
const PIECE_COLORS: Array = [
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
var _cursor_pos: Vector2 = Vector2.ZERO
var _hovered_cell: Vector2i = Vector2i(-1, -1)

signal piece_picked_up_from_grid(piece_id: int, shape: PieceShape)
signal piece_placed_on_grid(piece_id: int)

func _ready() -> void:
	grid_data = GridData.new(ROWS, COLS)

# ---------------------------------------------------------------------------
# Drawing
# ---------------------------------------------------------------------------

func _draw() -> void:
	_draw_cells()
	if _held_shape:
		_draw_placement_preview()

func _draw_cells() -> void:
	for row in range(1, ROWS + 1):
		for col in range(1, COLS + 1):
			var rect := _cell_rect(row, col)
			var val := grid_data.get_cell(row, col)
			var color: Color
			if val > 0:
				color = PIECE_COLORS[(val - 1) % PIECE_COLORS.size()]
			elif Vector2i(row, col) == _hovered_cell:
				color = COLOR_HOVER
			else:
				color = COLOR_EMPTY
			draw_rect(rect, color)
			draw_rect(rect, COLOR_BORDER, false)

func _draw_placement_preview() -> void:
	var origin := _pos_to_cell(_effective_cursor_pos())
	if origin == Vector2i(-1, -1):
		return
	var valid := grid_data.can_place(_held_shape, origin.x, origin.y)
	var color := COLOR_VALID if valid else COLOR_INVALID
	for offset in _held_shape.offsets:
		var r := origin.x + offset.x
		var c := origin.y + offset.y
		if grid_data.is_in_bounds(r, c):
			draw_rect(_cell_rect(r, c), color)

# ---------------------------------------------------------------------------
# Input
# ---------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_cursor_pos = to_local(event.position)
		_hovered_cell = _pos_to_cell(_cursor_pos)
		queue_redraw()
	elif event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_cursor_pos = to_local(event.position)
			_handle_tap(_cursor_pos)
	elif event is InputEventScreenTouch:
		_cursor_pos = to_local(event.position)
		if event.pressed:
			_handle_tap(_cursor_pos)
		queue_redraw()
	elif event is InputEventScreenDrag:
		_cursor_pos = to_local(event.position)
		_hovered_cell = _pos_to_cell(_cursor_pos)
		queue_redraw()

func _handle_tap(local_pos: Vector2) -> void:
	var cell := _pos_to_cell(_effective_cursor_pos())
	if cell == Vector2i(-1, -1):
		return

	if _held_shape:
		var piece_id := grid_data.place_piece(_held_shape, cell.x, cell.y)
		if piece_id != -1:
			_held_shape = null
			emit_signal("piece_placed_on_grid", piece_id)
			queue_redraw()
	else:
		var val := grid_data.get_cell(cell.x, cell.y)
		if val > 0:
			var info := grid_data.get_piece_info(val)
			var shape: PieceShape = info["shape"]
			grid_data.remove_piece(val)
			_held_shape = shape
			emit_signal("piece_picked_up_from_grid", val, shape)
			queue_redraw()

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Begin holding a piece (e.g. dragged from inventory).
func hold_piece(shape: PieceShape) -> void:
	_held_shape = shape
	queue_redraw()

## Rotate the currently held piece 90 degrees clockwise.
func rotate_held_cw() -> void:
	if _held_shape:
		_held_shape = _held_shape.rotated_cw()
		queue_redraw()

## Cancel hold and return the held shape (or null if nothing was held).
func cancel_hold() -> PieceShape:
	var shape := _held_shape
	_held_shape = null
	queue_redraw()
	return shape

## Returns pixel size of the full grid.
func get_grid_pixel_size() -> Vector2:
	return Vector2(COLS * CELL_SIZE, ROWS * CELL_SIZE)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _effective_cursor_pos() -> Vector2:
	if Settings.drag_offset and _held_shape != null:
		return _cursor_pos + Vector2(0, DRAG_OFFSET_PX)
	return _cursor_pos

func _cell_rect(row: int, col: int) -> Rect2:
	return Rect2(
		(col - 1) * CELL_SIZE + 1,
		(row - 1) * CELL_SIZE + 1,
		CELL_SIZE - 2,
		CELL_SIZE - 2
	)

func _pos_to_cell(pos: Vector2) -> Vector2i:
	var col := int(pos.x / CELL_SIZE) + 1
	var row := int(pos.y / CELL_SIZE) + 1
	if grid_data.is_in_bounds(row, col):
		return Vector2i(row, col)
	return Vector2i(-1, -1)
