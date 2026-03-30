extends Node2D

@onready var farm_grid:    FarmGrid    = $FarmGrid
@onready var inventory_ui: InventoryUI = $UILayer/InventoryUI
@onready var hud_ui:       HudUI       = $UILayer/HudUI
@onready var _ui_layer:    CanvasLayer = $UILayer

var _inventory: Inventory
## The InventoryItem currently in the air (held by farm_grid).
var _held_item: InventoryItem = null
## Maps piece_id -> InventoryItem for pieces currently on the grid,
## so their name and metadata survive pick-up/put-down cycles.
var _placed_items: Dictionary = {}
## Maps piece_id -> bool: false = building is toggled off by the player.
var _piece_active: Dictionary = {}
## Most recently computed power state. Null until the first piece is placed.
var _power_state: PowerSystem.PowerState = null
## Most recently computed neighbor state. Null until the first piece is placed.
var _neighbor_state: NeighborSystem.NeighborState = null
## Reusable confirmation dialog for risky Next Season actions.
var _confirm_dialog: ConfirmationDialog
## Timer that ends the simulation phase after SIMULATION_DURATION seconds.
var _sim_timer: Timer
## Season progress bar and elapsed-time label shown just above the grid during simulation.
var _sim_progress_container: HBoxContainer
var _sim_progress_bar:       ProgressBar
var _sim_progress_label:     Label
## Elapsed seconds in the current simulation; reset at start of each season.
var _sim_elapsed: float = 0.0
## Speed multiplier applied to simulation delta. Set > 1 by _skip_simulation().
var _sim_speed_scale: float = 1.0
var _build_menu: BuildMenu

enum Phase { PLANNING, SIMULATION }
var _phase: Phase = Phase.PLANNING

## Build state for each placed piece.  UNBUILT = placed this planning phase,
## flashing, discarded if dragged off-grid.  BUILT = permanent, cannot move.
enum BuildState { UNBUILT, BUILT }
var _piece_build_state: Dictionary = {}    # piece_id -> BuildState
## Build state carried by the currently held piece.
var _held_build_state: BuildState = BuildState.BUILT
## The pending InventoryItem created for a build-menu selection (not from _inventory).
var _pending_menu_item: InventoryItem = null

## Duration of one season simulation (seconds).
const SIMULATION_DURATION := 15.0
## Simulation log entry color constants.
const LOG_COLOR_GAIN  := "#88ee88"  # light green — basic resource production
const LOG_COLOR_LOSS  := "#ee8800"  # orange — basic resource consumption
const LOG_COLOR_DEATH := "#ee4444"  # red — settler death / critical event
const LOG_COLOR_ITEM  := "#eeee88"  # yellow — inventory item gained
## Construction cost locked in at simulation start, before UNBUILT→BUILT transition
## erases the information. Used by _end_simulation() to correctly charge Matter.
var _sim_construction_cost: int = 0
## Season outcome log. Reset at simulation start; populated during _end_simulation().
## Each entry: {"label": String, "value": String, "label_color": String, "value_color": String}
var _sim_log: Array[Dictionary] = []
## Piece ID of the Solar Rig; settlers walk from here to greenhouses.
var _solar_rig_piece_id: int = -1
## Per-greenhouse state during simulation. Each entry:
## {piece_id, def (GreenhouseDefinition), row, col, tend_countdown, tend_count, settler_dispatched}
var _greenhouse_states: Array[Dictionary] = []
## Active settler animations. Each entry:
## {sprite, from_pos, to_pos, solar_pos, elapsed, duration, returning, gh_idx, settler_name}
var _settler_agents: Array[Dictionary] = []
## Live log overlay VBoxContainer — shows entries as they occur during simulation.
var _sim_live_log_box: VBoxContainer
## Maximum entries shown in the live log overlay at once.
const LIVE_LOG_MAX_ENTRIES := 6
## Maps cafeteria piece_id -> KitchenGrid; one grid per placed BUILT cafeteria.
var _kitchen_grids: Dictionary = {}
## Maps cafeteria piece_id -> {kitchen_piece_id -> InventoryItem}.
var _kitchen_placed_items: Dictionary = {}
## piece_id of the cafeteria whose kitchen grid is currently open (-1 = none).
var _active_cafeteria_id: int = -1

func _ready() -> void:
	_inventory = Inventory.new(10)
	inventory_ui.set_inventory(_inventory)
	inventory_ui.set_grid_bottom(farm_grid.position.y + farm_grid.get_grid_pixel_size().y)
	farm_grid.set_inventory_control(inventory_ui)
	inventory_ui.item_requested.connect(_on_item_requested)
	farm_grid.piece_picked_up_from_grid.connect(_on_piece_picked_up_from_grid)
	farm_grid.piece_placed_on_grid.connect(_on_piece_placed_on_grid)
	farm_grid.piece_released.connect(_on_piece_released)
	farm_grid.piece_returned_to_grid.connect(_on_piece_returned_to_grid)
	farm_grid.inventory_item_pickup_confirmed.connect(_on_inventory_item_pickup_confirmed)
	hud_ui.next_season_pressed.connect(_on_next_season_pressed)
	_confirm_dialog = ConfirmationDialog.new()
	_confirm_dialog.confirmed.connect(_begin_simulation)
	add_child(_confirm_dialog)
	_sim_timer = Timer.new()
	_sim_timer.one_shot = true
	_sim_timer.timeout.connect(_end_simulation)
	add_child(_sim_timer)
	farm_grid.piece_double_tapped.connect(toggle_piece)

	# Season progress bar — sits just above the farm grid, visible only during simulation.
	const PROGRESS_H := 16
	var grid_bottom: float = farm_grid.position.y + farm_grid.get_grid_pixel_size().y
	_sim_progress_container = HBoxContainer.new()
	_sim_progress_container.position = Vector2(0.0, farm_grid.position.y - PROGRESS_H)
	_sim_progress_container.size     = Vector2(270.0, PROGRESS_H)
	_sim_progress_container.visible  = false
	_ui_layer.add_child(_sim_progress_container)

	_sim_progress_bar = ProgressBar.new()
	_sim_progress_bar.min_value = 0.0
	_sim_progress_bar.max_value = SIMULATION_DURATION
	_sim_progress_bar.value = 0.0
	_sim_progress_bar.show_percentage = false
	_sim_progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sim_progress_bar.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	_sim_progress_container.add_child(_sim_progress_bar)

	_sim_progress_label = Label.new()
	_sim_progress_label.text = "0.0 s"
	_sim_progress_label.custom_minimum_size = Vector2(40.0, 0.0)
	_sim_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_sim_progress_label.add_theme_font_size_override("font_size", 10)
	_sim_progress_container.add_child(_sim_progress_label)

	# Live log overlay — fills the scenic-view area between HUD and progress bar.
	var live_log_top: float = hud_ui.offset_bottom
	var live_log_h: float   = _sim_progress_container.position.y - live_log_top
	_sim_live_log_box = VBoxContainer.new()
	_sim_live_log_box.position      = Vector2(2.0, live_log_top)
	_sim_live_log_box.size          = Vector2(266.0, live_log_h)
	_sim_live_log_box.clip_contents = true
	_sim_live_log_box.visible       = false
	_ui_layer.add_child(_sim_live_log_box)

	farm_grid.piece_long_pressed.connect(_on_piece_long_pressed)

	# Build menu — shown below the grid when the inventory is collapsed.
	var viewport_h: float = get_viewport().get_visible_rect().size.y
	_build_menu = BuildMenu.new()
	_build_menu.position = Vector2(0.0, grid_bottom)
	_build_menu.size     = Vector2(270.0, viewport_h - grid_bottom - InventoryUI.COLLAPSED_H)
	_build_menu.building_requested.connect(_on_building_requested)
	_ui_layer.add_child(_build_menu)  # _ready() fires here, initialising _item_list
	_build_menu.set_definitions(_buildable_definitions())
	inventory_ui.state_changed.connect(_on_inventory_state_changed)
	# Ensure inventory_ui renders on top of all programmatically-added UILayer children.
	_ui_layer.move_child(inventory_ui, _ui_layer.get_child_count() - 1)

	# Pre-place starting buildings directly on the grid (as BUILT).
	_place_starting_buildings()

