class_name Settler
extends RefCounted

## Represents a single named settler with their current health and morale.
## Owned by GameState.settlers (Array[Settler]).

enum Health { FED, STARVING, DEAD }

var name:   String = ""
var health: Health = Health.FED
var morale: int    = 10


func _init(settler_name: String) -> void:
	name = settler_name
