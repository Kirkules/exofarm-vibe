class_name HomeScreen
extends Control

## Hub home screen. Entry point when no run is in progress.
## Navigates to: game (continue/new run), settings, catalog, run history.

var _interstitial: NewRunInterstitial


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
	title.text = "ExoFarm"
	title.add_theme_font_size_override("font_size", 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var subtitle: Label = Label.new()
	subtitle.text = "SEED Expedition Dispatch"
	subtitle.add_theme_font_size_override("font_size", 9)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.modulate = Color(0.7, 0.7, 0.7, 1.0)
	vbox.add_child(subtitle)

	_add_spacer(vbox, 8.0)

	if GameState.run_in_progress:
		var continue_btn: Button = _make_button("Continue Run")
		continue_btn.pressed.connect(_on_continue_run)
		vbox.add_child(continue_btn)

	var new_btn: Button = _make_button("New Run")
	new_btn.pressed.connect(_on_new_run)
	vbox.add_child(new_btn)

	_add_spacer(vbox, 8.0)

	var settings_btn: Button = _make_button("Settings")
	settings_btn.pressed.connect(_on_settings)
	vbox.add_child(settings_btn)

	var catalog_btn: Button = _make_button("Catalog")
	catalog_btn.pressed.connect(_on_catalog)
	vbox.add_child(catalog_btn)

	var history_btn: Button = _make_button("Mission History")
	history_btn.pressed.connect(_on_history)
	vbox.add_child(history_btn)


func _on_continue_run() -> void:
	get_tree().change_scene_to_file("res://scenes/game/game.tscn")


func _on_new_run() -> void:
	_interstitial = NewRunInterstitial.new()
	_interstitial.confirmed.connect(_start_new_run)
	add_child(_interstitial)


func _start_new_run() -> void:
	GameState.reset_for_new_run()
	get_tree().change_scene_to_file("res://scenes/game/game.tscn")


func _on_settings() -> void:
	var settings: SettingsScreen = SettingsScreen.new()
	settings.in_run = false
	add_child(settings)


func _on_catalog() -> void:
	get_tree().change_scene_to_file("res://scenes/hub/catalog_screen.tscn")


func _on_history() -> void:
	get_tree().change_scene_to_file("res://scenes/hub/run_history_screen.tscn")


func _make_button(text: String) -> Button:
	var btn: Button = Button.new()
	btn.text                    = text
	btn.custom_minimum_size     = Vector2(160.0, 32.0)
	return btn


func _add_spacer(parent: Control, height: float) -> void:
	var s: Control = Control.new()
	s.custom_minimum_size = Vector2(0.0, height)
	parent.add_child(s)
