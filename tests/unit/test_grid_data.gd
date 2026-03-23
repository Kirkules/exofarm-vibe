# Requires the GUT plugin: https://github.com/bitwes/Gut
extends GutTest

var grid: GridData

func before_each() -> void:
	grid = GridData.new(6, 8)

# ---------------------------------------------------------------------------
# Bounds checking
# ---------------------------------------------------------------------------

func test_top_left_is_in_bounds() -> void:
	assert_true(grid.is_in_bounds(1, 1))

func test_bottom_right_is_in_bounds() -> void:
	assert_true(grid.is_in_bounds(6, 8))

func test_row_zero_is_out_of_bounds() -> void:
	assert_false(grid.is_in_bounds(0, 1))

func test_col_zero_is_out_of_bounds() -> void:
	assert_false(grid.is_in_bounds(1, 0))

func test_row_beyond_max_is_out_of_bounds() -> void:
	assert_false(grid.is_in_bounds(7, 1))

func test_col_beyond_max_is_out_of_bounds() -> void:
	assert_false(grid.is_in_bounds(1, 9))

func test_get_cell_out_of_bounds_returns_sentinel() -> void:
	assert_eq(grid.get_cell(0, 0), -2)

func test_row_negative_is_out_of_bounds() -> void:
	assert_false(grid.is_in_bounds(-1, 0))

func test_col_negative_is_out_of_bounds() -> void:
	assert_false(grid.is_in_bounds(0, -1))

func test_both_coordinates_negative_is_out_of_bounds() -> void:
	assert_false(grid.is_in_bounds(-1, -4))



# ---------------------------------------------------------------------------
# Empty grid
# ---------------------------------------------------------------------------

func test_all_cells_empty_on_init() -> void:
	for row in range(1, 7):
		for col in range(1, 9):
			assert_eq(grid.get_cell(row, col), 0,
				"Cell (%d,%d) should be empty" % [row, col])

# ---------------------------------------------------------------------------
# Impassable terrain
# ---------------------------------------------------------------------------

func test_set_impassable_marks_cell() -> void:
	grid.set_impassable(3, 4)
	assert_eq(grid.get_cell(3, 4), -1)

func test_impassable_cell_blocks_placement() -> void:
	grid.set_impassable(1, 1)
	var shape: PieceShape = PieceShape.new()
	assert_false(grid.can_place(shape, 1, 1))

# ---------------------------------------------------------------------------
# Placement
# ---------------------------------------------------------------------------

func test_can_place_single_cell_on_empty_grid() -> void:
	var shape: PieceShape = PieceShape.new()
	assert_true(grid.can_place(shape, 1, 1))

func test_place_single_cell_returns_valid_id() -> void:
	var shape: PieceShape = PieceShape.new()
	var id: int = grid.place_piece(shape, 1, 1)
	assert_gt(id, 0)

func test_placed_cell_shows_piece_id() -> void:
	var shape: PieceShape = PieceShape.new()
	var id: int = grid.place_piece(shape, 2, 3)
	assert_eq(grid.get_cell(2, 3), id)

func test_cannot_place_on_occupied_cell() -> void:
	var shape: PieceShape = PieceShape.new()
	grid.place_piece(shape, 1, 1)
	assert_false(grid.can_place(shape, 1, 1))

func test_place_returns_minus_one_on_failure() -> void:
	var shape: PieceShape = PieceShape.new()
	grid.place_piece(shape, 1, 1)
	assert_eq(grid.place_piece(shape, 1, 1), -1)

func test_cannot_place_out_of_bounds() -> void:
	var shape: PieceShape = PieceShape.new()
	assert_false(grid.can_place(shape, 0, 1))
	assert_false(grid.can_place(shape, 1, 0))
	assert_false(grid.can_place(shape, 7, 1))
	assert_false(grid.can_place(shape, 1, 9))

# ---------------------------------------------------------------------------
# Multi-cell placement
# ---------------------------------------------------------------------------

func test_place_l_shape_occupies_all_cells() -> void:
	var shape: PieceShape = PieceShape.new()
	shape.offsets = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1)]
	var id: int = grid.place_piece(shape, 1, 2)
	assert_gt(id, 0)
	assert_eq(grid.get_cell(1, 2), id)
	assert_eq(grid.get_cell(2, 2), id)
	assert_eq(grid.get_cell(3, 2), id)
	assert_eq(grid.get_cell(3, 3), id)

func test_l_shape_out_of_bounds_cannot_place() -> void:
	var shape: PieceShape = PieceShape.new()
	shape.offsets = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1)]
	# Place with origin at (5,8): cell (7,8) would be row 7 — out of bounds
	assert_false(grid.can_place(shape, 5, 8))

func test_negative_offset_placement() -> void:
	# Rotated L-shape has offsets like (0,0),(0,-1),(0,-2),(1,-2)
	var shape: PieceShape = PieceShape.new()
	shape.offsets = [Vector2i(0, 0), Vector2i(0, -1), Vector2i(0, -2), Vector2i(1, -2)]
	# Origin at (1,3): leftmost cell is col 1 — just in bounds
	assert_true(grid.can_place(shape, 1, 3))
	# Origin at (1,2): leftmost cell would be col 0 — out of bounds
	assert_false(grid.can_place(shape, 1, 2))

# ---------------------------------------------------------------------------
# Removal
# ---------------------------------------------------------------------------

func test_remove_piece_frees_cells() -> void:
	var shape: PieceShape = PieceShape.new()
	var id: int = grid.place_piece(shape, 1, 1)
	grid.remove_piece(id)
	assert_eq(grid.get_cell(1, 1), 0)

func test_remove_nonexistent_piece_returns_false() -> void:
	assert_false(grid.remove_piece(999))

func test_cell_can_be_reused_after_removal() -> void:
	var shape: PieceShape = PieceShape.new()
	var id: int = grid.place_piece(shape, 1, 1)
	grid.remove_piece(id)
	assert_true(grid.can_place(shape, 1, 1))

# ---------------------------------------------------------------------------
# Piece info and counts
# ---------------------------------------------------------------------------

func test_get_piece_info_returns_correct_data() -> void:
	var shape: PieceShape = PieceShape.new()
	var id: int = grid.place_piece(shape, 3, 5)
	var info: Dictionary = grid.get_piece_info(id)
	assert_eq(info["row"], 3)
	assert_eq(info["col"], 5)
	assert_eq(info["shape"], shape)

func test_get_piece_info_unknown_id_returns_empty() -> void:
	assert_eq(grid.get_piece_info(999), {})

func test_piece_count_increments_on_place() -> void:
	var shape: PieceShape = PieceShape.new()
	grid.place_piece(shape, 1, 1)
	grid.place_piece(shape, 1, 3)
	assert_eq(grid.get_piece_count(), 2)

func test_piece_count_decrements_on_remove() -> void:
	var shape: PieceShape = PieceShape.new()
	var id: int = grid.place_piece(shape, 1, 1)
	grid.place_piece(shape, 1, 3)
	grid.remove_piece(id)
	assert_eq(grid.get_piece_count(), 1)

func test_ids_are_unique() -> void:
	var shape: PieceShape = PieceShape.new()
	var id1: int = grid.place_piece(shape, 1, 1)
	var id2: int = grid.place_piece(shape, 1, 3)
	assert_ne(id1, id2)
