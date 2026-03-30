class_name KitchenGrid
extends GameGrid

## Merge-space grid shown as an overlay on the farm grid when a Cafeteria is on
## the grid.  Items are 1×1 polyominos.  game.gd manages all inventory transitions.

const KITCHEN_ROWS      := 4
const KITCHEN_COLS      := 3
const KITCHEN_CELL_SIZE := 40
const HEADER_H          := 32

const COLOR_BG       := Color(0.08, 0.08, 0.12, 0.95)
const COLOR_INACTIVE := Color(0.10, 0.10, 0.14)
const COLOR_PANEL_BORDER := Color(0.55, 0.55, 0.75)

## Emitted when capacity reduction forces a piece out of the grid.
## game.gd returns the corresponding item to inventory.
signal piece_ejected(piece_id: int)

var _capacity: int = 0


func _ready() -> void:
	rows      = KITCHEN_ROWS
	cols      = KITCHEN_COLS
	cell_size = KITCHEN_CELL_SIZE
	color_empty   = Color(0.18, 0.18, 0.24)
	color_border  = Color(0.06, 0.06, 0.10)
	color_hover   = Color(0.28, 0.22, 0.32)
	color_valid   = Color(0.30, 0.65, 0.30, 0.65)
	color_invalid = Color(0.65, 0.25, 0.25, 0.65)
	super._ready()
	# Kitchen grids are only active when explicitly opened via merge_grid_opened.
	set_grid_active(false)

	var header: Label = Label.new()
	header.text = "Kitchen"
	header.position = Vector2(0.0, -float(HEADER_H))
	header.size = Vector2(float(KITCHEN_COLS * KITCHEN_CELL_SIZE), float(HEADER_H))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", Color(0.75, 0.75, 0.85))
	add_child(header)


func _draw() -> void:
	# Background panel (cells + header + 2px border)
	var panel_w: float = float(cols * cell_size)
	var panel_h: float = float(rows * cell_size + HEADER_H)
	draw_rect(Rect2(0.0, -float(HEADER_H), panel_w, panel_h), COLOR_BG)
	draw_rect(Rect2(-1.0, -float(HEADER_H) - 1.0, panel_w + 2.0, panel_h + 2.0),
		COLOR_PANEL_BORDER, false)
	super._draw()


## Returns the full screen rect including the header area.
func get_full_screen_rect() -> Rect2:
	var r: Rect2 = get_screen_rect()
	r.position.y -= HEADER_H
	r.size.y     += HEADER_H
	return r


## Block placement on cells whose slot index is >= capacity.
func _can_place_at_cell(cell: Vector2i) -> bool:
	var slot_idx: int = (cell.x - 1) * cols + (cell.y - 1)
	return slot_idx < _capacity


func _draw_grid_overlays() -> void:
	for row: int in range(1, rows + 1):
		for col: int in range(1, cols + 1):
			var slot_idx: int = (row - 1) * cols + (col - 1)
			if slot_idx >= _capacity:
				draw_rect(_cell_rect(row, col), COLOR_INACTIVE)
				draw_rect(_cell_rect(row, col), color_border, false)


## Kitchen grids are only activated via merge_grid_opened; merge_grid_closed must not restore them.
func _on_merge_grid_closed() -> void:
	pass


## Set the number of active slots.  Pieces in slots >= cap are ejected via
## piece_ejected so game.gd can return the corresponding items to inventory.
func set_capacity(cap: int) -> void:
	_capacity = clampi(cap, 0, rows * cols)
	# Eject pieces whose slot index now falls outside the active capacity.
	for piece_id: int in grid_data.get_all_piece_ids():
		var info: Dictionary = grid_data.get_piece_info(piece_id)
		if info.is_empty():
			continue
		var slot_idx: int = (info["row"] - 1) * cols + (info["col"] - 1)
		if slot_idx >= _capacity:
			grid_data.remove_piece(piece_id)
			_remove_piece_sprite(piece_id)
			piece_ejected.emit(piece_id)
	queue_redraw()
