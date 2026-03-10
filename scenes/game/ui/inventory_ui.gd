class_name InventoryUI
extends Control

## Inventory panel anchored to the bottom of the screen.
## Collapsed: shows a single summary row (item count / capacity).
## Expanded: shows one row per item with priority buttons and a tap-to-pick-up action.

const COLLAPSED_H := 48
const EXPANDED_H  := 300
const ROW_H       := 36

const COLOR_BG         := Color(0.10, 0.10, 0.12)
const COLOR_ROW_NORMAL := Color(0.16, 0.16, 0.20)
const COLOR_ROW_OVER   := Color(0.45, 0.15, 0.15)  # overflow highlight
const COLOR_HEADER     := Color(0.12, 0.12, 0.16)

## Emitted when the player taps an item and wants to pick it up (e.g. a piece shape).
signal item_requested(item: InventoryItem)

var _inventory: Inventory = null
var _expanded: bool = false

# Node references built in _build_ui
var _root_panel: PanelContainer
var _header_label: Label
var _scroll: ScrollContainer
var _item_list: VBoxContainer

func _ready() -> void:
	_build_ui()
	_refresh()

func set_inventory(inv: Inventory) -> void:
	if _inventory:
		_inventory.changed.disconnect(_refresh)
	_inventory = inv
	if _inventory:
		_inventory.changed.connect(_refresh)
	_refresh()

# ---------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	# Root panel fills our Control rect.
	_root_panel = PanelContainer.new()
	_root_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_BG
	_root_panel.add_theme_stylebox_override("panel", style)
	add_child(_root_panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root_panel.add_child(vbox)

	# Header row (always visible)
	var header := PanelContainer.new()
	header.custom_minimum_size = Vector2(0, COLLAPSED_H)
	var hstyle := StyleBoxFlat.new()
	hstyle.bg_color = COLOR_HEADER
	header.add_theme_stylebox_override("panel", hstyle)
	header.gui_input.connect(_on_header_input)
	vbox.add_child(header)

	_header_label = Label.new()
	_header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_header_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_header_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	header.add_child(_header_label)

	# Scrollable item list (hidden when collapsed)
	_scroll = ScrollContainer.new()
	_scroll.visible = false
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_scroll)

	_item_list = VBoxContainer.new()
	_item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_item_list)

func _on_header_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_toggle_expand()
	elif event is InputEventScreenTouch and event.pressed:
		_toggle_expand()

func _toggle_expand() -> void:
	_expanded = not _expanded
	_scroll.visible = _expanded
	custom_minimum_size = Vector2(0, EXPANDED_H if _expanded else COLLAPSED_H)
	_refresh()

# ---------------------------------------------------------------------------
# Refresh
# ---------------------------------------------------------------------------

func _refresh() -> void:
	if not is_inside_tree():
		return
	var used := 0
	var cap  := 0
	if _inventory:
		used = _inventory.slots_used()
		cap  = _inventory.capacity
	_header_label.text = "Inventory  %d / %d  [%s]" % [used, cap, "v" if _expanded else "^"]
	_rebuild_rows()

func _rebuild_rows() -> void:
	for child in _item_list.get_children():
		child.queue_free()

	if not _inventory:
		return

	var items := _inventory.get_items()
	var over  := _inventory.is_over_capacity()

	for i in items.size():
		var item: InventoryItem = items[i]
		var row := _make_row(item, over)
		_item_list.add_child(row)

func _make_row(item: InventoryItem, inventory_over_cap: bool) -> PanelContainer:
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(0, ROW_H)
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_ROW_OVER if inventory_over_cap else COLOR_ROW_NORMAL
	row.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	row.add_child(hbox)

	# ▲ button
	var btn_up := Button.new()
	btn_up.text = "▲"
	btn_up.custom_minimum_size = Vector2(ROW_H, ROW_H)
	btn_up.pressed.connect(_inventory.send_to_top.bind(item))
	hbox.add_child(btn_up)

	# ▼ button
	var btn_dn := Button.new()
	btn_dn.text = "▼"
	btn_dn.custom_minimum_size = Vector2(ROW_H, ROW_H)
	btn_dn.pressed.connect(_inventory.send_to_bottom.bind(item))
	hbox.add_child(btn_dn)

	# Item label (tappable to pick up)
	var lbl := Button.new()
	lbl.text = "%s  [%d]" % [item.display_name, item.slot_size]
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.alignment = HORIZONTAL_ALIGNMENT_LEFT
	lbl.flat = true
	lbl.pressed.connect(_on_item_tapped.bind(item))
	hbox.add_child(lbl)

	return row

func _on_item_tapped(item: InventoryItem) -> void:
	item_requested.emit(item)
