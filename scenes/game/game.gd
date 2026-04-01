extends Node2D

@onready var farm_grid:    FarmGrid    = $FarmGrid
@onready var inventory_ui: InventoryUI = $UILayer/InventoryUI
@onready var hud_ui:       HudUI       = $UILayer/HudUI
@onready var _ui_layer:    CanvasLayer = $UILayer

var _inventory:     Inventory
var _build_menu:    BuildMenu
var _confirm_dialog: ConfirmationDialog

## Construction cost locked in at simulation start (before UNBUILT→BUILT erases it).
var _sim_construction_cost: int = 0

var building_manager:      BuildingManager
var kitchen_manager:       KitchenManager
var simulation_controller: SimulationController
var settler_manager:       SettlerManager

## Panels that dismiss on an outside tap. Each entry must implement:
##   is_open() -> bool, open_screen_rect() -> Rect2, close() -> void.
var _dismissable_panels: Array[Object] = []

enum Phase { PLANNING, SIMULATION }
var _phase: Phase = Phase.PLANNING

## Shared item definitions — created once so recipe ingredient keys match placed item data.
var _wheat_def:           PlaceableDefinition
var _tomato_def:          PlaceableDefinition
var _eggplant_def:        PlaceableDefinition
var _pasta_def:           PlaceableDefinition
var _tomato_sauce_def:    PlaceableDefinition
var _pasta_norma_def:     MealDefinition


func _ready() -> void:
	_create_item_defs()
	_inventory = Inventory.new(10)
	inventory_ui.set_inventory(_inventory)
	var grid_bottom: float = farm_grid.position.y + farm_grid.get_grid_pixel_size().y
	inventory_ui.set_grid_bottom(grid_bottom)
	farm_grid.set_inventory_control(inventory_ui)
	inventory_ui.item_requested.connect(_on_item_requested)
	inventory_ui.state_changed.connect(_on_inventory_state_changed)

	building_manager = BuildingManager.new()
	add_child(building_manager)
	building_manager.setup(farm_grid, _inventory)
	building_manager.power_changed.connect(_on_power_changed)
	building_manager.piece_released_off_farm.connect(_on_piece_released_off_farm)
	building_manager.cafeteria_long_pressed.connect(_on_cafeteria_long_pressed)
	building_manager.piece_picked_up_from_farm.connect(_on_piece_picked_up_from_farm)

	kitchen_manager = KitchenManager.new()
	add_child(kitchen_manager)
	kitchen_manager.setup(_inventory, inventory_ui, _ui_layer, grid_bottom)

	simulation_controller = SimulationController.new()
	add_child(simulation_controller)
	simulation_controller.setup(farm_grid, _inventory, _ui_layer, hud_ui)
	simulation_controller.finished.connect(_end_simulation)

	_confirm_dialog = ConfirmationDialog.new()
	_confirm_dialog.confirmed.connect(_begin_simulation)
	add_child(_confirm_dialog)

	settler_manager = SettlerManager.new()
	add_child(settler_manager)
	settler_manager.setup(_inventory, inventory_ui, _ui_layer, hud_ui)
	settler_manager.assignments_changed.connect(_refresh_food_hud)
	hud_ui.settler_label_tapped.connect(func() -> void:
		if not settler_manager.is_open():
			kitchen_manager.close()
		settler_manager.toggle())

	kitchen_manager.set_recipes(_recipe_definitions())
	_dismissable_panels = [kitchen_manager, settler_manager]
	hud_ui.next_season_pressed.connect(_on_next_season_pressed)

	# Build menu — shown below the grid when the inventory is collapsed.
	var viewport_h: float = get_viewport().get_visible_rect().size.y
	_build_menu = BuildMenu.new()
	_build_menu.position = Vector2(0.0, grid_bottom)
	_build_menu.size     = Vector2(270.0, viewport_h - grid_bottom - InventoryUI.COLLAPSED_H)
	_build_menu.building_requested.connect(_on_building_requested)
	_ui_layer.add_child(_build_menu)
	_build_menu.set_definitions(_buildable_definitions())

	# Ensure inventory_ui renders above all programmatically-added UILayer children.
	_ui_layer.move_child(inventory_ui, _ui_layer.get_child_count() - 1)

	_place_starting_buildings()


