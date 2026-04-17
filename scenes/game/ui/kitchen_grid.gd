class_name KitchenGrid
extends GameGrid

## Merge-space grid shown as an overlay on the farm grid when a Cafeteria is on
## the grid.  Items are 1×1 polyominos.  game.gd manages all inventory transitions.

const KITCHEN_ROWS      := 4
const KITCHEN_COLS      := 3
const KITCHEN_CELL_SIZE := 40
const HEADER_H          := 32

const COLOR_BG       := Color(0.08, 0.08, 0.12, 0.95)
const COLOR_INACTIVE := Color(0.10, 0.10, 0.14)
const COLOR_PANEL_BORDER := Color(0.55, 0.55, 0.75)

## Emitted when capacity reduction forces a piece out of the grid.
## game.gd returns the corresponding item to inventory.
signal piece_ejected(piece_id: int)

var _capacity: int = 0

# ---------------------------------------------------------------------------
# Recipe group state
# ---------------------------------------------------------------------------
## Known recipes used for group matching. Set via set_recipes() by KitchenManager.
var _known_recipes: Array[RecipeDefinition] = []
## Maps group_id (int) → group dict:
##   { "piece_ids": Array[int], "cells": Array[Vector2i], "item_counts": Dictionary }
##   item_counts: PlaceableDefinition → int (multiset of items in this group)
var _recipe_groups: Dictionary = {}
var _next_group_id: int = 0
## Maps piece_id → group_id for O(1) group lookup.
var _piece_group_id: Dictionary = {}
## Maps piece_id → Vector2i (grid cell), stored independently so it survives grid_data removal.
var _piece_cell: Dictionary = {}
## Maps piece_id → PlaceableDefinition, stored for group rebuilds after removal.
var _piece_def: Dictionary = {}


func _ready() -> void:
	rows      = KITCHEN_ROWS
	cols      = KITCHEN_COLS
	cell_size = KITCHEN_CELL_SIZE
	color_empty   = Color(0.18, 0.18, 0.24)
	color_border  = Color(0.06, 0.06, 0.10)
	color_hover   = Color(0.28, 0.22, 0.32)
	color_valid   = Color(0.30, 0.65, 0.30, 0.65)
	color_invalid = Color(0.65, 0.25, 0.25, 0.65)
	super._ready()
	# Kitchen grids start inactive; KitchenManager.open() activates them explicitly.
	set_grid_active(false)

	var header: Label = Label.new()
	header.text = "Kitchen"
	header.position = Vector2(0.0, -float(HEADER_H))
	header.size = Vector2(float(KITCHEN_COLS * KITCHEN_CELL_SIZE), float(HEADER_H))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", Color(0.75, 0.75, 0.85))
	add_child(header)


func _draw() -> void:
	# Background panel (cells + header + 2px border)
	var panel_w: float = float(cols * cell_size)
	var panel_h: float = float(rows * cell_size + HEADER_H)
	draw_rect(Rect2(0.0, -float(HEADER_H), panel_w, panel_h), COLOR_BG)
	draw_rect(Rect2(-1.0, -float(HEADER_H) - 1.0, panel_w + 2.0, panel_h + 2.0),
		COLOR_PANEL_BORDER, false)
	super._draw()


## Returns the full screen rect including the header area.
func get_full_screen_rect() -> Rect2:
	var r: Rect2 = get_screen_rect()
	r.position.y -= HEADER_H
	r.size.y     += HEADER_H
	return r


## Block placement on cells whose slot index is >= capacity.
func _can_place_at_cell(cell: Vector2i) -> bool:
	var slot_idx: int = (cell.x - 1) * cols + (cell.y - 1)
	return slot_idx < _capacity


## Accept only KITCHEN_GRID items that are not also FARM_GRID (farm items stay on farm).
func try_receive_drop(cursor_screen: Vector2, shape: PieceShape,
		payload: Variant, hint: String) -> int:
	var item: InventoryItem = payload as InventoryItem
	if item == null:
		return -1
	var def: PlaceableDefinition = item.data as PlaceableDefinition
	if def == null or not (PlaceableDefinition.GridType.KITCHEN_GRID in def.allowed_grids):
		return -1
	if PlaceableDefinition.GridType.FARM_GRID in def.allowed_grids:
		return -1  # farm-grid items do not route to the kitchen
	return super.try_receive_drop(cursor_screen, shape, payload, hint)


func _draw_grid_overlays() -> void:
	for row: int in range(1, rows + 1):
		for col: int in range(1, cols + 1):
			var slot_idx: int = (row - 1) * cols + (col - 1)
			if slot_idx >= _capacity:
				draw_rect(_cell_rect(row, col), COLOR_INACTIVE)
				draw_rect(_cell_rect(row, col), color_border, false)
	# Highlight recipe groups: bright green border for complete, dim teal for partial.
	for gid: int in _recipe_groups:
		var group: Dictionary = _recipe_groups[gid]
		var is_complete: bool = false
		for recipe: RecipeDefinition in _known_recipes:
			if _multisets_equal(group["item_counts"], recipe.ingredients):
				is_complete = true
				break
		var highlight: Color = Color(0.30, 0.90, 0.40, 0.55) if is_complete \
				else Color(0.20, 0.55, 0.55, 0.35)
		for cell: Vector2i in group["cells"]:
			draw_rect(_cell_rect(cell.x, cell.y), highlight, false, 2.0)