## Builds starting building definitions and places them directly on the grid.
func _place_starting_buildings() -> void:
	var solar_shape: PieceShape = PieceShape.new()
	solar_shape.color = Color(0.95, 0.80, 0.20)
	solar_shape.label = "SOL"
	var solar_rig: BuildingDefinition = BuildingDefinition.new()
	solar_rig.display_name = "Solar Rig"
	solar_rig.shape = solar_shape
	solar_rig.moveable = false
	solar_rig.energy_production = 10
	solar_rig.power_range = 3

	var matter_shape: PieceShape = PieceShape.new()
	matter_shape.color = Color(0.45, 0.75, 0.55)
	matter_shape.label = "MAT"
	var matter_manip: BuildingDefinition = BuildingDefinition.new()
	matter_manip.display_name = "Matter Manipulator"
	matter_manip.shape = matter_shape
	matter_manip.moveable = false
	matter_manip.matter_production = 5
	matter_manip.power_draw = 2

	# Place each building — set _held_item so _on_piece_placed_on_grid registers it.
	# Capture the solar rig piece_id for settler dispatch during simulation.
	_held_item = InventoryItem.new(solar_rig.display_name, 1, solar_rig)
	_solar_rig_piece_id = farm_grid.place_piece_at(solar_rig.shape, 3, 3, solar_rig.display_name)
	_held_item = InventoryItem.new(matter_manip.display_name, 1, matter_manip)
	farm_grid.place_piece_at(matter_manip.shape, 3, 4, matter_manip.display_name)

## Returns the definitions available in the build menu this run.
func _buildable_definitions() -> Array[PlaceableDefinition]:
	var result: Array[PlaceableDefinition] = []

	# --- Crop item definitions (harvested produce; not placed on the farm grid) ---

	var wheat_item_shape: PieceShape = PieceShape.new()
	wheat_item_shape.color = Color(1.0, 0.92, 0.40)  # brighter gold than the greenhouse
	wheat_item_shape.cell_style = PieceShape.CellStyle.CIRCLE
	var wheat_item: PlaceableDefinition = PlaceableDefinition.new()
	wheat_item.display_name = "Wheat"  # auto-label: "WHE"
	wheat_item.shape = wheat_item_shape
	wheat_item.allowed_grids = [PlaceableDefinition.GridType.KITCHEN_GRID]

	var tomato_item_shape: PieceShape = PieceShape.new()
	tomato_item_shape.color = Color(0.95, 0.35, 0.25)  # brighter red
	tomato_item_shape.cell_style = PieceShape.CellStyle.CIRCLE
	var tomato_item: PlaceableDefinition = PlaceableDefinition.new()
	tomato_item.display_name = "Tomato"  # auto-label: "TOM"
	tomato_item.shape = tomato_item_shape
	tomato_item.allowed_grids = [PlaceableDefinition.GridType.KITCHEN_GRID]

	var eggplant_item_shape: PieceShape = PieceShape.new()
	eggplant_item_shape.color = Color(0.65, 0.25, 0.85)  # brighter purple
	eggplant_item_shape.cell_style = PieceShape.CellStyle.CIRCLE
	var eggplant_item: PlaceableDefinition = PlaceableDefinition.new()
	eggplant_item.display_name = "Eggplant"  # auto-label: "EGG"
	eggplant_item.shape = eggplant_item_shape
	eggplant_item.allowed_grids = [PlaceableDefinition.GridType.KITCHEN_GRID]

	# --- Greenhouse definitions (crop-producing grid pieces) ---

	var wheat_gh_shape: PieceShape = PieceShape.new()
	wheat_gh_shape.color = Color(0.95, 0.85, 0.30)  # muted gold
	wheat_gh_shape.label = "WGH"
	var wheat_gh: GreenhouseDefinition = GreenhouseDefinition.new()
	wheat_gh.display_name = "Wheat Greenhouse"
	wheat_gh.shape = wheat_gh_shape
	wheat_gh.matter_cost = 1
	wheat_gh.power_draw = 1
	wheat_gh.output_item = wheat_item
	result.append(wheat_gh)

	var tomato_gh_shape: PieceShape = PieceShape.new()
	tomato_gh_shape.color = Color(0.90, 0.28, 0.20)  # muted red
	tomato_gh_shape.label = "TGH"
	var tomato_gh: GreenhouseDefinition = GreenhouseDefinition.new()
	tomato_gh.display_name = "Tomato Greenhouse"
	tomato_gh.shape = tomato_gh_shape
	tomato_gh.matter_cost = 1
	tomato_gh.power_draw = 1
	tomato_gh.output_item = tomato_item
	result.append(tomato_gh)

	var eggplant_gh_shape: PieceShape = PieceShape.new()
	eggplant_gh_shape.color = Color(0.50, 0.15, 0.65)  # muted purple
	eggplant_gh_shape.label = "EGH"
	var eggplant_gh: GreenhouseDefinition = GreenhouseDefinition.new()
	eggplant_gh.display_name = "Eggplant Greenhouse"
	eggplant_gh.shape = eggplant_gh_shape
	eggplant_gh.matter_cost = 1
	eggplant_gh.power_draw = 1
	eggplant_gh.output_item = eggplant_item
	result.append(eggplant_gh)

	# --- Cafeteria (merge space + consumption area) ---
	var cafeteria_shape: PieceShape = PieceShape.new()
	cafeteria_shape.color = Color(0.90, 0.65, 0.30)  # warm amber
	cafeteria_shape.label = "CAF"
	var cafeteria_offsets: Array[Vector2i] = [Vector2i(0, 0), Vector2i(0, 1)]
	cafeteria_shape.offsets = cafeteria_offsets
	var cafeteria_def: CafeteriaDefinition = CafeteriaDefinition.new()
	cafeteria_def.display_name = "Cafeteria"
	cafeteria_def.shape        = cafeteria_shape
	cafeteria_def.moveable     = false
	cafeteria_def.matter_cost  = 2
	cafeteria_def.power_draw   = 1
	cafeteria_def.merge_slots  = KitchenGrid.KITCHEN_COLS * KitchenGrid.KITCHEN_ROWS
	result.append(cafeteria_def)

	return result

