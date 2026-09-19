class_name RunMapGenerator
extends RefCounted
## Branching RunMap graph generator — architecture plan §7 ("RunMap Graph generator —
## thiết kế lại"), path-walking algorithm, NOT the "random 1-2 edges + orphan-repair"
## approach the first draft used (that draft was rejected in review: bottlenecks, crossing
## edges, ~50% dead-end nodes). Every function here is static; this class carries no
## instance state.
##
## ── Algorithm summary (architecture plan §7) ──────────────────────────────────────────
## The run is a sequence of "segments", each running from one mandatory single-node row
## (the start row, or a boss row) down to the next boss row. Within a segment, K (4-6,
## chosen per segment via the passed-in Rng — "K≈4-6" per the plan) parallel paths walk
## row-by-row from the segment's start column (0) to its end column (0), each step moving
## at most 1 column (|Δcol|<=1). Paths are processed in a fixed index order every row and
## constrained to non-decreasing column position relative to the previous path index —
## this is what guarantees "no crossing edges" (invariant #2) as a structural property of
## the construction rather than something checked-and-rejected after the fact. Duplicate
## (col_a -> col_b) transitions across different paths collapse onto the same edge ("gộp
## cạnh trùng" per the plan) because nodes are keyed by (row, col), not by path identity.
##
## Node TYPE (battle/elite/event/shop/treasure/boss) is assigned in a second pass, after
## the whole row/column/edge shape already exists ("Gán type SAU khi có graph, không phải
## trước" per the plan) — see _assign_types().
##
## ── Determinism (architecture plan §5, §7) ────────────────────────────────────────────
## generate() is a pure function of (rng's starting state, mode, ascension): the SAME Rng
## seed always produces a byte-identical graph (verified by tests/t_map_invariants.gd).
## Retries (see MAX_RETRIES) consume further draws from the same Rng instance rather than
## reseeding, so the seed -> graph mapping stays a pure function end to end, including the
## retry path.
##
## ── Row-number scale decision (NOT specified by the plan — chosen here, flagged) ──────
## The plan explicitly declares this out of scope for the architecture step ("Số hàng cụ
## thể ... sẽ chốt bằng cách chạy tools/sim.js khi thực hiện bước 4 của checklist triển
## khai") and only gives a worked EXAMPLE for short mode in the task brief: scaling
## short's 12 rows -> 18 rows (x1.5) puts boss rows at ~6/12/18. This file applies that
## same x1.5 scale factor to BOTH modes (round-half-up on each of the old boss/elite step
## numbers) rather than inventing an unrelated number for full mode:
##   short: len 12->18,  boss [4,8,12]->[6,12,18],   elite [3,6,10]->[5,9,15]
##   full:  len 20->30,  boss [5,10,15,20]->[8,15,23,30], elite [3,7,12,17]->[5,11,18,26]
## This keeps segment lengths (4-7 free rows) inside the plan's "K≈4-6" walk-length
## ballpark for every segment in both modes. MODE_CONFIG below is precomputed (not derived
## at runtime) specifically so a future balance pass can read/edit these numbers directly
## without reverse-engineering the scaling math — re-tuning `TUNE.base/growth` via
## tools/sim.js is explicitly OUT OF SCOPE for this file (task instructions) and these row
## counts are expected to change when that pass happens.
const MODE_CONFIG := {
	"short": {
		"total_rows": 18, "boss_rows": [6, 12, 18], "elite_rows": [5, 9, 15],
		"shop_min_row": 5, "elite_min_row": 5,
	},
	"full": {
		"total_rows": 30, "boss_rows": [8, 15, 23, 30], "elite_rows": [5, 11, 18, 26],
		"shop_min_row": 5, "elite_min_row": 5,
	},
}

const K_MIN := 4              ## Parallel path-walks per segment, lower bound (plan §7 "K≈4-6").
const K_MAX := 6              ## Parallel path-walks per segment, upper bound (inclusive).
const MAX_WIDTH := 3          ## Column cap per row. Also caps in-degree at <=3 (invariant #2)
                               ## by construction: a node's predecessors can only come from
                               ## the <=MAX_WIDTH distinct columns of the previous row.
const MAX_RETRIES := 20       ## Plan §7: "seed vi phạm -> retry <=20 lần rồi fail cứng".


