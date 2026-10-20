class_name RunMapNode
extends RefCounted
## A single node in the branching RunMap graph (architecture plan §7,
## design/gdd/godot-port-rule-spec.md §1/§9). Deliberately NOT a Resource: this is
## runtime/save-able state (`visited`/`locked` mutate as the player progresses through a
## run), not static content — see architecture plan §6 "Luật cứng cho MỌI data model dạng
## Resource: Resource chỉ chứa dữ liệu TĨNH, CHỈ-ĐỌC". Mirrors the `to_data()`/`from_data()`
## style of scripts/data_models/unit.gd so RunMapGraph can round-trip through
## RunState.map_graph (a plain Dictionary field) exactly like CombatEngine round-trips.

var id: String = ""
var row: int = 0                    ## 1-indexed row number (matches the rule-spec-style
                                     ## "step" numbering the boss/elite row lists use).
var col: int = 0                    ## Horizontal position hint within the row, 0-indexed.
                                     ## Not guaranteed contiguous (e.g. columns 0 and 2 can
                                     ## exist with no column 1) — only used for left-to-right
                                     ## ordering when rendering, never for graph logic.
var node_type: String = ""          ## "battle" | "elite" | "event" | "shop" | "treasure" | "boss"
var next_ids: Array[String] = []    ## Outgoing edges — ids of nodes in the next row this
                                     ## node connects to. Empty only for the final boss node.
var reward_kind: String = ""        ## battle/elite only: "level"|"hp"|"face"|"shard" (depth v3 7.1). A hint of which card is
                                     ## sure to be offered, not a fixed card. Set after the graph by RunMapGenerator.assign_extras.
var affix: String = ""              ## elite only: Elite affix id (group A), "" when none
var affix2: String = ""             ## elite only: second affix (group B), only after boss 1
var visited: bool = false
var locked: bool = false


func to_data() -> Dictionary:
	return {
		"id": id, "row": row, "col": col, "node_type": node_type,
		"next_ids": next_ids.duplicate(), "visited": visited, "locked": locked,
		"reward_kind": reward_kind, "affix": affix, "affix2": affix2,
	}


static func from_data(d: Dictionary) -> RunMapNode:
	var n := RunMapNode.new()
	n.id = String(d.get("id", ""))
	n.row = int(d.get("row", 0))
	n.col = int(d.get("col", 0))
	n.node_type = String(d.get("node_type", ""))
	n.next_ids.assign(d.get("next_ids", []))
	n.visited = bool(d.get("visited", false))
	n.locked = bool(d.get("locked", false))
	n.reward_kind = String(d.get("reward_kind", ""))
	n.affix = String(d.get("affix", ""))
	n.affix2 = String(d.get("affix2", ""))
	return n
