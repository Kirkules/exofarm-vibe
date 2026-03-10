extends Node2D

@onready var farm_grid: FarmGrid = $FarmGrid

func _ready() -> void:
	# Phase 0: load a test L-shaped piece into hand so the grid is immediately usable.
	var test_shape := PieceShape.new()
	test_shape.offsets = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1)]
	farm_grid.hold_piece(test_shape.with_centered_origin())

func _unhandled_input(event: InputEvent) -> void:
	# Phase 0: R key or volume-up rotates the held piece clockwise.
	if event.is_action_pressed("ui_accept"):
		farm_grid.rotate_held_cw()