## Builds a full RunMapGraph for `mode` ("short"|"full") and `ascension` (0-10) from `rng`.
## Retries internally (same Rng instance, see class doc) up to MAX_RETRIES times if a build
## violates any of the 10 invariants (see validate()). Returns null and push_error()s on
## total exhaustion — deliberately NOT a silently-degraded map (plan §7: "fail cứng ở lần
## cuối, không âm thầm nhả map xấu"). Callers must treat a null return as fatal; do not add
## a fallback empty-graph path here.
static func generate(rng: Rng, mode: String, ascension: int) -> RunMapGraph:
	var result := generate_with_diagnostics(rng, mode, ascension)
	if result["graph"] == null:
		push_error("RunMapGenerator.generate: FAILED after %d attempts (mode=%s, ascension=%d) — last violations: %s" % [
			MAX_RETRIES, mode, ascension, ", ".join(result["violations"] as Array)])
	return result["graph"]


## Same as generate(), but always returns diagnostics ({graph, attempts, violations}) even
## on failure — graph is null and violations holds the last attempt's failures. Used by
## generate() itself and by tests/t_map_invariants.gd (which needs the violation list to
## report *why* a seed failed, not just that it failed).
static func generate_with_diagnostics(rng: Rng, mode: String, ascension: int) -> Dictionary:
	var cfg: Dictionary = MODE_CONFIG.get(mode, MODE_CONFIG["short"])
	var last_violations: Array[String] = []
	for attempt in range(MAX_RETRIES):
		var graph := _build_once(rng, cfg, ascension)
		var violations := validate(graph, cfg, ascension)
		if violations.is_empty():
			return {"graph": graph, "attempts": attempt + 1, "violations": []}
		last_violations = violations
	return {"graph": null, "attempts": MAX_RETRIES, "violations": last_violations}


# ---------------------------------------------------------------------------------------
# Construction
# ---------------------------------------------------------------------------------------

static func _build_once(rng: Rng, cfg: Dictionary, ascension: int) -> RunMapGraph:
	var graph := RunMapGraph.new()
	graph.boss_rows.assign((cfg["boss_rows"] as Array).duplicate())
	graph.elite_rows.assign((cfg["elite_rows"] as Array).duplicate())
	graph.start_node_id = "r1_c0"

	var nodes_by_key: Dictionary = {}   # "row_col" -> RunMapNode
	_ensure_node(nodes_by_key, 1, 0)

	var segment_bounds: Array = [1]
	segment_bounds.append_array(graph.boss_rows)
	for i in range(segment_bounds.size() - 1):
		_walk_segment(rng, nodes_by_key, int(segment_bounds[i]), int(segment_bounds[i + 1]))

	_assign_types(nodes_by_key, graph, cfg, ascension, rng)

	var total_rows: int = cfg["total_rows"]
	graph.rows = []
	for row_num in range(1, total_rows + 1):
		var row_nodes: Array[RunMapNode] = []
		for key in nodes_by_key:
			var n: RunMapNode = nodes_by_key[key]
			if n.row == row_num:
				row_nodes.append(n)
		row_nodes.sort_custom(func(a: RunMapNode, b: RunMapNode) -> bool: return a.col < b.col)
		graph.rows.append(row_nodes)

	return graph