# ---------------------------------------------------------------------------
# Input
# ---------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	var press_pos: Vector2 = Vector2.ZERO
	var is_new_press: bool = false
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		is_new_press = true
		press_pos    = (event as InputEventMouseButton).position
	elif event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		is_new_press = true
		press_pos    = (event as InputEventScreenTouch).position

	# Close any open dismissable panel on a new press outside it.
	if is_new_press:
		for panel: Object in _dismissable_panels:
			if panel.is_open() and not panel.open_screen_rect().has_point(press_pos):
				panel.close()
				get_viewport().set_input_as_handled()
				return

	# Enter/space rotates the held piece clockwise.
	if event.is_action_pressed("ui_accept"):
		farm_grid.rotate_held_cw()


# ---------------------------------------------------------------------------
# Signal handlers — inventory / build menu
# ---------------------------------------------------------------------------

func _on_item_requested(item: InventoryItem) -> void:
	if _phase == Phase.SIMULATION:
		return
	if not item.data is PlaceableDefinition:
		return
	if kitchen_manager.is_open():
		kitchen_manager.route_inventory_hold(item)
		return
	if settler_manager.is_open():
		settler_manager.route_inventory_hold(item)
		return  # non-SETTLER_GRID items have nowhere to go; farm grid is locked
	building_manager.begin_inventory_hold(item)

func _on_building_requested(def: PlaceableDefinition) -> void:
	building_manager.begin_build_menu_hold(def)

func _on_inventory_state_changed(collapsed: bool) -> void:
	_build_menu.visible = collapsed


# ---------------------------------------------------------------------------
# Signal handlers — BuildingManager
# ---------------------------------------------------------------------------

func _on_power_changed(_placed: Dictionary) -> void:
	_refresh_food_hud()
	hud_ui.refresh_energy_tooltip(building_manager.build_energy_entries())
	kitchen_manager.sync(building_manager.placed_items(), building_manager.build_states())

func _refresh_food_hud() -> void:
	var food: Dictionary = _compute_food_state()
	var matter_net: int  = food["matter_prod"] - food["construction_cost"] - food["paste_produced"]
	hud_ui.set_settler_projected_morale(food["projected_morale"])
	hud_ui.set_settler_projected_health(food["projected_health"])
	hud_ui.refresh_matter(GameState.matter + matter_net, matter_net)
	hud_ui.refresh_matter_tooltip(GameState.matter, building_manager.build_matter_entries(food))
	hud_ui.refresh()

func _on_piece_picked_up_from_farm() -> void:
	kitchen_manager.close()
	# kitchen_manager.sync() is already called by _on_power_changed (fired before this signal).

func _on_piece_released_off_farm(item: InventoryItem,
		build_state: BuildingManager.BuildState, com_screen_pos: Vector2) -> void:
	var def: PlaceableDefinition = item.data as PlaceableDefinition
	# Route SETTLER_GRID items to the settler panel if CoM is over a settler slot.
	if def != null and PlaceableDefinition.GridType.SETTLER_GRID in def.allowed_grids \
			and settler_manager.is_open():
		if settler_manager.try_place_item(item, com_screen_pos):
			return
	# Route KITCHEN_GRID-only items to the active kitchen grid if CoM is over it.
	if def != null \
			and PlaceableDefinition.GridType.KITCHEN_GRID in def.allowed_grids \
			and not (PlaceableDefinition.GridType.FARM_GRID in def.allowed_grids) \
			and kitchen_manager.is_open():
		if kitchen_manager.try_place_item(item, com_screen_pos):
			return
	# UNBUILT pieces (from build menu) are discarded when dropped off-grid.
	if build_state == BuildingManager.BuildState.UNBUILT:
		return
	_inventory.add(item)

