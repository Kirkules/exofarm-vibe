class_name MissionReportPopup
extends Control

## End-of-run popup. Created programmatically and added to UILayer.
## Covers the screen with a 10% border on all sides; background is dimmed but visible.
## Stays up until the player taps "Return Home".

signal return_home_pressed()

const BORDER_FRAC: float = 0.1
const VIEWPORT_W:  float = 270.0
const VIEWPORT_H:  float = 600.0

const POPUP_X: float = VIEWPORT_W * BORDER_FRAC
const POPUP_Y: float = VIEWPORT_H * BORDER_FRAC
const POPUP_W: float = VIEWPORT_W * (1.0 - BORDER_FRAC * 2.0)
const POPUP_H: float = VIEWPORT_H * (1.0 - BORDER_FRAC * 2.0)

var _dim:   ColorRect
var _panel: PanelContainer
var _scroll: ScrollContainer
var _vbox:  VBoxContainer


func _ready() -> void:
	# Dim layer covers full screen and blocks input to everything behind it.
	_dim = ColorRect.new()
	_dim.color         = Color(0.0, 0.0, 0.0, 0.55)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter  = Control.MOUSE_FILTER_STOP
	add_child(_dim)

	_panel = PanelContainer.new()
	_panel.position    = Vector2(POPUP_X, POPUP_Y)
	_panel.size        = Vector2(POPUP_W, POPUP_H)
	add_child(_panel)

	var outer: VBoxContainer = VBoxContainer.new()
	outer.add_theme_constant_override("separation", 0)
	_panel.add_child(outer)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(_scroll)

	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", 6)
	_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_vbox)

	var btn: Button = Button.new()
	btn.text     = "Return Home"
	btn.pressed.connect(func() -> void: return_home_pressed.emit())
	outer.add_child(btn)

	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_report(report: MissionReport) -> void:
	_vbox.add_child(_make_header(report))
	_vbox.add_child(_make_separator())
	_vbox.add_child(_make_settlers_section(report))
	_vbox.add_child(_make_separator())
	_vbox.add_child(_make_food_section(report))
	_vbox.add_child(_make_separator())
	_vbox.add_child(_make_production_section(report))
	_vbox.add_child(_make_separator())
	_vbox.add_child(_make_assessment_section(report))


# ---------------------------------------------------------------------------
# Section builders
# ---------------------------------------------------------------------------

func _make_header(report: MissionReport) -> Control:
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)

	var title_text: String
	match report.end_reason:
		MissionReport.EndReason.COMPLETE:
			title_text = "MISSION COMPLETE"
		MissionReport.EndReason.COLONY_LOST:
			title_text = "COLONY LOST"
		MissionReport.EndReason.ENDED_EARLY:
			title_text = "MISSION ENDED EARLY"

	var title: Label = _make_label(title_text, 12, true)
	vbox.add_child(title)

	var subtitle: Label = _make_label(
		"Season %d of %d  ·  Kepler-438b" % [report.seasons_survived, MissionReport.MAX_SEASONS],
		9, false)
	vbox.add_child(subtitle)

	return vbox


func _make_settlers_section(report: MissionReport) -> Control:
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	vbox.add_child(_make_label("SETTLERS", 9, true))

	for i: int in report.settler_names.size():
		var row: HBoxContainer = HBoxContainer.new()
		var name_lbl: Label = _make_label(report.settler_names[i], 9, false)
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_lbl)

		var status_text: String
		if report.settler_survived[i]:
			var morale_word: String = _morale_word(report.settler_end_morale[i])
			status_text = "Survived  ·  %s" % morale_word
		else:
			status_text = "Lost — Season %d" % report.settler_lost_season[i]

		var status_lbl: Label = _make_label(status_text, 9, false)
		if not report.settler_survived[i]:
			status_lbl.modulate = Color(0.7, 0.4, 0.4, 1.0)
		row.add_child(status_lbl)
		vbox.add_child(row)

	return vbox


func _make_food_section(report: MissionReport) -> Control:
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	vbox.add_child(_make_label("FOOD & NUTRITION", 9, true))
	vbox.add_child(_make_stat_row(
		"%d" % report.total_cafeteria_meals, "meals from the Cafeteria"))
	vbox.add_child(_make_stat_row(
		"%d" % report.total_paste_servings,  "settlers fed by Nutrient Paste"))
	return vbox


func _make_production_section(report: MissionReport) -> Control:
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	vbox.add_child(_make_label("PRODUCTION", 9, true))
	vbox.add_child(_make_stat_row(
		"%d" % report.total_matter_produced, "Matter produced"))
	vbox.add_child(_make_stat_row(
		"%d" % report.total_crops_yielded,   "crops yielded"))
	return vbox


func _make_assessment_section(report: MissionReport) -> Control:
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.add_child(_make_label("ASSESSMENT", 9, true))
	vbox.add_child(_make_label(report.assessment, 11, true))
	var flavor: Label = _make_label(report.assessment_flavor, 8, false)
	flavor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(flavor)
	return vbox


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_separator() -> HSeparator:
	return HSeparator.new()


func _make_label(text: String, size: int, bold: bool) -> Label:
	var lbl: Label = Label.new()
	lbl.text       = text
	lbl.add_theme_font_size_override("font_size", size)
	if bold:
		lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	else:
		lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1.0))
	return lbl


func _make_stat_row(value: String, description: String) -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	var val_lbl: Label = _make_label(value, 9, true)
	val_lbl.custom_minimum_size = Vector2(24.0, 0.0)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(val_lbl)
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(6.0, 0.0)
	row.add_child(spacer)
	row.add_child(_make_label(description, 9, false))
	return row


func _morale_word(morale: int) -> String:
	if morale >= 2:  return "Happy"
	if morale == 1:  return "Good"
	if morale == 0:  return "Content"
	if morale == -1: return "Restless"
	return "Struggling"
