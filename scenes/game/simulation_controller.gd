class_name SimulationController
extends Node

## Owns simulation timer, progress bar, live log overlay, and greenhouse/settler animation.
## Call setup() once from game.gd _ready(). Call begin() to start a season; skip() to fast-forward.
## Emits finished() when the timer expires — game.gd then calls end_cleanup().

## Duration of one season simulation in seconds.
const SIMULATION_DURATION := 15.0
## Maximum entries shown in the live log overlay at once.
const LIVE_LOG_MAX_ENTRIES := 6

## Log entry color constants (shared with game.gd via SimulationController.LOG_COLOR_*).
const LOG_COLOR_GAIN  := "#88ee88"  # light green — resource production
const LOG_COLOR_LOSS  := "#ee8800"  # orange — resource consumption / warning
const LOG_COLOR_DEATH := "#ee4444"  # red — settler death / critical event
const LOG_COLOR_ITEM  := "#eeee88"  # yellow — inventory item gained
const LOG_COLOR_SKIP  := "#636363"  # dim grey — skipped task

## Emitted when the simulation timer expires; game.gd runs _end_simulation().
signal finished()

var _farm_grid: FarmGrid
var _inventory:  Inventory
var _ui_layer:   CanvasLayer
var _hud_ui:     HudUI

var _sim_timer:              Timer
var _sim_progress_container: HBoxContainer
var _sim_progress_bar:       ProgressBar
var _sim_progress_label:     Label
var _sim_live_log_box:       VBoxContainer

var _sim_elapsed:     float = 0.0
var _sim_speed_scale: float = 1.0
var _sim_log:         Array[Dictionary] = []

## Per-greenhouse state during simulation.
var _greenhouse_states: Array[Dictionary] = []
## Per-cafeteria crafting state during simulation.
var _cafeteria_states: Array[Dictionary] = []
## piece_ids of kitchen grid items consumed by completed crafting this season.
var _crafted_ingredient_ids: Array[int] = []
## Active settler walk/work animations.
var _settler_agents: Array[Dictionary] = []
## Per-settler skip budget for the current season (settler_name -> int).
var _settler_skips_remaining: Dictionary = {}

var _solar_rig_piece_id: int = -1
var _running: bool = false


func setup(farm_grid: FarmGrid, inventory: Inventory,
		ui_layer: CanvasLayer, hud_ui: HudUI) -> void:
	_farm_grid = farm_grid
	_inventory  = inventory
	_ui_layer   = ui_layer
	_hud_ui     = hud_ui
	_build_ui()

func _build_ui() -> void:
	const PROGRESS_H := 16
	_sim_progress_container = HBoxContainer.new()
	_sim_progress_container.position = Vector2(0.0, _farm_grid.position.y - PROGRESS_H)
	_sim_progress_container.size     = Vector2(270.0, PROGRESS_H)
	_sim_progress_container.visible  = false
	_ui_layer.add_child(_sim_progress_container)

	_sim_progress_bar = ProgressBar.new()
	_sim_progress_bar.min_value  = 0.0
	_sim_progress_bar.max_value  = SIMULATION_DURATION
	_sim_progress_bar.value      = 0.0
	_sim_progress_bar.show_percentage        = false
	_sim_progress_bar.size_flags_horizontal  = Control.SIZE_EXPAND_FILL
	_sim_progress_bar.size_flags_vertical    = Control.SIZE_EXPAND_FILL
	_sim_progress_container.add_child(_sim_progress_bar)

	_sim_progress_label = Label.new()
	_sim_progress_label.text = "0.0 s"
	_sim_progress_label.custom_minimum_size     = Vector2(40.0, 0.0)
	_sim_progress_label.horizontal_alignment    = HORIZONTAL_ALIGNMENT_RIGHT
	_sim_progress_label.add_theme_font_size_override("font_size", 10)
	_sim_progress_container.add_child(_sim_progress_label)

	var live_log_top: float = _hud_ui.offset_bottom
	var live_log_h:   float = _sim_progress_container.position.y - live_log_top
	_sim_live_log_box = VBoxContainer.new()
	_sim_live_log_box.position      = Vector2(2.0, live_log_top)
	_sim_live_log_box.size          = Vector2(266.0, live_log_h)
	_sim_live_log_box.clip_contents = true
	_sim_live_log_box.visible       = false
	_ui_layer.add_child(_sim_live_log_box)

	_sim_timer = Timer.new()
	_sim_timer.one_shot = true
	_sim_timer.timeout.connect(_on_timer_finished)
	add_child(_sim_timer)


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

