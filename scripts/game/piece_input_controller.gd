class_name PieceInputController
extends Node

## Phase 1 strangler shim: receives all _input() events and dispatches them to
## registered pickup sources. Grids no longer process input independently.
##
## In Phase 2, drag state will move here and grids will become fully passive.

# Registered pickup sources (grids, inventory) in insertion order.
var _pickup_sources: Array[Object] = []

# Drop targets sorted by priority descending: Array of {"source": Object, "priority": int}.
var _drop_targets: Array = []


# ---------------------------------------------------------------------------
# Registration API
# ---------------------------------------------------------------------------

## Register a source that can be picked up from.
## If the source is a GameGrid, its _pic_managed flag is set so its own _input() is suppressed.
func register_pickup_source(source: Object) -> void:
	if source in _pickup_sources:
		return
	if source is GameGrid:
		(source as GameGrid)._pic_managed = true
	_pickup_sources.append(source)


## Unregister a pickup source. Its _pic_managed flag is cleared if it is a GameGrid.
func unregister_pickup_source(source: Object) -> void:
	if not (source in _pickup_sources):
		return
	if source is GameGrid:
		(source as GameGrid)._pic_managed = false
	_pickup_sources.erase(source)


## Register a target that can receive drops. priority controls conflict resolution
## when multiple targets overlap (higher priority checked first).
func register_drop_target(source: Object, priority: int = 0) -> void:
	for entry: Dictionary in _drop_targets:
		if entry["source"] == source:
			entry["priority"] = priority
			_sort_drop_targets()
			return
	_drop_targets.append({"source": source, "priority": priority})
	_sort_drop_targets()


## Unregister a drop target.
func unregister_drop_target(source: Object) -> void:
	for i: int in range(_drop_targets.size() - 1, -1, -1):
		if (_drop_targets[i] as Dictionary)["source"] == source:
			_drop_targets.remove_at(i)
			return


func _sort_drop_targets() -> void:
	_drop_targets.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return (a["priority"] as int) > (b["priority"] as int))


# ---------------------------------------------------------------------------
# Input dispatch
# ---------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	for source: Object in _pickup_sources:
		if source is GameGrid:
			(source as GameGrid).receive_input(event)
