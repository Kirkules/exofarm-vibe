class_name KitchenPanel
extends Control

## Merge-space panel shown as an overlay on the farm grid when a Cafeteria is on
## the grid.  Items are dragged here from inventory; dragging a filled slot returns
## the item to inventory.  game.gd manages all inventory transitions.

const COLS      := 3
const ROWS      := 4
const SLOT_SIZE := 40
const SLOT_GAP  := 4
const HEADER_H  := 32
const PADDING   := 6
## Total panel height; update this if ROWS / SLOT_SIZE / HEADER_H / PADDING change.
const PANEL_H   := HEADER_H + PADDING + ROWS * SLOT_SIZE + (ROWS - 1) * SLOT_GAP + PADDING

const COLOR_BG          := Color(0.08, 0.08, 0.12, 0.95)
const COLOR_SLOT_EMPTY  := Color(0.18, 0.18, 0.24)
const COLOR_SLOT_FILLED := Color(0.28, 0.22, 0.32)

## Emitted when the player presses down on an occupied slot (drag start).
## game.gd removes the item from the panel and begins a farm_grid hold.
signal item_held(item: InventoryItem)
## Emitted when capacity reduction forces an item out of the panel.
## game.gd returns the item to inventory in response.
signal item_tapped(item: InventoryItem)

var _capacity: int = 0
## Sparse storage: size is always COLS*ROWS; null means empty slot.
var _items: Array[InventoryItem] = []
var _grid_container: GridContainer


func _ready() -> void:
	custom_minimum_size = Vector2(0.0, PANEL_H)
	_items.resize(COLS * ROWS)

	var bg: PanelContainer = PanelContainer.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color     = COLOR_BG
	style.border_color = Color(0.55, 0.55, 0.75)
	style.set_border_width_all(2)
	bg.add_theme_stylebox_override("panel", style)
	add_child(bg)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", PADDING)
	bg.add_child(vbox)

	# --- Header ---
	var lbl: Label = Label.new()
	lbl.text                  = "Kitchen"
	lbl.custom_minimum_size   = Vector2(0.0, float(HEADER_H))
	lbl.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment    = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.85))
	vbox.add_child(lbl)

	# --- Slot grid ---
	_grid_container = GridContainer.new()
	_grid_container.columns = COLS
	_grid_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_grid_container.add_theme_constant_override("h_separation", SLOT_GAP)
	_grid_container.add_theme_constant_override("v_separation", SLOT_GAP)
	vbox.add_child(_grid_container)


## Set total number of active slots.  Excess items are ejected via item_tapped signal.
func set_capacity(cap: int) -> void:
	_capacity = clampi(cap, 0, COLS * ROWS)
	# Eject items that fall outside the new capacity (iterate from high to low).
	for i: int in range(COLS * ROWS - 1, _capacity - 1, -1):
		if _items[i] != null:
			var excess: InventoryItem = _items[i]
			_items[i] = null
			item_tapped.emit(excess)
	_rebuild_slots()


## Place an item in a specific slot (0-indexed).  Returns false if the slot is
## occupied or out of range.
func add_item_at(item: InventoryItem, slot_idx: int) -> bool:
	if slot_idx < 0 or slot_idx >= _capacity:
		return false
	if _items[slot_idx] != null:
		return false
	_items[slot_idx] = item
	_rebuild_slots()
	return true


## Place an item in the first empty slot.  Returns false if at capacity.
func add_item(item: InventoryItem) -> bool:
	var idx: int = _first_empty_slot()
	if idx == -1:
		return false
	_items[idx] = item
	_rebuild_slots()
	return true


## Remove a specific item (safe if not present).
func remove_item(item: InventoryItem) -> void:
	for i: int in COLS * ROWS:
		if _items[i] == item:
			_items[i] = null
			_rebuild_slots()
			return


## Returns a typed copy of the current non-null items.
func get_items() -> Array[InventoryItem]:
	var result: Array[InventoryItem] = []
	for item: InventoryItem in _items:
		if item != null:
			result.append(item)
	return result


