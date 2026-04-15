class_name InventoryUI
extends Control

## Inventory panel anchored to the bottom of the screen.
##
## Three display states:
##   COLLAPSED — header bar only; tap to expand to PARTIAL
##   PARTIAL   — items visible; sized to sit below the farm grid without covering it
##   FULL      — taller panel that may overlap the grid; for browsing many items
##
## In PARTIAL: left button collapses, right button expands to FULL.
## In FULL:    left button restores to PARTIAL, right button collapses entirely.

enum PanelState { COLLAPSED, PARTIAL, FULL }

const COLLAPSED_H := 48
const FULL_H      := 400
const ROW_H       := 36

const COLOR_BG         := Color(0.10, 0.10, 0.12)
const COLOR_ROW_NORMAL := Color(0.16, 0.16, 0.20)
const COLOR_HEADER     := Color(0.12, 0.12, 0.16)
const COLOR_DROP_LINE  := Color(1.0, 1.0, 1.0, 0.85)

## Emitted when the player taps an item and wants to pick it up (e.g. a piece shape).
signal item_requested(item: InventoryItem)
## Emitted whenever the panel state changes; collapsed=true when the panel is collapsed.
signal state_changed(collapsed: bool)

var _inventory: Inventory = null
var _state: PanelState = PanelState.COLLAPSED

## Set from game.gd so PARTIAL height stops just below the grid.
var _grid_bottom: float = 342.0

# Node references
var _root_panel: PanelContainer
var _header_panel: PanelContainer
var _count_label: Label        # rebuilt with header on state change; updated by _refresh
var _scroll: ScrollContainer
var _item_list: VBoxContainer

# Drag drop-zone state
var _current_groups: Array = []   # [{item: InventoryItem, count: int}, ...] from last _rebuild_rows
var _group_row_nodes: Array = []  # PanelContainer per group row, parallel to _current_groups
var _drag_gap_idx: int = -1       # highlighted insertion gap; -1 = none
var _drop_indicator: ColorRect    # overlay line; sibling of _root_panel, z_index=1

func _ready() -> void:
	_build_ui()
	_apply_state()

func set_inventory(inv: Inventory) -> void:
	if _inventory:
		_inventory.changed.disconnect(_refresh)
	_inventory = inv
	if _inventory:
		_inventory.changed.connect(_refresh)
	_refresh()

func set_grid_bottom(y: float) -> void:
	_grid_bottom = y

## Re-apply current state so PARTIAL height recalculates after _grid_bottom changes.
func refresh_layout() -> void:
	_apply_state()

## Called by GameGrid each frame while a piece is held and its CoM is over this panel.
func set_drag_pos(screen_pos: Vector2) -> void:
	var new_gap: int = _group_row_nodes.size()  # default: after all rows
	for i: int in _group_row_nodes.size():
		var row: Control = _group_row_nodes[i] as Control
		if screen_pos.y < row.global_position.y + row.size.y * 0.5:
			new_gap = i
			break
	_drag_gap_idx = new_gap
	_update_drop_indicator()

## Called by GameGrid when the held piece leaves this panel or is released.
func clear_drag() -> void:
	_drag_gap_idx = -1
	_drop_indicator.visible = false

## Returns the first InventoryItem of the group that the current gap points before.
## Returns null if the gap is at the end of the list (drop after last group).
func get_drop_ref_item() -> InventoryItem:
	if _drag_gap_idx < 0 or _drag_gap_idx >= _current_groups.size():
		return null
	return _current_groups[_drag_gap_idx]["item"] as InventoryItem

func _partial_h() -> float:
	var available: float = get_viewport_rect().size.y - _grid_bottom - 8.0
	return maxf(float(COLLAPSED_H) * 2.0, available)

# ---------------------------------------------------------------------------
# Build (once)
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	_root_panel = PanelContainer.new()
	_root_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg: StyleBoxFlat = StyleBoxFlat.new()
	bg.bg_color = COLOR_BG
	_root_panel.add_theme_stylebox_override("panel", bg)
	add_child(_root_panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root_panel.add_child(vbox)

	_header_panel = PanelContainer.new()
	_header_panel.custom_minimum_size = Vector2(0, COLLAPSED_H)
	var hs: StyleBoxFlat = StyleBoxFlat.new()
	hs.bg_color = COLOR_HEADER
	_header_panel.add_theme_stylebox_override("panel", hs)
	vbox.add_child(_header_panel)

	_scroll = ScrollContainer.new()
	_scroll.visible = false
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_scroll)

	_item_list = VBoxContainer.new()
	_item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_item_list)

	# Drop indicator: sibling of _root_panel so it renders above all panel content.
	_drop_indicator = ColorRect.new()
	_drop_indicator.color = COLOR_DROP_LINE
	_drop_indicator.size = Vector2(0.0, 3.0)
	_drop_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drop_indicator.z_index = 1
	_drop_indicator.visible = false
	add_child(_drop_indicator)

# ---------------------------------------------------------------------------
# State management
# ---------------------------------------------------------------------------

func _set_state(s: PanelState) -> void:
	_state = s
	_apply_state()
	state_changed.emit(s == PanelState.COLLAPSED)

func _apply_state() -> void:
	for child: Node in _header_panel.get_children():
		child.queue_free()
	_count_label = null

	match _state:
		PanelState.COLLAPSED:
			_scroll.visible = false
			custom_minimum_size = Vector2(0, COLLAPSED_H)
			_build_collapsed_header()

		PanelState.PARTIAL:
			_scroll.visible = true
			custom_minimum_size = Vector2(0, _partial_h())
			_build_expanded_header("▼", _go_to_collapsed, "▲▲", _go_to_full)

		PanelState.FULL:
			_scroll.visible = true
			custom_minimum_size = Vector2(0, FULL_H)
			_build_expanded_header("▼", _go_to_partial, "▼▼", _go_to_collapsed)

	_refresh()

