class_name RunMapController
extends Node2D
## RunMap.tscn root, plus the four node screens the map opens.
##
## SOURCE OF TRUTH: `docs/design-handoff-v2/mockups-v2/run-flow-v2.html`. That one file holds
## six screens - MAP, REWARD, SHOP, EVENT, TREASURE, RESULT - and five of them are built here
## (RESULT is scenes/result/ResultView.gd). Every width, gap, radius, border, shelf, font size
## and colour below is read out of that markup, not out of a prose restatement of it. See
## godot/CLAUDE.md, first section, for why that distinction is the whole point.
##
## LAYOUT: the board uses the mockup's own lanes (x 780/1150/1520) and 118px row pitch as a
## REFERENCE FRAME, windowed to the 7 rows around the player (3 behind, current, 3 ahead) - see
## _ROWS_BEHIND/_ROWS_AHEAD/_MOCK_HERE_Y below - and fits that frame into the live graph region
## (MAP-13). `project.godot` runs `window/stretch/aspect="expand"`, so the canvas keeps its
## 1920 width and grows vertically; the fit is what stops the graph from pinning itself to the
## top 1080 and leaving a void underneath. There is no Camera2D: nothing pans or zooms,
## deliberately - no drag/scroll input is asked for anywhere.
##
## RunState.enter_node()/after_node() and their combat/event/shop/treasure branching are
## UNCHANGED - this file only ever reads RunState fields and calls those existing methods.
## The four node screens at the bottom of this file were, until this pass, one shared 620px
## centred modal over a dimmed map; the mockup draws each as its own full-canvas screen with
## its own painted plate, and that is what they are now.
##
## REBUILD STRATEGY: the node/edge/rail/header layers are fully rebuilt on every _refresh()
## call rather than patched in place. The window slides every time current_row changes, so most
## nodes would need to move AND retint on every refresh anyway; a full rebuild is simpler and
## correct, at the cost of a per-node crossfade reveal (replaced by a flat fade-in of the whole
## map layer - see _refresh()). A deliberate deviation, not an oversight.
##
## CLASSIFICATION LOGIC (_reachable_now_ids/_current_row/_node_tier/_is_fogged) is pure
## graph-row math, has nothing to do with screen-space layout, and tests/t_run_map_fog.gd pins
## it directly by name via .call(). Do not change its behaviour here; only the RENDERING built
## on top of it has ever changed.

## The node glyph, by node_type (RunMapNode.gd: "battle"|"elite"|"event"|"shop"|"treasure"|
## "boss"). Named exactly as `run-flow-v2.html` names it - `assets/node/${t === "shop" ?
## "merchant" : t}.png` - and translated by MockupAssets rather than by a hand-written res://
## string, which is the rule for anything the mockups name (godot/CLAUDE.md, "Asset paths").
func _node_icon(node_type: String) -> Texture2D:
	return UI3.icon("node_%s" % ("shop" if node_type == "shop" else node_type))


## UI-03 (A4 Blend) run map, spec screens/03-run-map. Built from UI3Theme / UI3 only.
const _ROWS_BEHIND := 3           ## rows shown behind the current one
const _ROWS_AHEAD := 3            ## rows shown ahead of it (the band slides at either end of the run)

const _MAP_W := 1024.0
const _MAP_H := 640.0
const _MAP_PAD_X := 96.0
const _LANE_Y: Array[float] = [150.0, 300.0, 450.0]
const _NODE_SIZE := {"battle": 56.0, "event": 56.0, "shop": 56.0, "treasure": 56.0, "elite": 72.0, "boss": 96.0}
const _NODE_ICON_PX := {"battle": 32.0, "event": 32.0, "shop": 32.0, "treasure": 32.0, "elite": 40.0, "boss": 56.0}
const _PLATE_LEFT_W := 384.0
const _PLATE_RIGHT_W := 416.0
const _SCREEN_MARGIN := 24.0
const _RELIC_ROW_H := 44.0

@onready var _root: Control = %Root
var _content: Control = null
var _core_panel: CorePanel = null   ## the left-plate Cores strip (rebuilt with the plate); source of the Anchor tile rect
var _graph: RunMapGraph = null
var _edges_canvas: _EdgeCanvas = null
var _nodes_layer: Control = null
var _map_layer: Control = null
var _board: Control = null
var _left_root: Control = null
var _detail_root: Control = null
var _node_visuals: Dictionary = {}   # node_id -> {"node": RunMapNode, "root": Button, "caption": Label|null}
var _selected_id := ""
## Mouse/touch "second press travels": the node last pressed and when (ms). Cleared whenever the
## selection moves to another node.
var _pressed_once_id := ""
var _pressed_once_ms := 0
const _DOUBLE_PRESS_MS := 400
## Tests: stop _on_node_pressed before it asks RunState to enter the node.
var no_travel := false
signal travel_requested(node_id: String)
var _offers: RunMapOffers = RunMapOffers.new(self)
var _hud: RunMapHud = RunMapHud.new(self)
var _combo: ComboBanner = ComboBanner.new(self)
var _swap: RunMapSlotSwap = RunMapSlotSwap.new(self)
var _shop: RunMapShop = RunMapShop.new(self)
var _event: RunMapEvent = RunMapEvent.new(self)
var _treasure: RunMapTreasure = RunMapTreasure.new(self)
var _travel_btn: Button = null


## Lines of the map, drawn with draw_line (spec: "edges with draw_line").
class _EdgeCanvas extends Control:
	var segs: Array = []   # {"a": Vector2, "b": Vector2, "color": Color, "width": float, "dashed": bool}

	func _draw() -> void:
		for s in segs:
			if bool(s["dashed"]):
				draw_dashed_line(s["a"], s["b"], s["color"], float(s["width"]), 10.0)
			else:
				draw_line(s["a"], s["b"], s["color"], float(s["width"]), true)


const _BG_PATH := "res://assets/backgrounds/origins/class/reptile.jpg"
const _BG_SCRIM_ALPHA := 0.6


func _ready() -> void:
	EventBus.node_entered.connect(_on_node_entered)
	AnchorAdapter.listen("anchor_awakened", _on_anchor_awakened)
	_graph = RunMapGraph.from_data(RunState.map_graph)
	_root.theme = UI3Theme.get_theme()

	var bg := ColorRect.new()
	bg.name = "PlateHost"   # the screen backdrop (neutral-1), what t_ui_laws L0 looks for
	bg.color = UI3Theme.color("bg")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bg)

	# Painted backdrop (purple-toned, Liam b931): cover-fit, never stretched, then a flat
	# neutral-1 scrim so nodes, dashed lines and plates stay readable. No blur, no gradient.
	var art := TextureRect.new()
	art.name = "Background"
	art.texture = load(_BG_PATH) as Texture2D
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(art)
	var dim := ColorRect.new()
	dim.name = "Scrim"
	var dim_c := UI3Theme.color("bg")
	dim_c.a = _BG_SCRIM_ALPHA
	dim.color = dim_c
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(dim)

	_board = Control.new()
	_board.name = "Content"
	_board.set_anchors_preset(Control.PRESET_FULL_RECT)
	_board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_board)

	# Map: 1024x640, centred.
	_map_layer = Control.new()
	_map_layer.name = "MapLayer"
	_map_layer.set_anchors_preset(Control.PRESET_CENTER)
	_map_layer.offset_left = -_MAP_W * 0.5
	_map_layer.offset_right = _MAP_W * 0.5
	_map_layer.offset_top = -_MAP_H * 0.5
	_map_layer.offset_bottom = _MAP_H * 0.5
	_map_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_board.add_child(_map_layer)

	_edges_canvas = _EdgeCanvas.new()
	_edges_canvas.name = "Edges"
	_edges_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_edges_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_layer.add_child(_edges_canvas)

	_nodes_layer = Control.new()
	_nodes_layer.name = "Nodes"
	_nodes_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_nodes_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_layer.add_child(_nodes_layer)

	_left_root = Control.new()
	_left_root.name = "Rail"
	_left_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_left_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_board.add_child(_left_root)

	_detail_root = Control.new()
	_detail_root.name = "Detail"
	_detail_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_detail_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_board.add_child(_detail_root)

	var hint := UI3.key_hint(tr("Arrows pick · Enter or double-click travels · Esc menu"))
	hint.name = "KeyHint"
	hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hint.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hint.offset_right = -_SCREEN_MARGIN
	hint.offset_bottom = -_SCREEN_MARGIN
	_board.add_child(hint)

	_refresh(false)
	_build_overlay_ui()
	_maybe_show_pending_reward()