## Returns true if at least one slot is free within the current capacity.
func has_space() -> bool:
	return _first_empty_slot() != -1


## Remove all items without emitting signals (used at season-end consumption).
func clear() -> void:
	for i: int in COLS * ROWS:
		_items[i] = null
	_rebuild_slots()


## Return the index of the empty slot whose centre is closest to global_pos.
## Returns -1 if no empty slot exists within the current capacity.
func find_nearest_empty_slot(global_pos: Vector2) -> int:
	var best_idx: int    = -1
	var best_dist: float = INF
	for i: int in _capacity:
		if _items[i] != null:
			continue
		var center: Vector2 = _slot_center_global(i)
		var dist: float     = global_pos.distance_squared_to(center)
		if dist < best_dist:
			best_dist = dist
			best_idx  = i
	return best_idx


# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

func _first_empty_slot() -> int:
	for i: int in _capacity:
		if _items[i] == null:
			return i
	return -1


## Global screen position of the centre of slot i.
func _slot_center_global(slot_idx: int) -> Vector2:
	if _grid_container == null or not is_inside_tree():
		return Vector2.ZERO
	var col: int     = slot_idx % COLS
	var row: int     = slot_idx / COLS
	var slot_tl: Vector2 = _grid_container.global_position + Vector2(
		float(col) * (SLOT_SIZE + SLOT_GAP),
		float(row) * (SLOT_SIZE + SLOT_GAP)
	)
	return slot_tl + Vector2(SLOT_SIZE * 0.5, SLOT_SIZE * 0.5)


func _rebuild_slots() -> void:
	for child: Node in _grid_container.get_children():
		_grid_container.remove_child(child)
		child.queue_free()

	for i: int in COLS * ROWS:
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)

		var slot_style: StyleBoxFlat = StyleBoxFlat.new()
		slot_style.corner_radius_top_left     = 3
		slot_style.corner_radius_top_right    = 3
		slot_style.corner_radius_bottom_left  = 3
		slot_style.corner_radius_bottom_right = 3

		var is_active: bool = i < _capacity

		if not is_active:
			slot_style.bg_color = Color(0.10, 0.10, 0.14)
			btn.add_theme_stylebox_override("normal",  slot_style)
			btn.add_theme_stylebox_override("hover",   slot_style)
			btn.add_theme_stylebox_override("pressed", slot_style)
			btn.disabled = true
		elif _items[i] != null:
			var item: InventoryItem = _items[i]
			slot_style.bg_color = COLOR_SLOT_FILLED
			btn.add_theme_stylebox_override("normal",  slot_style)
			btn.add_theme_stylebox_override("hover",   slot_style)
			btn.add_theme_stylebox_override("pressed", slot_style)
			btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			if item.data is PlaceableDefinition:
				var def: PlaceableDefinition = item.data as PlaceableDefinition
				var icon_tr: TextureRect = TextureRect.new()
				icon_tr.texture      = PieceSpriteGenerator.generate_icon(def.shape, def.shape.color)
				icon_tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				icon_tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				icon_tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				icon_tr.mouse_filter   = Control.MOUSE_FILTER_IGNORE
				btn.add_child(icon_tr)
				var overlay: Label = Label.new()
				overlay.text       = def.shape.get_label(item.display_name)
				overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				overlay.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				overlay.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
				overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
				overlay.add_theme_font_size_override("font_size", 8)
				overlay.add_theme_color_override("font_color", Color.WHITE)
				overlay.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
				overlay.add_theme_constant_override("shadow_offset_x", 1)
				overlay.add_theme_constant_override("shadow_offset_y", 1)
				btn.add_child(overlay)
			var captured: InventoryItem = item
			btn.button_down.connect(func() -> void: item_held.emit(captured))
		else:
			slot_style.bg_color = COLOR_SLOT_EMPTY
			btn.add_theme_stylebox_override("normal",  slot_style)
			btn.add_theme_stylebox_override("hover",   slot_style)
			btn.add_theme_stylebox_override("pressed", slot_style)
			btn.mouse_default_cursor_shape = Control.CURSOR_ARROW

		_grid_container.add_child(btn)
