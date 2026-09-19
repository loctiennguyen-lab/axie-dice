class_name RunMapGraph
extends RefCounted
## The full branching RunMap for one run (architecture plan §7). Built once by
## RunMapGenerator.generate() at RunState.start_new_run() time, then stored as a plain
## Dictionary in RunState.map_graph via to_data()/from_data() — never held as a live object
## across the RunState/scene boundary, consistent with the "hand off by DATA, not by live
## object" rule the rest of the port follows (architecture plan §4).

var rows: Array = []              ## Array of Array[RunMapNode], index i == row (i+1).
var boss_rows: Array[int] = []    ## 1-indexed rows that are mandatory single boss nodes.
                                   ## Plural: short/full mode both have 3-4 boss rows, not 1
                                   ## (architecture plan §7's whole reason for existing).
var elite_rows: Array[int] = []   ## 1-indexed rows guaranteed to contain >=1 elite node.
var start_node_id: String = ""


func get_row(row_num: int) -> Array:
	var idx := row_num - 1
	if idx < 0 or idx >= rows.size():
		return []
	return rows[idx]


func find_node(node_id: String) -> RunMapNode:
	for row in rows:
		for n in row:
			if (n as RunMapNode).id == node_id:
				return n
	return null


func to_data() -> Dictionary:
	var rows_data: Array = []
	for row in rows:
		var row_data: Array = []
		for n in row:
			row_data.append((n as RunMapNode).to_data())
		rows_data.append(row_data)
	return {
		"rows": rows_data,
		"boss_rows": boss_rows.duplicate(),
		"elite_rows": elite_rows.duplicate(),
		"start_node_id": start_node_id,
	}


static func from_data(d: Dictionary) -> RunMapGraph:
	var g := RunMapGraph.new()
	g.rows = []
	for row_data in (d.get("rows", []) as Array):
		var row: Array[RunMapNode] = []
		for node_data in (row_data as Array):
			row.append(RunMapNode.from_data(node_data as Dictionary))
		g.rows.append(row)
	g.boss_rows.assign(d.get("boss_rows", []))
	g.elite_rows.assign(d.get("elite_rows", []))
	g.start_node_id = String(d.get("start_node_id", ""))
	return g
