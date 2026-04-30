class_name SettingsScreen
extends Control

## Settings popup. Accessible from both the hub and in-run (via gear button).
## When in_run = true, shows the "End Mission" option.

## Set before adding to the scene tree.
var in_run: bool = false

signal end_mission_requested()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var dim: ColorRect = ColorRect.new()
	dim.color         = Color(0.0, 0.0, 0.0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter  = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
			queue_free())
	add_child(dim)

	var panel: PanelContainer = PanelContainer.new()
	panel.position = Vector2(40.0, 80.0)
	panel.size     = Vector2(190.0, 0.0)
	add_child(panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var title: Label = Label.new()
	title.text = "Settings"
	title.add_theme_font_size_override("font_size", 12)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())
	vbox.add_child(_make_volume_row("Master Volume"))
	vbox.add_child(_make_volume_row("SFX Volume"))
	vbox.add_child(_make_volume_row("Music Volume"))

	if in_run:
		vbox.add_child(HSeparator.new())
		var end_btn: Button = Button.new()
		end_btn.text = "End Mission"
		end_btn.pressed.connect(_on_end_mission)
		vbox.add_child(end_btn)

	vbox.add_child(HSeparator.new())

	var close_btn: Button = Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(func() -> void: queue_free())
	vbox.add_child(close_btn)


func _on_end_mission() -> void:
	end_mission_requested.emit()
	queue_free()


func _make_volume_row(label_text: String) -> Control:
	var row: VBoxContainer = VBoxContainer.new()
	row.add_theme_constant_override("separation", 2)

	var lbl: Label = Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 9)
	row.add_child(lbl)

	var slider: HSlider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step      = 0.05
	slider.value     = 1.0
	row.add_child(slider)

	return row
