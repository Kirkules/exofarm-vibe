class_name CatalogScreen
extends Control

## Design catalog stub. Will show all known designs and recipes from meta-progression.


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.12, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.size = Vector2(200.0, 0.0)
	add_child(vbox)

	var title: Label = Label.new()
	title.text                 = "Design Catalog"
	title.add_theme_font_size_override("font_size", 14)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var stub: Label = Label.new()
	stub.text                 = "No designs unlocked yet.\nComplete expeditions to expand\nhumanity's knowledge."
	stub.add_theme_font_size_override("font_size", 9)
	stub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stub.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
	stub.modulate             = Color(0.7, 0.7, 0.7, 1.0)
	vbox.add_child(stub)

	var back_btn: Button = Button.new()
	back_btn.text                = "Back"
	back_btn.custom_minimum_size = Vector2(120.0, 32.0)
	back_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/hub/home_screen.tscn"))
	vbox.add_child(back_btn)
