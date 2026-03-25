class_name HudUI
extends Control

## Top-of-screen HUD bar showing season number, resources, settler count,
## and the Next Season button.
## Automatically insets content below the device's display cutout.
## Background is transparent; the Next Season button has dedicated space
## in the top-right, and info rows wrap vertically as needed.

const COLOR_TOOLTIP := Color(0.12, 0.12, 0.16)
## Content height (before safe-area inset) — sized for two label rows.
const BASE_HEIGHT := 56

## Emitted when the player presses the Next Season button.
signal next_season_pressed

var _season_label:  Label
var _energy_label:  Label
var _matter_label:  Label
var _settler_label: Label
var _next_btn:      Button
var _content_margin: MarginContainer

## Tooltip panel that drops below the HUD bar to show settler names.
var _settler_tooltip:  PanelContainer
var _tooltip_name_box: VBoxContainer


func _ready() -> void:
	_build_ui()
	_apply_safe_area()
	refresh()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_apply_safe_area()

# ---------------------------------------------------------------------------
# Build (once)
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	# No opaque panel — transparent background.
	_content_margin = MarginContainer.new()
	_content_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_content_margin)

	# Outer row: info VBox on the left, Next Season button on the right.
	var outer_hbox: HBoxContainer = HBoxContainer.new()
	_content_margin.add_child(outer_hbox)

	var info_vbox: VBoxContainer = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer_hbox.add_child(info_vbox)

	# Row 1: Season | Energy | Matter
	var row1: HBoxContainer = HBoxContainer.new()
	info_vbox.add_child(row1)

	_season_label = _make_info_label()
	row1.add_child(_season_label)

	_energy_label = _make_info_label()
	row1.add_child(_energy_label)

	_matter_label = _make_info_label()
	row1.add_child(_matter_label)

	# Row 2: Settlers (interactive — press to reveal names)
	_settler_label = _make_info_label()
	_settler_label.mouse_filter = Control.MOUSE_FILTER_STOP
	_settler_label.gui_input.connect(_on_settler_label_input)
	info_vbox.add_child(_settler_label)

	# Next Season button — top-aligned so it sits in the top-right corner.
	_next_btn = Button.new()
	_next_btn.text = "Next Season"
	_next_btn.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_next_btn.pressed.connect(_on_next_season_button_pressed)
	outer_hbox.add_child(_next_btn)

	# Settler name tooltip — drops below the HUD bar.
	_settler_tooltip = PanelContainer.new()
	var tt_bg: StyleBoxFlat = StyleBoxFlat.new()
	tt_bg.bg_color = COLOR_TOOLTIP
	_settler_tooltip.add_theme_stylebox_override("panel", tt_bg)
	_settler_tooltip.visible = false
	_settler_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_settler_tooltip)

	_tooltip_name_box = VBoxContainer.new()
	_settler_tooltip.add_child(_tooltip_name_box)

func _make_info_label() -> Label:
	var lbl: Label = Label.new()
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return lbl

# ---------------------------------------------------------------------------
# Safe area
# ---------------------------------------------------------------------------

func _apply_safe_area() -> void:
	var safe_area: Rect2i  = DisplayServer.get_display_safe_area()
	var window_size: Vector2i  = DisplayServer.window_get_size()
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var scale_y: float = viewport_size.y / float(window_size.y)
	var top_inset: int = int(safe_area.position.y * scale_y)
	_content_margin.add_theme_constant_override("margin_top", top_inset)
	var total_height: int = BASE_HEIGHT + top_inset
	custom_minimum_size.y = total_height
	offset_bottom = total_height
	# Keep tooltip anchored just below the HUD bar.
	_settler_tooltip.position = Vector2(0.0, float(total_height))

# ---------------------------------------------------------------------------
# Public
# ---------------------------------------------------------------------------

## Hide the Next Season button during simulation; restore it on return to planning.
func set_simulation_active(v: bool) -> void:
	_next_btn.visible = not v
	if v:
		_hide_settler_tooltip()

## Reads current values from GameState and updates all labels.
func refresh() -> void:
	_season_label.text  = "Season %d" % GameState.season
	_energy_label.text  = "E %d/%d" % [GameState.energy, GameState.energy_capacity]
	_matter_label.text  = "M %d/%d" % [GameState.matter, GameState.matter_capacity]
	_settler_label.text = "Settlers: %d" % GameState.settler_count

# ---------------------------------------------------------------------------
# Settler tooltip
# ---------------------------------------------------------------------------

func _show_settler_tooltip() -> void:
	for child: Node in _tooltip_name_box.get_children():
		child.queue_free()
	for name: String in GameState.settler_names:
		var lbl: Label = Label.new()
		lbl.text = name
		lbl.add_theme_font_size_override("font_size", 10)
		_tooltip_name_box.add_child(lbl)
	_settler_tooltip.visible = true

func _hide_settler_tooltip() -> void:
	_settler_tooltip.visible = false

# ---------------------------------------------------------------------------
# Internal
# ---------------------------------------------------------------------------

func _on_settler_label_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_show_settler_tooltip()
			else:
				_hide_settler_tooltip()
	elif event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event as InputEventScreenTouch
		if st.pressed:
			_show_settler_tooltip()
		else:
			_hide_settler_tooltip()

func _on_next_season_button_pressed() -> void:
	next_season_pressed.emit()