## Walks K parallel non-crossing paths from the single node at (start_row, col=0) to the
## single node at (end_row, col=0), through the free rows strictly between them. See class
## doc for the non-crossing argument.
static func _walk_segment(rng: Rng, nodes_by_key: Dictionary, start_row: int, end_row: int) -> void:
	_ensure_node(nodes_by_key, start_row, 0)
	_ensure_node(nodes_by_key, end_row, 0)

	var free_rows: Array = []
	for r in range(start_row + 1, end_row):
		free_rows.append(r)

	if free_rows.is_empty():
		# Segment too short for a free row (shouldn't happen with MODE_CONFIG's spacing,
		# but degrade gracefully rather than crash if a future config ever produces one).
		_link(nodes_by_key, start_row, 0, end_row, 0)
		return

	var k: int = K_MIN + rng.next_int(K_MAX - K_MIN + 1)
	var prev_cols: Array = []
	for p in range(k):
		prev_cols.append(0)

	var row_cols_by_row: Dictionary = {}   # row -> Array[int], this row's column per path index
	for row in free_rows:
		var this_row_cols: Array = []
		var prev_assigned := -1
		for p in range(k):
			var delta: int = rng.next_int(3) - 1   # -1, 0, or +1
			var col: int = int(prev_cols[p]) + delta
			col = clampi(col, 0, MAX_WIDTH - 1)
			col = max(col, prev_assigned)   # non-decreasing across path index -> no crossing
			this_row_cols.append(col)
			prev_assigned = col
		# Repair: force >=2 distinct columns whenever possible. This is what makes
		# invariant #3 ("≥60% of free rows have ≥2 real choices") hold by construction for
		# nearly every seed rather than merely "probably" — bumping the LAST path's column
		# up (or, as a fallback, the FIRST path's column down) preserves the non-decreasing
		# ordering the crossing-edge guarantee depends on.
		if _distinct_count(this_row_cols) < 2 and k >= 2:
			this_row_cols[k - 1] = min(int(this_row_cols[k - 1]) + 1, MAX_WIDTH - 1)
			if _distinct_count(this_row_cols) < 2:
				this_row_cols[0] = max(int(this_row_cols[0]) - 1, 0)
		row_cols_by_row[row] = this_row_cols
		for col in this_row_cols:
			_ensure_node(nodes_by_key, row, int(col))
		prev_cols = this_row_cols

	var first_free: int = free_rows[0]
	for col in (row_cols_by_row[first_free] as Array):
		_link(nodes_by_key, start_row, 0, first_free, int(col))

	for i in range(free_rows.size() - 1):
		var r_a: int = free_rows[i]
		var r_b: int = free_rows[i + 1]
		var cols_a: Array = row_cols_by_row[r_a]
		var cols_b: Array = row_cols_by_row[r_b]
		for p in range(k):
			_link(nodes_by_key, r_a, int(cols_a[p]), r_b, int(cols_b[p]))

	# Invariant #9: the row immediately before a boss row converges 100% onto that boss
	# node — automatic here because every last-free-row node's only outgoing edge target
	# is (end_row, 0).
	var last_free: int = free_rows[free_rows.size() - 1]
	for col in (row_cols_by_row[last_free] as Array):
		_link(nodes_by_key, last_free, int(col), end_row, 0)


static func _ensure_node(nodes_by_key: Dictionary, row: int, col: int) -> RunMapNode:
	var key := "%d_%d" % [row, col]
	if nodes_by_key.has(key):
		return nodes_by_key[key]
	var n := RunMapNode.new()
	n.id = "r%d_c%d" % [row, col]
	n.row = row
	n.col = col
	n.node_type = ""   # assigned later by _assign_types()
	n.next_ids = []
	n.visited = false
	n.locked = true
	nodes_by_key[key] = n
	return n


static func _link(nodes_by_key: Dictionary, r1: int, c1: int, r2: int, c2: int) -> void:
	var a := _ensure_node(nodes_by_key, r1, c1)
	var b := _ensure_node(nodes_by_key, r2, c2)
	if not a.next_ids.has(b.id):
		a.next_ids.append(b.id)


static func _distinct_count(values: Array) -> int:
	var seen: Dictionary = {}
	for v in values:
		seen[v] = true
	return seen.size()


# ---------------------------------------------------------------------------------------
# Type assignment (runs AFTER the graph shape exists — plan §7)
# ---------------------------------------------------------------------------------------

