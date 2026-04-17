class_name SettlerFoodGrid
extends GameGrid

## 1×1 interactive grid for assigning a meal to one settler for the season.
## Created and positioned by SettlerManager; shown as part of the settler panel.
## Shows "paste" placeholder text when no meal is assigned.

const SLOT_SIZE := 40

var _paste_label: Label


func _ready() -> void:
	rows      = 1
	cols      = 1
	cell_size = SLOT_SIZE
	color_empty   = Color(0.15, 0.15, 0.22)
	color_border  = Color(0.06, 0.06, 0.10)
	color_hover   = Color(0.28, 0.22, 0.32)
	color_valid   = Color(0.30, 0.65, 0.30, 0.65)
	color_invalid = Color(0.65, 0.25, 0.25, 0.65)
	super._ready()
	set_grid_active(false)  # activated by SettlerManager when panel opens

	_paste_label = Label.new()
	_paste_label.text = "paste"
	_paste_label.add_theme_font_size_override("font_size", 8)
	_paste_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65, 0.75))
	_paste_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_paste_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_paste_label.size = Vector2(float(SLOT_SIZE), float(SLOT_SIZE))
	add_child(_paste_label)

	piece_placed_on_grid.connect(func(_pid: int) -> void: _update_paste_label())
	piece_picked_up_from_grid.connect(func(_pid: int, _s: PieceShape) -> void: _update_paste_label())
	piece_returned_to_grid.connect(func(_pid: int) -> void: _update_paste_label())


func _update_paste_label() -> void:
	_paste_label.visible = grid_data.get_piece_count() == 0
