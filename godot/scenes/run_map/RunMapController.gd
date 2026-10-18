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
var _graph: RunMapGraph = null
var _edges_canvas: _EdgeCanvas = null
var _nodes_layer: Control = null
var _map_layer: Control = null
var _board: Control = null
var _left_root: Control = null
var _detail_root: Control = null
var _node_visuals: Dictionary = {}   # node_id -> {"node": RunMapNode, "root": Button, "caption": Label|null}
var _selected_id := ""
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


func _ready() -> void:
	EventBus.node_entered.connect(_on_node_entered)
	_graph = RunMapGraph.from_data(RunState.map_graph)
	_root.theme = UI3Theme.get_theme()

	var bg := ColorRect.new()
	bg.name = "PlateHost"   # the screen backdrop (neutral-1), what t_ui_laws L0 looks for
	bg.color = UI3Theme.color("bg")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bg)

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

	var hint := UI3.key_hint(tr("Arrows pick · Enter travels · Esc menu"))
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

	if animate and is_inside_tree() and not MetaState.reduce_flash:
		_map_layer.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(_map_layer, "modulate:a", 1.0, UI3Theme.motion_sec("base"))
	else:
		_map_layer.modulate.a = 1.0
	if _overlay_root == null or not _overlay_root.visible:
		_focus_selected.call_deferred()


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
## rarity_legendary amber). The tokens have no Uncommon, so it borrows `mana` (purple): the one
## palette colour not used by another rarity. Index = RelicDef.rarity (0 Common .. 4 Legendary).
const _RARITY_TOKENS := ["rarity_common", "mana", "rarity_rare", "rarity_epic", "rarity_legendary", "rarity_legendary"]


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
	icon.texture = UI3.icon("ui_lock" if locked else "node_%s" % node.node_type)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_anchors_preset(Control.PRESET_CENTER)
	icon.offset_left = -icon_px * 0.5
	icon.offset_right = icon_px * 0.5
	icon.offset_top = -icon_px * 0.5
	icon.offset_bottom = icon_px * 0.5
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(icon)

	var base := Vector2.ONE
	if node.node_type == "boss" and not locked:
		base = Vector2(1.25, 1.25)
	if selected:
		base *= 1.1
	btn.set_meta("base_scale", base)
	btn.scale = base
	if locked or passed:
		btn.modulate.a = 0.4
	var id := node.id
	btn.gui_input.connect(_on_token_input.bind(id))
	btn.mouse_entered.connect(_hover_token.bind(btn, true))
	btn.mouse_exited.connect(_hover_token.bind(btn, false))
	_nodes_layer.add_child(btn)

	var caption: Label = null
	# Passed nodes carry no caption (it collided with its neighbours at 1280); clicking one shows
	# "Already passed" in the detail plate.
	if not locked:
		var text := _boss_name(node) if node.node_type == "boss" else _type_name(node.node_type)
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


func _hover_token(btn: Button, on: bool) -> void:
	if is_instance_valid(btn):
		var base: Vector2 = btn.get_meta("base_scale", Vector2.ONE)
		btn.scale = base * (1.1 if on else 1.0)


func _on_token_input(ev: InputEvent, id: String) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		_select_node(id)
	elif ev.is_action_pressed("ui_accept") and not ev.is_echo():
		if _reachable_now_ids().has(id):
			get_viewport().set_input_as_handled()
			_on_node_pressed(id)


## Picking a node only updates the detail plate; Travel (or Enter on a reachable node) enters it.
func _select_node(id: String) -> void:
	if id == _selected_id or not _node_visuals.has(id):
		return
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
	var res: Dictionary = await RunState.request_enter_node(id, node.node_type)
	if not bool(res["ok"]) and String(res["code"]) != "busy":
		NetNotice.show(self, String(res["code"]), _on_node_pressed.bind(id))


## In-run menu (L1 C3): Esc or the MENU button. The map's state lives in RunState, so saving and
## reloading RunMap.tscn on "Back to run" resumes exactly here.
func open_run_menu() -> void:
	prepare_run_menu()
	get_tree().change_scene_to_file("res://scenes/settings/Settings.tscn")


func prepare_run_menu() -> void:
	RunState.save_run({})
	SettingsView.in_run = true
	SettingsView.return_scene = "res://scenes/run_map/RunMap.tscn"


func _unhandled_key_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_ESCAPE:
		open_run_menu()
		get_viewport().set_input_as_handled()


func _on_save_and_quit_pressed() -> void:
	RunState.save_run({})
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")


func _rebuild_left() -> void:
	for c in _left_root.get_children():
		_left_root.remove_child(c)
		c.queue_free()

	# TopLeft: header + party.
	var top := UI3.plate(&"plate")
	top.name = "PartyPlate"
	top.custom_minimum_size.x = _PLATE_LEFT_W
	top.set_anchors_preset(Control.PRESET_TOP_LEFT)
	top.offset_left = _SCREEN_MARGIN
	top.offset_top = _SCREEN_MARGIN
	_left_root.add_child(top)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	top.add_child(col)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	col.add_child(head)
	var menu_btn := UI3.icon_button("ui_menu", tr("Menu"))
	menu_btn.name = "RunMenuButton"
	menu_btn.pressed.connect(open_run_menu)
	head.add_child(menu_btn)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_theme_constant_override("separation", 0)
	head.add_child(titles)
	var total_rows := _graph.rows.size() if _graph != null else 0
	titles.add_child(UI3.label(tr("Floor %d of %d") % [maxi(_current_row(), 0), total_rows], "LabelTitle"))
	titles.add_child(UI3.label(tr("Ascension %d · Shards %d") % [RunState.ascension, RunState.shards_this_run]))

	for entry in RunState.roster:
		col.add_child(_build_party_row(entry))

	# BottomLeft: relics.
	var bottom := UI3.plate(&"plate")
	bottom.name = "RelicPlate"
	bottom.custom_minimum_size.x = _PLATE_LEFT_W
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	bottom.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bottom.offset_left = _SCREEN_MARGIN
	bottom.offset_bottom = -_SCREEN_MARGIN
	_left_root.add_child(bottom)
	var rcol := VBoxContainer.new()
	rcol.add_theme_constant_override("separation", 8)
	bottom.add_child(rcol)
	rcol.add_child(UI3.label(tr("Relics · %d") % RunState.owned_relic_ids.size(), "LabelTitle"))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.get_v_scroll_bar().custom_minimum_size.x = UI3Theme.SCROLL_W
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	for relic_id in RunState.owned_relic_ids:
		list.add_child(_build_relic_row(relic_id))
	var list_h := float(RunState.owned_relic_ids.size()) * (_RELIC_ROW_H + 8.0)
	scroll.custom_minimum_size.y = minf(list_h, 5.0 * (_RELIC_ROW_H + 8.0))
	scroll.visible = not RunState.owned_relic_ids.is_empty()
	rcol.add_child(scroll)