## Single "read RunState, redraw" entry point. Everything is rebuilt on each call (a handful of nodes).
func _refresh(animate: bool = true) -> void:
	var current_row := _current_row()
	var reachable := _reachable_now_ids()
	if not reachable.has(_selected_id):
		_selected_id = reachable[0] if not reachable.is_empty() else ""
	_rebuild_map(current_row, reachable)
	_rebuild_left()
	_rebuild_detail()
	_preload_next_arenas(reachable)

	if animate and is_inside_tree() and not MetaState.reduce_flash:
		_map_layer.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(_map_layer, "modulate:a", 1.0, minf(UI3Theme.motion_sec("base"), UI3Motion.REDUCED_MAX_SEC) if UI3Motion.reduced() else UI3Theme.motion_sec("base"))
	else:
		_map_layer.modulate.a = 1.0
	if _overlay_root == null or not _overlay_root.visible:
		_focus_selected.call_deferred()


## Starts loading the arena v2 diorama for the biome of the fights the player can reach next
## (also their children when the reachable node is an event/shop), and the boss biome once the
## boss is 3 rows or closer. At most ArenaV2Diorama.MAX_PRELOAD biomes, nearest first.
func _preload_next_arenas(reachable: Array) -> void:
	if _graph == null or _graph.rows.is_empty():
		return
	var total := _graph.rows.size()
	var biomes: Array[String] = []
	var queue: Array = []
	for id in reachable:
		queue.append(String(id))
	var depth := 0
	while not queue.is_empty() and depth < 2 and biomes.size() < ArenaV2Diorama.MAX_PRELOAD:
		var nxt: Array = []
		for id in queue:
			var n := _graph.find_node(String(id))
			if n == null:
				continue
			if n.node_type == "battle" or n.node_type == "elite" or n.node_type == "boss":
				var b := CombatArena3D.biome_for(n.row, n.node_type == "boss", total)
				if b != "" and not biomes.has(b):
					biomes.append(b)
			elif depth == 0:
				nxt.append_array(n.next_ids)
		queue = nxt
		depth += 1
	if not _graph.boss_rows.is_empty() and _current_row() >= int(_graph.boss_rows[0]) - 3:
		var bb := CombatArena3D.biome_for(int(_graph.boss_rows[0]), true, total)
		if bb != "":
			biomes.erase(bb)
			biomes.push_front(bb)   # near the boss its biome beats a far fight's
	ArenaV2Diorama.preload_biomes(biomes)


func _focus_selected() -> void:
	var entry: Dictionary = _node_visuals.get(_selected_id, {})
	var btn: Button = entry.get("root")
	if btn != null and is_instance_valid(btn) and btn.is_inside_tree() and btn.focus_mode != Control.FOCUS_NONE:
		btn.grab_focus()


func _current_row() -> int:
	if RunState.current_node_id == "":
		return 0
	var cur := _graph.find_node(RunState.current_node_id)
	return cur.row if cur != null else 0


## The row the player can act on RIGHT NOW — current.next_ids, or the graph's single start node
## if nothing has been entered yet (identical semantics to v1's old _current_choices()).
func _reachable_now_ids() -> Array[String]:
	var out: Array[String] = []
	if _graph == null:
		return out
	if RunState.current_node_id == "":
		if _graph.start_node_id != "":
			out.append(_graph.start_node_id)
		return out
	var current := _graph.find_node(RunState.current_node_id)
	if current == null:
		return out
	out.assign(current.next_ids)
	return out


## A node is fogged only if it is 2+ rows beyond current_node_id AND not visited/current/
## reachable-now. Unchanged from v1 — tests/t_run_map_fog.gd pins this by name.
func _is_fogged(node: RunMapNode, current_row: int, reachable_ids: Array[String]) -> bool:
	if node.visited or node.id == RunState.current_node_id or reachable_ids.has(node.id):
		return false
	return node.row - current_row >= 2


## A9+: true while the unavoidable all-elite row (INV10) is still ahead of the player.
## No count, no position.
func _forced_elite_row_ahead(current_row: int) -> bool:
	if _graph == null or RunState.ascension < 9:
		return false
	for r in _graph.elite_rows:
		if r <= current_row:
			continue
		var nodes := _graph.get_row(r)
		if nodes.is_empty():
			continue
		var all_elite := true
		for raw_node in nodes:
			if (raw_node as RunMapNode).node_type != "elite":
				all_elite = false
				break
		if all_elite:
			return true
	return false


func _node_tier(node: RunMapNode, current_row: int, reachable_ids: Array[String]) -> String:
	if node.id == RunState.current_node_id:
		return "current"
	if reachable_ids.has(node.id):
		return "reachable"
	if _is_fogged(node, current_row, reachable_ids):
		return "fog"
	return "dim"   # visited, or an unchosen/inert node not yet 2+ rows out


## Maps the fine-grained classification tier to one of the four v2 VISUAL buckets (handoff:
## "token 122 here / 106 open / 94 fog / 80 done"). "dim" (visited OR an inert unchosen
## sibling) always renders at the "done" size — which of the two tones it gets (parchment
## "visited" vs. dark "skip") is decided separately from `node.visited`, not from the tier.
func _visual_bucket(tier: String) -> String:
	match tier:
		"current": return "here"
		"reachable": return "open"
		"fog": return "fog"
		_: return "done"


func _tone_key_for_type(node_type: String) -> String:
	return "merchant" if node_type == "shop" else node_type


## The band of rows on screen, as offsets from the current row: (lowest_rel, highest_rel).
##
## It stays `_ROWS_BEHIND + _ROWS_AHEAD + 1` slots wide for as long as the map has that many
## rows. When the player stands near either end of the run the band SLIDES rather than
## shrinking, which is the whole fix: the build clamped it, so at row 2 the two slots BELOW the
## player had no rows to put in them and a seven-slot frame drew five, bunched into the top of
## the screen with a third of the canvas blank underneath (bug report 2026-09-21, "The Path
## đang mất thẩm mỹ"). Sliding keeps the frame full, keeps the row pitch constant as the player
## walks, and spends the freed slots on the road AHEAD — the half they can actually act on.
##
## No information leaks by showing more: the extra rows are fogged by _is_fogged(), which keys
## off `current_row` and not off this window.
func _row_window(current_row: int) -> Vector2i:
	var last_row: int = _graph.rows.size() if _graph != null else 0
	if last_row <= 0:
		return Vector2i(-_ROWS_BEHIND, _ROWS_AHEAD)
	var lo := current_row - _ROWS_BEHIND
	var hi := current_row + _ROWS_AHEAD
	if lo < 1:
		hi += 1 - lo      # slide the whole band up; do not just clip the bottom off it
		lo = 1
	if hi > last_row:
		lo = maxi(1, lo - (hi - last_row))
		hi = last_row
	return Vector2i(lo - current_row, hi - current_row)