func _on_building_requested(def: PlaceableDefinition) -> void:
	if farm_grid.has_held_piece or farm_grid.has_pending_pickup:
		return
	_pending_menu_item = InventoryItem.new(def.display_name, 1, def)
	farm_grid.begin_pending_inventory_hold(_pending_menu_item)

func _on_inventory_state_changed(collapsed: bool) -> void:
	_build_menu.visible = collapsed

func _unhandled_input(event: InputEvent) -> void:
	# Close the kitchen grid on a new press outside it and outside the inventory.
	if _active_cafeteria_id != -1:
		var press_pos: Vector2 = Vector2.ZERO
		var is_new_press: bool = false
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
			is_new_press = true
			press_pos = (event as InputEventMouseButton).position
		elif event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
			is_new_press = true
			press_pos = (event as InputEventScreenTouch).position
		if is_new_press:
			var active_kg: KitchenGrid = _kitchen_grids.get(_active_cafeteria_id, null) as KitchenGrid
			if active_kg == null or not active_kg.get_full_screen_rect().has_point(press_pos):
				_close_kitchen_grid()
				get_viewport().set_input_as_handled()
				return
	# Phase 0: Enter/space rotates the held piece clockwise.
	if event.is_action_pressed("ui_accept"):
		farm_grid.rotate_held_cw()

func _on_item_requested(item: InventoryItem) -> void:
	if _phase == Phase.SIMULATION:
		return
	if not item.data is PlaceableDefinition:
		return
	# When the kitchen grid is open, route inventory holds to it.
	if _active_cafeteria_id != -1:
		var active_kg: KitchenGrid = _kitchen_grids.get(_active_cafeteria_id, null) as KitchenGrid
		if active_kg != null and not active_kg.has_held_piece and not active_kg.has_pending_pickup:
			active_kg.begin_pending_inventory_hold(item)
		return
	if farm_grid.has_held_piece or farm_grid.has_pending_pickup:
		return
	farm_grid.begin_pending_inventory_hold(item)

func _on_inventory_item_pickup_confirmed(item: InventoryItem) -> void:
	_held_item = item
	_inventory.remove(item)
	# Items selected from the build menu (not _inventory) start UNBUILT.
	_held_build_state = BuildState.UNBUILT if item == _pending_menu_item else BuildState.BUILT
	_pending_menu_item = null
	var def: PlaceableDefinition = item.data as PlaceableDefinition
	var can_place_on_grid: bool = def == null or PlaceableDefinition.GridType.FARM_GRID in def.allowed_grids
	farm_grid.set_held_can_place(can_place_on_grid)
	var pr: int = (def as BuildingDefinition).power_range if def is BuildingDefinition else 0
	farm_grid.set_held_power_range(pr)

func _on_piece_picked_up_from_grid(piece_id: int, _shape: PieceShape) -> void:
	_close_kitchen_grid()
	_held_item = _placed_items.get(piece_id, null)
	_held_build_state = _piece_build_state.get(piece_id, BuildState.BUILT)
	_placed_items.erase(piece_id)
	_piece_build_state.erase(piece_id)
	_piece_active.erase(piece_id)
	if _held_item:
		farm_grid.set_held_hint(_held_item.display_name)
		var def: PlaceableDefinition = _held_item.data as PlaceableDefinition
		var pr: int = (def as BuildingDefinition).power_range if def is BuildingDefinition else 0
		farm_grid.set_held_power_range(pr)
	# UNBUILT pieces dropped off-grid should be discarded, not snapped back.
	farm_grid.set_held_discardable(_held_build_state == BuildState.UNBUILT)
	_recompute_power()
	_sync_kitchen_grid()

func _on_piece_placed_on_grid(piece_id: int) -> void:
	if _held_item:
		_placed_items[piece_id] = _held_item
	_held_item = null
	var def: PlaceableDefinition = (_placed_items[piece_id].data if _placed_items.has(piece_id) else null) as PlaceableDefinition
	# Reject items that don't belong on the farm grid (e.g. crop output items).
	if def != null and not (PlaceableDefinition.GridType.FARM_GRID in def.allowed_grids):
		farm_grid.remove_piece(piece_id)
		_inventory.add(_placed_items[piece_id])
		_placed_items.erase(piece_id)
		_piece_build_state.erase(piece_id)
		farm_grid.set_held_power_range(0)
		return
	_piece_build_state[piece_id] = _held_build_state
	var is_unbuilt: bool = _held_build_state == BuildState.UNBUILT
	_held_build_state = BuildState.BUILT  # reset for next placement
	farm_grid.set_piece_moveable(piece_id, is_unbuilt or (def != null and def.moveable))
	farm_grid.set_piece_toggleable(piece_id, def is BuildingDefinition and not is_unbuilt)
	farm_grid.set_piece_flashing(piece_id, is_unbuilt)
	farm_grid.set_held_power_range(0)
	_recompute_power()
	_sync_kitchen_grid()

## Called when a held INVENTORY-origin piece is released without landing on this grid.
## Routes KITCHEN_GRID items to the kitchen panel if CoM is over it; all others go to
## inventory unless the piece was UNBUILT (from build menu), in which case it is discarded.
func _on_piece_released(com_screen_pos: Vector2) -> void:
	var item: InventoryItem     = _held_item
	var build_state: BuildState = _held_build_state
	_held_item        = null
	_held_build_state = BuildState.BUILT
	farm_grid.set_held_power_range(0)
	if item == null:
		return
	var def: PlaceableDefinition = item.data as PlaceableDefinition
	# Route KITCHEN_GRID-only items to the active kitchen grid if CoM is over it.
	var active_kg: KitchenGrid = _kitchen_grids.get(_active_cafeteria_id, null) as KitchenGrid
	if active_kg != null \
			and def != null \
			and PlaceableDefinition.GridType.KITCHEN_GRID in def.allowed_grids \
			and not (PlaceableDefinition.GridType.FARM_GRID in def.allowed_grids) \
			and active_kg.get_full_screen_rect().has_point(com_screen_pos):
		var best_cell: Vector2i = _find_nearest_empty_kitchen_cell(active_kg, com_screen_pos)
		if best_cell != Vector2i(-1, -1):
			# Restore _held_item so _on_kitchen_piece_placed (fired by place_piece_at)
			# can register the item in _kitchen_placed_items correctly.
			_held_item = item
			var piece_id: int = active_kg.place_piece_at(def.shape, best_cell.x, best_cell.y, item.display_name)
			_held_item = null
			if piece_id != -1:
				return
	# UNBUILT pieces (from build menu) are discarded when dropped off-grid.
	if build_state == BuildState.UNBUILT:
		return
	_inventory.add(item)