func _build_party_row(entry: Dictionary) -> Control:
	var hero_key := String(entry.get("hero_key", ""))
	var hero_def: Dictionary = ContentDB.heroes.get(hero_key, {})
	var base_hp: int = int(entry.get("max_hp", 0))
	if base_hp <= 0:
		base_hp = int(hero_def.get("max_hp", 10))
	var max_hp: int = base_hp + int(entry.get("bonus_hp", 0))   # full rest between nodes

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var line := HBoxContainer.new()
	box.add_child(line)
	var name_lbl := UI3.label(String(hero_def.get("n", hero_key)))
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.clip_text = true
	line.add_child(name_lbl)
	line.add_child(UI3.label("%d" % max_hp, "LabelTitle"))
	box.add_child(UI3.hp_bar(max_hp, max_hp, 0, 0, &"axie"))
	return box


func _build_relic_row(relic_id: String) -> Control:
	var def = RelicRegistry.get_def(relic_id)
	var rarity := int(def.rarity) if def != null else 0
	var relic_name := String(def.name) if def != null else relic_id
	var row := UI3.plate(&"row")
	row.custom_minimum_size.y = _RELIC_ROW_H
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 8)
	row.add_child(line)
	var name_lbl := UI3.label(relic_name)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.clip_text = true
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	line.add_child(name_lbl)
	var rar_lbl := UI3.label(_rarity_name(rarity))
	rar_lbl.add_theme_color_override("font_color", _rarity_color(rarity))
	line.add_child(rar_lbl)
	return row


func _node_info(node: RunMapNode) -> Dictionary:
	match node.node_type:
		"battle":
			return {"desc": tr("A fight against a squad of enemies."), "win": [tr("Choose 1 of 3 rewards")]}
		"elite":
			return {"desc": tr("A tougher fight against stronger enemies."), "win": [tr("Choose 1 of 3 rewards")]}
		"event":
			return {"desc": tr("Something happens on the road. You choose how it ends."), "win": [tr("Depends on your choice")]}
		"shop":
			return {"desc": tr("A merchant sells relics for Shards."), "win": [tr("Spend your Shards")]}
		"treasure":
			return {"desc": tr("A sealed vault with a better than usual reward."), "win": [tr("Pick a reward")]}
		"boss":
			return {"desc": tr("The guardian of this stretch of the road."),
				"win": [tr("Clears the run") if _is_final_boss(node) else tr("Choose 1 of 3 rewards")]}
	return {"desc": "", "win": []}


func _rebuild_detail() -> void:
	for c in _detail_root.get_children():
		_detail_root.remove_child(c)
		c.queue_free()
	_travel_btn = null
	var node: RunMapNode = null
	if _graph != null and _selected_id != "":
		node = _graph.find_node(_selected_id)
	if node == null:
		return
	var reachable := _reachable_now_ids().has(node.id)

	var plate := UI3.plate(&"plate")
	plate.name = "DetailPlate"
	plate.custom_minimum_size.x = _PLATE_RIGHT_W
	plate.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	plate.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	plate.offset_right = -_SCREEN_MARGIN
	plate.offset_top = _SCREEN_MARGIN
	_detail_root.add_child(plate)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 16)
	plate.add_child(col)

	var info := _node_info(node)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 16)
	col.add_child(head)
	var icon := TextureRect.new()
	icon.texture = UI3.icon("node_%s" % node.node_type)
	icon.custom_minimum_size = Vector2(64, 64)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	head.add_child(icon)
	var title := UI3.label(_boss_name(node) if node.node_type == "boss" else _type_name(node.node_type), "LabelScreenTitle")
	title.name = "DetailTitle"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.clip_text = true
	head.add_child(title)

	var desc := UI3.label(String(info["desc"]))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size.x = 368
	col.add_child(desc)

	col.add_child(UI3.label(tr("If you win"), "LabelMuted"))
	for line in info["win"]:
		var row := UI3.plate(&"row")
		row.add_child(UI3.label(String(line)))
		col.add_child(row)

	var note: Label
	if node.visited or node.id == RunState.current_node_id:
		note = UI3.label(tr("Already passed"), "LabelMuted")
	elif reachable:
		note = UI3.label(tr("On your path"), "LabelMuted")
	else:
		note = UI3.label(tr("Not on your path"))
		note.add_theme_color_override("font_color", UI3Theme.color("danger_text"))
	note.name = "PathNote"
	col.add_child(note)
	if reachable and _graph != null and not _graph.boss_rows.is_empty():
		var boss_row := int(_graph.boss_rows[_graph.boss_rows.size() - 1])
		var path_note := UI3.label(tr("Floor %d of %d · %d floors to the boss") % [node.row, _graph.rows.size(), maxi(boss_row - node.row, 0)], "LabelMuted")
		path_note.name = "PathRoute"
		path_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		path_note.custom_minimum_size.x = 368
		col.add_child(path_note)

	var is_boss := node.node_type == "boss"
	_travel_btn = UI3.button(tr("Face the Boss") if is_boss else tr("Travel"), &"primary", &"L")
	_travel_btn.name = "TravelButton"
	if reachable:
		_travel_btn.pressed.connect(_on_node_pressed.bind(node.id))
	else:
		UI3.set_disabled_reason(_travel_btn, tr("Already passed") if (node.visited or node.id == RunState.current_node_id) else tr("Not on your path"))
	col.add_child(_travel_btn)
	if reachable:
		# Focus order: reachable nodes -> Travel -> relics.
		for id in _reachable_now_ids():
			var entry: Dictionary = _node_visuals.get(id, {})
			var b: Button = entry.get("root")
			if b != null:
				b.focus_neighbor_right = b.get_path_to(_travel_btn)


func _spacer(h: float) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, h)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s


func _on_node_entered(node_type: String, node_id: String) -> void:
	match node_type:
		"battle", "elite", "boss":
			get_tree().change_scene_to_file("res://scenes/combat/Combat.tscn")
		"event":
			_on_event_node(node_id)
		"shop":
			_on_shop_node(node_id)
		"treasure":
			_on_treasure_node(node_id)


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
	RunState.after_node()
	_refresh(true)
	# AFTER after_node(), not before: that call is what advances power_level and the phase, and
	# a save taken ahead of it would resume the player onto a node they had already finished.
	_save_map_progress()


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


## Opens a node screen on `plate` and returns the full-canvas host to lay its content out in.
## Plate -> scrim -> UI, in that order, per DangoTheme's own background formula.
func _open_screen(plate: Texture2D) -> Control:
	_clear_overlay_content()
	_board.visible = true
	_overlay_root.visible = true
	DangoTheme.build_plate(_overlay_root, plate, DangoTheme.Scrim.DEFAULT, false)

	var host := Control.new()
	host.name = "ScreenContent"
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_root.add_child(host)
	return host


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


