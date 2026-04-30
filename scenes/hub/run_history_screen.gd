class_name RunHistoryScreen
extends Control

## Mission history screen. Lists all completed run reports, newest first.


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.12, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var outer: VBoxContainer = VBoxContainer.new()
	outer.add_theme_constant_override("separation", 0)
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left",   8)
	outer.add_theme_constant_override("margin_right",  8)
	outer.add_theme_constant_override("margin_top",    8)
	outer.add_theme_constant_override("margin_bottom", 8)
	add_child(outer)

	var title: Label = Label.new()
	title.text                 = "Mission History"
	title.add_theme_font_size_override("font_size", 14)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer.add_child(title)

	outer.add_child(HSeparator.new())

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)

	var list: VBoxContainer = VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	var reports: Array[MissionReport] = GameState.load_mission_reports()
	if reports.is_empty():
		var empty_lbl: Label = Label.new()
		empty_lbl.text                 = "No completed missions yet."
		empty_lbl.add_theme_font_size_override("font_size", 9)
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.modulate             = Color(0.7, 0.7, 0.7, 1.0)
		list.add_child(empty_lbl)
	else:
		# Show newest first.
		var sorted: Array[MissionReport] = reports.duplicate()
		sorted.reverse()
		for i: int in sorted.size():
			list.add_child(_make_report_row(sorted[i], reports.size() - i))
			list.add_child(HSeparator.new())

	outer.add_child(HSeparator.new())

	var back_btn: Button = Button.new()
	back_btn.text                = "Back"
	back_btn.custom_minimum_size = Vector2(0.0, 32.0)
	back_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/hub/home_screen.tscn"))
	outer.add_child(back_btn)


func _make_report_row(report: MissionReport, run_number: int) -> Control:
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)

	var date_str: String = Time.get_datetime_string_from_unix_time(report.timestamp).left(10)

	var header_row: HBoxContainer = HBoxContainer.new()
	var run_lbl: Label = Label.new()
	run_lbl.text = "Run %d" % run_number
	run_lbl.add_theme_font_size_override("font_size", 10)
	run_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(run_lbl)
	var date_lbl: Label = Label.new()
	date_lbl.text   = date_str
	date_lbl.add_theme_font_size_override("font_size", 9)
	date_lbl.modulate = Color(0.7, 0.7, 0.7, 1.0)
	header_row.add_child(date_lbl)
	vbox.add_child(header_row)

	var detail: Label = Label.new()
	detail.text = "%s  ·  Season %d/%d  ·  %s" % [
		"Kepler-438b",
		report.seasons_survived,
		MissionReport.MAX_SEASONS,
		report.assessment,
	]
	detail.add_theme_font_size_override("font_size", 9)
	detail.modulate    = Color(0.8, 0.8, 0.8, 1.0)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(detail)

	return vbox
