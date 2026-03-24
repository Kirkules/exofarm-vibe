class_name NeighborSystem

## Computes piece-to-piece neighbor relationships based on each piece's effect_range.
##
## Usage:
##   var state: NeighborSystem.NeighborState = NeighborSystem.compute(placed)
##
## `placed` is a Dictionary: piece_id (int) -> {
##     "row":    int,
##     "col":    int,
##     "def":    PlaceableDefinition,
##     "active": bool
## }
##
## Neighbor rules:
##   - Piece A lists piece B as a neighbor if:
##       manhattan_dist(A.origin, B.origin) <= A.effect_range
##   - Relationships are directional: A having B in range does NOT imply B has A.
##   - Pieces with effect_range == 0 produce no outgoing neighbors but may appear
##     in other pieces' neighbor lists.
##   - Active/inactive state is not filtered; callers decide whether to apply effects
##     from inactive pieces.

class NeighborState:
	## Maps piece_id -> Array of piece_ids within this piece's effect_range.
	## Only populated for pieces whose effect_range > 0.
	var neighbors: Dictionary = {}    # piece_id -> Array[int]
	## Reverse map: piece_id -> Array of piece_ids that have this piece in their range.
	var in_range_of: Dictionary = {}  # piece_id -> Array[int]

	## Returns the pieces that piece_id can affect (within its own effect_range).
	func get_neighbors(piece_id: int) -> Array:
		return neighbors.get(piece_id, [])

	## Returns the pieces whose effect_range reaches piece_id.
	func get_in_range_of(piece_id: int) -> Array:
		return in_range_of.get(piece_id, [])

	## True if piece_id has at least one piece within its own effect_range.
	func has_neighbors(piece_id: int) -> bool:
		return not (neighbors.get(piece_id, []) as Array).is_empty()

## Compute and return a NeighborState from the current placed-piece dictionary.
static func compute(placed: Dictionary) -> NeighborSystem.NeighborState:
	var state: NeighborSystem.NeighborState = NeighborSystem.NeighborState.new()

	# Initialise empty lists for every piece.
	for piece_id: int in placed:
		state.neighbors[piece_id]   = []
		state.in_range_of[piece_id] = []

	# For each piece with a positive effect_range, find all others within range.
	for piece_id: int in placed:
		var entry: Dictionary = placed[piece_id]
		var def: PlaceableDefinition = entry["def"] as PlaceableDefinition
		if def == null or def.shape == null:
			continue
		var effect_range: int = def.shape.effect_range
		if effect_range <= 0:
			continue
		var row: int = entry["row"]
		var col: int = entry["col"]

		for other_id: int in placed:
			if other_id == piece_id:
				continue
			var other: Dictionary = placed[other_id]
			var d: int = absi(row - other["row"]) + absi(col - other["col"])
			if d <= effect_range:
				(state.neighbors[piece_id]   as Array).append(other_id)
				(state.in_range_of[other_id] as Array).append(piece_id)

	return state