## The mockup's eyebrow pill: a solid fill, 4px black, a hard shelf, and Baloo at
## `letter-spacing:.2em` in the fill's own ink.
func _eyebrow_chip(text: String, fill: Color, height: float, font_px: int,
		tracking_em: float = 0.0) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	chip.custom_minimum_size.y = height
	var sb := DangoTheme.solid_chip_style(fill, 10, 4, Vector2(22, 4))
	sb.shadow_color = DangoTheme.SHELF
	sb.shadow_size = 0
	sb.shadow_offset = Vector2(0, 5)
	chip.add_theme_stylebox_override("panel", sb)
	var lbl := DangoTheme.display_label(text, font_px, DangoTheme.ink_on(fill), 800, tracking_em)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chip.add_child(lbl)
	return chip


## A cream reading card - the shape the reward, shop-row, event-option and treasure cards all
## share: CREAM, pure-black outline, hard shelf, contents clipped so a full-bleed header band
## keeps the card's own corner radius.
## `clip` is G3's rounded-corner clip. Pass FALSE for a card that goes inside another clipped
## frame: Godot's `clip_children` is a canvas group, and canvas groups DO NOT NEST — the inner
## group's contents simply do not draw. The shop rows are the case in this file: they sit inside
## the clipped shop panel and rendered as four empty cream bars with every icon, name, price and
## BUY button missing. A card only needs the clip when it has a full-bleed child of its own (a
## header band, an accent rail) whose square corners would otherwise cut the frame's radius; a
## row whose children are all inset by the content margins does not.
func _cream_card(radius: int, border_w: int, shelf: float,
		clip: bool = true) -> PanelContainer:
	var card := PanelContainer.new()
	card.clip_contents = true
	var sb := StyleBoxFlat.new()
	sb.bg_color = DangoTheme.CREAM
	sb.border_color = Color.BLACK
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.shadow_color = DangoTheme.SHELF_DEEP if shelf >= 6.0 else DangoTheme.SHELF
	sb.shadow_size = 0
	sb.shadow_offset = Vector2(0, shelf)
	# Inset by exactly the border width so a full-bleed child (a header band, an accent strip)
	# starts INSIDE the black ring instead of painting over it. Callers that want the mockup's
	# own padding set these again afterwards.
	sb.content_margin_left = float(border_w)
	sb.content_margin_right = float(border_w)
	sb.content_margin_top = float(border_w)
	sb.content_margin_bottom = float(border_w)
	card.add_theme_stylebox_override("panel", sb)
	if clip:
		DangoTheme.clip_to_frame(card)   # G3
	return card


## The big flat action button these screens use: a solid fill, 4px black, a 4px shelf, Baloo at
## the mockup's own size, ink chosen by `ink_on()`.
func _flat_button(text: String, fill: Color, height: float, font_px: int,
		radius: int = 13, tracking_em: float = 0.0) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size.y = height
	btn.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	btn.add_theme_font_size_override("font_size", font_px)
	# The mockup's own `letter-spacing` on this button's label, verbatim in em.
	DangoTheme.apply_tracking(btn, tracking_em, font_px)
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = Color.BLACK
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(radius)
	sb.shadow_color = DangoTheme.SHELF
	sb.shadow_size = 0
	sb.shadow_offset = Vector2(0, 4)
	for state_key in ["normal", "hover", "pressed", "disabled"]:
		btn.add_theme_stylebox_override(state_key, sb)
	var ink := DangoTheme.ink_on(fill)
	for color_key in ["font_color", "font_hover_color", "font_pressed_color",
			"font_disabled_color"]:
		btn.add_theme_color_override(color_key, ink)
	return btn


## A solid rarity chip - the mockup draws rarity on these screens as a rarity-FILLED pill with
## black ink on it, not as DangoTheme.rarity_chip()'s dark pill with a coloured border. On a
## cream card the dark pill is the wrong object; `ink_on()` keeps the label legible per UI
## rule 4. Named "RarityChip" so it is still findable by name.
##
## FLAGGED: t_runloop_ui.test_reward_and_shop_cards_show_a_rarity_chip_matching_rar() asserts
## this chip's LABEL colour equals DangoTheme.rarity_color(rar), which was true of the dark
## pill and cannot be true of a filled one - the label would be the same colour as the fill
## behind it. The chip still carries the rarity at full strength; the assertion needs to move
## to the chip's fill. Reported, not worked around.
func _solid_rarity_chip(rar: int, height: float, font_px: int, radius: int,
		border_w: int, tracking_em: float = 0.0) -> PanelContainer:
	var fill := DangoTheme.rarity_color(rar)
	var chip := PanelContainer.new()
	chip.name = "RarityChip"
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chip.custom_minimum_size.y = height
	chip.add_theme_stylebox_override("panel",
		DangoTheme.solid_chip_style(fill, radius, border_w,
			Vector2(8.0 + border_w, border_w)))   # mockup `padding:0 8px`
	var lbl := DangoTheme.display_label(DangoTheme.rarity_name(rar).to_upper(), font_px,
		DangoTheme.ink_on(fill), 800, tracking_em)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chip.add_child(lbl)
	return chip


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

## Shown once, right after a won combat, before the player can interact with the map at all
## (RunState.pending_rewards was populated by apply_combat_result() before CombatView even
## changed scene to this one). If pending_rewards is somehow empty on arrival (e.g. an empty
## roster edge case - RewardGenerator's own "hp" fallback fill can only return {} then), the
## map still has to advance exactly once: after_node() is now ONLY ever called from
## _on_reward_chosen(), so nothing else would ever call it for this node.
func _maybe_show_pending_reward() -> void:
	if RunState.phase == RunState.RunPhase.PACT:
		_show_pact_overlay()
		return
	if RunState.pending_rewards.is_empty():
		if RunState.phase == RunState.RunPhase.REWARD:
			RunState.after_node()
			_refresh(true)
		return
	_show_reward_overlay("CHOOSE ONE REWARD")


## The eyebrow above the reward title. The mockup reads "WAVE 3 CLEARED"; this build resolves a
## reward per NODE and has no wave concept (ContentDB.gd says so in as many words), so the node
## the player just finished is what the pill names.
func _cleared_eyebrow() -> String:
	if _graph == null or RunState.current_node_id == "":
		return "NODE CLEARED"
	var node := _graph.find_node(RunState.current_node_id)
	if node == null:
		return "NODE CLEARED"
	var kind := "MERCHANT" if node.node_type == "shop" else node.node_type.to_upper()
	return "%s CLEARED" % kind


## Reward `t` -> kind label and card icon (assets/ui3/icons). Unlisted types fall back to "Reward".
const _REWARD_KIND := {
	"relic": "Relic", "level": "Tier up", "ascend": "Ascend", "hp": "Max HP",
	"reroll": "Reroll", "chaos": "Chaos deal", "curse": "Curse pact",
}
const _REWARD_ICON := {
	"relic": "ui_mooncard", "level": "face_buff", "ascend": "node_boss", "hp": "face_heal",
	"reroll": "ui_reroll", "chaos": "face_summon", "curse": "status_vuln",
}
const _REWARD_CARD_W := 384.0
const _REWARD_CARD_W_WIDE := 336.0   # 4 cards (Scavenger's Eye)
const _REWARD_ART := 160.0
## Skip button on the reward screen. OFF: owner rule 21/9 says a pick is mandatory; the approved
## mockup draws Skip. Pending Liam's call, flip this one flag. Skipping keeps the shards and ends the node.
const _REWARD_ALLOW_SKIP := false