static func _assign_types(nodes_by_key: Dictionary, graph: RunMapGraph, cfg: Dictionary,
		ascension: int, rng: Rng) -> void:
	var by_row: Dictionary = {}   # int row -> Array[RunMapNode]
	for key in nodes_by_key:
		var n: RunMapNode = nodes_by_key[key]
		if not by_row.has(n.row):
			by_row[n.row] = []
		(by_row[n.row] as Array).append(n)

	# Row 1: mandatory single node, forced battle (rule spec §1 "step 1 luôn 1 node battle").
	for n in (by_row.get(1, []) as Array):
		(n as RunMapNode).node_type = "battle"

	for boss_row in graph.boss_rows:
		for n in (by_row.get(boss_row, []) as Array):
			(n as RunMapNode).node_type = "boss"

	var content_rows: Array = []
	for row_num in by_row.keys():
		if int(row_num) == 1 or graph.boss_rows.has(int(row_num)):
			continue
		content_rows.append(int(row_num))
	content_rows.sort()

	var last_shop_row := -999
	var free_row_index := 0   # global counter across the WHOLE run (not reset per segment)
	for row_num in content_rows:
		var nodes: Array = by_row[row_num]
		var is_elite_row: bool = graph.elite_rows.has(row_num)
		# Invariant #8 ("<=2 consecutive non-combat rows on any path"): forcing every 3rd
		# free row to be all-combat is a sufficient (not merely likely) guarantee — see
		# validate()'s INV8 check, which verifies this directly on the row structure.
		var is_forced_combat_row: bool = (free_row_index % 3 == 2)
		free_row_index += 1

		if is_elite_row:
			var elite_col_i: int = rng.next_int(nodes.size())
			for i in range(nodes.size()):
				(nodes[i] as RunMapNode).node_type = "elite" if i == elite_col_i else "battle"
		elif is_forced_combat_row:
			for n in nodes:
				(n as RunMapNode).node_type = "battle"
		else:
			var battle_i: int = rng.next_int(nodes.size())
			var allow_shop: bool = row_num >= int(cfg["shop_min_row"]) and row_num - 1 != last_shop_row
			var pool: Array[String] = ["event", "event", "treasure"]
			if allow_shop:
				pool.append("shop")
			var used_shop_this_row := false
			for i in range(nodes.size()):
				var node: RunMapNode = nodes[i]
				if i == battle_i:
					node.node_type = "battle"
				else:
					var t: String = pool[rng.next_int(pool.size())]
					if t == "shop":
						if used_shop_this_row:
							t = "event"   # at most 1 shop per row — keeps "no 2 consecutive
										   # shop nodes on any path" simple and row-checkable.
						else:
							used_shop_this_row = true
					node.node_type = t
			if used_shop_this_row:
				last_shop_row = row_num

	if ascension >= 9:
		_apply_extra_elite_row(by_row, graph)


## Ascension>=9 "extraElite" (rule spec §9 ASCENSION table; architecture plan §7 invariant
## #10): must be an UNAVOIDABLE elite row — every column forced to elite — or the ascension
## modifier has no teeth (a player could just always pick the non-elite column).
##
## PLACEMENT DECISION (explicitly deferred by the plan to the sim.js re-tune pass —
## "quyết định cụ thể chốt cùng lúc bước re-tune balance, không phải bây giờ"): this picks
## the first content row starting 2 rows after the FIRST boss row that isn't already a
## designated boss/elite row. This is a functional placeholder satisfying invariant #10,
## not a balanced final position — flag this to game-designer/systems-designer before
## shipping ascension 9-10 to players.
static func _apply_extra_elite_row(by_row: Dictionary, graph: RunMapGraph) -> void:
	if graph.boss_rows.is_empty():
		return
	var candidate: int = graph.boss_rows[0] + 2
	var last_boss: int = graph.boss_rows[graph.boss_rows.size() - 1]
	while graph.boss_rows.has(candidate) or graph.elite_rows.has(candidate) or not by_row.has(candidate):
		candidate += 1
		if candidate > last_boss:
			return   # No legal row found — leave the map without the extra row rather than
					  # corrupt an existing boss/elite row's semantics.
	for n in (by_row[candidate] as Array):
		(n as RunMapNode).node_type = "elite"
	graph.elite_rows.append(candidate)
	graph.elite_rows.sort()


# ---------------------------------------------------------------------------------------
# Validation — the 10 invariants, architecture plan §7
# ---------------------------------------------------------------------------------------

