class_name MissionReport
extends Resource

## Snapshot of a completed run, saved immediately when the run ends.
## Used to populate the Mission Report popup and the run history screen.

enum EndReason { COMPLETE, COLONY_LOST, ENDED_EARLY }

## Unix timestamp of when the run ended — used for ordering and labeling in history.
var timestamp: int = 0
var seasons_survived: int = 0
const MAX_SEASONS: int = 15
var end_reason: EndReason = EndReason.COMPLETE

## Settler outcomes — all arrays are parallel and indexed by settler slot.
var settler_names: Array[String] = []
var settler_survived: Array[bool] = []
## Season the settler died in, or -1 if they survived.
var settler_lost_season: Array[int] = []
## End-of-run morale value for each settler (-1 for dead settlers).
var settler_end_morale: Array[int] = []

## Food stats accumulated across all seasons.
var total_cafeteria_meals: int = 0
var total_paste_servings: int = 0

## Production stats accumulated across all seasons.
var total_matter_produced: int = 0
var total_crops_yielded: int = 0

## Happiness accumulator — raw sum of per-settler morale across all seasons.
var accumulated_happiness: int = 0

## Assessment — computed at report creation time.
var assessment: String = ""
var assessment_flavor: String = ""


func compute_assessment() -> void:
	var all_dead: bool = true
	for survived: bool in settler_survived:
		if survived:
			all_dead = false
			break

	if all_dead:
		assessment = "Unsuitable"
		assessment_flavor = "The settlement could not sustain itself on this planet."
		return

	var total_settlers: int = settler_names.size()
	var survivors: int = 0
	for survived: bool in settler_survived:
		if survived:
			survivors += 1
	var survival_rate: float = float(survivors) / float(total_settlers)
	var total_fed: int = total_cafeteria_meals + total_paste_servings
	var cafeteria_rate: float = float(total_cafeteria_meals) / float(total_fed) if total_fed > 0 else 0.0

	if survival_rate == 1.0 and accumulated_happiness > 0 and cafeteria_rate >= 0.5:
		assessment = "Strongly Viable"
		assessment_flavor = "This planet shows strong potential to support a thriving human colony."
	elif survival_rate >= 0.5 and accumulated_happiness >= 0:
		assessment = "Viable"
		assessment_flavor = "This planet could support human settlement with continued investment."
	elif survival_rate >= 0.5:
		assessment = "Marginal"
		assessment_flavor = "Settlers struggled to maintain a comfortable standard of living here."
	else:
		assessment = "Unsuitable"
		assessment_flavor = "The settlement suffered significant losses and could not sustain itself."

	if end_reason == EndReason.ENDED_EARLY:
		assessment_flavor += " Mission was concluded before a full seasonal assessment could be made."


func to_dict() -> Dictionary:
	return {
		"timestamp":             timestamp,
		"seasons_survived":      seasons_survived,
		"end_reason":            end_reason,
		"settler_names":         settler_names,
		"settler_survived":      settler_survived,
		"settler_lost_season":   settler_lost_season,
		"settler_end_morale":    settler_end_morale,
		"total_cafeteria_meals": total_cafeteria_meals,
		"total_paste_servings":  total_paste_servings,
		"total_matter_produced": total_matter_produced,
		"total_crops_yielded":   total_crops_yielded,
		"accumulated_happiness": accumulated_happiness,
		"assessment":            assessment,
		"assessment_flavor":     assessment_flavor,
	}


static func from_dict(d: Dictionary) -> MissionReport:
	var r: MissionReport = MissionReport.new()
	r.timestamp             = d.get("timestamp", 0)
	r.seasons_survived      = d.get("seasons_survived", 0)
	r.end_reason            = d.get("end_reason", EndReason.COMPLETE) as EndReason
	r.settler_names.assign(d.get("settler_names", []))
	r.settler_survived.assign(d.get("settler_survived", []))
	r.settler_lost_season.assign(d.get("settler_lost_season", []))
	r.settler_end_morale.assign(d.get("settler_end_morale", []))
	r.total_cafeteria_meals = d.get("total_cafeteria_meals", 0)
	r.total_paste_servings  = d.get("total_paste_servings", 0)
	r.total_matter_produced = d.get("total_matter_produced", 0)
	r.total_crops_yielded   = d.get("total_crops_yielded", 0)
	r.accumulated_happiness = d.get("accumulated_happiness", 0)
	r.assessment            = d.get("assessment", "")
	r.assessment_flavor     = d.get("assessment_flavor", "")
	return r