var _reward_sel := 0
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


## Reward screen (07): title + Shards pill, a row of 3 cards, Reroll / Take. There is no Skip:
## choosing stays mandatory (owner decision 21/9, RunState.after_node() is only reached by a pick).
func _show_reward_overlay(title: String, _backdrop: Texture2D = null) -> void:
	var host := _open_ui3_screen()
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(center)
	var col := VBoxContainer.new()
	col.name = "RewardColumn"
	col.add_theme_constant_override("separation", 40)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(col)

	var head := HBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_theme_constant_override("separation", 24)
	col.add_child(head)
	var title_lbl := UI3.label(tr(title), "LabelScreenTitle")
	title_lbl.name = "RewardTitle"
	head.add_child(title_lbl)
	head.add_child(UI3.currency_pill([{"icon": "cur_shard", "value": str(RunState.shards_this_run)}]))

	_overlay_vbox = HBoxContainer.new()
	_overlay_vbox.name = "RewardRow"
	_overlay_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_overlay_vbox.add_theme_constant_override("separation", 32)
	col.add_child(_overlay_vbox)

	_reward_cards.clear()
	_reward_sel = 0
	var wide := RunState.pending_rewards.size() >= 4
	for reward in RunState.pending_rewards:
		_add_reward_card(reward, wide)

	var actions := HBoxContainer.new()
	actions.name = "RewardActions"
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 16)
	col.add_child(actions)
	var left := RunState.reward_reroll_charges
	var reroll := UI3.button(tr("Reroll · %d left") % left, &"secondary", &"M")
	reroll.name = "RerollButton"
	if left > 0:
		reroll.pressed.connect(_on_reward_reroll.bind(title))
	else:
		UI3.set_disabled_reason(reroll, tr("Reroll · 0 left"))
	actions.add_child(reroll)
	if _REWARD_ALLOW_SKIP:
		var skip := UI3.button(tr("Skip"), &"secondary", &"M")
		skip.name = "SkipButton"
		skip.pressed.connect(_ask_skip_reward.bind(col))
		actions.add_child(skip)
	var take := UI3.button(tr("Take"), &"primary", &"L")
	take.name = "TakeButton"
	take.pressed.connect(_take_selected_reward)
	actions.add_child(take)

	_select_reward(0)
	if not _reward_cards.is_empty():
		_reward_cards[0].grab_focus.call_deferred()
	else:
		take.grab_focus.call_deferred()


## Inline confirm row under the actions: "Skip this reward? You keep the N Shards." Back / Skip.
func _ask_skip_reward(col: VBoxContainer) -> void:
	var old := col.find_child("SkipConfirm", true, false)
	if old != null:
		return
	var row := HBoxContainer.new()
	row.name = "SkipConfirm"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	row.add_child(UI3.label(tr("Skip this reward? You keep the %d Shards.") % RunState.shards_this_run))
	var back := UI3.button(tr("Back"), &"secondary", &"S")
	back.pressed.connect(row.queue_free)
	row.add_child(back)
	var go := UI3.button(tr("Skip"), &"secondary", &"S")
	go.pressed.connect(func() -> void:
		RunState.pending_rewards.clear()
		_finish_node())
	row.add_child(go)
	col.add_child(row)
	back.grab_focus()


func _select_reward(i: int) -> void:
	_reward_sel = clampi(i, 0, maxi(_reward_cards.size() - 1, 0))
	for k in _reward_cards.size():
		UI3.set_card_selected(_reward_cards[k], k == _reward_sel)


func _take_selected_reward() -> void:
	if _reward_sel >= 0 and _reward_sel < RunState.pending_rewards.size():
		var r: Dictionary = RunState.pending_rewards[_reward_sel]
		if String(r.get("t", "")) in ["chaos", "curse"]:
			_ask_lasting_reward(r)
			return
		_on_reward_chosen(r)


## Chaos / Curse last the whole run: inline confirm under the actions (spec 31). Back keeps the pick open.
func _ask_lasting_reward(r: Dictionary) -> void:
	var col := _overlay_vbox.get_parent() as Control if _overlay_vbox != null else null
	if col == null or col.find_child("LastingConfirm", true, false) != null:
		return
	var row := HBoxContainer.new()
	row.name = "LastingConfirm"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	row.add_child(UI3.label(tr("This lasts the whole run. Take it?")))
	var back := UI3.button(tr("Back"), &"secondary", &"S")
	back.name = "LastingBack"
	back.pressed.connect(row.queue_free)
	row.add_child(back)
	var go := UI3.button(tr("Take it"), &"secondary", &"S")
	go.name = "LastingTake"
	go.pressed.connect(func() -> void: _on_reward_chosen(r))
	row.add_child(go)
	col.add_child(row)
	back.grab_focus()


## Chaos / Curse card body split into Gain and Gamble/Curse text, from the generator's real strings.
func _trade_parts(r: Dictionary) -> Dictionary:
	var sub := String(r.get("sub", ""))
	var desc := String(r.get("desc", ""))
	if String(r.get("t", "")) == "chaos":
		var lines := sub.split("\n")
		var cost := String(lines[0]).trim_prefix("GAMBLE: ")
		cost = cost.substr(0, 1).to_upper() + cost.substr(1)
		cost = cost.substr(0, 1).to_upper() + cost.substr(1)
		var gain := UI3.describe(String(lines[1]) if lines.size() > 1 else "")
		return {"gain": ("MP %d · " % int(gain["mp"]) if int(gain["mp"]) >= 0 else "") + String(gain["text"]),
			"cost": cost, "cost_kind": &"gamble"}
	return {"gain": sub.trim_prefix("IN EXCHANGE: you gain ").trim_suffix("."), "cost": desc, "cost_kind": &"curse"}


