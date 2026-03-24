extends Node2D

@onready var farm_grid: FarmGrid = $FarmGrid
@onready var inventory_ui: InventoryUI = $UILayer/InventoryUI
@onready var hud_ui: HudUI = $UILayer/HudUI

var _inventory: Inventory
## The InventoryItem currently in the air (held by farm_grid).
var _held_item: InventoryItem = null
## Maps piece_id -> InventoryItem for pieces currently on the grid,
## so their name and metadata survive pick-up/put-down cycles.
var _placed_items: Dictionary = {}

func _ready() -> void:
	_inventory = Inventory.new(10)
	inventory_ui.set_inventory(_inventory)
	inventory_ui.set_grid_bottom(farm_grid.position.y + farm_grid.get_grid_pixel_size().y)
	farm_grid.set_inventory_control(inventory_ui)
	inventory_ui.item_requested.connect(_on_item_requested)
	farm_grid.piece_picked_up_from_grid.connect(_on_piece_picked_up_from_grid)
	farm_grid.piece_placed_on_grid.connect(_on_piece_placed_on_grid)
	farm_grid.piece_hold_cancelled.connect(_on_piece_hold_cancelled)
	farm_grid.piece_returned_to_grid.connect(_on_piece_returned_to_grid)
	farm_grid.inventory_item_pickup_confirmed.connect(_on_inventory_item_pickup_confirmed)
	hud_ui.next_season_pressed.connect(_on_next_season_pressed)

	# Seed inventory with starting buildings and test pieces.
	for def: PlaceableDefinition in _starting_placeables():
		_inventory.add(InventoryItem.new(def.display_name, def.slot_size, def))

func _starting_placeables() -> Array[PlaceableDefinition]:
	var result: Array[PlaceableDefinition] = []

	# Solar Rig — produces energy each season.
	var solar_shape: PieceShape = PieceShape.new()
	solar_shape.color = Color(0.95, 0.80, 0.20)
	solar_shape.label = "SOL"
	var solar_rig: BuildingDefinition = BuildingDefinition.new()
	solar_rig.display_name = "Solar Rig"
	solar_rig.shape = solar_shape
	solar_rig.moveable = false
	solar_rig.energy_production = 3
	result.append(solar_rig)

	# Matter Manipulator — produces matter each season.
	var matter_shape: PieceShape = PieceShape.new()
	matter_shape.color = Color(0.45, 0.75, 0.55)
	matter_shape.label = "MAT"
	var matter_manip: BuildingDefinition = BuildingDefinition.new()
	matter_manip.display_name = "Matter Manipulator"
	matter_manip.shape = matter_shape
	matter_manip.moveable = false
	matter_manip.matter_production = 3
	result.append(matter_manip)

	# Placeholder test pieces (to be replaced by proper definitions in later phases).
	var l_shape: PieceShape = PieceShape.new()
	l_shape.offsets = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1)]
	l_shape.color = Color(0.40, 0.60, 0.90)
	l_shape.effect_range = 2
	var l_piece: PlaceableDefinition = PlaceableDefinition.new()
	l_piece.display_name = "L-Piece"
	l_piece.shape = l_shape.with_centered_origin()
	result.append(l_piece)

	var crop_shape: PieceShape = PieceShape.new()
	crop_shape.color = Color(0.55, 0.88, 0.38)
	crop_shape.effect_range = 1
	var crop_plot: PlaceableDefinition = PlaceableDefinition.new()
	crop_plot.display_name = "Crop Plot"
	crop_plot.shape = crop_shape
	result.append(crop_plot)
	result.append(crop_plot)  # two copies

	return result

func _unhandled_input(event: InputEvent) -> void:
	# Phase 0: Enter/space rotates the held piece clockwise.
	if event.is_action_pressed("ui_accept"):
		farm_grid.rotate_held_cw()

func _on_item_requested(item: InventoryItem) -> void:
	if farm_grid.has_held_piece or farm_grid.has_pending_pickup:
		return
	if item.data is PlaceableDefinition:
		farm_grid.begin_pending_inventory_hold(item)

func _on_inventory_item_pickup_confirmed(item: InventoryItem) -> void:
	_held_item = item
	_inventory.remove(item)

func _on_piece_picked_up_from_grid(piece_id: int, _shape: PieceShape) -> void:
	_held_item = _placed_items.get(piece_id, null)
	_placed_items.erase(piece_id)
	if _held_item:
		farm_grid.set_held_hint(_held_item.display_name)

func _on_piece_placed_on_grid(piece_id: int) -> void:
	if _held_item:
		_placed_items[piece_id] = _held_item
		var def: PlaceableDefinition = _held_item.data as PlaceableDefinition
		farm_grid.set_piece_moveable(piece_id, def.moveable if def else true)
	_held_item = null

func _on_piece_hold_cancelled(_shape: PieceShape) -> void:
	if _held_item:
		_inventory.add(_held_item)
		_held_item = null

func _on_piece_returned_to_grid(piece_id: int) -> void:
	if _held_item:
		_placed_items[piece_id] = _held_item
		var def: PlaceableDefinition = _held_item.data as PlaceableDefinition
		farm_grid.set_piece_moveable(piece_id, def.moveable if def else true)
	_held_item = null

func _on_next_season_pressed() -> void:
	GameState.season += 1
	GameState.energy = GameState.energy_capacity
	GameState.matter = GameState.matter_capacity
	hud_ui.refresh()