func _on_piece_returned_to_grid(piece_id: int) -> void:
	if _held_item:
		_placed_items[piece_id] = _held_item
	_held_item = null
	var def: PlaceableDefinition = (_placed_items[piece_id].data if _placed_items.has(piece_id) else null) as PlaceableDefinition
	_piece_build_state[piece_id] = _held_build_state
	var is_unbuilt: bool = _held_build_state == BuildState.UNBUILT
	_held_build_state = BuildState.BUILT
	farm_grid.set_piece_moveable(piece_id, is_unbuilt or (def != null and def.moveable))
	farm_grid.set_piece_toggleable(piece_id, def is BuildingDefinition and not is_unbuilt)
	farm_grid.set_piece_flashing(piece_id, is_unbuilt)
	farm_grid.set_held_power_range(0)
	_recompute_power()
	_sync_kitchen_grid()

## Toggle a placed building on or off and recompute power.
func toggle_piece(piece_id: int) -> void:
	var now_active: bool = not _piece_active.get(piece_id, true)
	_piece_active[piece_id] = now_active
	farm_grid.set_piece_active_visual(piece_id, now_active)
	_recompute_power()

## Sync kitchen grids to match placed BUILT cafeterias.
## Creates grids for new cafeterias, tears down grids for removed ones.
func _sync_kitchen_grid() -> void:
	# Collect current BUILT cafeterias.
	var built_cafeterias: Dictionary = {}  # piece_id -> slot count
	for piece_id: int in _placed_items:
		if _piece_build_state.get(piece_id, BuildState.BUILT) != BuildState.BUILT:
			continue
		var def: PlaceableDefinition = _placed_items[piece_id].data as PlaceableDefinition
		if def is CafeteriaDefinition:
			built_cafeterias[piece_id] = (def as CafeteriaDefinition).merge_slots
	# Tear down grids whose cafeteria is no longer present.
	for cid: int in _kitchen_grids.keys():
		if not built_cafeterias.has(cid):
			_teardown_kitchen_grid(cid)
	# Create grids for new cafeterias; update capacity for existing ones.
	for cid: int in built_cafeterias:
		if _kitchen_grids.has(cid):
			(_kitchen_grids[cid] as KitchenGrid).set_capacity(built_cafeterias[cid])
		else:
			_create_kitchen_grid_for(cid, built_cafeterias[cid])

## Create and wire a KitchenGrid for the given cafeteria piece_id.
func _create_kitchen_grid_for(cafeteria_id: int, slots: int) -> void:
	var kg: KitchenGrid = KitchenGrid.new()
	var kg_w: float = KitchenGrid.KITCHEN_COLS * KitchenGrid.KITCHEN_CELL_SIZE
	var grid_bottom: float = farm_grid.position.y + farm_grid.get_grid_pixel_size().y
	kg.position = Vector2(
		(270.0 - kg_w) / 2.0,
		grid_bottom - KitchenGrid.KITCHEN_ROWS * KitchenGrid.KITCHEN_CELL_SIZE)
	kg.visible = false
	kg.set_inventory_control(inventory_ui)
	_kitchen_placed_items[cafeteria_id] = {}
	var cid: int = cafeteria_id
	kg.inventory_item_pickup_confirmed.connect(
		func(item: InventoryItem) -> void: _on_kitchen_inventory_item_pickup_confirmed(kg, item))
	kg.piece_placed_on_grid.connect(
		func(pid: int) -> void: _on_kitchen_piece_placed(cid, pid))
	kg.piece_picked_up_from_grid.connect(
		func(pid: int, shape: PieceShape) -> void: _on_kitchen_piece_picked_up(kg, cid, pid, shape))
	kg.piece_released.connect(
		func(pos: Vector2) -> void: _on_kitchen_piece_released(pos))
	kg.piece_returned_to_grid.connect(
		func(pid: int) -> void: _on_kitchen_piece_returned(cid, pid))
	kg.piece_ejected.connect(
		func(pid: int) -> void: _on_kitchen_piece_ejected(cid, pid))
	_ui_layer.add_child(kg)
	_ui_layer.move_child(inventory_ui, _ui_layer.get_child_count() - 1)
	_kitchen_grids[cafeteria_id] = kg
	kg.set_capacity(slots)

## Eject all items from a kitchen grid to inventory, then remove and free it.
func _teardown_kitchen_grid(cafeteria_id: int) -> void:
	if _active_cafeteria_id == cafeteria_id:
		_close_kitchen_grid()
	var items: Dictionary = _kitchen_placed_items.get(cafeteria_id, {}) as Dictionary
	for item: Variant in items.values():
		_inventory.add(item as InventoryItem)
	_kitchen_placed_items.erase(cafeteria_id)
	var kg: KitchenGrid = _kitchen_grids.get(cafeteria_id, null) as KitchenGrid
	if kg != null:
		_ui_layer.remove_child(kg)
		kg.queue_free()
	_kitchen_grids.erase(cafeteria_id)

## Open the kitchen grid for a specific cafeteria.
func _open_kitchen_grid(cafeteria_piece_id: int) -> void:
	var kg: KitchenGrid = _kitchen_grids.get(cafeteria_piece_id, null) as KitchenGrid
	if kg == null:
		return
	_active_cafeteria_id = cafeteria_piece_id
	kg.visible = true
	kg.set_grid_active(true)  # merge_grid_opened only deactivates others; must activate explicitly
	EventBus.merge_grid_opened.emit(kg)

## Close the currently open kitchen grid.
func _close_kitchen_grid() -> void:
	if _active_cafeteria_id == -1:
		return
	var kg: KitchenGrid = _kitchen_grids.get(_active_cafeteria_id, null) as KitchenGrid
	if kg != null:
		kg.visible = false
	_active_cafeteria_id = -1
	EventBus.merge_grid_closed.emit()

