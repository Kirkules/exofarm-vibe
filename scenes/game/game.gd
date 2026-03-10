extends Node2D

@onready var farm_grid: FarmGrid = $FarmGrid
@onready var inventory_ui: InventoryUI = $UILayer/InventoryUI

var _inventory: Inventory

func _ready() -> void:
	_inventory = Inventory.new(10)
	inventory_ui.set_inventory(_inventory)
	inventory_ui.item_requested.connect(_on_item_requested)
	farm_grid.piece_picked_up_from_grid.connect(_on_piece_picked_up_from_grid)

	# Phase 0: load a test L-shaped piece into inventory.
	var test_shape := PieceShape.new()
	test_shape.offsets = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1)]
	var item := InventoryItem.new("L-Piece", 1, test_shape.with_centered_origin())
	_inventory.add(item)

func _unhandled_input(event: InputEvent) -> void:
	# Phase 0: Enter/space rotates the held piece clockwise.
	if event.is_action_pressed("ui_accept"):
		farm_grid.rotate_held_cw()

func _on_item_requested(item: InventoryItem) -> void:
	# If the item carries a PieceShape and the grid isn't already holding one, pick it up.
	if farm_grid.has_held_piece:
		return
	if item.data is PieceShape:
		_inventory.remove(item)
		farm_grid.hold_piece(item.data)

func _on_piece_picked_up_from_grid(piece_id: int, shape: PieceShape) -> void:
	# When a placed piece is lifted from the grid, put it back in inventory.
	var item := InventoryItem.new("Piece #%d" % piece_id, 1, shape)
	_inventory.add(item)