func _on_cafeteria_long_pressed(piece_id: int) -> void:
	if _phase == Phase.SIMULATION:
		return
	settler_manager.close()
	kitchen_manager.open(piece_id)


# ---------------------------------------------------------------------------
# Season flow
# ---------------------------------------------------------------------------

func _on_next_season_pressed() -> void:
	if _phase == Phase.SIMULATION:
		simulation_controller.skip()
		return
	var food: Dictionary = _compute_food_state()
	if food["deaths"] > 0:
		_confirm_dialog.dialog_text = \
			"Not enough food for all settlers.\n%d settler(s) will starve.\n\nProceed anyway?" \
			% food["deaths"]
		_confirm_dialog.popup_centered()
	else:
		_begin_simulation()

func _begin_simulation() -> void:
	kitchen_manager.close()
	settler_manager.close()
	_sim_construction_cost = building_manager.compute_construction_cost()
	var log_entries: Array[Dictionary] = building_manager.transition_unbuilt_to_built()
	_phase = Phase.SIMULATION
	# Build the cafeteria craft queue from powered cafeterias with complete recipe groups.
	var cafeteria_craft_queue: Dictionary = {}
	var power_st: PowerSystem.PowerState  = building_manager.power_state()
	for pid: int in building_manager.placed_items():
		var item: InventoryItem = (building_manager.placed_items() as Dictionary)[pid] as InventoryItem
		if not (item.data is CafeteriaDefinition):
			continue
		if not power_st.is_powered(pid):
			continue
		var kg: KitchenGrid = kitchen_manager.kitchen_grid_for(pid)
		if kg == null:
			continue
		var groups: Array[Dictionary] = kg.get_complete_recipe_groups()
		if not groups.is_empty():
			cafeteria_craft_queue[pid] = groups
	simulation_controller.begin(
		building_manager.placed_items(),
		building_manager.power_state(),
		building_manager.solar_rig_piece_id(),
		cafeteria_craft_queue)
	# Log per-building construction entries after begin() clears the log.
	for entry: Dictionary in log_entries:
		simulation_controller.add_log_entry(entry)

## Called when simulation_controller emits finished().
func _end_simulation() -> void:
	var food: Dictionary    = _compute_food_state(_sim_construction_cost)
	var paste_produced: int = food["paste_produced"]
	var sim: SimulationController = simulation_controller

	# Matter production.
	if food["matter_prod"] > 0:
		sim.add_log_entry({"label": "Matter Manipulator:",
				"value": "+%d Matter" % food["matter_prod"],
				"label_color": "", "value_color": SimulationController.LOG_COLOR_GAIN})
	GameState.matter += food["matter_prod"]

	# Construction cost (already logged per-building in _begin_simulation).
	GameState.matter = maxi(0, GameState.matter - food["construction_cost"])

	# Remove ingredients that were consumed during crafting; partial recipe groups stay.
	var crafted_ids: Array[int] = simulation_controller.get_crafted_ingredient_ids()
	if not crafted_ids.is_empty():
		kitchen_manager.consume_specific_items(crafted_ids)

	# Consume settler meal assignments.
	var meals_consumed: int = settler_manager.consume_assigned_meals()
	if meals_consumed > 0:
		sim.add_log_entry({"label": "Meals consumed:",
				"value": "-%d meal(s)" % meals_consumed,
				"label_color": "", "value_color": SimulationController.LOG_COLOR_ITEM})

	# Nutrient Paste.
	if paste_produced > 0:
		sim.add_log_entry({"label": "Nutrient Paste:",
				"value": "-%d Matter" % paste_produced,
				"label_color": "", "value_color": SimulationController.LOG_COLOR_LOSS})
	elif food["paste_needed"] > 0 and not building_manager.food_is_powered():
		sim.add_log_entry({"label": "Matter Manipulator not powered —",
				"value": "no Nutrient Paste",
				"label_color": "", "value_color": SimulationController.LOG_COLOR_LOSS})
	GameState.matter = maxi(0, GameState.matter - paste_produced)

	# Settler deaths and morale.
	var projected: Array    = food["projected_health"]
	var proj_morale: Array  = food["projected_morale"]
	for i: int in GameState.settlers.size():
		var s: Settler = GameState.settlers[i]
		if s.health != Settler.Health.DEAD and projected[i] == Settler.Health.DEAD:
			sim.add_log_entry({"label": "%s starved to death." % s.name,
					"value": "", "label_color": SimulationController.LOG_COLOR_DEATH,
					"value_color": ""})
		s.health = projected[i] as Settler.Health
		s.morale = proj_morale[i] as int

	GameState.season += 1
	hud_ui.refresh_log(sim.get_log())

	_phase = Phase.PLANNING
	simulation_controller.end_cleanup()
	EventBus.simulation_ended.emit()
	hud_ui.set_simulation_active(false)
	# Recompute power (triggers _on_power_changed → HUD update + kitchen sync).
	building_manager.recompute_power()

	if GameState.settler_count == 0:
		_on_colony_lost()


