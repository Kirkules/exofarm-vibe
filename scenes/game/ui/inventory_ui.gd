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
const COLOR_ROW_OVER   := Color(0.45, 0.15, 0.15)
const COLOR_HEADER     := Color(0.12, 0.12, 0.16)

## Emitted when the player taps an item and wants to pick it up (e.g. a piece shape).
signal item_requested(item: InventoryItem)

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

# ---------------------------------------------------------------------------
# State management
# ---------------------------------------------------------------------------

func _set_state(s: PanelState) -> void:
	_state = s
	_apply_state()

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
		var used: int = _inventory.slots_used() if _inventory else 0
		var cap: int  = _inventory.capacity    if _inventory else 0
		_count_label.text = "Inventory  %d / %d" % [used, cap]
	_rebuild_rows()

func _rebuild_rows() -> void:
	for child: Node in _item_list.get_children():
		child.queue_free()
	if not _inventory:
		return
	var items: Array[InventoryItem] = _inventory.get_items()
	var over: bool = _inventory.is_over_capacity()
	for item: InventoryItem in items:
		_item_list.add_child(_make_row(item, over))

func _make_row(item: InventoryItem, inventory_over_cap: bool) -> PanelContainer:
	var row: PanelContainer = PanelContainer.new()
	row.custom_minimum_size = Vector2(0, ROW_H)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = COLOR_ROW_OVER if inventory_over_cap else COLOR_ROW_NORMAL
	row.add_theme_stylebox_override("panel", style)

	var hbox: HBoxContainer = HBoxContainer.new()
	row.add_child(hbox)

	var btn_up: Button = Button.new()
	btn_up.text = "▲"
	btn_up.custom_minimum_size = Vector2(ROW_H, ROW_H)
	btn_up.pressed.connect(_inventory.send_to_top.bind(item))
	hbox.add_child(btn_up)

	var btn_dn: Button = Button.new()
	btn_dn.text = "▼"
	btn_dn.custom_minimum_size = Vector2(ROW_H, ROW_H)
	btn_dn.pressed.connect(_inventory.send_to_bottom.bind(item))
	hbox.add_child(btn_dn)

	if item.data is PieceShape:
		var icon_btn: Button = Button.new()
		icon_btn.custom_minimum_size = Vector2(ROW_H, ROW_H)
		icon_btn.flat = true
		icon_btn.button_down.connect(_on_item_tapped.bind(item))
		hbox.add_child(icon_btn)
		var icon: TextureRect = TextureRect.new()
		icon.texture = PieceSpriteGenerator.generate_icon(item.data, item.data.color)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_btn.add_child(icon)

	var lbl: Button = Button.new()
	lbl.text = "%s  [%d]" % [item.display_name, item.slot_size]
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.alignment = HORIZONTAL_ALIGNMENT_LEFT
	lbl.flat = true
	lbl.button_down.connect(_on_item_tapped.bind(item))
	hbox.add_child(lbl)

	return row

func _on_item_tapped(item: InventoryItem) -> void:
	item_requested.emit(item)