func is_running() -> bool:
	return _running

func get_log() -> Array[Dictionary]:
	return _sim_log

## Returns the kitchen-grid piece_ids consumed by completed crafting this season.
func get_crafted_ingredient_ids() -> Array[int]:
	return _crafted_ingredient_ids

## Begin simulation for the new season.
## placed_items: piece_id -> InventoryItem (post UNBUILT→BUILT transition).
## power_state: from BuildingManager.power_state() — pre-transition state per design.
## cafeteria_craft_queue: cafeteria_piece_id -> Array[{recipe, piece_ids}] (complete groups).
func begin(placed_items: Dictionary, power_state: PowerSystem.PowerState,
		solar_rig_piece_id: int, cafeteria_craft_queue: Dictionary = {}) -> void:
	_sim_elapsed     = 0.0
	_sim_speed_scale = 1.0
	_solar_rig_piece_id = solar_rig_piece_id
	_sim_log.clear()
	_hud_ui.refresh_log([])
	_crafted_ingredient_ids.clear()
	for child: Node in _sim_live_log_box.get_children():
		_sim_live_log_box.remove_child(child)
		child.queue_free()
	_sim_live_log_box.visible = true

	# Build greenhouse states for all powered greenhouses.
	_greenhouse_states.clear()
	_cafeteria_states.clear()
	_settler_agents.clear()
	_settler_skips_remaining.clear()
	for s: Settler in GameState.settlers:
		if s.health != Settler.Health.DEAD:
			_settler_skips_remaining[s.name] = maxi(0, -s.morale)
	for piece_id: int in placed_items:
		var def: PlaceableDefinition = placed_items[piece_id].data as PlaceableDefinition
		if not def is GreenhouseDefinition:
			continue
		if power_state == null or not power_state.is_powered(piece_id):
			continue
		var info: Dictionary = _farm_grid.grid_data.get_piece_info(piece_id)
		_greenhouse_states.append({
			"piece_id":           piece_id,
			"def":                def as GreenhouseDefinition,
			"row":                info["row"],
			"col":                info["col"],
			"tend_countdown":     (def as GreenhouseDefinition).tend_interval,
			"tend_count":         0,
			"settler_dispatched": false,
		})

	# Build cafeteria states for powered cafeterias with complete recipe groups.
	for caf_id: int in cafeteria_craft_queue:
		var info: Dictionary = _farm_grid.grid_data.get_piece_info(caf_id)
		if info.is_empty():
			continue
		var queue: Array = cafeteria_craft_queue[caf_id] as Array
		if queue.is_empty():
			continue
		_cafeteria_states.append({
			"piece_id":          caf_id,
			"row":               info["row"],
			"col":               info["col"],
			"craft_queue":       queue.duplicate(),
			"current_craft_idx": 0,
			"settler_dispatched": false,
		})

	EventBus.simulation_started.emit()
	_hud_ui.set_simulation_active(true)
	_sim_progress_bar.value  = 0.0
	_sim_progress_label.text = "0.0 s"
	_sim_progress_container.visible = true
	_sim_timer.start(SIMULATION_DURATION)
	_running = true

## Compress remaining simulation time into 0.5 s for fast-forward.
func skip() -> void:
	var remaining: float = _sim_timer.time_left
	if remaining <= 0.5:
		return
	_sim_speed_scale = remaining / 0.5
	_sim_timer.stop()
	_sim_timer.start(0.5)

## Stamp current timestamp onto base, append to log, and push to live overlay.
func add_log_entry(base: Dictionary) -> void:
	base["timestamp"] = _sim_elapsed
	_sim_log.append(base)
	_update_live_log(base)

