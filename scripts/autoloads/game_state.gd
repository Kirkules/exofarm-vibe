extends Node

const SAVE_PATH := "user://save.res"

var season: int = 1
var settler_count: int = 3
var settler_names: Array[String] = ["Alice", "Bruno", "Carmen"]
var morale: int = 10
var energy_capacity: int = 0
var energy: int = 0
var matter: int = 0

func _ready() -> void:
	# Ensure we handle app pause and close for save-on-background.
	get_tree().set_auto_accept_quit(false)
	energy = 0
	matter = 0

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		save()
		if what == NOTIFICATION_WM_CLOSE_REQUEST:
			get_tree().quit()

## Saves current game state. Stub — SaveData resource implemented in Phase 2+.
func save() -> void:
	pass

## Loads saved game state. Stub — implemented in Phase 2+.
func load_save() -> void:
	pass