func _in_window(node: RunMapNode, current_row: int) -> bool:
	var window := _row_window(current_row)
	var rel := node.row - current_row
	return rel >= window.x and rel <= window.y


## The lane a node is drawn in. A single-node row (boss / segment) sits in the middle lane.
static func lane_index(col: int, row_size: int) -> int:
	if row_size == 1:
		return 1
	return clampi(col, 0, 2)


## Centre of a node inside the 1024x640 map: rows run left to right, lanes top to bottom.
func _node_pos(node: RunMapNode, current_row: int) -> Vector2:
	var row_size := 0
	var idx := node.row - 1
	if _graph != null and idx >= 0 and idx < _graph.rows.size():
		row_size = (_graph.rows[idx] as Array).size()
	var window := _row_window(current_row)
	var slots := maxi(window.y - window.x, 1)
	var pitch := (_MAP_W - 2.0 * _MAP_PAD_X) / float(slots)
	var rel := node.row - current_row
	return Vector2(_MAP_PAD_X + float(rel - window.x) * pitch, _LANE_Y[lane_index(node.col, row_size)])


## Five rarities, five different tokens: common grey, uncommon green, rare blue, epic purple, legendary amber.
## Colours come from the handoff tokens (rarity_common grey, rarity_rare green, rarity_epic cyan,
## rarity_legendary amber, UI-05 rarity_uncommon blue). Index = RelicDef.rarity (0 Common .. 4 Legendary).
const _RARITY_TOKENS := ["rarity_common", "rarity_uncommon", "rarity_rare", "rarity_epic", "rarity_legendary", "rarity_legendary"]


func _rarity_color(rar: int) -> Color:
	return UI3Theme.color(_RARITY_TOKENS[clampi(rar, 0, _RARITY_TOKENS.size() - 1)])


## A relic offer takes its rarity from the relic definition, so the reward card and the relic
## plate can never disagree.
func _reward_rarity(r: Dictionary) -> int:
	if String(r.get("t", "")) == "relic":
		var def = RelicRegistry.get_def(String(r.get("key", "")))
		if def != null:
			return int(def.rarity)
	return int(r.get("rar", 0))


## Depth v3 Core tiers (RelicDef.rarity 0/1/2 -> Moss / Amber / Crystal) and axes. Colour token per tier;
## the tier WORD always sits beside it. Spec: design/ux/depth-v3/core-offer.md
const CORE_TIER_HINT := "Core tier: Moss → Amber → Crystal (strongest)"
const _CORE_TIER_NAME := ["Moss", "Amber", "Crystal"]
const _CORE_TIER_TOKEN := ["rarity_rare", "rarity_legendary", "rarity_epic"]
const _CORE_AXIS_NAME := {"stat": "Stat", "dice": "Dice faces", "pos": "Position", "mana": "Mana",
	"quest": "Quest", "rule": "Rule change", "run_rule": "Run rule"}


## S3-11: the cost of each Run rule on its own PRICE line (UI-side wording; the rule text stays in the data and is shown as-is).
const _RULE_PRICE := {
	"rule_starfall": "+15% enemy HP all run", "rule_heavy_finish": "Enemies deal 10% more damage",
	"rule_pilot_light": "Turn 1 damage is 0; normal and elite enemies +10% HP", "rule_cheap_mana": "No free reroll; max 5 rerolls a turn",
	"rule_tundra": "No free reroll (rerolls cost 2 Mana)", "rule_set_is_king": "A die in no SET gets -2; no free reroll",
	"rule_hard_shell": "Every enemy has Armor 2", "rule_dry_steppe": "Leftover Mana is lost at end of turn",
	"rule_balance": "From the 3rd damage face each turn, damage faces deal 2 less", "rule_old_forest": "Enemies have +30% HP too",
	"rule_pack_alpha": "The biggest enemy is a Pack Alpha (+25% HP) that shields the others",
	"rule_upside_down": "Enemy attacks hit your back row first",
	"rule_wasteland": "Only 3 Core picks", "rule_high_stakes": "Paid rerolls can Crack dice (20% each)",
	"rule_quick_beat": "Boss Strike turns hit 20% harder", "rule_crow": "An Axie falling drops that pick one tier"}
const _RULE_TINTS := ["house_volley", "house_gambler", "house_mana_mine", "house_kin", "house_embers", "house_big_hand"]



func _is_core_card(r: Dictionary) -> bool:
	return bool(r.get("core", false))


func _core_offer_active() -> bool:
	for r in RunState.pending_rewards:
		if _is_core_card(r):
			return true
	return false


func _rarity_name(rar: int) -> String:
	var names := [tr("Common"), tr("Uncommon"), tr("Rare"), tr("Epic"), tr("Legendary"), tr("Mythic")]
	return names[clampi(rar, 0, names.size() - 1)]


func _type_name(node_type: String) -> String:
	match node_type:
		"battle": return tr("Battle")
		"elite": return tr("Elite")
		"event": return tr("Event")
		"shop": return tr("Shop")
		"treasure": return tr("Treasure")
		"boss": return tr("Boss")
	return node_type.capitalize()


func _boss_name(node: RunMapNode) -> String:
	var key: String = RunState._boss_key_for_node(node.id)
	return String(ContentDB.bosses.get(key, {}).get("n", tr("Boss")))


func _is_final_boss(node: RunMapNode) -> bool:
	return _graph != null and node.node_type == "boss" and not _graph.boss_rows.is_empty() \
		and node.row == int(_graph.boss_rows[_graph.boss_rows.size() - 1])


func _rebuild_map(current_row: int, reachable: Array) -> void:
	for c in _nodes_layer.get_children():
		_nodes_layer.remove_child(c)
		c.queue_free()
	_node_visuals.clear()
	_edges_canvas.segs.clear()
	if _graph == null:
		_edges_canvas.queue_redraw()
		return

	var live_edge := UI3Theme.color("accent")
	var past_edge := UI3Theme.color("disabled_border")
	var inert_edge := UI3Theme.color("disabled")
	for row in _graph.rows:
		for raw_node in row:
			var a: RunMapNode = raw_node
			if not _in_window(a, current_row):
				continue
			for next_id in a.next_ids:
				var b := _graph.find_node(next_id)
				if b == null or not _in_window(b, current_row):
					continue
				var seg := {"a": _node_pos(a, current_row), "b": _node_pos(b, current_row),
					"color": inert_edge, "width": 3.0, "dashed": true}
				if a.id == RunState.current_node_id and reachable.has(b.id):
					seg["color"] = live_edge
					seg["width"] = 6.0
					seg["dashed"] = false
				elif a.visited and b.visited:
					seg["color"] = past_edge
					seg["width"] = 4.0
					seg["dashed"] = false
				_edges_canvas.segs.append(seg)
	_edges_canvas.queue_redraw()

	for row in _graph.rows:
		for raw_node in row:
			var n: RunMapNode = raw_node
			if _in_window(n, current_row):
				_build_token(n, current_row, reachable)
	for id in reachable:
		var entry: Dictionary = _node_visuals.get(id, {})
		var btn: Button = entry.get("root")
		if btn != null:
			btn.focus_entered.connect(_select_node.bind(id))