## Returns an empty array if `graph` satisfies all 10 invariants, otherwise one human-
## readable description string per violation (a single invariant can contribute multiple
## strings if it's violated in more than one place). Pure/side-effect-free — used both by
## generate()'s retry loop and directly by tests/t_map_invariants.gd for diagnostics.
static func validate(graph: RunMapGraph, cfg: Dictionary, ascension: int) -> Array[String]:
	var violations: Array[String] = []
	if graph == null:
		violations.append("graph is null")
		return violations

	var all_nodes: Array[RunMapNode] = []
	for row in graph.rows:
		for n in row:
			all_nodes.append(n)

	var by_id: Dictionary = {}
	for n in all_nodes:
		by_id[n.id] = n

	# INV1 — everything reachable from start; every boss node reachable from start.
	var reachable := _bfs_forward(by_id, graph.start_node_id)
	for n in all_nodes:
		if not reachable.has(n.id):
			violations.append("INV1: node %s not reachable from start" % n.id)

	# INV2 — no crossing edges; in-degree <= 3.
	var in_degree: Dictionary = {}
	for n in all_nodes:
		for next_id in n.next_ids:
			in_degree[next_id] = int(in_degree.get(next_id, 0)) + 1
	for id in in_degree:
		if int(in_degree[id]) > 3:
			violations.append("INV2: node %s in-degree %d > 3" % [id, in_degree[id]])
	for i in range(graph.rows.size() - 1):
		if _has_crossing_edges(graph.rows[i], by_id):
			violations.append("INV2: crossing edges leaving row %d" % (i + 1))

	# INV3 — >=60% of free (non-mandatory-single) rows have >=2 real choices.
	var free_rows_total := 0
	var free_rows_with_choice := 0
	for row in graph.rows:
		if row.is_empty():
			continue
		var is_mandatory_single: bool = row.size() == 1 and ((row[0] as RunMapNode).row == 1 or graph.boss_rows.has((row[0] as RunMapNode).row))
		if is_mandatory_single:
			continue
		free_rows_total += 1
		if row.size() >= 2:
			free_rows_with_choice += 1
	if free_rows_total > 0 and float(free_rows_with_choice) / float(free_rows_total) < 0.60:
		violations.append("INV3: only %d/%d free rows have >=2 choices (<60%%)" % [free_rows_with_choice, free_rows_total])

	# INV4 — >= K_MIN distinct start->final-boss paths (DP path count, saturating).
	var path_count := _count_paths_dp(graph, graph.start_node_id)
	var final_boss_row: int = graph.boss_rows[graph.boss_rows.size() - 1]
	var total_final_paths := 0
	for bn in graph.get_row(final_boss_row):
		total_final_paths += int(path_count.get((bn as RunMapNode).id, 0))
	if total_final_paths < K_MIN:
		violations.append("INV4: only %d distinct start->final-boss paths (< K_MIN=%d)" % [total_final_paths, K_MIN])

	# INV5 — every non-boss row has >=1 battle/elite node.
	for row in graph.rows:
		if row.is_empty():
			continue
		var row_num: int = (row[0] as RunMapNode).row
		if graph.boss_rows.has(row_num):
			continue
		var has_combat := false
		for n in row:
			if n.node_type == "battle" or n.node_type == "elite":
				has_combat = true
				break
		if not has_combat:
			violations.append("INV5: row %d has no battle/elite node" % row_num)

	# INV6 — designated elite rows have >=1 elite node.
	for elite_row in graph.elite_rows:
		var has_elite := false
		for n in graph.get_row(elite_row):
			if (n as RunMapNode).node_type == "elite":
				has_elite = true
				break
		if not has_elite:
			violations.append("INV6: designated elite row %d has no elite node" % elite_row)

	# INV7 — no shop before shop_min_row; no elite before elite_min_row.
	var shop_min_row: int = cfg["shop_min_row"]
	var elite_min_row: int = cfg["elite_min_row"]
	for n in all_nodes:
		if n.node_type == "shop" and n.row < shop_min_row:
			violations.append("INV7: shop node %s at row %d before shop_min_row %d" % [n.id, n.row, shop_min_row])
		if n.node_type == "elite" and n.row < elite_min_row:
			violations.append("INV7: elite node %s at row %d before elite_min_row %d" % [n.id, n.row, elite_min_row])

	# INV8a — sufficiency check: every window of 3 consecutive rows contains >=1 row where
	# EVERY node is battle/elite/boss. Since our rows array has no gaps (every row_num 1..
	# total_rows has >=1 node by construction), array-adjacency == row-number-adjacency, so
	# this directly implies no path can see 3 consecutive non-combat nodes.
	for i in range(graph.rows.size() - 2):
		var r0: Array = graph.rows[i]
		var r1: Array = graph.rows[i + 1]
		var r2: Array = graph.rows[i + 2]
		if not (_row_all_combat(r0) or _row_all_combat(r1) or _row_all_combat(r2)):
			var row0_num: int = (r0[0] as RunMapNode).row if not r0.is_empty() else -1
			var row2_num: int = (r2[0] as RunMapNode).row if not r2.is_empty() else -1
			violations.append("INV8: 3 consecutive rows %d-%d without a guaranteed all-combat row" % [row0_num, row2_num])
	# INV8b — no 2 consecutive rows both containing a shop node (stronger than, and
	# therefore sufficient for, "no 2 consecutive shop nodes on any single path").
	for i in range(graph.rows.size() - 1):
		if _row_has_shop(graph.rows[i]) and _row_has_shop(graph.rows[i + 1]):
			violations.append("INV8: consecutive shop rows %d and %d" % [i + 1, i + 2])

	# INV9 — the row immediately before each boss row converges 100% onto that boss node.
	for boss_row in graph.boss_rows:
		var boss_nodes := graph.get_row(boss_row)
		if boss_nodes.size() != 1:
			violations.append("INV9: boss row %d does not have exactly 1 node" % boss_row)
			continue
		var boss_id: String = (boss_nodes[0] as RunMapNode).id
		for n in graph.get_row(boss_row - 1):
			var rn: RunMapNode = n
			if rn.next_ids.size() != 1 or rn.next_ids[0] != boss_id:
				violations.append("INV9: node %s before boss row %d does not converge 100%% onto %s" % [rn.id, boss_row, boss_id])

	# INV10 — ascension>=9 maps to an unavoidable (every-column) forced elite row.
	if ascension >= 9:
		var found_unavoidable := false
		for elite_row in graph.elite_rows:
			var nodes := graph.get_row(elite_row)
			if not nodes.is_empty() and _row_all_combat_type(nodes, "elite"):
				found_unavoidable = true
				break
		if not found_unavoidable:
			violations.append("INV10: ascension>=9 has no row where every node is forced elite")

	return violations


