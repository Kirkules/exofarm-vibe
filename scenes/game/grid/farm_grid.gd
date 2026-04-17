class_name FarmGrid
extends GameGrid

## Farm-specific subclass of GameGrid.
##
## Adds power-range and effect-range overlay rendering on top of the base grid.
## Overrides try_receive_drop() to enforce FARM_GRID item type.
## set_held_power_range() stays here for BuildingManager to call after pickup.

# ---------------------------------------------------------------------------
# Farm-specific overlay colors
# ---------------------------------------------------------------------------

const COLOR_EFFECT         := Color(0.90, 0.75, 0.20, 0.28)  # effect-range drag preview
const COLOR_EFFECT_PLACED  := Color(0.90, 0.75, 0.20, 0.12)  # permanent effect overlay
const COLOR_POWER_RANGE    := Color(0.35, 0.70, 1.00, 0.18)  # sufficient power network
const COLOR_POWER_WEAK     := Color(0.95, 0.50, 0.20, 0.18)  # insufficient power network

# ---------------------------------------------------------------------------
# Overlay data — populated by BuildingManager after every grid change
# ---------------------------------------------------------------------------

## Power range overlay data. Each entry: {row, col, range, sufficient}.
var _power_sources:    Array = []
## Effect-range overlay data. Each entry: {row, col, range}.
var _effect_sources:   Array = []
## Power range of the currently held piece (0 = none). Set by BuildingManager.
var _held_power_range: int   = 0

# ---------------------------------------------------------------------------
# Drawing
# ---------------------------------------------------------------------------

## Called by GameGrid._draw() when grid_active is true.
func _draw_grid_overlays() -> void:
	_draw_power_overlays()
	_draw_effect_overlays()


func _draw_power_overlays() -> void:
	# Preview for the currently held piece, anchored to the snapped hover cell.
	if _held_power_range > 0 and _hover_cell != Vector2i(-1, -1):
		var preview: Color = Color(COLOR_POWER_RANGE.r, COLOR_POWER_RANGE.g, COLOR_POWER_RANGE.b, 0.28)
		for r: int in range(1, rows + 1):
			for c: int in range(1, cols + 1):
				if absi(_hover_cell.x - r) + absi(_hover_cell.y - c) <= _held_power_range:
					draw_rect(_cell_rect(r, c), preview)
	# Permanent overlays for placed power sources.
	for src: Dictionary in _power_sources:
		var color: Color   = COLOR_POWER_RANGE if src["sufficient"] else COLOR_POWER_WEAK
		var row: int       = src["row"]
		var col: int       = src["col"]
		var range_val: int = src["range"]
		for r: int in range(1, rows + 1):
			for c: int in range(1, cols + 1):
				if absi(row - r) + absi(col - c) <= range_val:
					draw_rect(_cell_rect(r, c), color)


func _draw_effect_overlays() -> void:
	# Permanent overlays for placed pieces with effect_range > 0.
	for src: Dictionary in _effect_sources:
		var row: int       = src["row"]
		var col: int       = src["col"]
		var range_val: int = src["range"]
		for r: int in range(1, rows + 1):
			for c: int in range(1, cols + 1):
				if absi(row - r) + absi(col - c) <= range_val:
					draw_rect(_cell_rect(r, c), COLOR_EFFECT_PLACED)
	# Drag preview: highlight cells within effect_range of the held piece.
	if _hover_shape == null or _hover_shape.effect_range <= 0:
		return
	if _hover_cell == Vector2i(-1, -1):
		return
	var piece_cells: Array[Vector2i] = []
	for offset: Vector2i in _hover_shape.offsets:
		piece_cells.append(Vector2i(_hover_cell.x + offset.x, _hover_cell.y + offset.y))
	for row: int in range(1, rows + 1):
		for col: int in range(1, cols + 1):
			var cell: Vector2i = Vector2i(row, col)
			if piece_cells.has(cell):
				continue
			if grid_data.get_cell(row, col) != 0:
				continue
			for pc: Vector2i in piece_cells:
				if absi(row - pc.x) + absi(col - pc.y) <= _hover_shape.effect_range:
					draw_rect(_cell_rect(row, col), COLOR_EFFECT)
					break

# ---------------------------------------------------------------------------
# Drop acceptance — FARM_GRID type check
# ---------------------------------------------------------------------------

func try_receive_drop(cursor_screen: Vector2, shape: PieceShape,
		payload: Variant, hint: String) -> int:
	var item: InventoryItem = payload as InventoryItem
	if item == null:
		return -1
	var def: PlaceableDefinition = item.data as PlaceableDefinition
	if def == null or not (PlaceableDefinition.GridType.FARM_GRID in def.allowed_grids):
		return -1
	return super.try_receive_drop(cursor_screen, shape, payload, hint)

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Update the power range overlay. Each entry: {row, col, range, sufficient}.
func set_power_overlay(sources: Array) -> void:
	_power_sources = sources
	queue_redraw()


## Update the effect-range overlay for placed pieces. Each entry: {row, col, range}.
func set_effect_overlay(sources: Array) -> void:
	_effect_sources = sources
	queue_redraw()


## Set the power range of the currently held piece for preview rendering.
## Call with 0 when the piece is placed, returned, or cancelled.
func set_held_power_range(power_range: int) -> void:
	_held_power_range = power_range
	queue_redraw()