# ---------------------------------------------------------------------------
# Recipe group — public API (called by KitchenManager)
# ---------------------------------------------------------------------------

## Provide the known recipes used for group matching.
func set_recipes(recipes: Array[RecipeDefinition]) -> void:
	_known_recipes = recipes

## Register a newly placed item and flood-merge with compatible neighbors.
## Must be called by KitchenManager after piece_placed_on_grid / piece_returned_to_grid.
func on_item_placed(piece_id: int, def: PlaceableDefinition) -> void:
	var info: Dictionary = grid_data.get_piece_info(piece_id)
	if info.is_empty():
		return
	var cell: Vector2i = Vector2i(info["row"], info["col"])
	_piece_cell[piece_id] = cell
	_piece_def[piece_id]  = def
	# Create a fresh 1-item group for this piece.
	var gid: int = _next_group_id
	_next_group_id += 1
	_recipe_groups[gid] = {
		"piece_ids":   [piece_id],
		"cells":       [cell],
		"item_counts": {def: 1},
	}
	_piece_group_id[piece_id] = gid
	# Greedily flood-merge with compatible neighbor groups.
	_flood_merge_from(gid, cell)
	queue_redraw()

## Unregister a removed item, split the group it belonged to if it breaks adjacency.
## Must be called by KitchenManager after pickup_confirmed (grid origin) / piece_ejected.
func on_item_removed(piece_id: int) -> void:
	if not _piece_group_id.has(piece_id):
		return
	var gid: int      = _piece_group_id[piece_id]
	var group: Dictionary = _recipe_groups.get(gid, {})
	if group.is_empty():
		_piece_group_id.erase(piece_id)
		_piece_cell.erase(piece_id)
		_piece_def.erase(piece_id)
		return
	# Remove this piece from its group.
	(group["piece_ids"] as Array).erase(piece_id)
	(group["cells"] as Array).erase(_piece_cell[piece_id])
	var def: PlaceableDefinition = _piece_def[piece_id]
	var new_count: int = (group["item_counts"].get(def, 1) as int) - 1
	if new_count <= 0:
		group["item_counts"].erase(def)
	else:
		group["item_counts"][def] = new_count
	_piece_group_id.erase(piece_id)
	_piece_cell.erase(piece_id)
	_piece_def.erase(piece_id)
	if (group["piece_ids"] as Array).is_empty():
		_recipe_groups.erase(gid)
	else:
		_split_group(gid)
	queue_redraw()

## Returns [{recipe, piece_ids, group_id}] for every group whose item_counts
## exactly matches a RecipeDefinition's ingredients.
func get_complete_recipe_groups() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for gid: int in _recipe_groups:
		var group: Dictionary = _recipe_groups[gid]
		for recipe: RecipeDefinition in _known_recipes:
			if _multisets_equal(group["item_counts"], recipe.ingredients):
				result.append({
					"recipe":    recipe,
					"piece_ids": (group["piece_ids"] as Array).duplicate(),
					"group_id":  gid,
				})
				break
	return result


# ---------------------------------------------------------------------------
# Recipe group — internals
# ---------------------------------------------------------------------------

## Flood-merge the group at gid with compatible neighbor groups, checking
## neighbors of from_cell in up/left/down/right order.
func _flood_merge_from(gid: int, from_cell: Vector2i) -> void:
	var directions: Array[Vector2i] = [
		Vector2i(-1,  0),  # up
		Vector2i( 0, -1),  # left
		Vector2i( 1,  0),  # down
		Vector2i( 0,  1),  # right
	]
	for dir: Vector2i in directions:
		var neighbor_cell: Vector2i = from_cell + dir
		var neighbor_pid: int = _piece_at_cell(neighbor_cell)
		if neighbor_pid <= 0:
			continue
		var neighbor_gid: int = _piece_group_id.get(neighbor_pid, -1)
		if neighbor_gid == -1 or neighbor_gid == gid:
			continue
		if _can_merge_groups(gid, neighbor_gid):
			_merge_into(gid, neighbor_gid)

## Returns the piece_id at the given grid cell, or 0 if empty/out-of-bounds.
func _piece_at_cell(cell: Vector2i) -> int:
	if cell.x < 1 or cell.x > rows or cell.y < 1 or cell.y > cols:
		return 0
	var v: int = grid_data.get_cell(cell.x, cell.y)
	return v if v > 0 else 0

## Returns true if the merged item_counts of gid_a and gid_b fit within any recipe.
func _can_merge_groups(gid_a: int, gid_b: int) -> bool:
	var ga: Dictionary = _recipe_groups[gid_a]
	var gb: Dictionary = _recipe_groups[gid_b]
	var merged: Dictionary = {}
	for k: PlaceableDefinition in ga["item_counts"]:
		merged[k] = ga["item_counts"][k] as int
	for k: PlaceableDefinition in gb["item_counts"]:
		merged[k] = (merged.get(k, 0) as int) + (gb["item_counts"][k] as int)
	return _multiset_fits_recipe(merged)