## Called when a non-moveable building is long-pressed; opens kitchen grid for cafeterias.
func _on_piece_long_pressed(piece_id: int) -> void:
	if _phase == Phase.SIMULATION:
		return
	var item: InventoryItem = _placed_items.get(piece_id, null)
	if item == null or not item.data is CafeteriaDefinition:
		return
	_open_kitchen_grid(piece_id)

## Kitchen grid: an inventory hold was confirmed; remove from inventory and begin drag.
func _on_kitchen_inventory_item_pickup_confirmed(kg: KitchenGrid, item: InventoryItem) -> void:
	_held_item = item
	_inventory.remove(item)
	var def: PlaceableDefinition = item.data as PlaceableDefinition
	var can_place: bool = def == null or PlaceableDefinition.GridType.KITCHEN_GRID in def.allowed_grids
	kg.set_held_can_place(can_place)

## Kitchen grid: a piece was placed on a slot.
func _on_kitchen_piece_placed(cafeteria_id: int, piece_id: int) -> void:
	var items: Dictionary = _kitchen_placed_items.get(cafeteria_id, {}) as Dictionary
	if _held_item:
		items[piece_id] = _held_item
	_held_item = null

## Kitchen grid: a placed piece was picked up for dragging.
func _on_kitchen_piece_picked_up(kg: KitchenGrid, cafeteria_id: int, piece_id: int, _shape: PieceShape) -> void:
	var items: Dictionary = _kitchen_placed_items.get(cafeteria_id, {}) as Dictionary
	_held_item = items.get(piece_id, null) as InventoryItem
	items.erase(piece_id)
	if _held_item:
		kg.set_held_hint(_held_item.display_name)

## Kitchen grid: a held piece was released without landing on this grid — return to inventory.
func _on_kitchen_piece_released(_com_screen_pos: Vector2) -> void:
	var item: InventoryItem = _held_item
	_held_item = null
	if item != null:
		_inventory.add(item)

## Kitchen grid: a held piece snapped back to its original slot.
func _on_kitchen_piece_returned(cafeteria_id: int, piece_id: int) -> void:
	var items: Dictionary = _kitchen_placed_items.get(cafeteria_id, {}) as Dictionary
	if _held_item:
		items[piece_id] = _held_item
	_held_item = null

## Kitchen grid: capacity reduction ejected a piece — return to inventory.
func _on_kitchen_piece_ejected(cafeteria_id: int, piece_id: int) -> void:
	var items: Dictionary = _kitchen_placed_items.get(cafeteria_id, {}) as Dictionary
	var item: InventoryItem = items.get(piece_id, null) as InventoryItem
	items.erase(piece_id)
	if item != null:
		_inventory.add(item)

## Find the nearest active empty cell in a KitchenGrid to a screen position.
## Returns Vector2i(-1, -1) if no empty active cell exists.
func _find_nearest_empty_kitchen_cell(kg: KitchenGrid, screen_pos: Vector2) -> Vector2i:
	var best: Vector2i = Vector2i(-1, -1)
	var best_dist: float = INF
	for row: int in range(1, KitchenGrid.KITCHEN_ROWS + 1):
		for col: int in range(1, KitchenGrid.KITCHEN_COLS + 1):
			var slot_idx: int = (row - 1) * KitchenGrid.KITCHEN_COLS + (col - 1)
			if slot_idx >= kg._capacity:
				continue
			if kg.grid_data.get_cell(row, col) != 0:
				continue
			var cell_center: Vector2 = kg.position + Vector2(
				(col - 0.5) * KitchenGrid.KITCHEN_CELL_SIZE,
				(row - 0.5) * KitchenGrid.KITCHEN_CELL_SIZE)
			var dist: float = (cell_center - screen_pos).length_squared()
			if dist < best_dist:
				best_dist = dist
				best = Vector2i(row, col)
	return best

## Returns true if any active BUILT Cafeteria on the grid is powered.
func _cafeteria_is_powered() -> bool:
	if _power_state == null:
		return false
	for piece_id: int in _placed_items:
		if not _piece_active.get(piece_id, true):
			continue
		if _piece_build_state.get(piece_id, BuildState.BUILT) != BuildState.BUILT:
			continue
		if not _placed_items[piece_id].data is CafeteriaDefinition:
			continue
		if _power_state.is_powered(piece_id):
			return true
	return false

func _recompute_power() -> void:
	var placed: Dictionary = _build_placed_dict()
	_power_state    = PowerSystem.compute(placed)
	_neighbor_state = NeighborSystem.compute(placed)
	# Energy capacity = total power pool from all placed sources.
	# During planning, energy is always at full capacity (nothing spent yet).
	GameState.energy_capacity = _power_state.total_pool()
	GameState.energy = GameState.energy_capacity - _power_state.total_draw()
	# Compute food and matter projection for HUD.
	var food: Dictionary    = _compute_food_state()
	var paste_produced: int    = food["paste_produced"]
	var matter_prod: int       = food["matter_prod"]
	var construction_cost: int = food["construction_cost"]
	var matter_net: int        = matter_prod - construction_cost - paste_produced
	hud_ui.set_settler_projected_health(food["projected_health"])
	hud_ui.refresh_matter(GameState.matter + matter_net, matter_net)
	hud_ui.refresh_energy_tooltip(_build_energy_entries())
	hud_ui.refresh_matter_tooltip(GameState.matter, _build_matter_entries(food))
	hud_ui.refresh()
	_refresh_overlays(placed)

## Returns the total Matter construction cost of all UNBUILT pieces on the grid.
## Deducted from Matter at season confirmation, before Nutrient Paste production.
func _compute_construction_cost() -> int:
	var cost: int = 0
	for piece_id: int in _placed_items:
		if _piece_build_state.get(piece_id, BuildState.BUILT) != BuildState.UNBUILT:
			continue
		var def: PlaceableDefinition = _placed_items[piece_id].data as PlaceableDefinition
		if def != null:
			cost += def.matter_cost
	return cost

## Returns the Matter that would be produced this season given the current grid layout.
## Buildings with power_draw > 0 only produce if powered.
func _compute_matter_production() -> int:
	var matter_prod: int = 0
	for piece_id: int in _placed_items:
		if not _piece_active.get(piece_id, true):
			continue
		var def: PlaceableDefinition = _placed_items[piece_id].data as PlaceableDefinition
		if not def is BuildingDefinition:
			continue
		var bdef: BuildingDefinition = def as BuildingDefinition
		if bdef.power_draw > 0 and (_power_state == null or not _power_state.is_powered(piece_id)):
			continue
		matter_prod += bdef.matter_production
	return matter_prod

## Returns true if any active placed building with matter_production > 0 is powered.
func _food_is_powered() -> bool:
	if _power_state == null:
		return false
	for piece_id: int in _placed_items:
		if not _piece_active.get(piece_id, true):
			continue
		var def: PlaceableDefinition = _placed_items[piece_id].data as PlaceableDefinition
		if not def is BuildingDefinition:
			continue
		var bdef: BuildingDefinition = def as BuildingDefinition
		if bdef.matter_production > 0 and _power_state.is_powered(piece_id):
			return true
	return false