func _build_token(node: RunMapNode, current_row: int, reachable: Array) -> void:
	var tier := _node_tier(node, current_row, reachable)
	var is_reach := tier == "reachable"
	var is_here := tier == "current"
	var fogged := tier == "fog"
	var passed := node.visited and not is_here
	var locked := fogged or (tier == "dim" and not node.visited) or passed
	# Lock glyph = a future node you cannot reach. Anything at or behind the player's row (taken or
	# not) keeps its own type icon, dimmed.
	var show_lock := fogged or (tier == "dim" and not node.visited and node.row > current_row)
	var size: float = _NODE_SIZE.get(node.node_type, 56.0)
	var selected := node.id == _selected_id
	var centre := _node_pos(node, current_row)

	var btn := Button.new()
	btn.name = "Node_%s" % node.id
	btn.custom_minimum_size = Vector2(size, size)
	btn.size = Vector2(size, size)
	btn.position = centre - Vector2(size, size) * 0.5
	btn.pivot_offset = Vector2(size, size) * 0.5
	btn.focus_mode = Control.FOCUS_ALL if is_reach else Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.tooltip_text = "" if fogged else _type_name(node.node_type)
	var radius := int(size * 0.5)
	var fill := UI3Theme.color("panel_raised") if is_reach else UI3Theme.color("panel")
	var border := UI3Theme.color("btn_secondary")
	var bw := 2
	if is_reach:
		border = UI3Theme.color("accent")
		bw = 4
	if is_here:
		fill = UI3Theme.color("accent")
		border = UI3Theme.color("selected_outline")
		bw = 4
	if node.node_type == "boss" and not locked:
		border = UI3Theme.color("danger_text")
		bw = 4
	if selected:
		border = UI3Theme.color("selected_outline")
		bw = 4
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(radius)
	var hover := sb.duplicate() as StyleBoxFlat
	hover.bg_color = UI3Theme.color("btn_secondary") if not is_here else fill
	for state_key in ["normal", "pressed", "disabled"]:
		btn.add_theme_stylebox_override(state_key, sb)
	btn.add_theme_stylebox_override("hover", hover)
	var ring := StyleBoxFlat.new()
	ring.bg_color = Color(0, 0, 0, 0)
	ring.border_color = UI3Theme.color("focus_ring")
	ring.set_border_width_all(UI3Theme.stroke("focus"))
	ring.set_corner_radius_all(radius + 4)
	ring.set_expand_margin_all(float(UI3Theme.stroke("focus_offset")))
	btn.add_theme_stylebox_override("focus", ring)

	var icon_px: float = _NODE_ICON_PX.get(node.node_type, 32.0)
	var icon := TextureRect.new()
	icon.texture = UI3.icon("ui_lock" if show_lock else "node_%s" % node.node_type)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_anchors_preset(Control.PRESET_CENTER)
	icon.offset_left = -icon_px * 0.5
	icon.offset_right = icon_px * 0.5
	icon.offset_top = -icon_px * 0.5
	icon.offset_bottom = icon_px * 0.5
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(icon)
	if show_lock:
		# S4-4: a node not reached yet reads "unknown", not "locked".
		icon.visible = false
		var q := UI3.label("?", "LabelTitle")
		q.name = "UnknownMark"
		q.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		q.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(q)
	if node.reward_kind != "" and not show_lock:
		var rk := TextureRect.new()
		rk.name = "RewardKind"
		rk.texture = UI3.icon(String(_NODE_REWARD_ICON.get(node.reward_kind, "cur_shard")))
		rk.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rk.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rk.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		rk.offset_left = -22.0 - size * 0.02
		rk.offset_top = size * 0.02
		rk.offset_right = -size * 0.02
		rk.offset_bottom = 22.0 + size * 0.02
		rk.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(rk)
	if node.affix != "" and not fogged:
		btn.tooltip_text = "%s: %s" % [_affix_name(node.affix), CombatView.affix_tip(node.affix)]
	if passed:
		var done := TextureRect.new()
		done.name = "DoneMark"
		done.texture = UI3.cream_icon("ui_check")
		done.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		done.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		done.custom_minimum_size = Vector2(18, 18)
		done.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		done.offset_left = -18.0 - size * 0.04
		done.offset_top = -18.0 - size * 0.04
		done.offset_right = -size * 0.04
		done.offset_bottom = -size * 0.04
		done.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(done)

	var base := Vector2.ONE
	if node.node_type == "boss" and not locked:
		base = Vector2(1.25, 1.25)
	if selected:
		base *= 1.1
	btn.set_meta("base_scale", base)
	btn.scale = base
	if locked or passed:
		btn.modulate.a = 0.55
	var id := node.id
	btn.gui_input.connect(_on_token_input.bind(id))
	btn.mouse_entered.connect(_hover_token.bind(btn, true))
	btn.mouse_exited.connect(_hover_token.bind(btn, false))
	_nodes_layer.add_child(btn)
	btn.set_meta("rest_pos", btn.position)
	icon.set_meta("is_glyph", true)
	# UI-06 map-reward: the current node's glyph bobs, the boss helm breathes while the boss is reachable.
	if is_here:
		MapRewardFx.bob_glyph.call_deferred(icon)
	elif node.node_type == "boss" and is_reach:
		MapRewardFx.breathe.call_deferred(icon)

	var caption: Label = null
	# Passed nodes carry no caption (it collided with its neighbours at 1280); clicking one shows
	# "Already passed" in the detail plate.
	if not locked:
		var text := _boss_name(node) if node.node_type == "boss" else _type_name(node.node_type)
		if node.affix != "":
			text = "%s · %s" % [text, _affix_name(node.affix)]
		caption = UI3.label(text)
		caption.name = "Caption_%s" % node.id
		caption.custom_minimum_size = Vector2(136, 0)
		caption.size = Vector2(136, 26)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.clip_text = true
		caption.position = Vector2(centre.x - 68.0, centre.y + size * 0.5 * base.x + 8.0)
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if passed:
			caption.modulate.a = 0.4
		_nodes_layer.add_child(caption)
	_node_visuals[node.id] = {"node": node, "root": btn, "caption": caption}


const _NODE_REWARD_ICON := {"level": "face_buff", "hp": "face_heal", "face": "face_dmg", "shard": "cur_shard"}
const _NODE_REWARD_NAME := {"level": "Level up", "hp": "Max HP", "face": "Face rune", "shard": "Big shard"}


func _affix_name(id: String) -> String:
	return CombatView.affix_name(id)


func _hover_token(btn: Button, on: bool) -> void:
	if is_instance_valid(btn):
		var base: Vector2 = btn.get_meta("base_scale", Vector2.ONE)
		# UI-06 map-reward: lift y -6, scale 1.06 and a cream ring (the focus ring keeps its own look).
		MapRewardFx.hover_token(btn, on, btn.get_meta("rest_pos", btn.position), base)


func _on_token_input(ev: InputEvent, id: String) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		# First press selects; a second press on the same reachable node (or a double-click) travels.
		var now := Time.get_ticks_msec()
		var second := _pressed_once_id == id and now - _pressed_once_ms <= _DOUBLE_PRESS_MS
		if _reachable_now_ids().has(id) and (second or ev.double_click):
			_pressed_once_id = ""
			get_viewport().set_input_as_handled()
			_on_node_pressed(id)
			return
		_pressed_once_id = id
		_pressed_once_ms = now
		_select_node(id)
	elif ev.is_action_pressed("ui_accept") and not ev.is_echo():
		if _reachable_now_ids().has(id):
			if is_inside_tree():   # a handler above may have changed scene
				get_viewport().set_input_as_handled()
			_on_node_pressed(id)