func _add_reward_card(r: Dictionary, wide := false) -> PanelContainer:
	var t := String(r.get("t", ""))
	var rar := _reward_rarity(r)
	var accent := _rarity_color(rar)
	var idx := _reward_cards.size()

	var card := UI3.plate(&"card")
	card.name = "RewardCard%d" % idx
	card.custom_minimum_size.x = _REWARD_CARD_W_WIDE if wide else _REWARD_CARD_W
	card.size_flags_vertical = Control.SIZE_FILL
	card.focus_mode = Control.FOCUS_ALL
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	# Focus ring drawn by the card itself: a child Panel would be squeezed inside the card's padding
	# by the PanelContainer. 2 px amber, 4 px outside the cream selection outline.
	card.draw.connect(func() -> void:
		if card.has_focus():
			card.draw_style_box(UI3Theme.focus_style(UI3Theme.radius("l")), Rect2(Vector2.ZERO, card.size)))
	card.focus_entered.connect(card.queue_redraw)
	card.focus_exited.connect(card.queue_redraw)
	card.focus_entered.connect(_select_reward.bind(idx))
	card.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_select_reward(idx)
			card.grab_focus()
		elif ev.is_action_pressed("ui_accept") and not ev.is_echo():
			_select_reward(idx)
			var tb := _overlay_root.find_child("TakeButton", true, false) as Control
			if tb != null:
				tb.grab_focus())
	_overlay_vbox.add_child(card)
	_reward_cards.append(card)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	card.add_child(col)

	col.add_child(UI3.label(tr(String(_REWARD_KIND.get(t, "Reward"))), "LabelMuted"))

	var art := Panel.new()
	art.name = "Art"
	art.custom_minimum_size = Vector2(0, _REWARD_ART)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art_sb := StyleBoxFlat.new()
	art_sb.bg_color = UI3Theme.color("panel_raised")
	art_sb.border_color = accent
	art_sb.set_border_width_all(UI3Theme.stroke("selected"))
	art_sb.set_corner_radius_all(UI3Theme.radius("m"))
	art.add_theme_stylebox_override("panel", art_sb)
	var icon := TextureRect.new()
	icon.texture = UI3.icon(String(_REWARD_ICON.get(t, "ui_mooncard")))
	icon.set_anchors_preset(Control.PRESET_CENTER)
	icon.custom_minimum_size = Vector2(96, 96)
	icon.offset_left = -48
	icon.offset_right = 48
	icon.offset_top = -48
	icon.offset_bottom = 48
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.add_child(icon)
	col.add_child(art)

	# A relic offer arrives as title "RELIC", desc = relic name, sub = effect text.
	var name_text := String(r.get("title", ""))
	var body_text := String(r.get("desc", ""))
	if t == "relic" and String(r.get("sub", "")) != "":
		name_text = String(r.get("desc", ""))
		body_text = String(r.get("sub", ""))
	elif String(r.get("sub", "")) != "":
		body_text += "\n" + String(r.get("sub", ""))
	name_text = UI3.player_text(name_text)
	var dsc := UI3.describe(body_text)
	body_text = ("MP %d · " % int(dsc["mp"]) if int(dsc["mp"]) >= 0 else "") + String(dsc["text"])
	var name_lbl := UI3.label(name_text, "LabelTitle")
	name_lbl.name = "RewardName"
	name_lbl.clip_text = true
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	col.add_child(name_lbl)
	var rar_lbl := UI3.label(_rarity_name(rar))
	rar_lbl.name = "RarityLabel"
	rar_lbl.add_theme_color_override("font_color", accent)
	col.add_child(rar_lbl)
	if t in ["chaos", "curse"]:
		var tp := _trade_parts(r)
		if t == "chaos":
			name_lbl.text = UI3.player_text(String(r.get("desc", "")))
		else:
			name_lbl.text = UI3.player_text(String(r.get("title", "")))
		col.add_child(UI3.trade_box(&"gain", String(tp["gain"])))
		col.add_child(UI3.trade_box(tp["cost_kind"], String(tp["cost"])))
		return card
	var desc := UI3.label(body_text)
	desc.name = "RewardDesc"
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size.x = (_REWARD_CARD_W_WIDE if wide else _REWARD_CARD_W) - 48.0
	col.add_child(desc)
	return card



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
	var host := _open_screen(MockupAssets.tex("assets/bg/rocky.jpg"))
	var view := PactView.new()
	view.name = "PactView"
	host.add_child(view)
	view.setup(RunState.pact_cards(), RunState.pact_can_skip(), AidPurchase.pact_swap_offer())
	view.swap_requested.connect(func(i: int):
		var res: Dictionary = await AidPurchase.buy_pact_swap(i, _save_map_progress)
		if not bool(res["ok"]) and String(res["code"]) in ["offline", "timeout", "expired", "version",
				"unauthenticated", "rejected", "out_of_order", "bad_request"]:
			NetNotice.show(self, String(res["code"]), func(): view.swap_requested.emit(i))
		if bool(res["ok"]) and is_instance_valid(view):
			_save_map_progress()
			view.setup(RunState.pact_cards(), RunState.pact_can_skip(), AidPurchase.pact_swap_offer()))
	view.picked.connect(func(i: int, sell_id: String):
		if RunState.take_pact(i, sell_id):
			_after_pact())
	view.skipped.connect(func():
		if RunState.skip_pact():
			_after_pact())


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
	RunState.apply_chosen_reward(reward)
	_finish_node()


## Spec 32: the slot kind of the new relic is full. The sale goes through RunState.acquire_relic (logged as
## swap_on_full), then the normal pick applies. Leave it returns to the cards with nothing taken.
func open_slot_swap(reward: Dictionary, chk: Dictionary) -> void:
	var key := String(reward.get("key", ""))
	var nd = RelicRegistry.get_def(key)
	if nd == null:
		return
	var active: bool = RelicSlots._is_active(nd)
	var cap := RelicSlots.capacity(RunState.ascension, RunState.owned_relic_ids)
	var cells: Array = []
	var sell_from: Array = chk["sell_from"]
	for oid in RunState.owned_relic_ids:
		var id := String(oid)
		var od = RelicRegistry.get_def(id)
		if od == null or id.begins_with("__"):
			continue
		var eternal := String(RunState.relic_stickers.get(id, "")) == RelicSlots.STICKER_ETERNAL
		if not sell_from.has(id) and not (eternal and RelicSlots._is_active(od) == active):
			continue
		cells.append({"id": id, "name": UI3.player_text(String(od.name)),
			"kind": tr("Active") if RelicSlots._is_active(od) else tr("Passive"),
			"sell": RelicSlots.sell_price(id, RunState.ascension), "eternal": eternal})
	var rule := (tr("Active slots are full (%d of %d). Sell one to take the new relic.") if active
		else tr("Passive slots are full (%d of %d). Sell one to take the new relic.")) % [
		cells.size(), int(cap["active"] if active else cap["passive"])]
	var dsc := UI3.describe(RewardGenerator.relic_desc(nd))
	var sheet := UI3.slot_swap_sheet(tr("Make room"), UI3.player_text(String(nd.name)),
		("MP %d · " % int(dsc["mp"]) if int(dsc["mp"]) >= 0 else "") + String(dsc["text"]), rule, cells,
		false, func(sell_id: String) -> void:
			var ok := RunState.acquire_relic(key, "reward", sell_id)
			sheet_closed(ok, reward),
		func() -> void: sheet_closed(false, {}, true), 3 if active else 4)
	sheet.name = "SlotSwapSheet"
	_overlay_root.add_child(sheet)