## Computes the projected food and Nutrient Paste state for the upcoming season end.
## Dead settlers are skipped; construction cost is deducted before paste is produced.
## Keys: matter_prod, construction_cost, food_items, paste_needed, paste_produced,
##       projected_health (Array[int] parallel to settler_names), deaths.
## Pass construction_cost_override >= 0 to use a pre-computed cost (used in simulation
## after the UNBUILT→BUILT transition has already run).
func _compute_food_state(construction_cost_override: int = -1) -> Dictionary:
	var matter_prod: int       = _compute_matter_production()
	var construction_cost: int = construction_cost_override if construction_cost_override >= 0 \
		else _compute_construction_cost()
	var food_items: int        = 0
	if _cafeteria_is_powered():
		for cid: int in _kitchen_placed_items:
			food_items += (_kitchen_placed_items[cid] as Dictionary).size()
	var living: int            = GameState.settler_count  # non-DEAD
	var paste_needed: int      = maxi(0, living - food_items)
	var paste_produced: int    = 0
	if paste_needed > 0 and _food_is_powered():
		var matter_avail: int = maxi(0, GameState.matter + matter_prod - construction_cost)
		paste_produced = mini(paste_needed, matter_avail)
	# Allocate food to living settlers in list order; project each settler's outcome.
	var food_remaining: int = food_items + paste_produced
	var projected_health: Array[int] = []
	var deaths: int = 0
	for i: int in GameState.settler_names.size():
		var current: int = GameState.settler_health[i]
		if current == GameState.SettlerHealth.DEAD:
			projected_health.append(GameState.SettlerHealth.DEAD)
		elif food_remaining > 0:
			projected_health.append(GameState.SettlerHealth.FED)
			food_remaining -= 1
		else:
			projected_health.append(GameState.SettlerHealth.DEAD)
			deaths += 1
	return {
		"matter_prod":       matter_prod,
		"construction_cost": construction_cost,
		"food_items":        food_items,
		"paste_needed":      paste_needed,
		"paste_produced":    paste_produced,
		"projected_health":  projected_health,
		"deaths":            deaths,
	}

## Builds the entry list for the Energy HUD tooltip.
## Each entry: {name: String, delta: int} — positive = produced, negative = drawn.
func _build_energy_entries() -> Array:
	var entries: Array = []
	for piece_id: int in _placed_items:
		if not _piece_active.get(piece_id, true):
			continue
		var item: InventoryItem = _placed_items[piece_id]
		var def: PlaceableDefinition = item.data as PlaceableDefinition
		if not def is BuildingDefinition:
			continue
		var bdef: BuildingDefinition = def as BuildingDefinition
		if bdef.energy_production > 0:
			entries.append({"name": item.display_name, "delta": bdef.energy_production})
		if bdef.power_draw > 0 and _power_state != null and _power_state.is_powered(piece_id):
			entries.append({"name": item.display_name, "delta": -bdef.power_draw})
	return entries

## Builds the entry list for the Matter HUD tooltip.
## Each entry: {name: String, delta: int} — positive = produced, negative = consumed.
func _build_matter_entries(food: Dictionary) -> Array:
	var entries: Array = []
	for piece_id: int in _placed_items:
		if not _piece_active.get(piece_id, true):
			continue
		var item: InventoryItem = _placed_items[piece_id]
		var def: PlaceableDefinition = item.data as PlaceableDefinition
		if not def is BuildingDefinition:
			continue
		var bdef: BuildingDefinition = def as BuildingDefinition
		if bdef.matter_production > 0:
			if bdef.power_draw == 0 or (_power_state != null and _power_state.is_powered(piece_id)):
				entries.append({"name": item.display_name, "delta": bdef.matter_production})
	var construction: int = food["construction_cost"]
	if construction > 0:
		entries.append({"name": "Construction", "delta": -construction})
	var paste: int = food["paste_produced"]
	if paste > 0:
		entries.append({"name": "Nutrient Paste", "delta": -paste})
	return entries

func _refresh_overlays(placed: Dictionary) -> void:
	var power_sources: Array = []
	var effect_sources: Array = []
	for piece_id: int in placed:
		var entry: Dictionary = placed[piece_id]
		if not entry["active"]:
			continue
		var def: PlaceableDefinition = entry["def"] as PlaceableDefinition
		if def == null or def.shape == null:
			continue
		# Power range overlay — buildings only.
		if def is BuildingDefinition:
			var bdef: BuildingDefinition = def as BuildingDefinition
			if bdef.power_range > 0:
				var net_idx: int = _power_state.piece_network_idx.get(piece_id, -1)
				var sufficient: bool = net_idx != -1 \
					and (_power_state.networks[net_idx] as PowerSystem.Network).is_sufficient()
				power_sources.append({
					"row":        entry["row"],
					"col":        entry["col"],
					"range":      bdef.power_range,
					"sufficient": sufficient,
				})
		# Effect-range overlay — any piece with effect_range > 0.
		if def.shape.effect_range > 0:
			effect_sources.append({
				"row":   entry["row"],
				"col":   entry["col"],
				"range": def.shape.effect_range,
			})
	farm_grid.set_power_overlay(power_sources)
	farm_grid.set_effect_overlay(effect_sources)

func _build_placed_dict() -> Dictionary:
	var placed: Dictionary = {}
	for piece_id: int in _placed_items:
		var info: Dictionary = farm_grid.grid_data.get_piece_info(piece_id)
		if info.is_empty():
			continue
		# UNBUILT pieces are not yet constructed; exclude them from power entirely.
		var is_built: bool = _piece_build_state.get(piece_id, BuildState.BUILT) == BuildState.BUILT
		placed[piece_id] = {
			"row":    info["row"],
			"col":    info["col"],
			"def":    _placed_items[piece_id].data,
			"active": is_built and _piece_active.get(piece_id, true),
		}
	return placed

func _on_next_season_pressed() -> void:
	if _phase == Phase.SIMULATION:
		_skip_simulation()
		return
	var food: Dictionary = _compute_food_state()
	if food["deaths"] > 0:
		_confirm_dialog.dialog_text = \
			"Not enough food for all settlers.\n%d settler(s) will starve.\n\nProceed anyway?" \
			% food["deaths"]
		_confirm_dialog.popup_centered()
	else:
		_begin_simulation()

## Compress remaining simulation time into 0.5 s for fast-forward during playtesting.
func _skip_simulation() -> void:
	var remaining: float = _sim_timer.time_left
	if remaining <= 0.5:
		return
	_sim_speed_scale = remaining / 0.5
	_sim_timer.stop()
	_sim_timer.start(0.5)