## Picking a node only updates the detail plate; Travel (or Enter on a reachable node) enters it.
func _select_node(id: String) -> void:
	if id == _selected_id or not _node_visuals.has(id):
		return
	if id != _pressed_once_id:
		_pressed_once_id = ""
	_selected_id = id
	_reselect.call_deferred()


func _reselect() -> void:
	_rebuild_map(_current_row(), _reachable_now_ids())
	_rebuild_detail()
	_focus_selected()


func _on_node_pressed(id: String) -> void:
	if not _reachable_now_ids().has(id):
		return   # defensive — the button should already be disabled for any non-reachable node
	var entry: Dictionary = _node_visuals.get(id, {})
	var node: RunMapNode = entry.get("node")
	if node == null:
		return
	travel_requested.emit(id)
	if no_travel:
		return
	var res: Dictionary = await RunState.request_enter_node(id, node.node_type)
	if not bool(res["ok"]) and String(res["code"]) != "busy":
		NetNotice.show(self, String(res["code"]), _on_node_pressed.bind(id), "Could not open that node")


## In-run menu (L1 C3): Esc or the MENU button. The map's state lives in RunState, so saving and
## reloading RunMap.tscn on "Back to run" resumes exactly here.
## UI-03 14: the pause plate over the map. Settings still goes to the Settings screen (see open_settings_from_menu).
func open_run_menu() -> void:
	if _overlay_root != null and _overlay_root.find_child("RunPauseMenu", true, false) != null:
		return
	if _overlay_root == null:
		return
	_overlay_root.theme = UI3Theme.get_theme()
	_overlay_root.visible = true
	var menu := RunPauseMenu.new()
	menu.build({"floor": maxi(_current_row(), 0), "total": _graph.rows.size() if _graph != null else 0,
		"ascension": RunState.ascension, "shards": RunState.shards_this_run})
	_overlay_root.add_child(menu)
	var close := func() -> void:
		if is_instance_valid(menu):
			_overlay_root.remove_child(menu)
			menu.queue_free()
		if _overlay_root.get_child_count() == 0:
			_overlay_root.visible = false
	menu.resumed.connect(close)
	menu.settings_requested.connect(open_settings_from_menu)
	menu.save_quit_confirmed.connect(_on_save_and_quit_pressed)
	menu.abandon_confirmed.connect(func() -> void:
		SettingsView.abandon_current_run()
		LandNav.back_to_land())


func open_settings_from_menu() -> void:
	prepare_run_menu()
	get_tree().change_scene_to_file("res://scenes/settings/Settings.tscn")


func prepare_run_menu() -> void:
	RunState.save_run({})
	SettingsView.in_run = true
	SettingsView.return_scene = "res://scenes/run_map/RunMap.tscn"


func _unhandled_key_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo and ev.is_action_pressed(&"map_menu"):
		open_run_menu()
		if is_inside_tree():   # a handler above may have changed scene
			get_viewport().set_input_as_handled()


func _on_save_and_quit_pressed() -> void:
	RunState.save_run({})
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")


## -> RunMapHud._rebuild_left
func _rebuild_left() -> void:
	_hud._rebuild_left()


## -> RunMapHud._build_party_row
func _build_party_row(entry: Dictionary) -> Control:
	return _hud._build_party_row(entry)


## -> RunMapHud._build_relic_row
func _build_relic_row(relic_id: String) -> Control:
	return _hud._build_relic_row(relic_id)


## -> RunMapHud._node_info
func _node_info(node: RunMapNode) -> Dictionary:
	return _hud._node_info(node)


## -> RunMapHud._rebuild_detail
func _rebuild_detail() -> void:
	_hud._rebuild_detail()


func _spacer(h: float) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, h)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s


func _on_node_entered(node_type: String, node_id: String) -> void:
	match node_type:
		"battle", "elite":
			get_tree().change_scene_to_file("res://scenes/combat/Combat.tscn")
		"boss":
			_enter_boss_fight()
		"event":
			_on_event_node(node_id)
		"shop":
			_on_shop_node(node_id)
		"treasure":
			_on_treasure_node(node_id)


## Boss node: the full boss intro (always, no seen flag), then Combat. Purely presentational: the node is
## already entered in RunState, so nothing here calls a rule or draws a seed. Resume/Continue never comes
## through here (it loads Combat.tscn directly), so a resumed boss fight has no intro.
func _enter_boss_fight() -> void:
	var key := String(RunState.pending_combat.get("boss_key", ""))
	var intro := BossIntro.new()
	if key == "" or not intro.setup(key):
		intro.free()
		push_warning("BossIntro: no art for boss '%s', going straight to combat" % key)
		get_tree().change_scene_to_file("res://scenes/combat/Combat.tscn")
		return
	var layer := CanvasLayer.new()
	layer.name = "BossIntroLayer"
	layer.layer = 100
	add_child(layer)
	layer.add_child(intro)
	intro.finished.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/combat/Combat.tscn"))


## Finishes a node: closes the overlay, calls RunState.after_node(), then refreshes the map
## with its reveal animation. Shared by event/shop nodes AND (via _on_reward_chosen(), for
## both the post-combat and treasure reward overlays) the reward-pick path — CombatView.
## _finish() no longer calls after_node() itself for an ordinary win; it only changes scene,
## exactly matching src/engine.js's takeReward() calling afterNode() strictly AFTER the pick,
## never before it. This IS the path where the map's fade-in reveal is actually observable for
## the combat-return case too — a brand-new RunMapController instance rebuilds the window fresh
## from RunState.current_node_id, which after_node() already advanced before the scene change.
func _finish_node() -> void:
	_close_overlay()
	# The Run Rule pick can leave the run waiting for an Anchor (REWARD, no cards): do NOT advance the node, show the Anchor screen.
	if RunState.phase == RunState.RunPhase.REWARD and RunState.pending_rewards.is_empty() and AnchorAdapter.offer_open():
		_save_map_progress()
		_maybe_show_pending_reward()
		return
	RunState.after_node()
	_refresh(true)
	# AFTER after_node(), not before: that call is what advances power_level and the phase, and
	# a save taken ahead of it would resume the player onto a node they had already finished.
	_save_map_progress()
	# A pick can chain another offer (Run Rule -> first Core, bonus Core after an event/quest/shop/Dim Stone):
	# after_node() then leaves pending_rewards filled. The map must never sit there with an offer nobody sees.
	if RunState.phase == RunState.RunPhase.PACT or not RunState.pending_rewards.is_empty():
		_maybe_show_pending_reward()


# ===========================================================================
# REWARD / SHOP / EVENT / TREASURE - four FULL 1920x1080 screens.
#
# `run-flow-v2.html` draws each of these as its own screen: its own painted plate, its own
# radial scrim, and a layout that uses the whole canvas. They used to be one shared 620px-wide
# centred modal over a dimmed map, which is a different object entirely - a dialog rather than
# a place. Every number below is read off that mockup's markup.
#
# Built procedurally, same convention the graph/rail already use: the number of reward cards,
# shop items and event options varies per node, so a static scene tree cannot describe them.
#
# ONE host, rebuilt per screen. `_overlay_root` stays in the tree (hidden) for the scene's
# whole life; everything under it is created when a screen opens and REMOVED, not merely
# queue_free()'d, when it closes - a deferred free would leave the previous screen's plate
# stacked under the next one's for a frame.
#
# `_overlay_vbox` is the card host of whichever screen is open: the reward row, the shop's item
# list, the event's option list, the treasure card column. It is a VBoxContainer laid out
# horizontally (an HBoxContainer) on the REWARD screen, where the mockup puts the
# three cards side by side.
# ===========================================================================

