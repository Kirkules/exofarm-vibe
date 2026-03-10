class_name PieceShape
extends Resource

## Defines the shape of a placeable piece as a list of cell offsets from an origin cell.
##
## Coordinates are Vector2i(row, col):
##   - row increases downward
##   - col increases rightward
##   - the origin cell is always present at offset Vector2i(0, 0)
##   - the origin is the rotation pivot: it stays at (0,0) after any rotation,
##     and tracks the player's touch/cursor position during drag placement
##
## Offsets may be negative (e.g. a cell two columns left of origin = Vector2i(0, -2)).

@export var offsets: Array[Vector2i] = [Vector2i(0, 0)]

## Returns the number of cells this piece occupies.
func get_cell_count() -> int:
	return offsets.size()

## Returns a new PieceShape rotated 90 degrees clockwise around the origin.
## Rotation formula: (row, col) -> (col, -row).
## The origin cell (0, 0) is preserved under this transformation.
func rotated_cw() -> PieceShape:
	var new_offsets: Array[Vector2i] = []
	for o in offsets:
		new_offsets.append(Vector2i(o.y, -o.x))
	var shape := PieceShape.new()
	shape.offsets = new_offsets
	return shape

## Returns a new PieceShape rotated 90 degrees counter-clockwise around the origin.
## Rotation formula: (row, col) -> (-col, row).
func rotated_ccw() -> PieceShape:
	var new_offsets: Array[Vector2i] = []
	for o in offsets:
		new_offsets.append(Vector2i(-o.y, o.x))
	var shape := PieceShape.new()
	shape.offsets = new_offsets
	return shape

## Returns all 4 clockwise rotation states starting from this shape.
## Index 0 = this shape; index 1 = 90 CW; index 2 = 180; index 3 = 270 CW.
func get_all_rotations() -> Array:
	var result: Array = [self]
	var current: PieceShape = self
	for _i in 3:
		current = current.rotated_cw()
		result.append(current)
	return result

## Returns the bounding rect of this shape as Rect2i(min_row, min_col, height, width).
func get_bounding_rect() -> Rect2i:
	if offsets.is_empty():
		return Rect2i()
	var min_row: int = offsets[0].x
	var max_row: int = offsets[0].x
	var min_col: int = offsets[0].y
	var max_col: int = offsets[0].y
	for o in offsets:
		min_row = mini(min_row, o.x)
		max_row = maxi(max_row, o.x)
		min_col = mini(min_col, o.y)
		max_col = maxi(max_col, o.y)
	return Rect2i(min_row, min_col, max_row - min_row + 1, max_col - min_col + 1)