## Hide simulation UI and free settler sprites. Called by game.gd after _end_simulation().
func end_cleanup() -> void:
	for agent: Dictionary in _settler_agents:
		(agent["sprite"] as ColorRect).queue_free()
	_settler_agents.clear()
	_greenhouse_states.clear()
	_cafeteria_states.clear()
	_sim_progress_container.visible = false
	_sim_live_log_box.visible       = false
	_running = false


# ---------------------------------------------------------------------------
# Internal — process loop
# ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	if not _running:
		return
	var scaled: float = delta * _sim_speed_scale
	_sim_elapsed             += scaled
	_sim_progress_bar.value   = _sim_elapsed
	_sim_progress_label.text  = "%.1f s" % _sim_elapsed
	_tick_greenhouses(scaled)
	_tick_cafeterias(scaled)
	_tick_settlers(scaled)

func _on_timer_finished() -> void:
	_running = false
	finished.emit()

func _tick_greenhouses(delta: float) -> void:
	for i: int in _greenhouse_states.size():
		var gh: Dictionary = _greenhouse_states[i]
		if gh["settler_dispatched"]:
			continue
		gh["tend_countdown"] = (gh["tend_countdown"] as float) - delta
		if (gh["tend_countdown"] as float) <= 0.0:
			_dispatch_settler(i)

## Returns the name of the first living settler not currently walking, or "" if none free.
func _find_free_settler() -> String:
	var busy_names: Array[String] = []
	for agent: Dictionary in _settler_agents:
		busy_names.append(agent["settler_name"] as String)
	for s: Settler in GameState.settlers:
		if s.health == Settler.Health.DEAD:
			continue
		if not busy_names.has(s.name):
			return s.name
	return ""

## Creates and adds a settler sprite at solar_pos. Caller positions it on the UI layer.
func _make_settler_sprite(solar_pos: Vector2) -> ColorRect:
	var sprite: ColorRect = ColorRect.new()
	sprite.size     = Vector2(10.0, 10.0)
	sprite.color    = Color(0.9, 0.75, 0.6)
	sprite.z_index  = 200
	_ui_layer.add_child(sprite)
	sprite.position = solar_pos - Vector2(5.0, 5.0)
	return sprite

func _dispatch_settler(gh_idx: int) -> void:
	if _solar_rig_piece_id == -1:
		return
	var free_name: String = _find_free_settler()
	if free_name.is_empty():
		return
	var gh: Dictionary         = _greenhouse_states[gh_idx]
	gh["settler_dispatched"]   = true
	var solar_info: Dictionary = _farm_grid.grid_data.get_piece_info(_solar_rig_piece_id)
	var solar_pos: Vector2     = _grid_cell_center(solar_info["row"], solar_info["col"])
	var gh_pos: Vector2        = _grid_cell_center(gh["row"], gh["col"])
	var grid_dist: float       = (gh_pos - solar_pos).length() / 32.0
	var travel_time: float     = maxf(grid_dist / 2.0, 0.01)
	var sprite: ColorRect      = _make_settler_sprite(solar_pos)
	_settler_agents.append({
		"sprite":          sprite,
		"from_pos":        solar_pos,
		"to_pos":          gh_pos,
		"solar_pos":       solar_pos,
		"elapsed":         0.0,
		"duration":        travel_time,
		"returning":       false,
		"is_cafeteria":    false,
		"gh_idx":          gh_idx,
		"caf_idx":         -1,
		"crafting":        false,
		"craft_elapsed":   0.0,
		"craft_duration":  0.0,
		"settler_name":    free_name,
		"tasks_this_trip": 0,
		"tasks_limit":     1 + maxi(0, _get_settler_morale(free_name)),
	})

func _tick_cafeterias(_delta: float) -> void:
	for i: int in _cafeteria_states.size():
		var caf: Dictionary = _cafeteria_states[i]
		if caf["settler_dispatched"]:
			continue
		var idx: int = caf["current_craft_idx"] as int
		if idx >= (caf["craft_queue"] as Array).size():
			continue
		_dispatch_cafeteria_settler(i)