var _overlay_layer: CanvasLayer = null
var _overlay_root: Control = null
var _overlay_vbox: BoxContainer = null

## Event option list, mockup: `top:398px; width:1040px`, centred, `gap:14px`.
## Treasure, mockup: art 240 square and a 470-wide card, `gap:44px`, at `top:276px`.
## The gutter a centred header/row block is inset to - see _screen_header().
const _SCREEN_GUTTER := 80.0

## Event option `fx` -> the glyph in its accent strip, the mockup's `o.icon` slot. FLAGGED: the
## option data in ContentDB.gd carries no icon field, so this table is authored here from each
## fx's own meaning, the same way reward_generator.gd's `_EVENT_FX_RARITY` is. Every path goes
## through MockupAssets, so an entry that stops resolving fails the asset gate rather than
## silently drawing nothing.


func _build_overlay_ui() -> void:
	_overlay_layer = CanvasLayer.new()
	_overlay_layer.layer = 20
	add_child(_overlay_layer)

	_overlay_root = Control.new()
	_overlay_root.name = "NodeScreen"
	_overlay_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	# STOP, not IGNORE: while one of these screens is open it owns every click on the canvas.
	# The map underneath must not be reachable through it.
	_overlay_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay_root.visible = false
	_overlay_layer.add_child(_overlay_root)


## The map is the run's resting point: every node resolves back to it, and a save taken here
## carries no in-flight combat. Called from the handful of places that finish a step rather
## than from a timer, so the file is written when something actually changed.
func _save_map_progress() -> void:
	RunState.save_run({})


func _close_overlay() -> void:
	_board.visible = true
	_overlay_root.visible = false
	_clear_overlay_content()


func _clear_overlay_content() -> void:
	_overlay_vbox = null
	_reward_cards.clear()   # its cards are freed below; never keep refs to them
	for c in _overlay_root.get_children():
		_overlay_root.remove_child(c)
		c.queue_free()


## A centred header column pinned at `top`, the shape all four screens open with.
func _screen_header(host: Control, top: float, separation: int) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.name = "ScreenHeader"
	col.set_anchors_preset(Control.PRESET_TOP_WIDE)
	# The mockup spans these header blocks `left:0;right:0` and centres inside them. A centred
	# column has the same centre line inset to a gutter, so it is inset here - UI law L1 wants
	# nothing positioned outside the safe area, and nothing moves on screen by obeying it.
	col.grow_vertical = Control.GROW_DIRECTION_END
	col.offset_left = _SCREEN_GUTTER
	col.offset_right = -_SCREEN_GUTTER
	col.offset_top = top
	col.offset_bottom = top
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", separation)
	host.add_child(col)
	return col


func _mockup_icon(path: String, px: float) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = MockupAssets.tex(path)
	icon.custom_minimum_size = Vector2(px, px)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE   # see _build_token()'s icon for why
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return icon


func _tex_icon(tex: Texture2D, px: float) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = tex
	icon.custom_minimum_size = Vector2(px, px)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return icon


# ---------------------------------------------------------------------------------------
# REWARD
# ---------------------------------------------------------------------------------------

## -> RunMapOffers._maybe_show_pending_reward
func _maybe_show_pending_reward() -> void:
	_offers._maybe_show_pending_reward()


## -> RunMapOffers._show_anchor_overlay
func _show_anchor_overlay() -> void:
	_offers._show_anchor_overlay()


## -> RunMapOffers._cleared_eyebrow
func _cleared_eyebrow() -> String:
	return _offers._cleared_eyebrow()


## Reward `t` -> category word and card icon (assets/ui3/icons). Unlisted types fall back to "Reward".
## UI-05: a relic offer reads "Core" (README "Reward category": Relic is shown as Core, as in UI-04).
const _REWARD_KIND := {
	"relic": "Core", "level": "Tier Up", "ascend": "Ascend", "hp": "Max HP",
	"reroll": "Reroll", "chaos": "Chaos Deal", "curse": "Curse Pact",
}
const _REWARD_ICON := {
	"relic": "ui_mooncard", "level": "face_buff", "ascend": "node_boss", "hp": "face_heal",
	"reroll": "ui_reroll", "chaos": "face_summon", "curse": "status_vuln",
}
## Skip button on the reward screen. OFF: owner rule 21/9 says a pick is mandatory; the approved
## mockup draws Skip. Pending Liam's call, flip this one flag. Skipping keeps the shards and ends the node.
const _REWARD_ALLOW_SKIP := false
## UI-05 b1 lane D components (31-reward): fixed-size RewardCard and the chaos ConfirmBar.
const _RewardCardUi := preload("res://scenes/shared/ui5/RewardCard.gd")
const _ConfirmBarUi := preload("res://scenes/shared/ui5/ConfirmBar.gd")
const _PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")

var _reward_sel := -1
var _reward_cards: Array[PanelContainer] = []


## Plate -> scrim (neutral-1 @ 80%) -> UI. Same host the shop/event/treasure screens use.
func _open_ui3_screen() -> Control:
	_clear_overlay_content()
	_board.visible = false   # map HUD stays hidden behind the scrim
	_overlay_root.visible = true
	_overlay_root.theme = UI3Theme.get_theme()
	var scrim := ColorRect.new()
	scrim.name = "Scrim"
	scrim.color = UI3Theme.color("scrim")
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_root.add_child(scrim)
	var host := Control.new()
	host.name = "ScreenContent"
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_root.add_child(host)
	return host


## -> RunMapOffers._show_reward_overlay
func _show_reward_overlay(title: String, _backdrop: Texture2D = null) -> void:
	_offers._show_reward_overlay(title, _backdrop)


## -> RunMapOffers._shard_chip
func _shard_chip(n: int) -> PanelContainer:
	return _offers._shard_chip(n)


## -> RunMapOffers._ask_skip_reward
func _ask_skip_reward(col: VBoxContainer) -> void:
	_offers._ask_skip_reward(col)


## -> RunMapOffers._select_reward
func _select_reward(i: int) -> void:
	_offers._select_reward(i)


## -> RunMapOffers._lift_selected_card
func _lift_selected_card() -> void:
	_offers._lift_selected_card()


var _taking := false   ## true from Take until the node finishes (spin + banner play in between): no double take


## -> RunMapOffers._take_selected_reward
func _take_selected_reward() -> void:
	_offers._take_selected_reward()


## -> RunMapOffers._ask_lasting_reward
func _ask_lasting_reward(r: Dictionary) -> void:
	_offers._ask_lasting_reward(r)


## -> RunMapOffers._trade_parts
func _trade_parts(r: Dictionary) -> Dictionary:
	return _offers._trade_parts(r)


## A1: Core offer cards arrive face-down with a tier halo, then flip left to right. Click / Space skips.
var _reveal: GachaReveal = null



## -> RunMapOffers._start_core_reveal
func _start_core_reveal(shake_host: Control) -> void:
	_offers._start_core_reveal(shake_host)


## -> RunMapOffers._add_reward_card
func _add_reward_card(r: Dictionary, _wide := false) -> PanelContainer:
	return _offers._add_reward_card(r, _wide)