static func _bfs_forward(by_id: Dictionary, start_id: String) -> Dictionary:
	var visited: Dictionary = {}
	if not by_id.has(start_id):
		return visited
	var queue: Array = [start_id]
	visited[start_id] = true
	while not queue.is_empty():
		var cur: String = queue.pop_front()
		var n: RunMapNode = by_id[cur]
		for next_id in n.next_ids:
			if not visited.has(next_id):
				visited[next_id] = true
				queue.append(next_id)
	return visited


static func _has_crossing_edges(row_from: Array, by_id: Dictionary) -> bool:
	var edges: Array = []   # [{a:int,b:int}]
	for n in row_from:
		var rn: RunMapNode = n
		for next_id in rn.next_ids:
			if by_id.has(next_id):
				var b: RunMapNode = by_id[next_id]
				edges.append({"a": rn.col, "b": b.col})
	for i in range(edges.size()):
		for j in range(edges.size()):
			if int(edges[i]["a"]) < int(edges[j]["a"]) and int(edges[i]["b"]) > int(edges[j]["b"]):
				return true
	return false


const PATH_COUNT_CAP := 1000000

static func _count_paths_dp(graph: RunMapGraph, start_id: String) -> Dictionary:
	var counts: Dictionary = {start_id: 1}
	for row in graph.rows:
		for n in row:
			var rn: RunMapNode = n
			var c: int = int(counts.get(rn.id, 0))
			if c == 0:
				continue
			for next_id in rn.next_ids:
				var added: int = int(counts.get(next_id, 0)) + c
				counts[next_id] = min(added, PATH_COUNT_CAP)
	return counts


static func _row_all_combat(row: Array) -> bool:
	if row.is_empty():
		return false
	for n in row:
		var t: String = (n as RunMapNode).node_type
		if not (t == "battle" or t == "elite" or t == "boss"):
			return false
	return true


static func _row_all_combat_type(row: Array, node_type: String) -> bool:
	for n in row:
		if (n as RunMapNode).node_type != node_type:
			return false
	return true


static func _row_has_shop(row: Array) -> bool:
	for n in row:
		if (n as RunMapNode).node_type == "shop":
			return true
	return false
