class_name InventoryItem
extends RefCounted

## A single item in the player's inventory.
## slot_size: how many inventory slots this item occupies (default 1).
## data: arbitrary payload — a PieceShape for building pieces, or null for simple resources.

var display_name: String
var slot_size: int
var data: Variant

func _init(p_name: String, p_slot_size: int = 1, p_data: Variant = null) -> void:
	display_name = p_name
	slot_size = p_slot_size
	data = p_data
