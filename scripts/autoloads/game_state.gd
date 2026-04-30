extends Node

const SAVE_PATH         := "user://save.res"
const REPORTS_PATH      := "user://mission_reports.json"

var season: int = 1
var settlers: Array[Settler] = [
	Settler.new("Alice"),
	Settler.new("Bruno"),
	Settler.new("Carmen"),
]
## Number of living (non-DEAD) settlers. Derived from settlers.
var settler_count: int:
	get:
		var count: int = 0
		for s: Settler in settlers:
			if s.health != Settler.Health.DEAD:
				count += 1
		return count
var energy_capacity: int = 0
var energy: int = 0
var matter: int = 0
## Running sum of per-settler morale across all seasons; used for end-of-run score.
var accumulated_happiness: int = 0

## Run-level stat accumulators — reset at the start of each new run.
var total_cafeteria_meals: int = 0
var total_paste_servings: int = 0
var total_matter_produced: int = 0
var total_crops_yielded: int = 0
## Maps settler name → season number they died in (only present if they died).
var settler_death_seasons: Dictionary = {}

var run_in_progress: bool = false


func _ready() -> void:
	get_tree().set_auto_accept_quit(false)
	energy = 0
	matter = 0


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		save()
		if what == NOTIFICATION_WM_CLOSE_REQUEST:
			get_tree().quit()


## Resets all run state for a fresh run.
func reset_for_new_run() -> void:
	season = 1
	settlers = [
		Settler.new("Alice"),
		Settler.new("Bruno"),
		Settler.new("Carmen"),
	]
	energy_capacity = 0
	energy = 0
	matter = 0
	accumulated_happiness = 0
	total_cafeteria_meals = 0
	total_paste_servings = 0
	total_matter_produced = 0
	total_crops_yielded = 0
	settler_death_seasons = {}
	run_in_progress = true


## Saves current game state. Stub — SaveData resource implemented in Phase 3.
func save() -> void:
	pass


## Loads saved game state. Stub — implemented in Phase 3.
func load_save() -> void:
	pass


## Appends a completed MissionReport to the on-disk history immediately.
func save_mission_report(report: MissionReport) -> void:
	var existing: Array = _load_report_list()
	existing.append(report.to_dict())
	var file: FileAccess = FileAccess.open(REPORTS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(existing))
		file.close()


## Returns all saved MissionReports ordered oldest-first.
func load_mission_reports() -> Array[MissionReport]:
	var dicts: Array = _load_report_list()
	var reports: Array[MissionReport] = []
	for d: Dictionary in dicts:
		reports.append(MissionReport.from_dict(d))
	reports.sort_custom(func(a: MissionReport, b: MissionReport) -> bool:
		return a.timestamp < b.timestamp)
	return reports


func _load_report_list() -> Array:
	if not FileAccess.file_exists(REPORTS_PATH):
		return []
	var file: FileAccess = FileAccess.open(REPORTS_PATH, FileAccess.READ)
	if not file:
		return []
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Array:
		return parsed
	return []