## B2 / B3: when taking this card completes a combo, a gold plate "<glyph> PAIR" / "<glyph> FULL" (dark text on gold,
## glyph = 2 / 3 cards) plus the combo name; owned partners ride in one chip "With: X, Y" inside the chip row
## (no separate "Works with" line). No 1/2 count and no progress bar anywhere.
## Anchor lane: a house Core gets a "[glyph] House" chip; the card that takes the Anchor to 2/2 says "1/2 -> AWAKEN" and gets a
## 2 px anchor_awake edge. Never a word about the tier of the next pick (gacha contract).
static func _add_house_chip(card: Control, chips: HFlowContainer, key: String) -> void:
	if not AnchorAdapter.is_house_core(key):
		return
	var house := AnchorAdapter.house_id(AnchorAdapter.current_id())
	var icon := UI3.icon(AnchorAdapter.house_icon(house))
	if AnchorAdapter.would_awaken(key):
		var gold := UI3Theme.color("anchor_awake")
		var c := UI3.icon_chip("%d/%d \u2192 %s" % [Anchors.AWAKEN_NEED - 1, Anchors.AWAKEN_NEED, TranslationServer.translate("AWAKEN")], icon, gold, "AwakenChip")
		chips.add_child(c)
		var edge := Panel.new()
		edge.name = "AwakenEdge"
		edge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		edge.add_theme_stylebox_override("panel", UI3Theme.flat(Color(0, 0, 0, 0), UI3Theme.radius("m"), 2, gold))
		card.add_child(edge)
		card.set_meta("awaken", true)
	else:
		chips.add_child(UI3.icon_chip(TranslationServer.translate("House"), icon, AnchorAdapter.house_color(house), "HouseChip"))


## -> RunMapOffers._add_combo_labels
func _add_combo_labels(col: VBoxContainer, key: String, chips: HFlowContainer) -> void:
	_offers._add_combo_labels(col, key, chips)


## A chromeless, full-rect Button used as a hit target over a styled PanelContainer. Every
## state is a StyleBoxEmpty, so it contributes nothing to the picture and only catches clicks.
func _hit_button() -> Button:
	var hit := Button.new()
	hit.name = "Hit"
	hit.flat = true
	hit.focus_mode = Control.FOCUS_ALL
	hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var blank := StyleBoxEmpty.new()
	for state_key in ["normal", "hover", "pressed", "disabled", "focus"]:
		hit.add_theme_stylebox_override(state_key, blank)
	return hit


## Boss Pact screen (scenes/pact/PactView.gd). Take/skip go through RunState; afterwards the normal
## reward cards follow (phase REWARD), saved first so a quit here resumes on the right screen.
func _show_pact_overlay() -> void:
	var host := _open_ui3_screen()
	var view := PactView.new()
	view.name = "PactView"
	host.add_child(view)
	view.setup(RunState.pact_cards(), RunState.pact_can_skip(), AidPurchase.pact_swap_offer())
	view.swap_requested.connect(func(i: int):
		var res: Dictionary = await AidPurchase.buy_pact_swap(i, _save_map_progress)
		if not bool(res["ok"]) and String(res["code"]) in ["offline", "timeout", "expired", "version",
				"unauthenticated", "rejected", "out_of_order", "bad_request"]:
			NetNotice.show(self, String(res["code"]), func(): view.swap_requested.emit(i), "Could not swap")
		if bool(res["ok"]) and is_instance_valid(view):
			_save_map_progress()
			view.setup(RunState.pact_cards(), RunState.pact_can_skip(), AidPurchase.pact_swap_offer()))
	view.picked.connect(func(i: int, sell_id: String):
		if RunState.take_pact(i, sell_id):
			_after_pact())
	view.skipped.connect(func():
		if RunState.skip_pact():
			_after_pact())
	view.menu_requested.connect(open_run_menu)


func _after_pact() -> void:
	_save_map_progress()
	_maybe_show_pending_reward()


func _on_reward_chosen(reward: Dictionary) -> void:
	var key := String(reward.get("key", ""))
	if String(reward.get("t", "")) in ["relic", "chaos"] and key != "":
		var chk := RelicSlots.check_add(RunState.owned_relic_ids, RunState.relic_stickers, key, RunState.ascension, false)
		if bool(chk["needs_sell"]):
			open_slot_swap(reward, chk)
			return
	_apply_and_finish(reward)


## Takes the reward (state decided here), then plays the after-pick beats: A5 spin for the Dim Stone bet, then the
## Pair / Full banner. The animations only show what RunState already did.
func _apply_and_finish(reward: Dictionary) -> void:
	_taking = true
	var before_ids: Array = UI3Gacha.owned_ids().duplicate()
	var before_owned: Array = RunState.owned_relic_ids.duplicate()
	var was_awake := AnchorAdapter.awakened()
	var is_core := _is_core_card(reward) and not bool(reward.get("rule", false))
	var pool_names: Array = []
	if is_core and String(reward.get("key", "")) == "c_dim_stone":
		for d in CoreOffer.valid_pool(RunState._core_ctx(RunState._core_offer_pick)):
			if int(d.rarity) == 2:
				pool_names.append(UI3.title_case(UI3.player_text(String(d.name))))
	var pick_rect := Rect2()
	if _reward_sel >= 0 and _reward_sel < _reward_cards.size() and is_instance_valid(_reward_cards[_reward_sel]):
		pick_rect = (_reward_cards[_reward_sel] as Control).get_global_rect()
	# UI-05 b23 lane M2: core-taken / level-up / reward-taken (motion_ui3.json layers) on the picked card. Layers whose
	# node this screen does not have (the Cores plate slot, the party row) are data only; the card shrinks in place.
	var take_tl: UI3Motion.Timeline = null
	if not UI3Gacha.is_instant() and not bool(reward.get("rule", false)) and _reward_sel >= 0 and _reward_sel < _reward_cards.size() \
			and is_instance_valid(_reward_cards[_reward_sel]):
		var pc := _reward_cards[_reward_sel] as Control
		var is_level := String(reward.get("t", "")) == "level"
		var mid := "core-taken" if _is_core_card(reward) else ("level-up" if is_level else "reward-taken")
		# UI-06 take-to-strip: a Core that is really being taken flies to the Cores strip (a copy of its face). The card
		# itself is hidden so only the copy moves; core-taken still plays its other layers (others fade, Take press).
		if is_core and _offers.fly_card_to_strip(pc) != null:
			pc.modulate.a = 0.0
		pc.pivot_offset = pc.size / 2.0
		var others: Array = []
		for oc in _reward_cards:
			if oc != pc and is_instance_valid(oc):
				others.append(oc)
		var tg := {"card": pc, "axie": pc, "others": others}
		for pair in [["title", "Title"], ["button", "TakeButton"]]:
			var tn: Node = _overlay_root.find_child(String(pair[1]), true, false) if _overlay_root != null else null
			if tn is CanvasItem:
				tg[String(pair[0])] = tn
		var tl := UI3Motion.play_timeline(mid, tg, {"host": self})
		if not is_level:
			take_tl = tl
	RunState.apply_chosen_reward(reward)
	var granted := ""
	if not pool_names.is_empty():
		for id in RunState.owned_relic_ids:
			if not before_owned.has(id) and RelicRegistry.get_def(String(id)) != null:
				granted = UI3.title_case(UI3.player_text(String(RelicRegistry.get_def(String(id)).name)))
	if granted != "" and _overlay_root != null:
		gacha_log.append("spin")
		var fx := GachaFx.new()
		fx.name = "GachaSpin"
		_overlay_root.add_child(fx)
		fx.start_spin(pool_names, granted, UI3Gacha.tier_color(2), pick_rect)
		if fx.running:
			await fx.finished
	var formed := UI3Gacha.combos_formed(before_ids, UI3Gacha.owned_ids())
	# Awakening and a Pair on the same pick: ONE moment (the Pair line goes inside it), queue = no second banner.
	if AnchorAdapter.has_anchor() and not was_awake and AnchorAdapter.awakened():
		AnchorFx.arm(AnchorAdapter.current_id())
	var afx := _play_awaken(_awaken_extra_line(formed))
	if afx != null and afx.running:
		await afx.finished
	elif afx == null:
		# The banner plays OVER the Core-pick overlay (it is still there), then the node finishes.
		var ban := _combo_banner(formed)
		if ban != null and ban.running:
			await ban.finished
	await _wait_timeline_bounded(take_tl, TAKE_TWEEN_CAP_MS)
	_taking = false
	_finish_node()