func _build_collapsed_header() -> void:
	var btn: Button = Button.new()
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = COLOR_HEADER
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.pressed.connect(_go_to_partial)
	_header_panel.add_child(btn)

	_count_label = Label.new()
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_count_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.add_child(_count_label)

func _build_expanded_header(
		left_text: String, left_action: Callable,
		right_text: String, right_action: Callable) -> void:
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_header_panel.add_child(hbox)

	var btn_left: Button = Button.new()
	btn_left.text = left_text
	btn_left.custom_minimum_size = Vector2(COLLAPSED_H, COLLAPSED_H)
	btn_left.pressed.connect(left_action)
	hbox.add_child(btn_left)

	_count_label = Label.new()
	_count_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(_count_label)

	var btn_right: Button = Button.new()
	btn_right.text = right_text
	btn_right.custom_minimum_size = Vector2(COLLAPSED_H, COLLAPSED_H)
	btn_right.pressed.connect(right_action)
	hbox.add_child(btn_right)

func _go_to_collapsed() -> void: _set_state(PanelState.COLLAPSED)
func _go_to_partial()   -> void: _set_state(PanelState.PARTIAL)
func _go_to_full()      -> void: _set_state(PanelState.FULL)

# ---------------------------------------------------------------------------
# Refresh (inventory data → display)
# ---------------------------------------------------------------------------

func _refresh() -> void:
	if not is_inside_tree():
		return
	if _count_label:
		var count: int = _inventory.item_count() if _inventory else 0
		_count_label.text = "Inventory  %d" % count
	_rebuild_rows()

func _rebuild_rows() -> void:
	_group_row_nodes.clear()
	for child: Node in _item_list.get_children():
		child.queue_free()
	if not _inventory:
		_current_groups = []
		return
	var items: Array[InventoryItem] = _inventory.get_items()
	# Group items that share the same data reference into a single row with a count.
	var groups: Array = []
	var seen: Dictionary = {}
	for item: InventoryItem in items:
		var key: Variant = item.data
		if key != null and seen.has(key):
			groups[seen[key]]["count"] += 1
		else:
			if key != null:
				seen[key] = groups.size()
			groups.append({"item": item, "count": 1})
	_current_groups = groups
	for entry: Dictionary in groups:
		var row: PanelContainer = _make_row(entry["item"], entry["count"])
		_item_list.add_child(row)
		_group_row_nodes.append(row)

func _make_row(item: InventoryItem, count: int) -> PanelContainer:
	var row: PanelContainer = PanelContainer.new()
	row.custom_minimum_size = Vector2(0, ROW_H)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = COLOR_ROW_NORMAL
	row.add_theme_stylebox_override("panel", style)

	var hbox: HBoxContainer = HBoxContainer.new()
	row.add_child(hbox)

	if item.data is PlaceableDefinition:
		var shape: PieceShape = (item.data as PlaceableDefinition).shape
		var icon_btn: Button = Button.new()
		icon_btn.custom_minimum_size = Vector2(ROW_H, ROW_H)
		icon_btn.flat = true
		icon_btn.button_down.connect(_on_item_tapped.bind(item))
		hbox.add_child(icon_btn)
		var icon: TextureRect = TextureRect.new()
		icon.texture = PieceSpriteGenerator.generate_icon(shape, shape.color)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_btn.add_child(icon)
		var icon_label: Label = Label.new()
		icon_label.text = shape.get_label(item.display_name)
		icon_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_label.add_theme_font_size_override("font_size", 8)
		icon_label.add_theme_color_override("font_color", Color.WHITE)
		icon_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
		icon_label.add_theme_constant_override("shadow_offset_x", 1)
		icon_label.add_theme_constant_override("shadow_offset_y", 1)
		icon_btn.add_child(icon_label)

	var lbl: Button = Button.new()
	lbl.text = "%s  [%d]" % [item.display_name, count]
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.alignment = HORIZONTAL_ALIGNMENT_LEFT
	lbl.flat = true
	lbl.button_down.connect(_on_item_tapped.bind(item))
	hbox.add_child(lbl)

	return row

# ---------------------------------------------------------------------------
# Drop-zone indicator
# ---------------------------------------------------------------------------

func _update_drop_indicator() -> void:
	if _drag_gap_idx < 0 or not _scroll.visible:
		_drop_indicator.visible = false
		return
	var line_y: float
	if _group_row_nodes.is_empty():
		line_y = _scroll.global_position.y - global_position.y
	elif _drag_gap_idx >= _group_row_nodes.size():
		var last: Control = _group_row_nodes[-1] as Control
		line_y = (last.global_position.y + last.size.y) - global_position.y
	else:
		var row: Control = _group_row_nodes[_drag_gap_idx] as Control
		line_y = row.global_position.y - global_position.y
	# Clip to the scroll area so the line never appears over the header.
	var scroll_top: float = _scroll.global_position.y - global_position.y
	var scroll_bot: float = scroll_top + _scroll.size.y
	line_y = clampf(line_y, scroll_top, scroll_bot)
	_drop_indicator.position = Vector2(0.0, line_y - 1.0)
	_drop_indicator.size = Vector2(size.x, 3.0)
	_drop_indicator.visible = true

func _on_item_tapped(item: InventoryItem) -> void:
	item_requested.emit(item)
