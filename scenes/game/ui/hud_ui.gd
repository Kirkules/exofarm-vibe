class_name HudUI
extends Control

## Top-of-screen HUD: Energy, Matter, and Settlers each on their own line,
## left-justified, with the Next Season button top-right.
## Transparent background; auto-insets below display cutout.

const COLOR_TOOLTIP := Color(0.12, 0.12, 0.16)
## Font size for HUD info labels (~80% of Godot's default 16px).
const INFO_FONT_SIZE := 13
## Content height before safe-area inset — fits three rows at INFO_FONT_SIZE.
const BASE_HEIGHT := 52

## Emitted when the player presses the Next Season button.
signal next_season_pressed

var _energy_label:  Label
var _matter_label:  RichTextLabel
var _settler_label: Label
var _next_btn:      Button
var _content_margin: MarginContainer

## Cached matter projection values, set by refresh_matter() before refresh().
var _matter_projected: int = 0
var _matter_delta:     int = 0
## How many settlers (first N in list order) are projected to be fed this season.
var _settler_fed_count: int = 0

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
	_content_margin = MarginContainer.new()
	_content_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_content_margin)

	# Outer row: info VBox on the left, Next Season button top-right.
	var outer_hbox: HBoxContainer = HBoxContainer.new()
	_content_margin.add_child(outer_hbox)

	var info_vbox: VBoxContainer = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer_hbox.add_child(info_vbox)

	_energy_label = _make_info_label()
	info_vbox.add_child(_energy_label)

	_matter_label = RichTextLabel.new()
	_matter_label.bbcode_enabled = true
	_matter_label.fit_content = true
	_matter_label.scroll_active = false
	_matter_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_matter_label.add_theme_font_size_override("normal_font_size", INFO_FONT_SIZE)
	info_vbox.add_child(_matter_label)

	_settler_label = _make_info_label()
	_settler_label.mouse_filter = Control.MOUSE_FILTER_STOP
	_settler_label.gui_input.connect(_on_settler_label_input)
	info_vbox.add_child(_settler_label)

	_next_btn = Button.new()
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
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lbl.add_theme_font_size_override("font_size", INFO_FONT_SIZE)
	return lbl

# ---------------------------------------------------------------------------
# Safe area
# ---------------------------------------------------------------------------

func _apply_safe_area() -> void:
	var safe_area: Rect2i      = DisplayServer.get_display_safe_area()
	var window_size: Vector2i  = DisplayServer.window_get_size()
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var scale_y: float = viewport_size.y / float(window_size.y)
	var top_inset: int = int(safe_area.position.y * scale_y)
	_content_margin.add_theme_constant_override("margin_top", top_inset)
	var total_height: int = BASE_HEIGHT + top_inset
	custom_minimum_size.y = total_height
	offset_bottom = total_height
	_settler_tooltip.position = Vector2(0.0, float(total_height))

# ---------------------------------------------------------------------------
# Public
# ---------------------------------------------------------------------------

## Hide the Next Season button during simulation; restore it on return to planning.
func set_simulation_active(v: bool) -> void:
	_next_btn.visible = not v
	if v:
		_hide_settler_tooltip()

## Update how many settlers are projected to be fed (first N in list order).
func set_settler_fed_count(fed_count: int) -> void:
	_settler_fed_count = fed_count

## Store projected matter and delta, then update the matter label.
## Must be called before refresh() so the correct values are displayed.
func refresh_matter(projected: int, delta: int) -> void:
	_matter_projected = projected
	_matter_delta     = delta
	_update_matter_label()

## Reads current values from GameState and updates all labels.
func refresh() -> void:
	_energy_label.text  = "Energy: %d/%d" % [GameState.energy, GameState.energy_capacity]
	_update_matter_label()
	_settler_label.text = "Settlers: %d" % GameState.settler_count
	if _settler_fed_count < GameState.settler_count:
		_settler_label.add_theme_color_override("font_color", Color("#ee8888"))
	else:
		_settler_label.remove_theme_color_override("font_color")
	_next_btn.text      = "Go to Season %d" % (GameState.season + 1)

func _update_matter_label() -> void:
	var sign: String  = "+" if _matter_delta >= 0 else ""
	var color: String = "#88ee88" if _matter_delta >= 0 else "#ee8888"
	_matter_label.text = "Matter: %d([color=%s]%s%d[/color])" \
		% [_matter_projected, color, sign, _matter_delta]

# ---------------------------------------------------------------------------
# Settler tooltip
# ---------------------------------------------------------------------------

func _show_settler_tooltip() -> void:
	for child: Node in _tooltip_name_box.get_children():
		child.queue_free()
	for i: int in range(GameState.settler_names.size()):
		var settler_name: String = GameState.settler_names[i]
		var status: String = "fed" if i < _settler_fed_count else "starving"
		var lbl: Label = Label.new()
		lbl.text = "%s (%s)" % [settler_name, status]
		lbl.add_theme_font_size_override("font_size", INFO_FONT_SIZE)
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
