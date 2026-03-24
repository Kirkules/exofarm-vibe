class_name HudUI
extends Control

## Top-of-screen HUD bar showing season number, resources, and the Next Season button.

const COLOR_BG := Color(0.10, 0.10, 0.12)

## Emitted when the player presses the Next Season button.
signal next_season_pressed

var _season_label: Label
var _energy_label: Label
var _matter_label: Label
var _power_label:  Label

func _ready() -> void:
	_build_ui()
	refresh()

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

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(hbox)

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

	_power_label = Label.new()
	_power_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_power_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox.add_child(_power_label)

	var btn: Button = Button.new()
	btn.text = "Next Season"
	btn.pressed.connect(_on_next_season_button_pressed)
	hbox.add_child(btn)

# ---------------------------------------------------------------------------
# Public
# ---------------------------------------------------------------------------

## Reads current values from GameState and updates all labels.
func refresh() -> void:
	_season_label.text = "Season %d" % GameState.season
	_energy_label.text = "Energy  %d / %d" % [GameState.energy, GameState.energy_capacity]
	_matter_label.text = "Matter  %d / %d" % [GameState.matter, GameState.matter_capacity]
	_power_label.text  = "Power  — / —"

## Update the power draw / pool display. Called by game.gd after every grid change.
func refresh_power(total_pool: int, total_draw: int) -> void:
	_power_label.text = "Power  %d / %d" % [total_draw, total_pool]

# ---------------------------------------------------------------------------
# Internal
# ---------------------------------------------------------------------------

func _on_next_season_button_pressed() -> void:
	next_season_pressed.emit()
