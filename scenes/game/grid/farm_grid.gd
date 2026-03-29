class_name FarmGrid
extends GameGrid

## Farm-specific subclass of GameGrid.
##
## Adds power-range and effect-range overlay rendering on top of the base
## grid.  All input, drag/hold, and piece-management logic is inherited.

# ---------------------------------------------------------------------------
# Farm-specific overlay colors
# ---------------------------------------------------------------------------

const COLOR_EFFECT         := Color(0.90, 0.75, 0.20, 0.28)  # effect-range drag preview
const COLOR_EFFECT_PLACED  := Color(0.90, 0.75, 0.20, 0.12)  # permanent effect overlay
const COLOR_POWER_RANGE    := Color(0.35, 0.70, 1.00, 0.18)  # sufficient power network
const COLOR_POWER_WEAK     := Color(0.95, 0.50, 0.20, 0.18)  # insufficient power network

# ---------------------------------------------------------------------------
# Overlay data — populated by game.gd after every grid change
# ---------------------------------------------------------------------------

## Power range overlay data. Each entry: {row, col, range, sufficient}.
var _power_sources:    Array = []
## Effect-range overlay data. Each entry: {row, col, range}.
var _effect_sources:   Array = []
## Power range of the currently held piece (0 = none).
var _held_power_range: int   = 0

# ---------------------------------------------------------------------------
# Drawing
# ---------------------------------------------------------------------------

## Called by GameGrid._draw() when grid_active is true.
func _draw_grid_overlays() -> void:
	_draw_power_overlays()
	_draw_effect_overlays()


func _draw_power_overlays() -> void:
	# Preview for the currently held piece, anchored to the snapped cursor position.
	if _held_power_range > 0 and _held_shape != null:
		var origin: Vector2i = _pos_to_cell(_effective_cursor_pos())
		if origin != Vector2i(-1, -1):
			var preview: Color = Color(COLOR_POWER_RANGE.r, COLOR_POWER_RANGE.g, COLOR_POWER_RANGE.b, 0.28)
			for r: int in range(1, rows + 1):
				for c: int in range(1, cols + 1):
					if absi(origin.x - r) + absi(origin.y - c) <= _held_power_range:
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
	# Drag preview: highlight cells within effect_range of the held piece's position.
	if not _held_shape or _held_shape.effect_range <= 0:
		return
	var origin: Vector2i = _pos_to_cell(_effective_cursor_pos())
	if origin == Vector2i(-1, -1):
		return
	var piece_cells: Array[Vector2i] = []
	for offset: Vector2i in _held_shape.offsets:
		piece_cells.append(Vector2i(origin.x + offset.x, origin.y + offset.y))
	for row: int in range(1, rows + 1):
		for col: int in range(1, cols + 1):
			var cell: Vector2i = Vector2i(row, col)
			if piece_cells.has(cell):
				continue
			if grid_data.get_cell(row, col) != 0:
				continue
			for pc: Vector2i in piece_cells:
				if absi(row - pc.x) + absi(col - pc.y) <= _held_shape.effect_range:
					draw_rect(_cell_rect(row, col), COLOR_EFFECT)
					break

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Update the power range overlay. Each entry: {row, col, range, sufficient}.
## Pass an empty array to clear all overlays.
func set_power_overlay(sources: Array) -> void:
	_power_sources = sources
	queue_redraw()


## Update the effect-range overlay for placed pieces. Each entry: {row, col, range}.
## Pass an empty array to clear all overlays.
func set_effect_overlay(sources: Array) -> void:
	_effect_sources = sources
	queue_redraw()


## Set the power range of the currently held piece for preview rendering.
## Call with 0 when the piece is placed, returned, or cancelled.
func set_held_power_range(power_range: int) -> void:
	_held_power_range = power_range
	queue_redraw()