## Closes the swap sheet. ok: the swap was made, so finish the pick. Otherwise the cards stay as they were.
func sheet_closed(ok: bool, reward: Dictionary, _left := false) -> void:
	var sh := _overlay_root.find_child("SlotSwapSheet", true, false)
	if sh != null:
		sh.get_parent().remove_child(sh)
		sh.queue_free()
	if ok:
		RunState.apply_chosen_reward(reward)
		_finish_node()


func _on_reward_reroll(title: String) -> void:
	var res: Dictionary = await RunState.request_reroll_pending_rewards()
	if not bool(res["ok"]):
		if String(res["code"]) not in ["illegal", "busy"]:
			NetNotice.show(self, String(res["code"]), _on_reward_reroll.bind(title))
		return
	_show_reward_overlay(title)


# ---------------------------------------------------------------------------------------
# SHOP
# ---------------------------------------------------------------------------------------

## Shop node: src/data.js genShop()/shopBuy() ported subset. The offer was built by
## RunState.enter_node(); this screen does not generate goods.
func _on_shop_node(_node_id: String) -> void:
	_render_shop()


## UI-03 08 Shop: left 384 (header + shards, Sell plate), middle (Relics / other goods in a
## 2-column grid of selectable cards), right 416 (detail + Buy, Leave shop). The offer was built by
## RunState.enter_node(); this screen only draws it. Sell uses RunState.sell_relic().
var _shop_sel := 0
var _shop_cards: Array[PanelContainer] = []

const _SHOP_ROW_H := 176.0
const _SHOP_ART := 128.0


func _shop_rarity(it: Dictionary) -> int:
	if String(it.get("kind", "")) == "relic":
		var def = RelicRegistry.get_def(String(it.get("key", "")))
		if def != null:
			return int(def.rarity)
	return int(it.get("rar", 0))


## Why item `i` cannot be bought right now, or "".
func _shop_block_reason(it: Dictionary) -> String:
	if bool(it.get("bought", false)):
		return tr("Sold out")
	var cost := int(it.get("cost", 0))
	if RunState.shards_this_run < cost:
		return tr("Need %d Shards") % cost
	return ""


func _render_shop() -> void:
	# Re-rendered after every purchase/sale, so this doubles as the shop's save point.
	_save_map_progress()
	var host := _open_ui3_screen()
	_shop_cards.clear()
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(margin)
	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 24)
	margin.add_child(root)

	# ---- Left: shop plate + Sell plate
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 384
	left.add_theme_constant_override("separation", 16)
	root.add_child(left)
	var hp := UI3.plate(&"plate")
	hp.name = "ShopHeader"
	left.add_child(hp)
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override("separation", 16)
	hp.add_child(hv)
	var hrow := HBoxContainer.new()
	hrow.add_theme_constant_override("separation", 16)
	hv.add_child(hrow)
	var ic := TextureRect.new()
	ic.texture = UI3.icon("node_shop")
	ic.custom_minimum_size = Vector2(48, 48)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hrow.add_child(ic)
	var tcol := VBoxContainer.new()
	hrow.add_child(tcol)
	tcol.add_child(UI3.label(tr("Shop"), "LabelScreenTitle"))
	tcol.add_child(UI3.label(tr("Row %d") % maxi(_current_row(), 0), "LabelMuted"))
	var pill := UI3.currency_pill([{"icon": "cur_shard", "value": str(RunState.shards_this_run)}])
	pill.name = "ShardsPill"
	hv.add_child(pill)

	var sp := UI3.plate(&"plate")
	sp.name = "SellPlate"
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(sp)
	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", 8)
	sp.add_child(sv)
	sv.add_child(UI3.label(tr("Sell"), "LabelTitle"))
	var sscroll := ScrollContainer.new()
	sscroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sv.add_child(sscroll)
	var slist := VBoxContainer.new()
	slist.name = "SellList"
	slist.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slist.add_theme_constant_override("separation", 8)
	sscroll.add_child(slist)
	var sellable := 0
	for rid in RunState.owned_relic_ids:
		if RunState.relic_stickers.get(rid, "") == RelicSlots.STICKER_ETERNAL:
			continue
		var def = RelicRegistry.get_def(String(rid))
		var price := RelicSlots.sell_price(String(rid), RunState.ascension)
		var sb := UI3.button("%s · +%d" % [String(def.name) if def != null else String(rid), price], &"secondary", &"S")
		sb.name = "Sell_%s" % rid
		sb.alignment = HORIZONTAL_ALIGNMENT_LEFT
		sb.clip_text = true
		sb.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		sb.pressed.connect(_on_shop_sell.bind(String(rid)))
		slist.add_child(sb)
		sellable += 1
	if sellable == 0:
		slist.add_child(UI3.label(tr("No relic to sell"), "LabelMuted"))

	# ---- Middle: goods
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 16)
	root.add_child(mid)
	var any_afford := false
	for it in RunState.shop_items:
		if not bool(it.get("bought", false)) and RunState.shards_this_run >= int(it.get("cost", 0)):
			any_afford = true
	if not any_afford and not RunState.shop_items.is_empty():
		var notice := UI3.plate(&"plate")
		notice.name = "NothingAffordable"
		notice.add_child(UI3.label(tr("You can't afford anything here. Sell a relic or leave."), "LabelTitle"))
		(notice.get_child(0) as Label).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		mid.add_child(notice)
	var groups := [["relic", tr("Relics")], ["", tr("Supplies")]]
	var idx_in_group := {}
	for g in groups:
		var idxs: Array[int] = []
		for i in RunState.shop_items.size():
			var is_relic: bool = String(RunState.shop_items[i].get("kind", "")) == "relic"
			if (g[0] == "relic") == is_relic:
				idxs.append(i)
		if idxs.is_empty():
			continue
		mid.add_child(UI3.label(g[1], "LabelScreenTitle"))
		var grid := GridContainer.new()
		grid.name = "ShopGrid_%s" % ("relic" if g[0] == "relic" else "supplies")
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 16)
		grid.add_theme_constant_override("v_separation", 16)
		mid.add_child(grid)
		for i in idxs:
			grid.add_child(_add_shop_row(RunState.shop_items[i], i))

	# ---- Right: detail + Leave
	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 416
	right.add_theme_constant_override("separation", 16)
	root.add_child(right)
	var dp := UI3.plate(&"plate")
	dp.name = "ShopDetail"
	dp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(dp)
	var dv := VBoxContainer.new()
	dv.name = "DetailCol"
	dv.add_theme_constant_override("separation", 16)
	dp.add_child(dv)
	var leave := UI3.button(tr("Leave shop"), &"secondary", &"M")
	leave.name = "LeaveShop"
	leave.pressed.connect(func() -> void: _finish_node())
	right.add_child(leave)

	if _shop_sel >= RunState.shop_items.size():
		_shop_sel = 0
	_select_shop(_shop_sel)
	if not any_afford or _shop_cards.is_empty():
		leave.grab_focus.call_deferred()
	elif _shop_sel < _shop_cards.size():
		_shop_cards[_shop_sel].grab_focus.call_deferred()


