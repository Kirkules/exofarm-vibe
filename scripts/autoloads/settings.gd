extends Node

const SAVE_PATH := "user://settings.cfg"

## If true, dragged items are offset upward from the touch point so a finger
## does not obscure them on a touchscreen.
var drag_offset: bool = true

var master_volume: float = 1.0
var sfx_volume: float = 1.0
var music_volume: float = 1.0

func _ready() -> void:
	load_settings()

func save_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("display", "drag_offset", drag_offset)
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.save(SAVE_PATH)

func load_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	drag_offset = config.get_value("display", "drag_offset", true)
	master_volume = config.get_value("audio", "master_volume", 1.0)
	sfx_volume = config.get_value("audio", "sfx_volume", 1.0)
	music_volume = config.get_value("audio", "music_volume", 1.0)