## Absorb other_gid into gid; other_gid is erased.
func _merge_into(gid: int, other_gid: int) -> void:
	var g: Dictionary     = _recipe_groups[gid]
	var other: Dictionary = _recipe_groups[other_gid]
	for pid: int in other["piece_ids"]:
		(g["piece_ids"] as Array).append(pid)
		(g["cells"] as Array).append(_piece_cell[pid])
		_piece_group_id[pid] = gid
	for k: PlaceableDefinition in other["item_counts"]:
		g["item_counts"][k] = (g["item_counts"].get(k, 0) as int) + (other["item_counts"][k] as int)
	_recipe_groups.erase(other_gid)

## After a removal, re-examine remaining pieces in gid for connected components.
## If the group split, create new groups for each component and erase the old one.
func _split_group(gid: int) -> void:
	var group: Dictionary = _recipe_groups[gid]
	var remaining: Array  = (group["piece_ids"] as Array).duplicate()
	if remaining.size() == 1:
		_rebuild_group_counts(gid)
		return
	# BFS to find connected components.
	var visited: Dictionary = {}   # piece_id → bool
	var components: Array   = []   # Array of Array[int]
	for start_pid: int in remaining:
		if visited.get(start_pid, false):
			continue
		var component: Array[int] = []
		var queue: Array[int]     = [start_pid]
		visited[start_pid]        = true
		while not queue.is_empty():
			var pid: int = queue.pop_front()
			component.append(pid)
			for other_pid: int in remaining:
				if not visited.get(other_pid, false) and _pieces_adjacent(pid, other_pid):
					visited[other_pid] = true
					queue.append(other_pid)
		components.append(component)
	if components.size() == 1:
		_rebuild_group_counts(gid)
		return
	# Multiple components — replace gid with one group per component.
	_recipe_groups.erase(gid)
	for comp: Array in components:
		var new_gid: int          = _next_group_id
		_next_group_id           += 1
		var new_counts: Dictionary = {}
		var new_cells: Array[Vector2i] = []
		for pid: int in comp:
			var def: PlaceableDefinition = _piece_def[pid]
			new_counts[def] = (new_counts.get(def, 0) as int) + 1
			new_cells.append(_piece_cell[pid])
			_piece_group_id[pid] = new_gid
		_recipe_groups[new_gid] = {
			"piece_ids":   comp,
			"cells":       new_cells,
			"item_counts": new_counts,
		}

## Recompute item_counts and cells for gid from its current piece_ids.
func _rebuild_group_counts(gid: int) -> void:
	var group: Dictionary      = _recipe_groups[gid]
	var new_counts: Dictionary = {}
	var new_cells: Array[Vector2i] = []
	for pid: int in group["piece_ids"]:
		var def: PlaceableDefinition = _piece_def[pid]
		new_counts[def] = (new_counts.get(def, 0) as int) + 1
		new_cells.append(_piece_cell[pid])
	group["item_counts"] = new_counts
	group["cells"]       = new_cells

## Returns true if two pieces occupy Manhattan-distance-1 cells.
func _pieces_adjacent(pid_a: int, pid_b: int) -> bool:
	var ca: Vector2i = _piece_cell[pid_a]
	var cb: Vector2i = _piece_cell[pid_b]
	return absi(ca.x - cb.x) + absi(ca.y - cb.y) == 1

## Returns true if counts is a sub-multiset of at least one known recipe's ingredients.
func _multiset_fits_recipe(counts: Dictionary) -> bool:
	for recipe: RecipeDefinition in _known_recipes:
		if _is_sub_multiset(counts, recipe.ingredients):
			return true
	return false

## Returns true if every key in sub has sub[k] <= super_set[k].
func _is_sub_multiset(sub: Dictionary, super_set: Dictionary) -> bool:
	for k: PlaceableDefinition in sub:
		if (sub[k] as int) > (super_set.get(k, 0) as int):
			return false
	return true

## Returns true if a and b contain identical keys with identical counts.
func _multisets_equal(a: Dictionary, b: Dictionary) -> bool:
	if a.size() != b.size():
		return false
	for k: PlaceableDefinition in a:
		if (a[k] as int) != (b.get(k, 0) as int):
			return false
	return true


## Set the number of active slots.  Pieces in slots >= cap are ejected via
## piece_ejected so game.gd can return the corresponding items to inventory.
func set_capacity(cap: int) -> void:
	_capacity = clampi(cap, 0, rows * cols)
	# Eject pieces whose slot index now falls outside the active capacity.
	for piece_id: int in grid_data.get_all_piece_ids():
		var info: Dictionary = grid_data.get_piece_info(piece_id)
		if info.is_empty():
			continue
		var slot_idx: int = (info["row"] - 1) * cols + (info["col"] - 1)
		if slot_idx >= _capacity:
			grid_data.remove_piece(piece_id)
			_remove_piece_sprite(piece_id)
			piece_ejected.emit(piece_id)
	queue_redraw()