func _dispatch_cafeteria_settler(caf_idx: int) -> void:
	if _solar_rig_piece_id == -1:
		return
	var free_name: String = _find_free_settler()
	if free_name.is_empty():
		return
	var caf: Dictionary        = _cafeteria_states[caf_idx]
	caf["settler_dispatched"]  = true
	var solar_info: Dictionary = _farm_grid.grid_data.get_piece_info(_solar_rig_piece_id)
	var solar_pos: Vector2     = _grid_cell_center(solar_info["row"], solar_info["col"])
	var caf_pos: Vector2       = _grid_cell_center(caf["row"], caf["col"])
	var grid_dist: float       = (caf_pos - solar_pos).length() / 32.0
	var travel_time: float     = maxf(grid_dist / 2.0, 0.01)
	var craft: Dictionary      = (caf["craft_queue"] as Array)[caf["current_craft_idx"] as int]
	var recipe: RecipeDefinition = craft["recipe"] as RecipeDefinition
	var sprite: ColorRect      = _make_settler_sprite(solar_pos)
	_settler_agents.append({
		"sprite":          sprite,
		"from_pos":        solar_pos,
		"to_pos":          caf_pos,
		"solar_pos":       solar_pos,
		"elapsed":         0.0,
		"duration":        travel_time,
		"returning":       false,
		"is_cafeteria":    true,
		"gh_idx":          -1,
		"caf_idx":         caf_idx,
		"crafting":        false,
		"craft_elapsed":   0.0,
		"craft_duration":  recipe.labor_cost,
		"settler_name":    free_name,
		"tasks_this_trip": 0,
		"tasks_limit":     1 + maxi(0, _get_settler_morale(free_name)),
	})

func _get_settler_morale(settler_name: String) -> int:
	for s: Settler in GameState.settlers:
		if s.name == settler_name:
			return s.morale
	return 0

