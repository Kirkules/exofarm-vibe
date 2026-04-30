class_name NewRunInterstitial
extends Control

## Popup shown before starting a new run, displaying settler names and planet info.
## Stub for a more detailed interstitial in a later phase.

signal confirmed()

const BORDER_FRAC: float = 0.15
const VIEWPORT_W:  float = 270.0
const VIEWPORT_H:  float = 600.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var dim: ColorRect = ColorRect.new()
	dim.color         = Color(0.0, 0.0, 0.0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter  = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var popup_x: float = VIEWPORT_W * BORDER_FRAC
	var popup_y: float = VIEWPORT_H * BORDER_FRAC
	var popup_w: float = VIEWPORT_W * (1.0 - BORDER_FRAC * 2.0)
	var popup_h: float = VIEWPORT_H * (1.0 - BORDER_FRAC * 2.0)

	var panel: PanelContainer = PanelContainer.new()
	panel.position = Vector2(popup_x, popup_y)
	panel.size     = Vector2(popup_w, popup_h)
	add_child(panel)

	var outer: VBoxContainer = VBoxContainer.new()
	outer.add_theme_constant_override("separation", 12)
	panel.add_child(outer)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(vbox)

	var mission_lbl: Label = _make_label("NEW EXPEDITION", 10, true)
	mission_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(mission_lbl)

	var planet_name: Label = _make_label("Kepler-438b", 14, true)
	planet_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(planet_name)

	var planet_type: Label = _make_label("Temperate Rocky", 9, false)
	planet_type.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	planet_type.modulate = Color(0.7, 0.7, 0.7, 1.0)
	vbox.add_child(planet_type)

	var sep: HSeparator = HSeparator.new()
	vbox.add_child(sep)

	var crew_lbl: Label = _make_label("CREW", 9, true)
	vbox.add_child(crew_lbl)

	# Show the default settlers (reset_for_new_run hasn't been called yet).
	var names: Array[String] = ["Alice", "Bruno", "Carmen"]
	for n: String in names:
		var lbl: Label = _make_label(n, 9, false)
		vbox.add_child(lbl)

	var begin_btn: Button = Button.new()
	begin_btn.text                = "Begin Mission"
	begin_btn.custom_minimum_size = Vector2(0.0, 36.0)
	begin_btn.pressed.connect(func() -> void: confirmed.emit())
	outer.add_child(begin_btn)


func _make_label(text: String, size: int, bold: bool) -> Label:
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", size)
	if bold:
		lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	else:
		lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1.0))
	return lbl