## Lock in the grid and start the simulation phase.
func _begin_simulation() -> void:
	_close_kitchen_grid()
	_sim_elapsed = 0.0
	_sim_speed_scale = 1.0
	_sim_log.clear()
	hud_ui.refresh_log([])
	for child: Node in _sim_live_log_box.get_children():
		_sim_live_log_box.remove_child(child)
		child.queue_free()
	_sim_live_log_box.visible = true
	# Capture construction cost before UNBUILT→BUILT erases it.
	_sim_construction_cost = _compute_construction_cost()
	_phase = Phase.SIMULATION
	for piece_id: int in _placed_items:
		var def: PlaceableDefinition = _placed_items[piece_id].data as PlaceableDefinition
		# Transition UNBUILT → BUILT: stop flashing, then apply moveable lock.
		if _piece_build_state.get(piece_id, BuildState.BUILT) == BuildState.UNBUILT:
			if def != null and def.matter_cost > 0:
				_add_log_entry({
					"label": "Constructed %s:" % def.display_name,
					"value": "-%d Matter" % def.matter_cost,
					"label_color": "", "value_color": LOG_COLOR_LOSS,
				})
			_piece_build_state[piece_id] = BuildState.BUILT
			farm_grid.set_piece_flashing(piece_id, false)
			farm_grid.set_piece_toggleable(piece_id, def is BuildingDefinition)
		farm_grid.set_piece_moveable(piece_id, def.moveable if def else true)
	# Initialize per-greenhouse simulation state for all powered BUILT greenhouses.
	_greenhouse_states.clear()
	_settler_agents.clear()
	for piece_id: int in _placed_items:
		var def: PlaceableDefinition = _placed_items[piece_id].data as PlaceableDefinition
		if not def is GreenhouseDefinition:
			continue
		if not _power_state.is_powered(piece_id):
			continue
		var info: Dictionary = farm_grid.grid_data.get_piece_info(piece_id)
		_greenhouse_states.append({
			"piece_id":           piece_id,
			"def":                def as GreenhouseDefinition,
			"row":                info["row"],
			"col":                info["col"],
			"tend_countdown":     (def as GreenhouseDefinition).tend_interval,
			"tend_count":         0,
			"settler_dispatched": false,
		})
	EventBus.simulation_started.emit()
	hud_ui.set_simulation_active(true)
	_sim_progress_bar.value  = 0.0
	_sim_progress_label.text = "0.0 s"
	_sim_progress_container.visible = true
	_sim_timer.start(SIMULATION_DURATION)

## Called when the simulation timer fires. Compute season outcomes and return to planning.
func _end_simulation() -> void:
	# Use construction cost saved before UNBUILT→BUILT transition ran.
	var food: Dictionary    = _compute_food_state(_sim_construction_cost)
	var paste_produced: int = food["paste_produced"]

	# Log and apply Matter production.
	if food["matter_prod"] > 0:
		_add_log_entry({"label": "Matter Manipulator:", "value": "+%d Matter" % food["matter_prod"],
				"label_color": "", "value_color": LOG_COLOR_GAIN})
	GameState.matter += food["matter_prod"]

	# Construction cost was already logged per-building in _begin_simulation().
	GameState.matter = maxi(0, GameState.matter - food["construction_cost"])

	# Log and consume kitchen grid items if cafeteria is powered.
	var kitchen_items: int   = 0
	for cid: int in _kitchen_placed_items:
		kitchen_items += (_kitchen_placed_items[cid] as Dictionary).size()
	var food_items_used: int = food["food_items"]
	if kitchen_items > 0:
		if food_items_used > 0:
			_add_log_entry({"label": "Cafeteria:",
					"value": "-%d food item%s" % [kitchen_items, "s" if kitchen_items != 1 else ""],
					"label_color": "", "value_color": LOG_COLOR_ITEM})
			for cid: int in _kitchen_placed_items:
				var kg: KitchenGrid = _kitchen_grids.get(cid, null) as KitchenGrid
				for pid: int in (_kitchen_placed_items[cid] as Dictionary).keys():
					if kg != null:
						kg.remove_piece(pid)
				(_kitchen_placed_items[cid] as Dictionary).clear()
		else:
			_add_log_entry({"label": "Cafeteria not powered —",
					"value": "food items unused",
					"label_color": LOG_COLOR_LOSS, "value_color": LOG_COLOR_LOSS})

	# Log and apply Nutrient Paste.
	if paste_produced > 0:
		_add_log_entry({"label": "Nutrient Paste:", "value": "-%d Matter" % paste_produced,
				"label_color": "", "value_color": LOG_COLOR_LOSS})
	elif food["paste_needed"] > 0 and not _food_is_powered():
		_add_log_entry({"label": "Matter Manipulator not powered —", "value": "no Nutrient Paste",
				"label_color": "", "value_color": LOG_COLOR_LOSS})
	GameState.matter = maxi(0, GameState.matter - paste_produced)

	# Log settler deaths before applying health update.
	var projected: Array = food["projected_health"]
	for i: int in GameState.settler_names.size():
		if GameState.settler_health[i] != GameState.SettlerHealth.DEAD \
				and projected[i] == GameState.SettlerHealth.DEAD:
			_add_log_entry({"label": "%s starved to death." % GameState.settler_names[i], "value": "",
					"label_color": LOG_COLOR_DEATH, "value_color": ""})
	# Apply settler health outcomes. Use .assign() so the typed Array[int] is updated
	# correctly from the plain Array retrieved from the food Dictionary.
	GameState.settler_health.assign(food["projected_health"])

	# Clean up any settler sprites still walking at simulation end.
	for agent: Dictionary in _settler_agents:
		(agent["sprite"] as ColorRect).queue_free()
	_settler_agents.clear()
	_greenhouse_states.clear()

	GameState.season += 1
	hud_ui.refresh_log(_sim_log)

	_phase = Phase.PLANNING
	_sim_progress_container.visible = false
	_sim_live_log_box.visible = false
	EventBus.simulation_ended.emit()
	hud_ui.set_simulation_active(false)
	_recompute_power()
	_sync_kitchen_grid()  # create grids for cafeterias that became BUILT this season
	if GameState.settler_count == 0:
		_on_colony_lost()

func _process(delta: float) -> void:
	if _phase != Phase.SIMULATION:
		return
	var scaled: float = delta * _sim_speed_scale
	_sim_elapsed += scaled
	_sim_progress_bar.value  = _sim_elapsed
	_sim_progress_label.text = "%.1f s" % _sim_elapsed
	_tick_greenhouses(scaled)
	_tick_settlers(scaled)