func _add_shop_row(raw: Dictionary, index: int) -> PanelContainer:
	var it: Dictionary = raw
	var rar := _shop_rarity(it)
	var accent := _rarity_color(rar)
	var bought := bool(it.get("bought", false))
	var cost := int(it.get("cost", 0))
	var afford := RunState.shards_this_run >= cost

	var card := UI3.plate(&"card")
	card.name = "ShopRow%d" % index
	card.custom_minimum_size = Vector2(0, _SHOP_ROW_H)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.focus_mode = Control.FOCUS_ALL
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.draw.connect(func() -> void:
		if card.has_focus():
			card.draw_style_box(UI3Theme.focus_style(UI3Theme.radius("l")), Rect2(Vector2.ZERO, card.size)))
	card.focus_entered.connect(card.queue_redraw)
	card.focus_exited.connect(card.queue_redraw)
	card.focus_entered.connect(_select_shop.bind(index))
	card.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			card.grab_focus()
			_select_shop(index)
		elif ev.is_action_pressed("ui_accept") and not ev.is_echo():
			_select_shop(index)
			var bb := _overlay_root.find_child("BuyButton", true, false) as Button
			if bb != null:
				bb.grab_focus())
	_shop_cards.append(card)
	card.set_meta("shop_index", index)
	if bought:
		card.modulate.a = 0.4

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	card.add_child(row)
	row.add_child(_shop_art(it, _SHOP_ART, accent))
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 8)
	row.add_child(col)
	var nm := UI3.label(String(it.get("title", "")), "LabelTitle")
	nm.name = "ItemName"
	nm.clip_text = true
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	col.add_child(nm)
	var rl := UI3.label(_rarity_name(rar))
	rl.name = "RarityLabel"
	rl.add_theme_color_override("font_color", accent)
	col.add_child(rl)
	var price := HBoxContainer.new()
	price.add_theme_constant_override("separation", 8)
	col.add_child(price)
	if bought:
		price.add_child(UI3.label(tr("Bought")))
	else:
		var si := TextureRect.new()
		si.texture = UI3.icon("cur_shard")
		si.custom_minimum_size = Vector2(28, 28)
		si.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		si.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		price.add_child(si)
		var pl := UI3.label(str(cost), "LabelTitle")
		pl.name = "Price"
		if not afford:
			pl.add_theme_color_override("font_color", UI3Theme.color("danger_text"))
		price.add_child(pl)
	return card


func _shop_art(it: Dictionary, px: float, accent: Color) -> Control:
	var art := Panel.new()
	art.name = "Art"
	art.custom_minimum_size = Vector2(px, px)
	art.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = UI3Theme.color("panel_raised")
	sb.border_color = accent
	sb.set_border_width_all(UI3Theme.stroke("selected"))
	sb.set_corner_radius_all(UI3Theme.radius("m"))
	art.add_theme_stylebox_override("panel", sb)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.add_child(c)
	var t := TextureRect.new()
	t.texture = CardArt.texture_for_shop(String(it.get("kind", "")), _shop_rarity(it))
	t.custom_minimum_size = Vector2(px * 0.7, px * 0.7)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(t)
	return art


func _select_shop(index: int) -> void:
	if _overlay_root == null or RunState.shop_items.is_empty():
		return
	_shop_sel = index
	for c in _shop_cards:
		c.theme_type_variation = "PanelCardSelected" if int(c.get_meta("shop_index")) == index else "PanelCard"   # no lift: it overlaps the grid heading
	var dv := _overlay_root.find_child("DetailCol", true, false) as VBoxContainer
	if dv == null or index >= RunState.shop_items.size():
		return
	for ch in dv.get_children():
		dv.remove_child(ch)
		ch.queue_free()
	var it: Dictionary = RunState.shop_items[index]
	var rar := _shop_rarity(it)
	var accent := _rarity_color(rar)
	var art := _shop_art(it, 200.0, accent)
	art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dv.add_child(art)
	var nm := UI3.label(String(it.get("title", "")), "LabelScreenTitle")
	nm.name = "DetailName"
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dv.add_child(nm)
	var rl := UI3.label(_rarity_name(rar))
	rl.add_theme_color_override("font_color", accent)
	dv.add_child(rl)
	var dsc := UI3.describe(String(it.get("desc", "")))
	var desc := UI3.label(("MP %d · " % int(dsc["mp"]) if int(dsc["mp"]) >= 0 else "") + String(dsc["text"]))
	desc.name = "DetailDesc"
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dv.add_child(desc)
	var why := _shop_block_reason(it)
	var buy := UI3.button(tr("Buy · %d Shards") % int(it.get("cost", 0)), &"primary", &"L")
	buy.name = "BuyButton"
	if why == "":
		buy.pressed.connect(func() -> void: _on_shop_buy(index))
	else:
		UI3.set_disabled_reason(buy, why)
	dv.add_child(buy)


func _on_shop_sell(relic_id: String) -> void:
	if RunState.sell_relic(relic_id):
		_render_shop()


func _on_shop_buy(index: int) -> void:
	# `bought` is marked inside try_buy_shop_item() now. Marking it here meant a replay, which
	# has no screen, left every item buyable forever.
	var res: Dictionary = await RunState.request_buy_shop_item(index)
	if not bool(res["ok"]) and String(res["code"]) not in ["illegal", "busy"]:
		NetNotice.show(self, String(res["code"]), _on_shop_buy.bind(index))
	_render_shop()   # rebuild so shard total / afford/bought states stay in sync


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


func _on_event_node(_node_id: String) -> void:
	if RunState.event_key.is_empty():
		push_error("RunMapController: no playable events in ContentDB - cannot resolve event node")
		_finish_node()
		return
	_event_opts = RunState.event_options()
	_event_sel = -1
	_build_event_screen(-1, "")


