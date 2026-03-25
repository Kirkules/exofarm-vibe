class_name HudUI
extends Control

## Top-of-screen HUD bar showing season number, resources, and the Next Season button.
## Automatically insets content below the device's display cutout (punch-hole camera,
## notch, etc.) using DisplayServer.get_display_safe_area().

const COLOR_BG    := Color(0.10, 0.10, 0.12)
const BASE_HEIGHT := 48  ## Content height before any safe-area inset.

## Emitted when the player presses the Next Season button.
signal next_season_pressed

var _season_label:   Label
var _energy_label:   Label
var _matter_label:   Label
var _next_btn:       Button
var _content_margin: MarginContainer


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
	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg: StyleBoxFlat = StyleBoxFlat.new()
	bg.bg_color = COLOR_BG
	panel.add_theme_stylebox_override("panel", bg)
	add_child(panel)

	_content_margin = MarginContainer.new()
	panel.add_child(_content_margin)

	var hbox: HBoxContainer = HBoxContainer.new()
	_content_margin.add_child(hbox)

	_season_label = Label.new()
	_season_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_season_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox.add_child(_season_label)

	_energy_label = Label.new()
	_energy_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_energy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox.add_child(_energy_label)

	_matter_label = Label.new()
	_matter_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_matter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox.add_child(_matter_label)

	_next_btn = Button.new()
	_next_btn.text = "Next Season"
	_next_btn.pressed.connect(_on_next_season_button_pressed)
	hbox.add_child(_next_btn)

# ---------------------------------------------------------------------------
# Safe area
# ---------------------------------------------------------------------------

func _apply_safe_area() -> void:
	var safe_area: Rect2i = DisplayServer.get_display_safe_area()
	var window_size: Vector2i = DisplayServer.window_get_size()
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var scale_y: float = viewport_size.y / float(window_size.y)
	var top_inset: int = int(safe_area.position.y * scale_y)
	_content_margin.add_theme_constant_override("margin_top", top_inset)
	var total_height: int = BASE_HEIGHT + top_inset
	custom_minimum_size.y = total_height
	offset_bottom = total_height

# ---------------------------------------------------------------------------
# Public
# ---------------------------------------------------------------------------

## Hide the Next Season button during simulation; restore it on return to planning.
func set_simulation_active(v: bool) -> void:
	_next_btn.visible = not v

## Reads current values from GameState and updates all labels.
func refresh() -> void:
	_season_label.text = "Season %d" % GameState.season
	_energy_label.text = "E %d/%d" % [GameState.energy, GameState.energy_capacity]
	_matter_label.text = "M %d/%d" % [GameState.matter, GameState.matter_capacity]

# ---------------------------------------------------------------------------
# Internal
# ---------------------------------------------------------------------------

func _on_next_season_button_pressed() -> void:
	next_season_pressed.emit()
