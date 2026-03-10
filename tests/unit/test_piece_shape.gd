# Requires the GUT plugin: https://github.com/bitwes/Gut
# Install via Godot Asset Library or by placing addons/gut/ in the project root.
extends GutTest

# ---------------------------------------------------------------------------
# Basic properties
# ---------------------------------------------------------------------------

func test_default_shape_is_single_cell() -> void:
	var shape := PieceShape.new()
	assert_eq(shape.get_cell_count(), 1)
	assert_eq(shape.offsets[0], Vector2i(0, 0))

func test_origin_always_present() -> void:
	var shape := PieceShape.new()
	shape.offsets = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1)]
	assert_true(shape.offsets.has(Vector2i(0, 0)), "Origin must be in offsets")

# ---------------------------------------------------------------------------
# Rotation — single cell
# ---------------------------------------------------------------------------

func test_single_cell_cw_rotation_unchanged() -> void:
	var shape := PieceShape.new()
	var rotated := shape.rotated_cw()
	assert_eq(rotated.get_cell_count(), 1)
	assert_eq(rotated.offsets[0], Vector2i(0, 0))

func test_single_cell_ccw_rotation_unchanged() -> void:
	var shape := PieceShape.new()
	var rotated := shape.rotated_ccw()
	assert_eq(rotated.get_cell_count(), 1)
	assert_eq(rotated.offsets[0], Vector2i(0, 0))

# ---------------------------------------------------------------------------
# Rotation — horizontal line (3 cells)
# ---------------------------------------------------------------------------

func test_horizontal_line_rotates_cw_to_vertical() -> void:
	var shape := PieceShape.new()
	shape.offsets = [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)]
	var rotated := shape.rotated_cw()
	# (r,c) -> (c,-r): (0,0)->(0,0), (0,1)->(1,0), (0,2)->(2,0)
	assert_eq(rotated.get_cell_count(), 3)
	assert_true(rotated.offsets.has(Vector2i(0, 0)))
	assert_true(rotated.offsets.has(Vector2i(1, 0)))
	assert_true(rotated.offsets.has(Vector2i(2, 0)))

# ---------------------------------------------------------------------------
# Rotation — origin is always preserved
# ---------------------------------------------------------------------------

func test_origin_preserved_through_all_rotations() -> void:
	var shape := PieceShape.new()
	shape.offsets = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1)]
	var current := shape
	for _i in 4:
		current = current.rotated_cw()
		assert_true(current.offsets.has(Vector2i(0, 0)),
			"Origin (0,0) must be present after rotation %d" % (_i + 1))

# ---------------------------------------------------------------------------
# Rotation — four rotations return to original
# ---------------------------------------------------------------------------

func test_four_cw_rotations_return_to_original() -> void:
	var shape := PieceShape.new()
	shape.offsets = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1)]
	var current := shape
	for _i in 4:
		current = current.rotated_cw()
	assert_eq(current.offsets.size(), shape.offsets.size())
	for o in shape.offsets:
		assert_true(current.offsets.has(o),
			"Offset %s missing after 4 rotations" % str(o))

func test_cw_then_ccw_returns_to_original() -> void:
	var shape := PieceShape.new()
	shape.offsets = [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 0)]
	var roundtrip := shape.rotated_cw().rotated_ccw()
	assert_eq(roundtrip.offsets.size(), shape.offsets.size())
	for o in shape.offsets:
		assert_true(roundtrip.offsets.has(o),
			"Offset %s missing after CW+CCW" % str(o))

# ---------------------------------------------------------------------------
# get_all_rotations
# ---------------------------------------------------------------------------

func test_get_all_rotations_returns_four() -> void:
	var shape := PieceShape.new()
	shape.offsets = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1)]
	assert_eq(shape.get_all_rotations().size(), 4)

func test_get_all_rotations_first_is_self() -> void:
	var shape := PieceShape.new()
	assert_eq(shape.get_all_rotations()[0], shape)

# ---------------------------------------------------------------------------
# get_bounding_rect
# ---------------------------------------------------------------------------

func test_bounding_rect_single_cell() -> void:
	var shape := PieceShape.new()
	var rect := shape.get_bounding_rect()
	assert_eq(rect, Rect2i(0, 0, 1, 1))

func test_bounding_rect_l_shape() -> void:
	var shape := PieceShape.new()
	shape.offsets = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1)]
	var rect := shape.get_bounding_rect()
	assert_eq(rect, Rect2i(0, 0, 3, 2))

func test_bounding_rect_with_negative_offsets() -> void:
	# After one CW rotation of L-shape: offsets include negative col values
	var shape := PieceShape.new()
	shape.offsets = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1)]
	var rotated := shape.rotated_cw()
	# (0,0),(0,-1),(0,-2),(1,-2) -> bounding rect row:0..1, col:-2..0 -> size 2x3
	var rect := rotated.get_bounding_rect()
	assert_eq(rect.size.x, 2)  # height (rows)
	assert_eq(rect.size.y, 3)  # width (cols)
