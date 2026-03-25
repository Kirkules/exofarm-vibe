class_name BuildMenu
extends Control

## Panel shown below the grid when the inventory is collapsed.
## Lists available buildable definitions; tapping one emits building_requested
## so game.gd can begin the pending-hold flow for grid placement.

signal building_requested(def: PlaceableDefinition)

const ROW_H        := 36
const COLOR_BG     := Color(0.10, 0.10, 0.12)
const COLOR_HEADER := Color(0.12, 0.12, 0.16)
const COLOR_ROW    := Color(0.16, 0.16, 0.20)

var _definitions: Array[PlaceableDefinition] = []
var _item_list: VBoxContainer


func _ready() -> void:
	_build_ui()

# ---------------------------------------------------------------------------
# Public
# ---------------------------------------------------------------------------

func set_definitions(defs: Array[PlaceableDefinition]) -> void:
	_definitions = defs
	_rebuild_rows()

# ---------------------------------------------------------------------------
# Build (once)
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	var root: PanelContainer = PanelContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg: StyleBoxFlat = StyleBoxFlat.new()
	bg.bg_color = COLOR_BG
	root.add_theme_stylebox_override("panel", bg)
	add_child(root)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(vbox)

	var header: PanelContainer = PanelContainer.new()
	header.custom_minimum_size = Vector2(0, ROW_H)
	var hs: StyleBoxFlat = StyleBoxFlat.new()
	hs.bg_color = COLOR_HEADER
	header.add_theme_stylebox_override("panel", hs)
	vbox.add_child(header)

	var title: Label = Label.new()
	title.text = "Build"
	title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(title)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_item_list = VBoxContainer.new()
	_item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_item_list)

# ---------------------------------------------------------------------------
# Rows
# ---------------------------------------------------------------------------

func _rebuild_rows() -> void:
	for child: Node in _item_list.get_children():
		child.queue_free()
	for def: PlaceableDefinition in _definitions:
		_item_list.add_child(_make_row(def))

func _make_row(def: PlaceableDefinition) -> PanelContainer:
	var row: PanelContainer = PanelContainer.new()
	row.custom_minimum_size = Vector2(0, ROW_H)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = COLOR_ROW
	row.add_theme_stylebox_override("panel", style)

	var hbox: HBoxContainer = HBoxContainer.new()
	row.add_child(hbox)

	if def.shape != null:
		var icon_btn: Button = Button.new()
		icon_btn.custom_minimum_size = Vector2(ROW_H, ROW_H)
		icon_btn.flat = true
		icon_btn.button_down.connect(func() -> void: building_requested.emit(def))
		hbox.add_child(icon_btn)
		var icon: TextureRect = TextureRect.new()
		icon.texture = PieceSpriteGenerator.generate_icon(def.shape, def.shape.color)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_btn.add_child(icon)
		var icon_lbl: Label = Label.new()
		icon_lbl.text = def.shape.get_label(def.display_name)
		icon_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_lbl.add_theme_font_size_override("font_size", 8)
		icon_lbl.add_theme_color_override("font_color", Color.WHITE)
		icon_lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
		icon_lbl.add_theme_constant_override("shadow_offset_x", 1)
		icon_lbl.add_theme_constant_override("shadow_offset_y", 1)
		icon_btn.add_child(icon_lbl)

	var name_btn: Button = Button.new()
	name_btn.text = def.display_name
	name_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_btn.flat = true
	name_btn.button_down.connect(func() -> void: building_requested.emit(def))
	hbox.add_child(name_btn)

	return row
