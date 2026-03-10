class_name GridData
extends RefCounted

## Stores the state of the farm grid: which cells are occupied by which pieces.
##
## Cells are addressed as (row, col), 1-indexed, with (1, 1) at the top-left.
## Row increases downward; col increases rightward.
##
## Cell values:
##    0  = empty
##   -1  = impassable terrain (set at run start, cannot be placed on)
##   >0  = piece_id of the piece occupying this cell

var rows: int
var cols: int

# Flat array: _cells[(row - 1) * cols + (col - 1)] = cell value
var _cells: Array[int] = []

# piece_id -> { "shape": PieceShape, "row": int, "col": int }
var _pieces: Dictionary = {}

var _next_id: int = 1

func _init(p_rows: int = 6, p_cols: int = 8) -> void:
	rows = p_rows
	cols = p_cols
	_cells.resize(rows * cols)
	_cells.fill(0)

func _cell_index(row: int, col: int) -> int:
	return (row - 1) * cols + (col - 1)

## Returns true if (row, col) is within the grid boundary.
func is_in_bounds(row: int, col: int) -> bool:
	return row >= 1 and row <= rows and col >= 1 and col <= cols

## Returns the cell value at (row, col), or -2 if out of bounds.
func get_cell(row: int, col: int) -> int:
	if not is_in_bounds(row, col):
		return -2
	return _cells[_cell_index(row, col)]

## Marks a cell as impassable terrain. Called at run start for fixed obstacles.
func set_impassable(row: int, col: int) -> void:
	if is_in_bounds(row, col):
		_cells[_cell_index(row, col)] = -1

## Returns true if the given shape can be placed with its origin at (origin_row, origin_col).
func can_place(shape: PieceShape, origin_row: int, origin_col: int) -> bool:
	for offset in shape.offsets:
		var r := origin_row + offset.x
		var c := origin_col + offset.y
		if not is_in_bounds(r, c):
			return false
		if _cells[_cell_index(r, c)] != 0:
			return false
	return true

## Places a piece on the grid. Returns the new piece_id on success, or -1 on failure.
func place_piece(shape: PieceShape, origin_row: int, origin_col: int) -> int:
	if not can_place(shape, origin_row, origin_col):
		return -1
	var piece_id := _next_id
	_next_id += 1
	for offset in shape.offsets:
		var r := origin_row + offset.x
		var c := origin_col + offset.y
		_cells[_cell_index(r, c)] = piece_id
	_pieces[piece_id] = {"shape": shape, "row": origin_row, "col": origin_col}
	return piece_id

## Removes a piece from the grid, freeing its cells. Returns true on success.
func remove_piece(piece_id: int) -> bool:
	if not _pieces.has(piece_id):
		return false
	var info: Dictionary = _pieces[piece_id]
	var shape: PieceShape = info["shape"]
	for offset in shape.offsets:
		var r: int = info["row"] + offset.x
		var c: int = info["col"] + offset.y
		_cells[_cell_index(r, c)] = 0
	_pieces.erase(piece_id)
	return true

## Returns the stored info for a piece: { "shape", "row", "col" }, or {} if not found.
func get_piece_info(piece_id: int) -> Dictionary:
	return _pieces.get(piece_id, {})

## Returns all currently placed piece IDs.
func get_all_piece_ids() -> Array:
	return _pieces.keys()

## Returns the number of pieces currently on the grid.
func get_piece_count() -> int:
	return _pieces.size()