const TAKE_TWEEN_CAP_MS := 1000   ## hard stop for the take moment (`core-taken` / `reward-taken`, longest row ~0.5 s + a hit-stop); never waited on forever

## Same for a UI3Motion.Timeline (a freed host ends it through its watchdog; the cap is a second line of defence).
func _wait_timeline_bounded(tl: UI3Motion.Timeline, cap_ms: int) -> void:
	if tl == null:
		return
	var deadline := Time.get_ticks_msec() + cap_ms
	while tl.running() and Time.get_ticks_msec() < deadline and is_inside_tree():
		await get_tree().process_frame


## -> RunMapOffers._play_awaken
func _play_awaken(extra_line := "") -> AnchorFx:
	return _offers._play_awaken(extra_line)


## -> RunMapOffers._awaken_extra_line
func _awaken_extra_line(formed: Array) -> String:
	return _offers._awaken_extra_line(formed)


## -> RunMapOffers._on_anchor_awakened
func _on_anchor_awakened(id: String) -> void:
	_offers._on_anchor_awakened(id)


## -> ComboBanner._combo_banner
func _combo_banner(formed: Array) -> GachaFx:
	return _combo._combo_banner(formed)


## -> RunMapSlotSwap.open_slot_swap
func open_slot_swap(reward: Dictionary, chk: Dictionary) -> void:
	_swap.open_slot_swap(reward, chk)


## -> RunMapSlotSwap.sheet_closed
func sheet_closed(ok: bool, reward: Dictionary, _left := false) -> void:
	_swap.sheet_closed(ok, reward, _left)


## Core offer: reroll ONE card (RunState action reroll_rewards [slot]). A7: the old card flies out (0.3 s) with the
## line "Won't come back this run", then the new card arrives face-down -> halo -> flip (0.5 s). Result is already decided.
var _reroll_slot := -1
var dm_log: Array[String] = []   ## test hook: dm_* events asked for (core open / hover / pick)
var _dm_audio: DiceMomentAudio = null
var _dm_hover_at := -1.0

## Dice-moment sound for the Core offer. Always logged; silent in headless/tests (DiceMomentAudio builds no voices then).
func _dm(event: String) -> void:
	dm_log.append(event)
	if CombatView.disable_juice_for_tests:
		return
	if _dm_audio == null or not is_instance_valid(_dm_audio):
		_dm_audio = DiceMomentAudio.new()
		add_child(_dm_audio)
	_dm_audio.play(event)


## -> RunMapOffers._dm_core_hover
func _dm_core_hover() -> void:
	_offers._dm_core_hover()

var gacha_log: Array[String] = []   ## test hook: reroll_out / reroll_in:<slot>


## -> RunMapOffers._on_core_card_reroll
func _on_core_card_reroll(idx: int) -> void:
	await _offers._on_core_card_reroll(idx)


## -> RunMapOffers._reroll_note
func _reroll_note(card: Control) -> void:
	await _offers._reroll_note(card)


## -> RunMapOffers._on_reward_reroll
func _on_reward_reroll(title: String) -> void:
	await _offers._on_reward_reroll(title)


# ---------------------------------------------------------------------------------------
# SHOP
# ---------------------------------------------------------------------------------------

## -> RunMapShop._on_shop_node
func _on_shop_node(_node_id: String) -> void:
	_shop._on_shop_node(_node_id)


## UI-03 08 Shop: left 384 (header + shards, Sell plate), middle (Relics / other goods in a
## 2-column grid of selectable cards), right 416 (detail + Buy, Leave shop). The offer was built by
## RunState.enter_node(); this screen only draws it. Sell uses RunState.sell_relic().
var _shop_sel := 0
var _shop_cards: Array[PanelContainer] = []

const _SHOP_ROW_H := 176.0
const _SHOP_ART := 128.0


## -> RunMapShop._shop_rarity
func _shop_rarity(it: Dictionary) -> int:
	return _shop._shop_rarity(it)


## -> RunMapShop._shop_block_reason
func _shop_block_reason(it: Dictionary) -> String:
	return _shop._shop_block_reason(it)


## -> RunMapShop._render_shop
func _render_shop() -> void:
	_shop._render_shop()


## -> RunMapShop._add_shop_row
func _add_shop_row(raw: Dictionary, index: int) -> PanelContainer:
	return _shop._add_shop_row(raw, index)


## -> RunMapShop._shop_art
func _shop_art(it: Dictionary, px: float, accent: Color) -> Control:
	return _shop._shop_art(it, px, accent)


## -> RunMapShop._select_shop
func _select_shop(index: int) -> void:
	_shop._select_shop(index)


## -> RunMapShop._on_shop_sell
func _on_shop_sell(relic_id: String) -> void:
	_shop._on_shop_sell(relic_id)


## -> RunMapShop._on_shop_buy
func _on_shop_buy(index: int) -> void:
	await _shop._on_shop_buy(index)


# ---------------------------------------------------------------------------------------
# EVENT
# ---------------------------------------------------------------------------------------

## Event node (UI-03 09): art 720 + a 720 column (header, body, choice rows, action). RunState picked
## WHICH event; this screen only reports an index, the verifier re-derives the offer from the seed.
var _event_opts: Array = []
var _event_sel := -1

const _EVENT_FX_UI3 := {
	"bless_reroll": "ui_reroll", "gamble_legend": "face_dmg", "pray": "face_heal", "rest": "face_heal",
	"forge": "face_dmg", "meditate": "face_mana", "chest": "node_treasure", "shards60": "cur_shard",
	"bet_small": "cur_shard", "bet_big": "cur_shard", "shards30": "cur_shard", "dip": "face_mana",
	"drink": "face_mana", "leave": "face_blank",
}


## -> RunMapEvent._on_event_node
func _on_event_node(_node_id: String) -> void:
	_event._on_event_node(_node_id)


## -> RunMapEvent._build_event_screen
func _build_event_screen(picked: int, outcome: String) -> void:
	_event._build_event_screen(picked, outcome)


var _event_cards: Array[PanelContainer] = []


## -> RunMapEvent._select_event
func _select_event(index: int) -> void:
	_event._select_event(index)


## -> RunMapEvent._add_event_option
func _add_event_option(raw: Dictionary, index: int, picked: int) -> Control:
	return _event._add_event_option(raw, index, picked)


## -> RunMapEvent._on_event_choice
func _on_event_choice(index: int) -> void:
	await _event._on_event_choice(index)


# ---------------------------------------------------------------------------------------
# TREASURE
# ---------------------------------------------------------------------------------------

## Treasure (UI-03 13, round 2): closed chest + "Open chest", then the rewards (a real choice of
## pending rewards at rewardTier 1) with Shards pill and "Take and continue". The 3D chest is not
## built yet: the chest is the node_treasure icon. No Skip, no reroll here.
func _on_treasure_node(node_id: String) -> void:
	RunState.generate_treasure_rewards(node_id)
	_build_treasure(false)


## -> RunMapTreasure._build_treasure
func _build_treasure(opened: bool) -> void:
	_treasure._build_treasure(opened)