## `picked` < 0: choices. Otherwise the outcome: the other choices at 40%, `outcome` as the body.
func _build_event_screen(picked: int, outcome: String) -> void:
	var ev: Dictionary = ContentDB.events.get(RunState.event_key, {})
	var host := _open_ui3_screen()
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(center)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 48)
	center.add_child(row)

	var art := UI3.plate(&"plate")
	art.name = "EventArt"
	art.custom_minimum_size = Vector2(720, 720)
	row.add_child(art)
	var art_c := CenterContainer.new()
	art.add_child(art_c)
	var art_i := TextureRect.new()
	art_i.texture = UI3.icon("node_event")
	art_i.custom_minimum_size = Vector2(320, 320)
	art_i.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art_i.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art_c.add_child(art_i)

	var col := VBoxContainer.new()
	col.custom_minimum_size.x = 720
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 24)
	row.add_child(col)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 16)
	col.add_child(head)
	var hi := TextureRect.new()
	hi.texture = UI3.icon("node_event")
	hi.custom_minimum_size = Vector2(64, 64)
	hi.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hi.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	head.add_child(hi)
	var hc := VBoxContainer.new()
	head.add_child(hc)
	var title := UI3.label(String(ev.get("n", tr("Event"))), "LabelScreenTitle")
	title.name = "EventTitle"
	hc.add_child(title)
	hc.add_child(UI3.label(tr("Event · Row %d") % maxi(_current_row(), 0), "LabelMuted"))

	var body := UI3.label(outcome if picked >= 0 else String(ev.get("desc", "")))
	body.name = "EventBody"
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(body)

	_overlay_vbox = VBoxContainer.new()
	_overlay_vbox.name = "EventOptions"
	_overlay_vbox.add_theme_constant_override("separation", 12)
	col.add_child(_overlay_vbox)
	_event_cards.clear()
	for i in _event_opts.size():
		_add_event_option(_event_opts[i], i, picked)

	var acts := HBoxContainer.new()
	acts.alignment = BoxContainer.ALIGNMENT_END
	col.add_child(acts)
	var go := UI3.button(tr("Continue") if picked >= 0 else tr("Pick a choice"), &"primary", &"L")
	go.name = "EventAction"
	if picked >= 0:
		go.pressed.connect(func() -> void: _finish_node())
		go.grab_focus.call_deferred()
	else:
		UI3.set_disabled_reason(go, tr("Pick a choice"))
		go.pressed.connect(func() -> void: _on_event_choice(_event_sel))
		if not _event_cards.is_empty():
			_event_cards[0].grab_focus.call_deferred()
	acts.add_child(go)


var _event_cards: Array[PanelContainer] = []


func _select_event(index: int) -> void:
	_event_sel = index
	for c in _event_cards:
		c.theme_type_variation = "PanelCardSelected" if int(c.get_meta("opt")) == index else "PanelCard"
	var go := _overlay_root.find_child("EventAction", true, false) as Button
	if go != null and index >= 0 and index < _event_opts.size():
		UI3.clear_disabled_reason(go)
		go.text = tr("Choose")


func _add_event_option(raw: Dictionary, index: int, picked: int) -> Control:
	var card := UI3.plate(&"card")
	card.name = "EventOption%d" % index
	card.custom_minimum_size.y = 88
	_overlay_vbox.add_child(card)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 16)
	card.add_child(line)
	var ic := TextureRect.new()
	ic.texture = UI3.icon(String(_EVENT_FX_UI3.get(String(raw.get("fx", "")), "face_blank")))
	ic.custom_minimum_size = Vector2(56, 56)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	line.add_child(ic)
	var tc := VBoxContainer.new()
	tc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(tc)
	tc.add_child(UI3.label(String(raw.get("text", "")), "LabelTitle"))
	var d := UI3.label(String(raw.get("desc", "")))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tc.add_child(d)
	card.set_meta("opt", index)
	if picked >= 0:
		card.modulate.a = 1.0 if index == picked else 0.4
		return card
	_event_cards.append(card)
	card.focus_mode = Control.FOCUS_ALL
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.draw.connect(func() -> void:
		if card.has_focus():
			card.draw_style_box(UI3Theme.focus_style(UI3Theme.radius("l")), Rect2(Vector2.ZERO, card.size)))
	card.focus_entered.connect(card.queue_redraw)
	card.focus_exited.connect(card.queue_redraw)
	card.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			card.grab_focus()
			_select_event(index)
		elif ev.is_action_pressed("ui_accept") and not ev.is_echo():
			_select_event(index)
			var go := _overlay_root.find_child("EventAction", true, false) as Control
			if go != null:
				go.grab_focus())
	return card


func _on_event_choice(index: int) -> void:
	if index < 0:
		return
	var res: Dictionary = await RunState.request_choose_event_option(index)
	if not bool(res["ok"]):
		if String(res["code"]) not in ["illegal", "busy"]:
			NetNotice.show(self, String(res["code"]), _on_event_choice.bind(index))
		return
	_save_map_progress()   # the effect is already applied; quitting on the outcome must not hand it back
	_build_event_screen(index, String(res["msg"]))


# ---------------------------------------------------------------------------------------
# TREASURE
# ---------------------------------------------------------------------------------------

## Treasure (UI-03 13, round 2): closed chest + "Open chest", then the rewards (a real choice of
## pending rewards at rewardTier 1) with Shards pill and "Take and continue". The 3D chest is not
## built yet: the chest is the node_treasure icon. No Skip, no reroll here.
func _on_treasure_node(node_id: String) -> void:
	RunState.generate_treasure_rewards(node_id)
	_build_treasure(false)


func _build_treasure(opened: bool) -> void:
	var host := _open_ui3_screen()
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(center)
	var col := VBoxContainer.new()
	col.name = "TreasureColumn"
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 24)
	center.add_child(col)
	var chest := TextureRect.new()
	chest.name = "Chest"
	chest.texture = UI3.icon("node_treasure")
	chest.custom_minimum_size = Vector2(0, 256 if opened else 384)
	chest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	col.add_child(chest)
	var hrow := HBoxContainer.new()
	hrow.alignment = BoxContainer.ALIGNMENT_CENTER
	hrow.add_theme_constant_override("separation", 24)
	col.add_child(hrow)
	hrow.add_child(UI3.label(tr("A sealed Gene vault") if not opened else tr("Choose one"), "LabelScreenTitle"))
	hrow.add_child(UI3.currency_pill([{"icon": "cur_shard", "value": str(RunState.shards_this_run)}]))

	if not opened:
		var open := UI3.button(tr("Open chest"), &"primary", &"L")
		open.name = "OpenChest"
		open.pressed.connect(func() -> void: _build_treasure(true))
		var oc := HBoxContainer.new()
		oc.alignment = BoxContainer.ALIGNMENT_CENTER
		oc.add_child(open)
		col.add_child(oc)
		open.grab_focus.call_deferred()
		return

	if RunState.pending_rewards.is_empty():
		col.add_child(UI3.label(tr("The vault was empty.")))
		var cont := UI3.button(tr("Continue"), &"primary", &"L")
		cont.name = "TakeButton"
		cont.pressed.connect(func() -> void: _finish_node())
		col.add_child(cont)
		cont.grab_focus.call_deferred()
		return
	_overlay_vbox = HBoxContainer.new()
	_overlay_vbox.name = "TreasureCards"
	_overlay_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_overlay_vbox.add_theme_constant_override("separation", 32)
	col.add_child(_overlay_vbox)
	_reward_cards.clear()
	_reward_sel = 0
	var wide := RunState.pending_rewards.size() >= 4
	for reward in RunState.pending_rewards:
		_add_reward_card(reward, wide)
	var take := UI3.button(tr("Take and continue"), &"primary", &"L")
	take.name = "TakeButton"
	take.pressed.connect(_take_selected_reward)
	var tc := HBoxContainer.new()
	tc.alignment = BoxContainer.ALIGNMENT_CENTER
	tc.add_child(take)
	col.add_child(tc)
	_select_reward(0)
	_reward_cards[0].grab_focus.call_deferred()