# ---------------------------------------------------------------------------
# Food state computation
# ---------------------------------------------------------------------------

## Computes projected food, Nutrient Paste, and morale state for the upcoming season end.
## Pass construction_cost_override >= 0 to use a pre-computed cost (used inside
## _end_simulation after the UNBUILT→BUILT transition has already run).
## Keys: matter_prod, construction_cost, food_items, paste_needed, paste_produced,
##       projected_health (Array[int] of Settler.Health, parallel to settlers),
##       projected_morale (Array[int], parallel to settlers), deaths.
func _compute_food_state(construction_cost_override: int = -1) -> Dictionary:
	var matter_prod: int       = building_manager.compute_matter_production()
	var construction_cost: int = construction_cost_override if construction_cost_override >= 0 \
		else building_manager.compute_construction_cost()
	var food_items: int = settler_manager.assigned_meal_count()
	var living: int         = GameState.settler_count
	var paste_needed: int   = maxi(0, living - food_items)
	var paste_produced: int = 0
	if paste_needed > 0 and building_manager.food_is_powered():
		var matter_avail: int = maxi(0, GameState.matter + matter_prod - construction_cost)
		paste_produced = mini(paste_needed, matter_avail)
	var paste_remaining: int         = paste_produced
	var projected_health: Array[int] = []
	var deaths: int                  = 0
	for i: int in GameState.settlers.size():
		var current: Settler.Health = GameState.settlers[i].health
		if current == Settler.Health.DEAD:
			projected_health.append(Settler.Health.DEAD)
		elif settler_manager.has_meal_assigned(i):
			projected_health.append(Settler.Health.FED)
		elif paste_remaining > 0:
			projected_health.append(Settler.Health.FED)
			paste_remaining -= 1
		else:
			projected_health.append(Settler.Health.DEAD)
			deaths += 1
	# Morale: base 0, minus one per projected-dead settler, minus 1 for paste, plus meal modifier.
	var projected_dead_count: int = 0
	for h: int in projected_health:
		if h == Settler.Health.DEAD:
			projected_dead_count += 1
	var projected_morale: Array[int] = []
	for i: int in GameState.settlers.size():
		if projected_health[i] == Settler.Health.DEAD:
			projected_morale.append(0)
			continue
		var m: int = -projected_dead_count
		var meal_item: InventoryItem = settler_manager.get_assigned_meal(i)
		if meal_item != null:
			var meal_def: MealDefinition = meal_item.data as MealDefinition
			if meal_def != null:
				m += meal_def.morale_modifier
		else:
			m -= 1  # Nutrient Paste penalty
		projected_morale.append(m)
	return {
		"matter_prod":       matter_prod,
		"construction_cost": construction_cost,
		"food_items":        food_items,
		"paste_needed":      paste_needed,
		"paste_produced":    paste_produced,
		"projected_health":  projected_health,
		"projected_morale":  projected_morale,
		"deaths":            deaths,
	}


