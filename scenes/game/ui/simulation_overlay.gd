class_name SimulationOverlay
extends Control

## Full-area overlay shown during season simulation.
## Covers the scenic view and farm grid, leaving the HUD and inventory visible.
## Positioned and sized by game.gd at startup.

const COLOR_BG := Color(0.05, 0.05, 0.08, 0.72)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP  # block clicks through to the grid

	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg: StyleBoxFlat = StyleBoxFlat.new()
	bg.bg_color = COLOR_BG
	panel.add_theme_stylebox_override("panel", bg)
	add_child(panel)

	var label: Label = Label.new()
	label.text = "Season animating..."
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	label.grow_vertical   = Control.GROW_DIRECTION_BOTH
	add_child(label)

	visible = false
