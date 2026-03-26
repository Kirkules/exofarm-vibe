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
## Projected health for each settler after this season (parallel to GameState.settler_names).
## Empty until the first _recompute_power call.
var _settler_projected_health: Array[int] = []

## Tooltip panels that drop below the HUD bar (z_index=100 renders above inventory).
var _energy_tooltip:   PanelContainer
var _energy_info_box:  VBoxContainer
var _matter_tooltip:   PanelContainer
var _matter_info_box:  VBoxContainer
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
	_energy_label.mouse_filter = Control.MOUSE_FILTER_STOP
	_energy_label.gui_input.connect(_on_energy_label_input)
	info_vbox.add_child(_energy_label)

	_matter_label = RichTextLabel.new()
	_matter_label.bbcode_enabled = true
	_matter_label.fit_content = true
	_matter_label.scroll_active = false
	_matter_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_matter_label.add_theme_font_size_override("normal_font_size", INFO_FONT_SIZE)
	_matter_label.mouse_filter = Control.MOUSE_FILTER_STOP
	_matter_label.gui_input.connect(_on_matter_label_input)
	info_vbox.add_child(_matter_label)

	_settler_label = _make_info_label()
	_settler_label.mouse_filter = Control.MOUSE_FILTER_STOP
	_settler_label.gui_input.connect(_on_settler_label_input)
	info_vbox.add_child(_settler_label)

	_next_btn = Button.new()
	_next_btn.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_next_btn.pressed.connect(_on_next_season_button_pressed)
	outer_hbox.add_child(_next_btn)

	# Tooltips — drop below the HUD bar; z_index=100 renders above inventory.
	_energy_tooltip = _make_tooltip_panel()
	_energy_info_box = VBoxContainer.new()
	_energy_tooltip.add_child(_energy_info_box)
	add_child(_energy_tooltip)

	_matter_tooltip = _make_tooltip_panel()
	_matter_info_box = VBoxContainer.new()
	_matter_tooltip.add_child(_matter_info_box)
	add_child(_matter_tooltip)

	_settler_tooltip = _make_tooltip_panel()
	_tooltip_name_box = VBoxContainer.new()
	_settler_tooltip.add_child(_tooltip_name_box)
	add_child(_settler_tooltip)

func _make_tooltip_panel() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	var bg: StyleBoxFlat = StyleBoxFlat.new()
	bg.bg_color = COLOR_TOOLTIP
	panel.add_theme_stylebox_override("panel", bg)
	panel.visible = false
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.z_index = 100
	return panel

## Creates a single-line RichTextLabel sized for tooltip content.
func _make_tooltip_rtlabel(bbcode: String) -> RichTextLabel:
	var lbl: RichTextLabel = RichTextLabel.new()
	lbl.bbcode_enabled = true
	lbl.fit_content = true
	lbl.scroll_active = false
	lbl.autowrap_mode = TextServer.AUTOWRAP_OFF  # lets fit_content drive width too
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("normal_font_size", INFO_FONT_SIZE)
	lbl.text = bbcode
	return lbl

## Returns BBCode for "Name (+/-N)" with the parenthetical colored by sign.
func _delta_line_bbcode(name: String, delta: int) -> String:
	var sign: String  = "+" if delta > 0 else ""
	var color: String = "#88ee88" if delta > 0 else "#ee8888"
	return "%s ([color=%s]%s%d[/color])" % [name, color, sign, delta]

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
	var tooltip_y: float = float(total_height)
	_energy_tooltip.position  = Vector2(0.0, tooltip_y)
	_matter_tooltip.position  = Vector2(0.0, tooltip_y)
	_settler_tooltip.position = Vector2(0.0, tooltip_y)

# ---------------------------------------------------------------------------
# Public
# ---------------------------------------------------------------------------

## Hide the Next Season button during simulation; restore it on return to planning.
func set_simulation_active(v: bool) -> void:
	_next_btn.visible = not v
	if v:
		_energy_tooltip.visible  = false
		_matter_tooltip.visible  = false
		_hide_settler_tooltip()

## Rebuild the Energy tooltip content.
## entries: Array of {name: String, delta: int} — positive = production, negative = draw.
func refresh_energy_tooltip(entries: Array) -> void:
	for child: Node in _energy_info_box.get_children():
		child.queue_free()
	for entry: Dictionary in entries:
		_energy_info_box.add_child(_make_tooltip_rtlabel(_delta_line_bbcode(entry["name"], entry["delta"])))

## Rebuild the Matter tooltip content.
## entries: Array of {name: String, delta: int} — positive = production, negative = consumption.
func refresh_matter_tooltip(stored: int, entries: Array) -> void:
	for child: Node in _matter_info_box.get_children():
		child.queue_free()
	_matter_info_box.add_child(_make_tooltip_rtlabel("Stored Matter (%d)" % stored))
	for entry: Dictionary in entries:
		_matter_info_box.add_child(_make_tooltip_rtlabel(_delta_line_bbcode(entry["name"], entry["delta"])))

## Update the projected health for each settler (parallel to GameState.settler_names).
func set_settler_projected_health(projected: Array[int]) -> void:
	_settler_projected_health = projected

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
	var any_starving: bool = false
	for i: int in _settler_projected_health.size():
		if GameState.settler_health[i] != GameState.SettlerHealth.DEAD \
				and _settler_projected_health[i] == GameState.SettlerHealth.DEAD:
			any_starving = true
			break
	if any_starving:
		_settler_label.add_theme_color_override("font_color", Color("#ee8800"))
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
	for i: int in GameState.settler_names.size():
		var settler_name: String = GameState.settler_names[i]
		var current: int = GameState.settler_health[i] if i < GameState.settler_health.size() \
			else GameState.SettlerHealth.FED
		var line: String
		if current == GameState.SettlerHealth.DEAD:
			line = "%s ([color=#ee4444]dead[/color])" % settler_name
		else:
			var projected: int = _settler_projected_health[i] \
				if i < _settler_projected_health.size() else GameState.SettlerHealth.FED
			if projected == GameState.SettlerHealth.FED:
				line = "%s ([color=#88ee88]fed[/color])" % settler_name
			else:
				line = "%s ([color=#ee8800]starving[/color])" % settler_name
		_tooltip_name_box.add_child(_make_tooltip_rtlabel(line))
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

func _on_energy_label_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_energy_tooltip.visible = mb.pressed
	elif event is InputEventScreenTouch:
		_energy_tooltip.visible = (event as InputEventScreenTouch).pressed

func _on_matter_label_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_matter_tooltip.visible = mb.pressed
	elif event is InputEventScreenTouch:
		_matter_tooltip.visible = (event as InputEventScreenTouch).pressed

func _on_next_season_button_pressed() -> void:
	next_season_pressed.emit()