# ---------------------------------------------------------------------------
# Setup helpers
# ---------------------------------------------------------------------------

func _place_starting_buildings() -> void:
	var solar_shape: PieceShape = PieceShape.new()
	solar_shape.color = Color(0.95, 0.80, 0.20)
	solar_shape.label = "SOL"
	var solar_rig: BuildingDefinition = BuildingDefinition.new()
	solar_rig.display_name     = "Solar Rig"
	solar_rig.shape            = solar_shape
	solar_rig.energy_production = 10
	solar_rig.power_range      = 3
	var solar_item: InventoryItem = InventoryItem.new(solar_rig.display_name, 1, solar_rig)
	var solar_pid: int = building_manager.place_at_built(solar_rig.shape, 3, 3, solar_item)
	building_manager.set_solar_rig_piece_id(solar_pid)

	var matter_shape: PieceShape = PieceShape.new()
	matter_shape.color = Color(0.45, 0.75, 0.55)
	matter_shape.label = "MAT"
	var matter_manip: BuildingDefinition = BuildingDefinition.new()
	matter_manip.display_name    = "Matter Manipulator"
	matter_manip.shape           = matter_shape
	matter_manip.matter_production = 5
	matter_manip.power_draw      = 2
	var matter_item: InventoryItem = InventoryItem.new(matter_manip.display_name, 1, matter_manip)
	building_manager.place_at_built(matter_manip.shape, 3, 4, matter_item)

## Creates all shared item definitions. Called once from _ready() before anything
## that needs item defs, so recipe ingredient keys match placed InventoryItem.data.
func _create_item_defs() -> void:
	var s: PieceShape

	s = PieceShape.new(); s.color = Color(1.0, 0.92, 0.40); s.cell_style = PieceShape.CellStyle.CIRCLE
	_wheat_def = PlaceableDefinition.new()
	_wheat_def.display_name  = "Wheat"
	_wheat_def.shape         = s
	_wheat_def.allowed_grids = [PlaceableDefinition.GridType.KITCHEN_GRID]

	s = PieceShape.new(); s.color = Color(0.95, 0.35, 0.25); s.cell_style = PieceShape.CellStyle.CIRCLE
	_tomato_def = PlaceableDefinition.new()
	_tomato_def.display_name  = "Tomato"
	_tomato_def.shape         = s
	_tomato_def.allowed_grids = [PlaceableDefinition.GridType.KITCHEN_GRID]

	s = PieceShape.new(); s.color = Color(0.65, 0.25, 0.85); s.cell_style = PieceShape.CellStyle.CIRCLE
	_eggplant_def = PlaceableDefinition.new()
	_eggplant_def.display_name  = "Eggplant"
	_eggplant_def.shape         = s
	_eggplant_def.allowed_grids = [PlaceableDefinition.GridType.KITCHEN_GRID]

	s = PieceShape.new(); s.color = Color(0.92, 0.88, 0.65); s.cell_style = PieceShape.CellStyle.CIRCLE
	_pasta_def = PlaceableDefinition.new()
	_pasta_def.display_name  = "Pasta"
	_pasta_def.shape         = s
	_pasta_def.allowed_grids = [PlaceableDefinition.GridType.KITCHEN_GRID]

	s = PieceShape.new(); s.color = Color(0.85, 0.22, 0.15); s.cell_style = PieceShape.CellStyle.CIRCLE
	_tomato_sauce_def = PlaceableDefinition.new()
	_tomato_sauce_def.display_name  = "Tomato Sauce"
	_tomato_sauce_def.shape         = s
	_tomato_sauce_def.allowed_grids = [PlaceableDefinition.GridType.KITCHEN_GRID]

	s = PieceShape.new(); s.color = Color(0.78, 0.42, 0.22); s.cell_style = PieceShape.CellStyle.CIRCLE
	_pasta_norma_def = MealDefinition.new()
	_pasta_norma_def.display_name  = "Pasta alla Norma"
	_pasta_norma_def.shape         = s
	_pasta_norma_def.allowed_grids = [
		PlaceableDefinition.GridType.KITCHEN_GRID,
		PlaceableDefinition.GridType.SETTLER_GRID,
	]


