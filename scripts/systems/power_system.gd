class_name PowerSystem

## Computes power network formation and powered status for all placed buildings.
##
## Usage:
##   var state: PowerSystem.PowerState = PowerSystem.compute(placed)
##
## `placed` is a Dictionary: piece_id (int) -> {
##     "row":    int,
##     "col":    int,
##     "def":    PlaceableDefinition,
##     "active": bool
## }
##
## Network formation rules:
##   - Two power sources A and B are in the same network if
##     manhattan_dist(A, B) <= A.power_range  OR  <= B.power_range
##     (either source can see the other's cell).
##   - A consumer is assigned to the network whose nearest in-range source
##     has the shortest Manhattan distance. Ties broken by lower piece_id.
##   - A building is "powered" if it is connected to a network whose
##     pool (sum of sources' energy_production) >= draw (sum of consumers'
##     power_draw assigned to that network).
##   - Inactive buildings (active = false) contribute 0 to pool and 0 to draw,
##     and are never powered.

class Network:
	var source_ids: Array[int] = []
	var pool: int = 0  ## sum of active sources' energy_production in this network
	var draw: int = 0  ## sum of active consumers assigned to this network

	func is_sufficient() -> bool:
		return pool >= draw

class PowerState:
	## All networks found in the current grid layout.
	var networks: Array = []  ## Array[PowerSystem.Network]
	## Maps piece_id -> index into networks (-1 = not connected to any network).
	var piece_network_idx: Dictionary = {}
	## Maps piece_id -> bool: true if connected to a sufficient network.
	var piece_powered: Dictionary = {}

	func total_pool() -> int:
		var t: int = 0
		for n: PowerSystem.Network in networks:
			t += n.pool
		return t

	func total_draw() -> int:
		var t: int = 0
		for n: PowerSystem.Network in networks:
			t += n.draw
		return t

	func is_powered(piece_id: int) -> bool:
		return piece_powered.get(piece_id, false)

## Compute and return a PowerState from the current placed-piece dictionary.
static func compute(placed: Dictionary) -> PowerSystem.PowerState:
	var state: PowerSystem.PowerState = PowerSystem.PowerState.new()

	# Initialise every piece as not powered and not networked.
	for piece_id: int in placed:
		state.piece_network_idx[piece_id] = -1
		state.piece_powered[piece_id]     = false

	# Collect active power sources and consumers from BuildingDefinitions only.
	var sources: Array = []   # {id, row, col, range, production}
	var consumers: Array = [] # {id, row, col, draw}

	for piece_id: int in placed:
		var entry: Dictionary = placed[piece_id]
		if not entry["active"]:
			continue
		if not entry["def"] is BuildingDefinition:
			continue
		var def: BuildingDefinition = entry["def"] as BuildingDefinition
		if def.power_range > 0:
			sources.append({
				"id":         piece_id,
				"row":        entry["row"],
				"col":        entry["col"],
				"range":      def.power_range,
				"production": def.energy_production,
			})
		if def.power_draw > 0:
			consumers.append({
				"id":  piece_id,
				"row": entry["row"],
				"col": entry["col"],
				"draw": def.power_draw,
			})

	if sources.is_empty():
		return state

	# -----------------------------------------------------------------------
	# Union-Find: group sources into connected components (networks).
	# -----------------------------------------------------------------------
	var parent: Dictionary = {}
	for s: Dictionary in sources:
		parent[s["id"]] = s["id"]

	for i: int in range(sources.size()):
		for j: int in range(i + 1, sources.size()):
			var a: Dictionary = sources[i]
			var b: Dictionary = sources[j]
			var d: int = absi(a["row"] - b["row"]) + absi(a["col"] - b["col"])
			if d <= a["range"] or d <= b["range"]:
				_union(parent, a["id"], b["id"])

	# Build Network objects from the resulting components.
	var root_to_net_idx: Dictionary = {}
	for s: Dictionary in sources:
		var root: int = _find(parent, s["id"])
		if not root_to_net_idx.has(root):
			root_to_net_idx[root] = state.networks.size()
			state.networks.append(PowerSystem.Network.new())
		var idx: int            = root_to_net_idx[root]
		var net: PowerSystem.Network = state.networks[idx]
		net.source_ids.append(s["id"])
		net.pool += s["production"]
		state.piece_network_idx[s["id"]] = idx
		state.piece_powered[s["id"]]     = true  # set properly after draw check below

	# -----------------------------------------------------------------------
	# Assign each consumer to the in-range source with the shortest distance.
	# Ties broken by lower piece_id (deterministic ordering).
	# -----------------------------------------------------------------------
	for c: Dictionary in consumers:
		var best_dist:    int = INF
		var best_id:      int = -1
		var best_net_idx: int = -1
		for s: Dictionary in sources:
			var d: int = absi(c["row"] - s["row"]) + absi(c["col"] - s["col"])
			if d > s["range"]:
				continue
			if d < best_dist or (d == best_dist and s["id"] < best_id):
				best_dist    = d
				best_id      = s["id"]
				best_net_idx = state.piece_network_idx[s["id"]]
		if best_net_idx != -1:
			var net: PowerSystem.Network = state.networks[best_net_idx]
			net.draw += c["draw"]
			state.piece_network_idx[c["id"]] = best_net_idx

	# -----------------------------------------------------------------------
	# Resolve powered status now that all draws are tallied.
	# -----------------------------------------------------------------------
	for piece_id: int in placed:
		var idx: int = state.piece_network_idx.get(piece_id, -1)
		if idx == -1:
			state.piece_powered[piece_id] = false
		else:
			state.piece_powered[piece_id] = (state.networks[idx] as PowerSystem.Network).is_sufficient()

	return state

# ---------------------------------------------------------------------------
# Union-Find helpers (path-compressed).
# ---------------------------------------------------------------------------

static func _find(parent: Dictionary, x: int) -> int:
	if parent[x] != x:
		parent[x] = _find(parent, parent[x])
	return parent[x]

static func _union(parent: Dictionary, x: int, y: int) -> void:
	var rx: int = _find(parent, x)
	var ry: int = _find(parent, y)
	if rx != ry:
		parent[ry] = rx