## Advance greenhouse tend countdowns; dispatch a settler when a greenhouse needs tending.
func _tick_greenhouses(delta: float) -> void:
	for i: int in _greenhouse_states.size():
		var gh: Dictionary = _greenhouse_states[i]
		if gh["settler_dispatched"]:
			continue
		gh["tend_countdown"] = (gh["tend_countdown"] as float) - delta
		if (gh["tend_countdown"] as float) <= 0.0:
			_dispatch_settler(i)

## Dispatch a settler sprite from the Solar Rig to greenhouse index gh_idx.
## Does nothing if the solar rig is unknown or all settlers are already walking.
func _dispatch_settler(gh_idx: int) -> void:
	if _solar_rig_piece_id == -1:
		return
	# Find a living settler not currently walking.
	var busy_names: Array[String] = []
	for agent: Dictionary in _settler_agents:
		busy_names.append(agent["settler_name"] as String)
	var free_name: String = ""
	for i: int in GameState.settler_names.size():
		if GameState.settler_health[i] == GameState.SettlerHealth.DEAD:
			continue
		var n: String = GameState.settler_names[i]
		if not busy_names.has(n):
			free_name = n
			break
	if free_name.is_empty():
		return
	var gh: Dictionary = _greenhouse_states[gh_idx]
	gh["settler_dispatched"] = true
	var solar_info: Dictionary = farm_grid.grid_data.get_piece_info(_solar_rig_piece_id)
	var solar_pos: Vector2 = _grid_cell_center(solar_info["row"], solar_info["col"])
	var gh_pos: Vector2    = _grid_cell_center(gh["row"], gh["col"])
	# Speed = 2 grid-units/second; grid-unit = CELL_SIZE px.
	var grid_dist: float   = (gh_pos - solar_pos).length() / 32.0
	var travel_time: float = maxf(grid_dist / 2.0, 0.01)
	var sprite: ColorRect = ColorRect.new()
	sprite.size    = Vector2(10.0, 10.0)
	sprite.color   = Color(0.9, 0.75, 0.6)
	sprite.z_index = 200
	_ui_layer.add_child(sprite)
	sprite.position = solar_pos - Vector2(5.0, 5.0)
	_settler_agents.append({
		"sprite":        sprite,
		"from_pos":      solar_pos,
		"to_pos":        gh_pos,
		"solar_pos":     solar_pos,
		"elapsed":       0.0,
		"duration":      travel_time,
		"returning":     false,
		"gh_idx":        gh_idx,
		"settler_name":  free_name,
	})

## Advance settler sprites; handle arrival at greenhouse and return to Solar Rig.
func _tick_settlers(delta: float) -> void:
	for i: int in range(_settler_agents.size() - 1, -1, -1):
		var agent: Dictionary = _settler_agents[i]
		agent["elapsed"] = (agent["elapsed"] as float) + delta
		var t: float = clampf((agent["elapsed"] as float) / (agent["duration"] as float), 0.0, 1.0)
		var pos: Vector2 = (agent["from_pos"] as Vector2).lerp(agent["to_pos"], t)
		(agent["sprite"] as ColorRect).position = pos - Vector2(5.0, 5.0)
		if (agent["elapsed"] as float) < (agent["duration"] as float):
			continue
		if not agent["returning"]:
			# Arrived at greenhouse: perform one tending operation.
			var gh: Dictionary = _greenhouse_states[agent["gh_idx"]]
			var gh_def: GreenhouseDefinition = gh["def"] as GreenhouseDefinition
			_add_log_entry({
				"label": "%s tended to %s." % [agent["settler_name"], gh_def.display_name],
				"value": "", "label_color": "", "value_color": "",
			})
			gh["tend_count"] = (gh["tend_count"] as int) + 1
			if (gh["tend_count"] as int) >= gh_def.tend_per_yield:
				gh["tend_count"] = 0
				if gh_def.output_item != null:
					_inventory.add(InventoryItem.new(
						gh_def.output_item.display_name,
						gh_def.output_item.slot_size,
						gh_def.output_item,
					))
					_add_log_entry({
						"label": "%s:" % gh_def.display_name,
						"value": "+1 %s" % gh_def.output_item.display_name,
						"label_color": "", "value_color": LOG_COLOR_ITEM,
					})
			# Reset countdown and begin return trip.
			gh["tend_countdown"] = gh_def.tend_interval
			agent["returning"] = true
			agent["from_pos"]  = agent["to_pos"]
			agent["to_pos"]    = agent["solar_pos"]
			agent["elapsed"]   = 0.0
		else:
			# Returned to Solar Rig: free this settler.
			(agent["sprite"] as ColorRect).queue_free()
			_greenhouse_states[agent["gh_idx"]]["settler_dispatched"] = false
			_settler_agents.remove_at(i)

## World-space center of a grid cell, usable as a CanvasLayer screen coordinate.
func _grid_cell_center(row: int, col: int) -> Vector2:
	return farm_grid.global_position + Vector2((col - 0.5) * 32.0, (row - 0.5) * 32.0)

## Stamp current timestamp onto base, append to _sim_log, and push to live overlay.
func _add_log_entry(base: Dictionary) -> void:
	base["timestamp"] = _sim_elapsed
	_sim_log.append(base)
	_update_live_log(base)

## Add a single-line entry to the live log overlay, trimming oldest beyond max.
func _update_live_log(entry: Dictionary) -> void:
	var ts: float = entry.get("timestamp", -1.0) as float
	var label_text: String = entry.get("label", "") as String
	var value_text: String = entry.get("value", "") as String
	var line: String = label_text
	if not value_text.is_empty():
		line = line + "  " + value_text
	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lbl: RichTextLabel = RichTextLabel.new()
	lbl.bbcode_enabled = true
	lbl.fit_content = true
	lbl.scroll_active = false
	lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("normal_font_size", 10)
	lbl.text = line
	row.add_child(lbl)
	if ts >= 0.0:
		var ts_lbl: RichTextLabel = RichTextLabel.new()
		ts_lbl.bbcode_enabled = true
		ts_lbl.fit_content = true
		ts_lbl.scroll_active = false
		ts_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
		ts_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ts_lbl.add_theme_font_size_override("normal_font_size", 10)
		ts_lbl.text = "[color=#999999](%.1fs)[/color]" % ts
		row.add_child(ts_lbl)
	_sim_live_log_box.add_child(row)
	# Trim oldest entries beyond the max.
	while _sim_live_log_box.get_child_count() > LIVE_LOG_MAX_ENTRIES:
		var oldest: Node = _sim_live_log_box.get_child(0)
		_sim_live_log_box.remove_child(oldest)
		oldest.queue_free()

func _on_colony_lost() -> void:
	var dlg: AcceptDialog = AcceptDialog.new()
	dlg.title = "Colony Lost"
	dlg.dialog_text = "All settlers have perished.\nThe colony is lost."
	add_child(dlg)
	dlg.popup_centered()