## Returns the recipe definitions available this run.
func _recipe_definitions() -> Array[RecipeDefinition]:
	var result: Array[RecipeDefinition] = []

	var r: RecipeDefinition

	# 2 Wheat → 1 Pasta
	r = RecipeDefinition.new()
	r.ingredients  = { _wheat_def: 2 }
	r.output_item  = _pasta_def
	r.output_count = 1
	r.labor_cost   = 1.0
	result.append(r)

	# 2 Tomato → 1 Tomato Sauce
	r = RecipeDefinition.new()
	r.ingredients  = { _tomato_def: 2 }
	r.output_item  = _tomato_sauce_def
	r.output_count = 1
	r.labor_cost   = 1.0
	result.append(r)

	# 1 Pasta + 1 Tomato Sauce + 1 Eggplant → 3 Pasta alla Norma
	r = RecipeDefinition.new()
	r.ingredients  = { _pasta_def: 1, _tomato_sauce_def: 1, _eggplant_def: 1 }
	r.output_item  = _pasta_norma_def
	r.output_count = 3
	r.labor_cost   = 2.0
	result.append(r)

	return result


func _make_greenhouse_def(name: String, label: String, color: Color,
		output: PlaceableDefinition) -> GreenhouseDefinition:
	var shape: PieceShape = PieceShape.new()
	shape.color = color
	shape.label = label
	var gh: GreenhouseDefinition = GreenhouseDefinition.new()
	gh.display_name = name
	gh.shape        = shape
	gh.matter_cost  = 1
	gh.power_draw   = 1
	gh.output_item  = output
	return gh

## Returns the definitions available in the build menu this run.
func _buildable_definitions() -> Array[PlaceableDefinition]:
	var result: Array[PlaceableDefinition] = []

	# --- Greenhouse definitions (output items come from shared _*_def vars) ---
	result.append(_make_greenhouse_def("Wheat Greenhouse",    "WGH", Color(0.95, 0.85, 0.30), _wheat_def))
	result.append(_make_greenhouse_def("Tomato Greenhouse",   "TGH", Color(0.90, 0.28, 0.20), _tomato_def))
	result.append(_make_greenhouse_def("Eggplant Greenhouse", "EGH", Color(0.50, 0.15, 0.65), _eggplant_def))

	# --- Cafeteria ---

	var cafeteria_shape: PieceShape = PieceShape.new()
	cafeteria_shape.color   = Color(0.90, 0.65, 0.30)
	cafeteria_shape.label   = "CAF"
	var cafeteria_offsets: Array[Vector2i] = [Vector2i(0, 0), Vector2i(0, 1)]
	cafeteria_shape.offsets = cafeteria_offsets
	var cafeteria_def: CafeteriaDefinition = CafeteriaDefinition.new()
	cafeteria_def.display_name = "Cafeteria"
	cafeteria_def.shape        = cafeteria_shape
	cafeteria_def.matter_cost  = 2
	cafeteria_def.power_draw   = 1
	cafeteria_def.merge_slots  = KitchenGrid.KITCHEN_COLS * KitchenGrid.KITCHEN_ROWS
	result.append(cafeteria_def)

	return result


# ---------------------------------------------------------------------------
# Colony lost
# ---------------------------------------------------------------------------

func _on_colony_lost() -> void:
	var dlg: AcceptDialog = AcceptDialog.new()
	dlg.title       = "Colony Lost"
	dlg.dialog_text = "All settlers have perished.\nThe colony is lost."
	add_child(dlg)
	dlg.popup_centered()
