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
## Active settler walk animations.
var _settler_agents: Array[Dictionary] = []

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

## Begin simulation for the new season.
## placed_items: piece_id -> InventoryItem (post UNBUILT→BUILT transition).
## power_state: from BuildingManager.power_state() — pre-transition state per design.
func begin(placed_items: Dictionary, power_state: PowerSystem.PowerState,
		solar_rig_piece_id: int) -> void:
	_sim_elapsed     = 0.0
	_sim_speed_scale = 1.0
	_solar_rig_piece_id = solar_rig_piece_id
	_sim_log.clear()
	_hud_ui.refresh_log([])
	for child: Node in _sim_live_log_box.get_children():
		_sim_live_log_box.remove_child(child)
		child.queue_free()
	_sim_live_log_box.visible = true

	# Build greenhouse states for all powered greenhouses.
	_greenhouse_states.clear()
	_settler_agents.clear()
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
	var gh: Dictionary         = _greenhouse_states[gh_idx]
	gh["settler_dispatched"]   = true
	var solar_info: Dictionary = _farm_grid.grid_data.get_piece_info(_solar_rig_piece_id)
	var solar_pos: Vector2     = _grid_cell_center(solar_info["row"], solar_info["col"])
	var gh_pos: Vector2        = _grid_cell_center(gh["row"], gh["col"])
	var grid_dist: float       = (gh_pos - solar_pos).length() / 32.0
	var travel_time: float     = maxf(grid_dist / 2.0, 0.01)
	var sprite: ColorRect      = ColorRect.new()
	sprite.size    = Vector2(10.0, 10.0)
	sprite.color   = Color(0.9, 0.75, 0.6)
	sprite.z_index = 200
	_ui_layer.add_child(sprite)
	sprite.position = solar_pos - Vector2(5.0, 5.0)
	_settler_agents.append({
		"sprite":       sprite,
		"from_pos":     solar_pos,
		"to_pos":       gh_pos,
		"solar_pos":    solar_pos,
		"elapsed":      0.0,
		"duration":     travel_time,
		"returning":    false,
		"gh_idx":       gh_idx,
		"settler_name": free_name,
	})

func _tick_settlers(delta: float) -> void:
	for i: int in range(_settler_agents.size() - 1, -1, -1):
		var agent: Dictionary = _settler_agents[i]
		agent["elapsed"] = (agent["elapsed"] as float) + delta
		var t: float     = clampf((agent["elapsed"] as float) / (agent["duration"] as float), 0.0, 1.0)
		var pos: Vector2 = (agent["from_pos"] as Vector2).lerp(agent["to_pos"], t)
		(agent["sprite"] as ColorRect).position = pos - Vector2(5.0, 5.0)
		if (agent["elapsed"] as float) < (agent["duration"] as float):
			continue
		if not agent["returning"]:
			# Arrived at greenhouse: perform one tending operation.
			var gh: Dictionary             = _greenhouse_states[agent["gh_idx"]]
			var gh_def: GreenhouseDefinition = gh["def"] as GreenhouseDefinition
			add_log_entry({
				"label":       "%s tended to %s." % [agent["settler_name"], gh_def.display_name],
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
			gh["tend_countdown"] = gh_def.tend_interval
			agent["returning"]   = true
			agent["from_pos"]    = agent["to_pos"]
			agent["to_pos"]      = agent["solar_pos"]
			agent["elapsed"]     = 0.0
		else:
			# Returned to Solar Rig: free this settler.
			(agent["sprite"] as ColorRect).queue_free()
			_greenhouse_states[agent["gh_idx"]]["settler_dispatched"] = false
			_settler_agents.remove_at(i)

func _grid_cell_center(row: int, col: int) -> Vector2:
	return _farm_grid.global_position + Vector2((col - 0.5) * 32.0, (row - 0.5) * 32.0)

func _update_live_log(entry: Dictionary) -> void:
	var ts: float          = entry.get("timestamp", -1.0) as float
	var label_text: String = entry.get("label", "") as String
	var value_text: String = entry.get("value", "") as String
	var line: String       = label_text
	if not value_text.is_empty():
		line = line + "  " + value_text
	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lbl: RichTextLabel = RichTextLabel.new()
	lbl.bbcode_enabled    = true
	lbl.fit_content       = true
	lbl.scroll_active     = false
	lbl.autowrap_mode     = TextServer.AUTOWRAP_OFF
	lbl.mouse_filter      = Control.MOUSE_FILTER_IGNORE
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("normal_font_size", 10)
	lbl.text = line
	row.add_child(lbl)
	if ts >= 0.0:
		var ts_lbl: RichTextLabel = RichTextLabel.new()
		ts_lbl.bbcode_enabled = true
		ts_lbl.fit_content    = true
		ts_lbl.scroll_active  = false
		ts_lbl.autowrap_mode  = TextServer.AUTOWRAP_OFF
		ts_lbl.mouse_filter   = Control.MOUSE_FILTER_IGNORE
		ts_lbl.add_theme_font_size_override("normal_font_size", 10)
		ts_lbl.text = "[color=#999999](%.1fs)[/color]" % ts
		row.add_child(ts_lbl)
	_sim_live_log_box.add_child(row)
	while _sim_live_log_box.get_child_count() > LIVE_LOG_MAX_ENTRIES:
		var oldest: Node = _sim_live_log_box.get_child(0)
		_sim_live_log_box.remove_child(oldest)
		oldest.queue_free()