## Returns the nearest unclaimed, ready task (greenhouse or cafeteria) to from_pos,
## or an empty dict if none are available.
func _find_nearest_available_task(from_pos: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var best_dist: float = INF
	for i: int in _greenhouse_states.size():
		var gh: Dictionary = _greenhouse_states[i]
		if gh["settler_dispatched"] or (gh["tend_countdown"] as float) > 0.0:
			continue
		var pos: Vector2 = _grid_cell_center(gh["row"] as int, gh["col"] as int)
		var d: float     = from_pos.distance_to(pos)
		if d < best_dist:
			best_dist = d
			best = {"type": "greenhouse", "idx": i, "pos": pos}
	for i: int in _cafeteria_states.size():
		var caf: Dictionary = _cafeteria_states[i]
		if caf["settler_dispatched"]:
			continue
		if (caf["current_craft_idx"] as int) >= (caf["craft_queue"] as Array).size():
			continue
		var pos: Vector2 = _grid_cell_center(caf["row"] as int, caf["col"] as int)
		var d: float     = from_pos.distance_to(pos)
		if d < best_dist:
			best_dist = d
			best = {"type": "cafeteria", "idx": i, "pos": pos}
	return best

## Mark a task as claimed so no other settler is dispatched to it.
func _claim_task(task: Dictionary) -> void:
	if (task["type"] as String) == "greenhouse":
		_greenhouse_states[task["idx"] as int]["settler_dispatched"] = true
	else:
		_cafeteria_states[task["idx"] as int]["settler_dispatched"] = true

## Redirect agent to travel directly to task from from_pos without returning to Solar Rig.
## Claims the task and updates all relevant agent fields in place.
func _send_agent_to_task(agent: Dictionary, from_pos: Vector2, task: Dictionary) -> void:
	_claim_task(task)
	var to_pos: Vector2    = task["pos"] as Vector2
	var travel_time: float = maxf((to_pos - from_pos).length() / 32.0 / 2.0, 0.01)
	agent["from_pos"]      = from_pos
	agent["to_pos"]        = to_pos
	agent["elapsed"]       = 0.0
	agent["duration"]      = travel_time
	agent["returning"]     = false
	agent["is_cafeteria"]  = (task["type"] as String) == "cafeteria"
	agent["gh_idx"]        = task["idx"] if (task["type"] as String) == "greenhouse" else -1
	agent["caf_idx"]       = task["idx"] if (task["type"] as String) == "cafeteria" else -1
	agent["crafting"]      = false
	agent["craft_elapsed"] = 0.0
	if (task["type"] as String) == "cafeteria":
		var caf: Dictionary          = _cafeteria_states[task["idx"] as int]
		var craft: Dictionary        = (caf["craft_queue"] as Array)[caf["current_craft_idx"] as int]
		agent["craft_duration"]      = (craft["recipe"] as RecipeDefinition).labor_cost
	else:
		agent["craft_duration"] = 0.0

func _tick_settlers(delta: float) -> void:
	for i: int in range(_settler_agents.size() - 1, -1, -1):
		var agent: Dictionary = _settler_agents[i]

		# --- Cafeteria crafting dwell phase ---
		if agent.get("crafting", false):
			agent["craft_elapsed"] = (agent["craft_elapsed"] as float) + delta
			if (agent["craft_elapsed"] as float) < (agent["craft_duration"] as float):
				continue
			# Crafting complete: produce meals.
			_on_cafeteria_craft_done(agent)
			agent["crafting"]        = false
			agent["tasks_this_trip"] = (agent["tasks_this_trip"] as int) + 1
			var caf_next: Dictionary = Dictionary()
			if (agent["tasks_this_trip"] as int) < (agent["tasks_limit"] as int):
				caf_next = _find_nearest_available_task(agent["to_pos"] as Vector2)
			if not caf_next.is_empty():
				_send_agent_to_task(agent, agent["to_pos"] as Vector2, caf_next)
			else:
				agent["returning"] = true
				agent["from_pos"]  = agent["to_pos"]
				agent["to_pos"]    = agent["solar_pos"]
				agent["elapsed"]   = 0.0
			continue

		# --- Travel phase ---
		agent["elapsed"] = (agent["elapsed"] as float) + delta
		var t: float     = clampf((agent["elapsed"] as float) / (agent["duration"] as float), 0.0, 1.0)
		var pos: Vector2 = (agent["from_pos"] as Vector2).lerp(agent["to_pos"], t)
		(agent["sprite"] as ColorRect).position = pos - Vector2(5.0, 5.0)
		if (agent["elapsed"] as float) < (agent["duration"] as float):
			continue

		if not agent["returning"]:
			if agent.get("is_cafeteria", false):
				# Arrived at cafeteria — begin crafting dwell.
				agent["crafting"]      = true
				agent["craft_elapsed"] = 0.0
			else:
				# Arrived at greenhouse.
				var gh: Dictionary               = _greenhouse_states[agent["gh_idx"] as int]
				var gh_def: GreenhouseDefinition = gh["def"] as GreenhouseDefinition
				var settler_name: String         = agent["settler_name"] as String
				# Skip check: negative morale gives a skip budget consumed 50% per arrival.
				var skips_left: int = _settler_skips_remaining.get(settler_name, 0) as int
				if skips_left > 0 and randf() < 0.5:
					_settler_skips_remaining[settler_name] = skips_left - 1
					gh["settler_dispatched"] = false
					add_log_entry({
						"label":       "%s skipped tending to %s." % [settler_name, gh_def.display_name],
						"value":       "(unhappy)",
						"label_color": LOG_COLOR_SKIP,
						"value_color": LOG_COLOR_SKIP,
					})
					var skip_next: Dictionary = Dictionary()
					if (agent["tasks_this_trip"] as int) < (agent["tasks_limit"] as int):
						skip_next = _find_nearest_available_task(agent["to_pos"] as Vector2)
					if not skip_next.is_empty():
						_send_agent_to_task(agent, agent["to_pos"] as Vector2, skip_next)
					else:
						agent["returning"] = true
						agent["from_pos"]  = agent["to_pos"]
						agent["to_pos"]    = agent["solar_pos"]
						agent["elapsed"]   = 0.0
				else:
					# Perform tending.
					add_log_entry({
						"label":       "%s tended to %s." % [settler_name, gh_def.display_name],
						"value":       "",
						"label_color": "",
						"value_color": "",
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
							add_log_entry({
								"label":       "%s:" % gh_def.display_name,
								"value":       "+1 %s" % gh_def.output_item.display_name,
								"label_color": "",
								"value_color": LOG_COLOR_ITEM,
							})
					gh["tend_countdown"]     = gh_def.tend_interval
					gh["settler_dispatched"] = false
					agent["tasks_this_trip"] = (agent["tasks_this_trip"] as int) + 1
					var gh_next: Dictionary = Dictionary()
					if (agent["tasks_this_trip"] as int) < (agent["tasks_limit"] as int):
						gh_next = _find_nearest_available_task(agent["to_pos"] as Vector2)
					if not gh_next.is_empty():
						_send_agent_to_task(agent, agent["to_pos"] as Vector2, gh_next)
					else:
						agent["returning"] = true
						agent["from_pos"]  = agent["to_pos"]
						agent["to_pos"]    = agent["solar_pos"]
						agent["elapsed"]   = 0.0
		else:
			# Returned to Solar Rig: free this settler.
			# (settler_dispatched already released at task completion or skip.)
			(agent["sprite"] as ColorRect).queue_free()
			_settler_agents.remove_at(i)

func _on_cafeteria_craft_done(agent: Dictionary) -> void:
	var caf_idx: int         = agent["caf_idx"] as int
	var caf: Dictionary      = _cafeteria_states[caf_idx]
	var idx: int             = caf["current_craft_idx"] as int
	var craft: Dictionary    = (caf["craft_queue"] as Array)[idx]
	var recipe: RecipeDefinition = craft["recipe"] as RecipeDefinition
	# Track ingredient piece_ids consumed by this craft.
	for pid: int in craft["piece_ids"]:
		_crafted_ingredient_ids.append(pid)
	# Add output meals to inventory.
	for _n: int in recipe.output_count:
		_inventory.add(InventoryItem.new(
			recipe.output_item.display_name,
			recipe.output_item.slot_size,
			recipe.output_item,
		))
	add_log_entry({
		"label":       "%s crafted %s:" % [agent["settler_name"], recipe.output_item.display_name],
		"value":       "+%d %s" % [recipe.output_count, recipe.output_item.display_name],
		"label_color": "",
		"value_color": LOG_COLOR_ITEM,
	})
	# Advance queue and free cafeteria for the next recipe immediately.
	caf["current_craft_idx"]  = idx + 1
	caf["settler_dispatched"] = false

func _grid_cell_center(row: int, col: int) -> Vector2:
	return _farm_grid.global_position + Vector2((col - 0.5) * 32.0, (row - 0.5) * 32.0)

func _make_live_log_rtlabel(text: String, expand: bool = false) -> RichTextLabel:
	var lbl: RichTextLabel = RichTextLabel.new()
	lbl.bbcode_enabled = true
	lbl.fit_content    = true
	lbl.scroll_active  = false
	lbl.autowrap_mode  = TextServer.AUTOWRAP_OFF
	lbl.mouse_filter   = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("normal_font_size", 10)
	if expand:
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.text = text
	return lbl

func _update_live_log(entry: Dictionary) -> void:
	var ts: float          = entry.get("timestamp", -1.0) as float
	var label_text: String = entry.get("label", "") as String
	var value_text: String = entry.get("value", "") as String
	var line: String       = label_text
	if not value_text.is_empty():
		line = line + "  " + value_text
	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_make_live_log_rtlabel(line, true))
	if ts >= 0.0:
		row.add_child(_make_live_log_rtlabel("[color=#999999](%.1fs)[/color]" % ts))
	_sim_live_log_box.add_child(row)
	while _sim_live_log_box.get_child_count() > LIVE_LOG_MAX_ENTRIES:
		var oldest: Node = _sim_live_log_box.get_child(0)
		_sim_live_log_box.remove_child(oldest)
		oldest.queue_free()
