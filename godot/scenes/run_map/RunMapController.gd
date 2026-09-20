extends Node2D
## RunMap.tscn root — v2 UI redesign (docs/design-handoff-v2, "RUN MAP" / "RUN MAP · left rail
## and header" screens; mockup: Godot Run Flow v2.dc.html, MAP tab; problem fixed:
## "Run Map is pinned to the corner over bright art").
##
## v1 (pre-2026-09-20) laid the graph out in WORLD space (Node2D + Camera2D) and auto-framed a
## window of rows with a tweened camera. v2 replaces that with a FIXED SCREEN-SPACE layout: the
## whole board draws directly in the 1920x1080 design canvas at a fixed lane pitch
## (x 780/1150/1520) and row pitch (118px), windowed to the 7 rows around the player
## (3 behind, current, 3 ahead) — see _ROWS_BEHIND/_ROWS_AHEAD/_HERE_Y below. There is no
## Camera2D anymore: nothing pans or zooms, which is deliberate per the handoff (no new
## drag/scroll input is asked for, same reasoning the v1 file recorded for auto-framing).
##
## RunState.enter_node()/after_node() and their combat/event/shop/treasure branching are
## UNCHANGED — this file only ever reads RunState fields and calls those two existing methods
## exactly where the v1 code already did. The four overlays (reward/shop/event/treasure) are
## explicitly OUT OF SCOPE for this pass and are carried over verbatim below.
##
## REBUILD STRATEGY: unlike v1 (persistent per-node Buttons updated in place so a "?" -> icon
## reveal could crossfade), v2 fully rebuilds the node/edge/rail/header layers on every
## _refresh() call. The window slides every time current_row changes, so most nodes would need
## to move AND retint on every refresh anyway; a full rebuild is simpler and correct, at the
## cost of the v1 crossfade reveal (replaced by a flat fade-in of the whole map layer — see
## _refresh()). This is a deliberate deviation from v1's animation nuance, not an oversight.
##
## CLASSIFICATION LOGIC (_reachable_now_ids/_current_row/_node_tier/_is_fogged) is carried over
## BYTE-IDENTICAL from v1 — it is pure graph-row math, has nothing to do with screen-space
## layout, and tests/t_run_map_fog.gd pins it directly by name via .call(). Do not change its
## behaviour here; only the RENDERING built on top of it changed.

## node_type (RunMapNode.gd: "battle"|"elite"|"event"|"shop"|"treasure"|"boss") -> icon path.
const _NODE_ICON := {
	"battle": preload("res://assets/icons/node/battle.png"),
	"elite": preload("res://assets/icons/node/elite.png"),
	"boss": preload("res://assets/icons/node/boss.png"),
	"event": preload("res://assets/icons/node/event.png"),
	"shop": preload("res://assets/icons/node/merchant.png"),
	"treasure": preload("res://assets/icons/node/treasure.png"),
}

const _MAP_BG := preload("res://assets/backgrounds/origins/scene/5-crossroad.jpg")

# ── v2 screen-space board (handoff "RUN MAP" box: "lanes x 780/1150/1520 · row pitch 118 ·
# token 122 here/106 open/94 fog/80 done · disc 74/64/56/48") ──────────────────────────────
const _LANE_X := [780.0, 1150.0, 1520.0]
const _ROW_PITCH := 118.0
const _HERE_Y := 592.0            ## screen y of the CURRENT node's row (mockup ROWS.r4)
const _ROWS_BEHIND := 3           ## rows shown below/behind current (mockup r1..r3)
const _ROWS_AHEAD := 3            ## rows shown above/ahead of current (mockup r5..r7)

const _TOKEN_SIZE := {"here": 122.0, "open": 106.0, "fog": 94.0, "done": 80.0}
const _DISC_SIZE := {"here": 74.0, "open": 64.0, "fog": 56.0, "done": 48.0}
# The glyph itself is deliberately SMALLER than its disc (mockup: iconSize 50/44/-/30 against
# disc 74/64/56/48 — roughly 65-69% of the disc, not a full-bleed fill). Skipped for "fog",
# which shows a text "?" glyph instead, sized separately where it's built.
const _ICON_SIZE := {"here": 50.0, "open": 44.0, "done": 30.0}
const _TOKEN_RADIUS := {"here": 24, "open": 18, "fog": 18, "done": 18}
const _TOKEN_BORDER := {"here": 5, "open": 4, "fog": 4, "done": 4}
const _TOKEN_SHELF := {"here": 8.0, "open": 6.0, "fog": 4.0, "done": 4.0}
const _RING_INSET := 11.0
const _RING_BORDER := 5.0

# FLAGGED: the mockup's TONE_SKIP (an inert, never-visited sibling node — e.g. a branch the
# player didn't take) has no entry in DangoTheme.NODE_TONES (only battle/elite/event/merchant/
# treasure/visited/fog exist there). Added as "skip" to DangoTheme.NODE_TONES (see that file)
# rather than duplicated here, per this task's "add missing colours to DangoTheme" instruction.

const _EDGE_PAST := Color(0x4A / 255.0, 0x52 / 255.0, 0x5F / 255.0)   # walked history
const _EDGE_FOG := Color(0x24 / 255.0, 0x2A / 255.0, 0x34 / 255.0)    # everything else, dashed
const _EDGE_CASING_W := 14.0
const _EDGE_CORE_W := 6.0
const _EDGE_DASH := 6.0
const _EDGE_GAP := 7.0

# CONSISTENCY SWEEP 2026-09-20: _EDGE_LIVE, _MUTED, _FOG_INK and _TICK_INK used to duplicate
# DangoTheme.CREAM_HI / CAPTION_MUTED / MUTED_TEXT / INK_ON_SUCCESS hex-for-hex (two of the four
# said so in their own comment). Call sites now read the shared token directly instead of a
# second, locally-named copy of the same colour.
const _BOSS_RIBBON_RED := Color(0xC9 / 255.0, 0x30 / 255.0, 0x2B / 255.0)

const _LEAD_AXIE_TEX := {
	"plant": preload("res://assets/axie/back-plant.png"),
	"beast": preload("res://assets/axie/back-beast.png"),
	"aqua": preload("res://assets/axie/back-aqua.png"),
	"reptile": preload("res://assets/axie/back-reptile.png"),
	"bug": preload("res://assets/axie/back-bug.png"),
}
const _LEAD_AXIE_W := 132.0
const _LEAD_AXIE_BOB_PX := 6.0
const _LEAD_AXIE_BOB_SECONDS := 1.8   # half of the mockup's 3.6s loop

const _CLASS_PORTRAIT := {
	"plant": preload("res://assets/portraits/plant.png"),
	"beast": preload("res://assets/portraits/beast.png"),
	"aqua": preload("res://assets/portraits/aqua.png"),
	"reptile": preload("res://assets/portraits/reptile.png"),
	"bug": preload("res://assets/portraits/bug.png"),
	"bird": preload("res://assets/portraits/bird.png"),
}

@onready var _root: Control = %Root

var _graph: RunMapGraph = null
var _plate: TextureRect = null
var _edges_layer: Node2D = null
var _nodes_layer: Control = null
var _map_layer: Control = null
var _rail_root: Control = null
var _header_root: Control = null
var _lead_axie_root: Control = null
var _lead_axie_sprite: TextureRect = null
var _lead_axie_tween: Tween = null
var _node_visuals: Dictionary = {}   # node_id -> {"node": RunMapNode, "root": Button, "caption": Label|null}
var _ring_tweens: Array[Tween] = []   # the "here" ring's blink loop — killed on every rebuild so
	# a freed token's tween never lingers past its Control (Tween lifetime is NOT tied to the
	# node it animates in Godot 4; leaving this untracked leaked a Tween every _refresh()).


func _ready() -> void:
	EventBus.node_entered.connect(_on_node_entered)
	_graph = RunMapGraph.from_data(RunState.map_graph)

	_plate = DangoTheme.build_plate(_root, _MAP_BG, DangoTheme.Scrim.DEFAULT)

	_map_layer = Control.new()
	_map_layer.name = "MapLayer"
	_map_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_map_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_map_layer)

	_edges_layer = Node2D.new()
	_edges_layer.name = "Edges"
	_map_layer.add_child(_edges_layer)

	# FIXED 2026-09-20: LeadAxie used to be added AFTER Nodes (drawn on top of every token).
	# That is invisible in the common case — the axie's own vertical span sits entirely above
	# the current token's top edge and never overlaps ANY token when the board branches away
	# from the current node's lane — but on a straight (non-branching) lane segment, the row
	# directly ABOVE current can share its lane, and the axie's body (132-136px tall, taller
	# than the 118px row pitch) then reaches into that neighbour's token, covering it entirely
	# and reading as "two plates for one node". Nodes now draw ON TOP of the axie, so the board
	# — what the player actually has to read and click — always wins that overlap; the axie is
	# still fully visible in every case the mockup itself shows.
	_lead_axie_root = Control.new()
	_lead_axie_root.name = "LeadAxie"
	_lead_axie_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_lead_axie_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_layer.add_child(_lead_axie_root)

	_nodes_layer = Control.new()
	_nodes_layer.name = "Nodes"
	_nodes_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_nodes_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_layer.add_child(_nodes_layer)

	_rail_root = Control.new()
	_rail_root.name = "Rail"
	_rail_root.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	_rail_root.offset_left = 28.0
	_rail_root.offset_right = 28.0 + 344.0
	_rail_root.offset_top = 28.0
	_rail_root.offset_bottom = -28.0
	_root.add_child(_rail_root)

	_header_root = Control.new()
	_header_root.name = "Header"
	_header_root.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_header_root.offset_left = 396.0   # rail (28 + 344) + 24 gap
	_header_root.offset_right = -28.0
	_header_root.offset_top = 30.0
	_header_root.offset_bottom = 30.0 + 66.0
	_root.add_child(_header_root)

	_refresh(false)   # initial paint — no fade on first load

	_build_overlay_ui()
	# Post-combat reward cards, if any, take priority over normal map interaction — see
	# RunState._generate_post_combat_rewards()'s ordering note for why this scene (not
	# Combat.tscn) is where that overlay has to live.
	_maybe_show_pending_reward()


# ===========================================================================
# State refresh — the single "read RunState, redraw" entry point. v2 rebuilds every layer
# from scratch on each call (see file header REBUILD STRATEGY) rather than patching persistent
# nodes in place; the whole map is cheap to rebuild (at most ~15 tokens/edges in the window)
# and this keeps "current row changed -> everything's screen position changed anyway" simple.
# ===========================================================================

func _refresh(animate: bool = true) -> void:
	var current_row := _current_row()
	var reachable := _reachable_now_ids()
	_rebuild_edges(current_row, reachable)
	_rebuild_nodes(current_row, reachable)
	_rebuild_lead_axie(current_row)
	_rebuild_header(current_row)
	_rebuild_rail()

	if animate and is_inside_tree():
		_map_layer.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(_map_layer, "modulate:a", 1.0, 0.25).set_ease(Tween.EASE_OUT)
	else:
		_map_layer.modulate.a = 1.0


## Kills every looping Tween this screen owns. Godot 4 does not tie a Tween's lifetime to the
## node that created it, so leaving these running past this screen's own lifetime (scene change,
## or a test's queue_free()) is a real leak, not just a lint warning.
func _exit_tree() -> void:
	for tw in _ring_tweens:
		if tw != null and tw.is_valid():
			tw.kill()
	if _lead_axie_tween != null and _lead_axie_tween.is_valid():
		_lead_axie_tween.kill()


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


## `rel` (row offset from the current row) never changes lane — only vertical position. Column
## is clamped to the 3 lanes RunMapGenerator.MAX_WIDTH already caps every row at.
func _node_screen_pos(node: RunMapNode, current_row: int) -> Vector2:
	var lane := clampi(node.col, 0, _LANE_X.size() - 1)
	var rel := node.row - current_row
	return Vector2(_LANE_X[lane], _HERE_Y - float(rel) * _ROW_PITCH)


func _in_window(node: RunMapNode, current_row: int) -> bool:
	var rel := node.row - current_row
	return rel >= -_ROWS_BEHIND and rel <= _ROWS_AHEAD


# ===========================================================================
# Edges — drawn TWICE per the handoff: a solid 14px pure-black casing, then a 6px core that is
# either solid (cream "live", grey "past") or dashed (everything else — "fog"/"skip" share one
# style in the mockup, so this file does not distinguish them either).
# ===========================================================================

func _rebuild_edges(current_row: int, _reachable: Array) -> void:
	for c in _edges_layer.get_children():
		c.queue_free()
	if _graph == null:
		return
	for row in _graph.rows:
		for raw_node in row:
			var from_node: RunMapNode = raw_node
			if not _in_window(from_node, current_row):
				continue
			for next_id in from_node.next_ids:
				var to_node := _graph.find_node(next_id)
				if to_node == null or not _in_window(to_node, current_row):
					continue
				_draw_edge(from_node, to_node, current_row)


func _draw_edge(from_node: RunMapNode, to_node: RunMapNode, current_row: int) -> void:
	var a := _node_screen_pos(from_node, current_row)
	var b := _node_screen_pos(to_node, current_row)

	var casing := Line2D.new()
	casing.width = _EDGE_CASING_W
	casing.default_color = Color.BLACK
	casing.antialiased = true
	casing.points = PackedVector2Array([a, b])
	_edges_layer.add_child(casing)

	var color: Color
	var dashed := false
	if from_node.id == RunState.current_node_id:
		color = DangoTheme.CREAM_HI
	elif from_node.visited and to_node.visited:
		color = _EDGE_PAST
	else:
		color = _EDGE_FOG
		dashed = true

	if dashed:
		_draw_dashed_line(_edges_layer, a, b, color, _EDGE_CORE_W, _EDGE_DASH, _EDGE_GAP)
	else:
		var core := Line2D.new()
		core.width = _EDGE_CORE_W
		core.default_color = color
		core.antialiased = true
		core.points = PackedVector2Array([a, b])
		_edges_layer.add_child(core)


## Godot's Line2D has no native dash pattern — approximated with a run of short solid segments.
## Deterministic (no randomness), so it never jitters between redraws.
func _draw_dashed_line(parent: Node2D, a: Vector2, b: Vector2, color: Color, width: float,
		dash: float, gap: float) -> void:
	var delta := b - a
	var length := delta.length()
	if length < 0.01:
		return
	var dir := delta / length
	var t := 0.0
	while t < length:
		var seg_end := minf(t + dash, length)
		var seg := Line2D.new()
		seg.width = width
		seg.default_color = color
		seg.antialiased = true
		seg.points = PackedVector2Array([a + dir * t, a + dir * seg_end])
		parent.add_child(seg)
		t += dash + gap


# ===========================================================================
# Node tokens — a rounded plate (base + top 44% block + bottom 19% lip, pure-black outline,
# hard shelf) with the icon on its own cream disc, per the handoff. The interactive surface is
# a single flat, chromeless Button sized to the token; every decorative child on top of it has
# MOUSE_FILTER_IGNORE so clicks still reach the button underneath.
# ===========================================================================

func _rebuild_nodes(current_row: int, reachable: Array) -> void:
	for c in _nodes_layer.get_children():
		c.queue_free()
	for tw in _ring_tweens:
		if tw != null and tw.is_valid():
			tw.kill()
	_ring_tweens.clear()
	_node_visuals.clear()
	if _graph == null:
		return
	# The CURRENT node is built LAST (drawn on top of every other token) — FIXED 2026-09-20: on
	# a straight, non-branching lane, the row directly above/below current shares its lane, and
	# that neighbour's caption chip (which sits just below ITS OWN token) lands inside the
	# current token's rect (row pitch 118px is tighter than an open token's half-height + its
	# caption's height+gap). Building rows in plain ascending order let whichever row happened
	# to be iterated later win that overlap — usually NOT current — which read as a caption
	# belonging to the wrong node. Current's own plate/ring/caption must always be the thing on
	# top at its own position.
	var current_node: RunMapNode = null
	for row in _graph.rows:
		for raw_node in row:
			var node: RunMapNode = raw_node
			if not _in_window(node, current_row):
				continue
			if node.id == RunState.current_node_id:
				current_node = node
				continue
			_build_token(node, current_row, reachable)
	if current_node != null:
		_build_token(current_node, current_row, reachable)


func _build_token(node: RunMapNode, current_row: int, reachable: Array) -> void:
	var tier := _node_tier(node, current_row, reachable)
	var bucket := _visual_bucket(tier)
	var size: float = _TOKEN_SIZE[bucket]
	var disc_size: float = _DISC_SIZE[bucket]
	var center := _node_screen_pos(node, current_row)

	var tone_key: String
	if bucket == "fog":
		tone_key = "fog"
	elif bucket == "done":
		tone_key = "visited" if node.visited else "skip"
	else:
		tone_key = _tone_key_for_type(node.node_type)
	var tone: Array = DangoTheme.node_tone(tone_key)

	var btn := Button.new()
	btn.name = "Node_%s" % node.id
	btn.custom_minimum_size = Vector2(size, size)
	btn.size = Vector2(size, size)
	btn.position = center - Vector2(size, size) * 0.5
	btn.flat = true
	btn.focus_mode = Control.FOCUS_ALL if tier == "reachable" else Control.FOCUS_NONE
	btn.disabled = tier != "reachable"
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if tier == "reachable" \
		else Control.CURSOR_ARROW
	var blank := StyleBoxEmpty.new()
	for state_key in ["normal", "hover", "pressed", "disabled", "focus"]:
		btn.add_theme_stylebox_override(state_key, blank)
	btn.pressed.connect(func(): _on_node_pressed(node.id))
	_nodes_layer.add_child(btn)

	var plate := Panel.new()
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.size = Vector2(size, size)
	plate.clip_contents = true
	var sb := StyleBoxFlat.new()
	sb.bg_color = tone[0]
	sb.border_color = Color.BLACK
	sb.set_border_width_all(int(_TOKEN_BORDER[bucket]))
	sb.set_corner_radius_all(int(_TOKEN_RADIUS[bucket]))
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 0
	sb.shadow_offset = Vector2(0, _TOKEN_SHELF[bucket])
	plate.add_theme_stylebox_override("panel", sb)
	btn.add_child(plate)

	var top_band := ColorRect.new()
	top_band.color = tone[1]
	top_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_band.position = Vector2.ZERO
	top_band.size = Vector2(size, size * 0.44)
	plate.add_child(top_band)

	var lip_band := ColorRect.new()
	lip_band.color = tone[2]
	lip_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lip_band.position = Vector2(0, size * 0.81)
	lip_band.size = Vector2(size, size * 0.19)
	plate.add_child(lip_band)

	# Ring — spec: this MUST be toggled with `visible`, not modulate, because the blink tween
	# animates modulate:a continuously; hiding it via modulate alone would leave the tween
	# fighting a static alpha and eventually showing the ring on every node on the board.
	var ring := Panel.new()
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.position = Vector2(-_RING_INSET, -_RING_INSET)
	ring.size = Vector2(size + _RING_INSET * 2.0, size + _RING_INSET * 2.0)
	var ring_sb := StyleBoxFlat.new()
	ring_sb.bg_color = Color(0, 0, 0, 0)
	ring_sb.border_color = DangoTheme.PRIMARY
	ring_sb.set_border_width_all(int(_RING_BORDER))
	ring_sb.set_corner_radius_all(int(_TOKEN_RADIUS[bucket]) + int(_RING_INSET))
	ring.add_theme_stylebox_override("panel", ring_sb)
	ring.visible = bucket == "here"
	btn.add_child(ring)
	if ring.visible:
		var tw := create_tween()
		tw.set_loops()
		tw.tween_property(ring, "modulate:a", 0.4, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(ring, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_ring_tweens.append(tw)

	var disc_center := CenterContainer.new()
	disc_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	disc_center.size = Vector2(size, size)
	btn.add_child(disc_center)

	var disc := Panel.new()
	disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	disc.custom_minimum_size = Vector2(disc_size, disc_size)
	var disc_sb := StyleBoxFlat.new()
	disc_sb.border_color = Color.BLACK
	disc_sb.set_border_width_all(3)
	disc_sb.set_corner_radius_all(int(disc_size * 0.5))
	match bucket:
		"fog": disc_sb.bg_color = DangoTheme.WELL_DEEP
		"done": disc_sb.bg_color = DangoTheme.CREAM_TRACK if node.visited else DangoTheme.PANEL
		_: disc_sb.bg_color = DangoTheme.CREAM_RAISED
	disc.add_theme_stylebox_override("panel", disc_sb)
	disc_center.add_child(disc)

	if bucket == "fog":
		var q := DangoTheme.display_label("?", 32, DangoTheme.MUTED_TEXT)
		q.set_anchors_preset(Control.PRESET_FULL_RECT)
		q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		disc.add_child(q)
	else:
		# The icon is centred at a FIXED size smaller than the disc (_ICON_SIZE), not stretched
		# to fill it — FIXED 2026-09-20: a full-rect-anchored icon filled the entire disc edge to
		# edge, so the disc's own cream ring collapsed to a sliver behind the glyph and read as
		# "no disc at all" at normal viewing scale, which is exactly the failure the handoff
		# calls out by name ("the shipped glyphs ... vanish on a saturated fill" — they were
        # vanishing onto the disc instead of the plate, but the visual result was the same).
		var icon_wrap := CenterContainer.new()
		icon_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
		disc.add_child(icon_wrap)

		var icon := TextureRect.new()
		icon.texture = _NODE_ICON.get(node.node_type)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		# EXPAND_IGNORE_SIZE is required here: without it, TextureRect reports the source
		# texture's native pixel size as its OWN minimum size, and Godot's anchor layout will
		# not shrink a Control below its minimum size — so the icon renders at full native
		# resolution regardless of custom_minimum_size below (the bug this comment is here to
		# stop from recurring).
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.custom_minimum_size = Vector2(_ICON_SIZE[bucket], _ICON_SIZE[bucket])
		if bucket == "done":
			icon.modulate.a = 0.5 if node.visited else 0.32
		icon_wrap.add_child(icon)

	if bucket == "done" and node.visited:
		var tick := Panel.new()
		tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tick.position = Vector2(size - 23.0, size - 23.0)
		tick.size = Vector2(30, 30)
		var tick_sb := StyleBoxFlat.new()
		tick_sb.bg_color = DangoTheme.SUCCESS
		tick_sb.border_color = Color.BLACK
		tick_sb.set_border_width_all(3)
		tick_sb.set_corner_radius_all(15)
		tick.add_theme_stylebox_override("panel", tick_sb)
		# FLAGGED: a checkmark glyph (U+2713) renders fine in-editor but this repo's other
		# Label text stays plain ASCII elsewhere in this file (e.g. the fog "?"), so a plain V
		# avoids depending on the active font's glyph coverage for a single pixel of polish;
		# swap for "✓" if FONT_DISPLAY is confirmed to carry it.
		var mark := DangoTheme.display_label("V", 15, DangoTheme.INK_ON_SUCCESS)
		mark.set_anchors_preset(Control.PRESET_FULL_RECT)
		mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tick.add_child(mark)
		btn.add_child(tick)

	var caption: Label = null
	if bucket == "here" or bucket == "open":
		var text := "YOU ARE HERE" if bucket == "here" else \
			("MERCHANT" if node.node_type == "shop" else node.node_type.to_upper())
		var chip := PanelContainer.new()
		var chip_sb := StyleBoxFlat.new()
		chip_sb.bg_color = DangoTheme.PRIMARY if bucket == "here" else DangoTheme.CREAM_RAISED
		chip_sb.border_color = Color.BLACK
		chip_sb.set_border_width_all(3)
		chip_sb.set_corner_radius_all(9)
		chip_sb.shadow_color = Color(0, 0, 0, 0.45)
		chip_sb.shadow_size = 0
		chip_sb.shadow_offset = Vector2(0, 3)
		chip_sb.content_margin_left = 12.0
		chip_sb.content_margin_right = 12.0
		chip_sb.content_margin_top = 4.0
		chip_sb.content_margin_bottom = 4.0
		chip.add_theme_stylebox_override("panel", chip_sb)
		caption = DangoTheme.display_label(text, 14, DangoTheme.INK_ON_PRIMARY if bucket == "here" else DangoTheme.INK)
		chip.add_child(caption)
		_nodes_layer.add_child(chip)
		var min_size := chip.get_combined_minimum_size()
		chip.position = Vector2(center.x - min_size.x * 0.5, center.y + size * 0.5 + 9.0)

	_node_visuals[node.id] = {"node": node, "root": btn, "caption": caption}


func _on_node_pressed(id: String) -> void:
	if not _reachable_now_ids().has(id):
		return   # defensive — the button should already be disabled for any non-reachable node
	var entry: Dictionary = _node_visuals.get(id, {})
	var node: RunMapNode = entry.get("node")
	if node == null:
		return
	RunState.enter_node(id, node.node_type)


# ===========================================================================
# Lead Axie — NEW in v2: the party's lead Axie stands on the current node, back-view, bobbing.
# ===========================================================================

func _rebuild_lead_axie(current_row: int) -> void:
	for c in _lead_axie_root.get_children():
		c.queue_free()
	if _lead_axie_tween != null and _lead_axie_tween.is_valid():
		_lead_axie_tween.kill()
	_lead_axie_tween = null
	_lead_axie_sprite = null
	if RunState.current_node_id == "" or _graph == null:
		return   # bootstrap — nothing is "here" yet, nothing to stand on
	var current := _graph.find_node(RunState.current_node_id)
	if current == null:
		return
	var center := _node_screen_pos(current, current_row)
	# The "here" token's own TOP edge — the ground plane the lead Axie stands on. FIXED
	# 2026-09-20: this used to anchor from an offset copied from the mockup's raw CSS (a
	# `bottom:` value on a 0-height positioning div), and the sign came out wrong — the sprite's
	# BOTTOM ended up ~40px below this edge, sunk into the token instead of standing on it.
	# Anchoring both the shadow and the sprite's bottom edge directly to the token's top edge is
	# both simpler and exactly what "feet planted on the token's top edge" means.
	var token_top := center.y - _TOKEN_SIZE["here"] * 0.5

	var shadow_panel := Panel.new()
	shadow_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow_panel.size = Vector2(104, 20)
	shadow_panel.position = Vector2(center.x - 52.0, token_top - 20.0)
	var shadow_sb := StyleBoxFlat.new()
	shadow_sb.bg_color = Color(0, 0, 0, 0.42)
	shadow_sb.set_corner_radius_all(10)
	shadow_panel.add_theme_stylebox_override("panel", shadow_sb)
	_lead_axie_root.add_child(shadow_panel)

	var cls := _lead_axie_class()
	var tex: Texture2D = _LEAD_AXIE_TEX.get(cls)
	if tex == null:
		return   # no back-view art for this class at all — nothing sensible to draw
	var sprite := TextureRect.new()
	sprite.texture = tex
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE   # see _build_token()'s icon for why
	var tex_size := tex.get_size()
	var h := _LEAD_AXIE_W * (tex_size.y / maxf(tex_size.x, 1.0))
	sprite.size = Vector2(_LEAD_AXIE_W, h)
	sprite.position = Vector2(center.x - _LEAD_AXIE_W * 0.5, token_top - h)
	_lead_axie_root.add_child(sprite)
	_lead_axie_sprite = sprite

	var base_y := sprite.position.y
	_lead_axie_tween = create_tween()
	_lead_axie_tween.set_loops()
	_lead_axie_tween.tween_property(sprite, "position:y", base_y - _LEAD_AXIE_BOB_PX,
		_LEAD_AXIE_BOB_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_lead_axie_tween.tween_property(sprite, "position:y", base_y,
		_LEAD_AXIE_BOB_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## The roster's first entry is the "lead". FLAGGED: no back-view art exists for "bird" (only
## plant/beast/aqua/reptile/bug ship under assets/axie/) — falls back to "plant" rather than
## drawing nothing, same reasoning CardArt/_relic_art uses for an out-of-range rarity.
func _lead_axie_class() -> String:
	if RunState.roster.is_empty():
		return "plant"
	var hero_key := String(RunState.roster[0].get("hero_key", ""))
	var cls := String(ContentDB.heroes.get(hero_key, {}).get("cls", "plant"))
	if not _LEAD_AXIE_TEX.has(cls):
		return "plant"
	return cls


# ===========================================================================
# Header — "THE PATH" + subline on the left, the boss as a right-aligned ribbon.
# ===========================================================================

func _rebuild_header(current_row: int) -> void:
	for c in _header_root.get_children():
		c.queue_free()

	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 20)
	_header_root.add_child(row)

	var title_col := VBoxContainer.new()
	title_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(title_col)

	var title := DangoTheme.display_label("THE PATH", 44, DangoTheme.CREAM_RAISED)
	title_col.add_child(title)

	var sub := Label.new()
	sub.text = "Pick the next node. Fog lifts one row ahead."
	sub.add_theme_color_override("font_color", DangoTheme.TEXT)
	title_col.add_child(sub)

	if _graph == null or _graph.boss_rows.is_empty():
		return
	var final_row: int = _graph.boss_rows[_graph.boss_rows.size() - 1]
	var boss_row_nodes := _graph.get_row(final_row)
	if boss_row_nodes.is_empty():
		return
	var boss_node: RunMapNode = boss_row_nodes[0]
	var boss_key: String = RunState._boss_key_for_node(boss_node.id)
	var boss_name := String(ContentDB.bosses.get(boss_key, {}).get("n", "???"))
	var rows_away := maxi(final_row - current_row, 0)

	var ribbon := PanelContainer.new()
	ribbon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var ribbon_sb := StyleBoxFlat.new()
	ribbon_sb.bg_color = _BOSS_RIBBON_RED
	ribbon_sb.border_color = Color.BLACK
	ribbon_sb.set_border_width_all(4)
	ribbon_sb.set_corner_radius_all(16)
	ribbon_sb.shadow_color = Color(0, 0, 0, 0.55)
	ribbon_sb.shadow_size = 0
	ribbon_sb.shadow_offset = Vector2(0, 6)
	ribbon_sb.content_margin_left = 12.0
	ribbon_sb.content_margin_right = 18.0
	ribbon_sb.content_margin_top = 0.0
	ribbon_sb.content_margin_bottom = 0.0
	ribbon.add_theme_stylebox_override("panel", ribbon_sb)
	ribbon.custom_minimum_size = Vector2(0, 66)
	row.add_child(ribbon)

	var ribbon_row := HBoxContainer.new()
	ribbon_row.add_theme_constant_override("separation", 14)
	ribbon_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ribbon.add_child(ribbon_row)

	var icon_panel := Panel.new()
	icon_panel.custom_minimum_size = Vector2(44, 44)
	icon_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var icon_sb := StyleBoxFlat.new()
	icon_sb.bg_color = DangoTheme.DANGER
	icon_sb.border_color = Color.BLACK
	icon_sb.set_border_width_all(3)
	icon_sb.set_corner_radius_all(12)
	icon_panel.add_theme_stylebox_override("panel", icon_sb)
	var icon_center := CenterContainer.new()
	icon_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon_panel.add_child(icon_center)
	var icon_tex := TextureRect.new()
	icon_tex.texture = _NODE_ICON.get("boss")
	icon_tex.custom_minimum_size = Vector2(28, 28)
	icon_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE   # see _build_token()'s icon for why
	icon_center.add_child(icon_tex)
	ribbon_row.add_child(icon_panel)

	var text_col := VBoxContainer.new()
	text_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ribbon_row.add_child(text_col)

	var eyebrow := DangoTheme.display_label("ROW %d · %d ROWS AWAY" % [final_row, rows_away], 11, Color(1, 1, 1, 0.75))
	text_col.add_child(eyebrow)

	var name_lbl := DangoTheme.display_label(boss_name, 25, DangoTheme.CREAM_RAISED)
	text_col.add_child(name_lbl)


# ===========================================================================
# Left rail — ONE content-hugging card (run identity + stats + party + relics) with
# SAVE & QUIT pinned to the bottom by a flex spacer. Replaces v1's separate panels; the v1
# "THIS RUN" trail panel, daily-mission line and node-type legend are deliberately not
# rebuilt (handoff: "deleted in v2, do not rebuild").
# ===========================================================================

func _rebuild_rail() -> void:
	for c in _rail_root.get_children():
		c.queue_free()

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 12)
	_rail_root.add_child(vbox)

	var card := PanelContainer.new()
	card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	card.add_theme_stylebox_override("panel",
		DangoTheme.surface_style(DangoTheme.Surface.PANEL_DEEP, 18, 4, 7.0, Vector2(19, 18)))
	vbox.add_child(card)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 0)
	card.add_child(content)
	_build_rail_head(content)
	# Measured with only the head in `content` so this is the head's own height plus the card's
	# chrome (border/content margins) — BEFORE the scrollable section below adds anything.
	var card_and_head_h: float = card.get_combined_minimum_size().y

	# PARTY + RELICS: the card must still HUG this content when it fits (per the handoff, the
	# rail card must never stretch) — but the project owner has now permitted a real
	# ScrollContainer for the run states where it genuinely does not fit (a long relic list).
	# ScrollContainer, unlike every other Container here, does NOT propagate its child's
	# minimum size upward on its own — its own minimum size defaults to its `custom_minimum_size`
	# regardless of content — so it is sized explicitly below to whichever is smaller: the
	# content's own natural height (-> hugs, no scrollbar, matches the non-scrolling case
	# exactly) or the space actually left in the rail (-> caps height and scrolls).
	var scroll_inner := _build_rail_scrollable()
	var natural_h: float = scroll_inner.get_combined_minimum_size().y
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	# Explicit even though ScrollContainer defaults to true — every other v2 screen's scroll
	# sets this itself (consistency sweep 2026-09-20); leaving it implicit here was the one
	# outlier, not a different behaviour.
	scroll.clip_contents = true
	scroll.add_child(scroll_inner)
	content.add_child(scroll)
	DangoTheme.style_scrollbars(scroll)

	var rail_h: float = _rail_root.size.y if _rail_root.size.y > 0.0 else 1024.0
	var reserved_below := 52.0 + 12.0   # SAVE & QUIT button + the rail VBox's own separation
	var max_scroll_h: float = maxf(rail_h - card_and_head_h - reserved_below, 40.0)
	scroll.custom_minimum_size.y = minf(natural_h, max_scroll_h)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var save_quit := Button.new()
	save_quit.text = "SAVE & QUIT"
	save_quit.custom_minimum_size = Vector2(0, 52)
	save_quit.size_flags_vertical = Control.SIZE_SHRINK_END
	var sq_sb := StyleBoxFlat.new()
	sq_sb.bg_color = DangoTheme.PANEL_ON_ART
	sq_sb.border_color = Color.BLACK
	sq_sb.set_border_width_all(4)
	sq_sb.set_corner_radius_all(14)
	sq_sb.shadow_color = Color(0, 0, 0, 0.55)
	sq_sb.shadow_size = 0
	sq_sb.shadow_offset = Vector2(0, 6)
	for state_key in ["normal", "hover", "pressed", "disabled"]:
		save_quit.add_theme_stylebox_override(state_key, sq_sb)
	save_quit.add_theme_color_override("font_color", DangoTheme.TEXT_DIM)
	save_quit.pressed.connect(_on_save_and_quit_pressed)
	vbox.add_child(save_quit)


func _on_save_and_quit_pressed() -> void:
	RunState.save_run({})
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")


## The identity/stats half of the card — always fully visible, never scrolled.
func _build_rail_head(content: VBoxContainer) -> void:
	var head := HBoxContainer.new()
	content.add_child(head)
	# FLAGGED: no run-display-name field exists on RunState; this is flavour text (matches the
	# mockup + the game's Lunacia setting), not derived data.
	var run_name := DangoTheme.display_label("LUNACIA RUN", 28, DangoTheme.CREAM_RAISED)
	run_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(run_name)

	var mode_chip := PanelContainer.new()
	mode_chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mode_chip.add_theme_stylebox_override("panel",
		DangoTheme.solid_chip_style(DangoTheme.PRIMARY, 8, 3, Vector2(11, 4)))
	var mode_lbl := DangoTheme.display_label("%s · A%d" % [RunState.mode.to_upper(), RunState.ascension], 13, DangoTheme.INK_ON_PRIMARY)
	mode_chip.add_child(mode_lbl)
	head.add_child(mode_chip)

	var seed_lbl := DangoTheme.display_label("SEED %d" % RunState.run_seed, 12, DangoTheme.CAPTION_MUTED)
	content.add_child(seed_lbl)

	content.add_child(_spacer(17.0))

	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 14)
	content.add_child(stats_row)
	var total_rows := _graph.rows.size() if _graph != null else 0
	var stat_defs := [
		["POWER", str(RunState.power_level), DangoTheme.CREAM_RAISED],
		["ROW", "%d / %d" % [maxi(_current_row(), 0), total_rows], DangoTheme.CREAM_RAISED],
		["SHARD", str(RunState.shards_this_run), DangoTheme.CREAM_HI],
	]
	for i in stat_defs.size():
		if i > 0:
			var divider := ColorRect.new()
			divider.color = DangoTheme.primary_divider_alpha()
			divider.custom_minimum_size = Vector2(2, 40)
			stats_row.add_child(divider)
		var cell := VBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var value := DangoTheme.display_label(String(stat_defs[i][1]), 30, stat_defs[i][2])
		cell.add_child(value)
		var key := DangoTheme.display_label(String(stat_defs[i][0]), 11, DangoTheme.CAPTION_MUTED)
		cell.add_child(key)
		stats_row.add_child(cell)

	content.add_child(_rule(17.0, 15.0))

	var party_caption := DangoTheme.display_label("PARTY", 12, DangoTheme.CAPTION_MUTED)
	content.add_child(party_caption)
	content.add_child(_spacer(12.0))


## The PARTY + RELICS half — the part whose length depends on run state (roster size never
## changes mid-run, but owned_relic_ids grows). Returned unparented so the caller can measure
## its natural height before deciding whether it needs to sit inside a ScrollContainer.
func _build_rail_scrollable() -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)

	var party_col := VBoxContainer.new()
	party_col.add_theme_constant_override("separation", 10)
	col.add_child(party_col)
	for entry in RunState.roster:
		party_col.add_child(_build_party_row(entry))

	col.add_child(_spacer(17.0))
	col.add_child(_rule(0.0, 15.0))

	var relic_head := HBoxContainer.new()
	col.add_child(relic_head)
	var relic_caption := DangoTheme.display_label("RELICS", 12, DangoTheme.CAPTION_MUTED)
	relic_caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	relic_head.add_child(relic_caption)
	var relic_count := DangoTheme.display_label(str(RunState.owned_relic_ids.size()), 13, DangoTheme.CHIP_INK_ON_WELL)
	relic_head.add_child(relic_count)
	col.add_child(_spacer(12.0))

	var relic_col := VBoxContainer.new()
	relic_col.add_theme_constant_override("separation", 9)
	col.add_child(relic_col)
	for relic_id in RunState.owned_relic_ids:
		relic_col.add_child(_build_relic_row(relic_id))

	return col


func _spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


func _rule(margin_top: float, margin_bottom: float) -> Control:
	var wrap := VBoxContainer.new()
	wrap.add_child(_spacer(margin_top))
	var line := ColorRect.new()
	line.color = DangoTheme.primary_divider_alpha()
	line.custom_minimum_size = Vector2(0, 2)
	wrap.add_child(line)
	wrap.add_child(_spacer(margin_bottom))
	return wrap


func _build_party_row(entry: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 11)

	var hero_key := String(entry.get("hero_key", ""))
	var hero_def: Dictionary = ContentDB.heroes.get(hero_key, {})
	var cls := String(hero_def.get("cls", "plant"))

	var portrait_wrap := Control.new()
	portrait_wrap.custom_minimum_size = Vector2(46, 46)
	portrait_wrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER   # see the relic icon fix below
	portrait_wrap.clip_contents = true
	var portrait_bg := Panel.new()
	portrait_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var pbg_sb := StyleBoxFlat.new()
	pbg_sb.bg_color = DangoTheme.class_color(cls)
	pbg_sb.border_color = Color.BLACK
	pbg_sb.set_border_width_all(3)
	pbg_sb.set_corner_radius_all(13)
	portrait_bg.add_theme_stylebox_override("panel", pbg_sb)
	portrait_wrap.add_child(portrait_bg)
	var portrait_tex: Texture2D = _CLASS_PORTRAIT.get(cls)
	if portrait_tex != null:
		var portrait_img := TextureRect.new()
		portrait_img.texture = portrait_tex
		portrait_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		portrait_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE   # see _build_token()'s icon
		portrait_img.set_anchors_preset(Control.PRESET_FULL_RECT)
		portrait_wrap.add_child(portrait_img)
	row.add_child(portrait_wrap)

	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_col)

	var name_row := HBoxContainer.new()
	text_col.add_child(name_row)
	var name_lbl := DangoTheme.display_label(String(hero_def.get("n", hero_key)), 17, DangoTheme.CREAM_RAISED)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(name_lbl)

	# No live HP field persists on RunState.roster between nodes (the party rests fully between
	# fights in this build — see report). max_hp is base + this run's permanent bonus_hp;
	# hp == max_hp is therefore always accurate here, not a placeholder.
	var base_hp: int = int(entry.get("max_hp", 0))
	if base_hp <= 0:
		base_hp = int(hero_def.get("max_hp", 10))
	var max_hp: int = base_hp + int(entry.get("bonus_hp", 0))
	var hp_color := DangoTheme.hp_color(1.0)
	var hp_lbl := DangoTheme.display_label("%d/%d" % [max_hp, max_hp], 16, hp_color)
	name_row.add_child(hp_lbl)

	var bar_wrap := Panel.new()
	bar_wrap.custom_minimum_size = Vector2(0, 9)
	bar_wrap.clip_contents = true
	var bar_sb := StyleBoxFlat.new()
	bar_sb.bg_color = DangoTheme.WELL_DEEP
	bar_sb.border_color = Color.BLACK
	bar_sb.set_border_width_all(2)
	bar_sb.set_corner_radius_all(5)
	bar_wrap.add_theme_stylebox_override("panel", bar_sb)
	var bar_fill := ColorRect.new()
	bar_fill.color = hp_color
	bar_fill.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar_wrap.add_child(bar_fill)
	text_col.add_child(bar_wrap)

	var tier_chip := PanelContainer.new()
	tier_chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tier_chip.add_theme_stylebox_override("panel",
		DangoTheme.solid_chip_style(DangoTheme.PANEL_RAISED, 6, 2, Vector2(8, 2)))
	var tier_lbl := DangoTheme.display_label("T%d" % int(entry.get("tier", 1)), 12, DangoTheme.CHIP_INK_ON_WELL)
	tier_chip.add_child(tier_lbl)
	row.add_child(tier_chip)

	return row


func _build_relic_row(relic_id: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 11)

	var def = RelicRegistry.get_def(relic_id)
	var rarity := int(def.rarity) if def != null else 0
	var relic_name := String(def.name) if def != null else relic_id
	# FLAGGED: an owned relic id with no loaded RelicDef (not yet ported to a .tres) renders its
	# raw id as both name and description, per this task's "missing effect -> render the id"
	# instruction, rather than being silently dropped from the list.
	var relic_desc := String(def.description) if def != null else relic_id

	var icon_panel := Panel.new()
	icon_panel.custom_minimum_size = Vector2(34, 34)
	# Without this, HBoxContainer's default cross-axis SIZE_FILL stretches the icon to match
	# the row's full height (set by the wrapped description text, well over 34px) — a rounded
	# square becomes a tall pill. Same fix as the mode/tier chips elsewhere in this file.
	icon_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var icon_sb := StyleBoxFlat.new()
	icon_sb.bg_color = DangoTheme.rarity_color(rarity)
	icon_sb.border_color = Color.BLACK
	icon_sb.set_border_width_all(3)
	icon_sb.set_corner_radius_all(10)
	icon_panel.add_theme_stylebox_override("panel", icon_sb)
	var icon_center := CenterContainer.new()
	icon_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon_panel.add_child(icon_center)
	var icon_tex := TextureRect.new()
	icon_tex.texture = CardArt.texture_for_reward("relic", rarity)
	icon_tex.custom_minimum_size = Vector2(20, 20)
	icon_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE   # see _build_token()'s icon for why
	icon_center.add_child(icon_tex)
	row.add_child(icon_panel)

	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_col)
	var name_lbl := DangoTheme.display_label(relic_name.to_upper(), 14, DangoTheme.CREAM_RAISED)
	text_col.add_child(name_lbl)
	var desc_lbl := Label.new()
	desc_lbl.text = relic_desc
	# FIXED 2026-09-20: this was AUTOWRAP_WORD_SMART, which let one long effect string wrap to
	# 3-4 lines and push the row height (and every relic below it) far past the mockup's fixed
	# pitch — the mockup's own row is a single clipped line. No wrap, clipped with an ellipsis.
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	desc_lbl.clip_text = true
	desc_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	desc_lbl.add_theme_color_override("font_color", DangoTheme.CAPTION_MUTED)
	text_col.add_child(desc_lbl)

	return row


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
# Reward / event / shop / treasure overlays (checklist step 4, reward-system pass —
# design/gdd/godot-port-rule-spec.md §9). UNCHANGED from v1 per this task's explicit scope —
# the four overlays share one builder here and get restyled together in a separate pass.
# Built procedurally at runtime, same convention this file already uses for graph node/edge
# visuals, rather than hand-laying every card/button in RunMap.tscn — the number of reward
# cards/shop items/event options varies per node, so a static scene tree can't describe it.
# One shared dim+panel overlay is reused for all four flows; each flow just clears and
# repopulates its content VBox.
# ===========================================================================

const _OVERLAY_DIM_COLOR := Color(0, 0, 0, 0.68)
const _OVERLAY_PANEL_MIN_WIDTH := 620.0
const _CARD_SEPARATION := 14

var _overlay_dim: ColorRect
var _overlay_bg: TextureRect     # painted scene behind the dim — see _build_overlay_ui()
var _event_node_id: String = ""   # so the RESULT screen reuses the offer's own backdrop
var _overlay_vbox: VBoxContainer


func _build_overlay_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)

	# Scene backdrop, BEHIND the dim rather than instead of it. The dim is what keeps the panel
	# text legible; a painted backdrop on its own would sit directly under body copy and the
	# contrast would depend on which picture happened to be chosen. Sized to fill and keep its
	# aspect, so a 16:9 painting on a taller window crops rather than stretches.
	_overlay_bg = TextureRect.new()
	_overlay_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_overlay_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_overlay_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_bg.visible = false
	layer.add_child(_overlay_bg)

	_overlay_dim = ColorRect.new()
	_overlay_dim.color = _OVERLAY_DIM_COLOR
	_overlay_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay_dim.visible = false
	layer.add_child(_overlay_dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay_dim.add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", DangoTheme.panel_style(DangoTheme.BG_PANEL, 3, 12, 24.0))
	panel.custom_minimum_size = Vector2(_OVERLAY_PANEL_MIN_WIDTH, 0)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	_overlay_vbox = VBoxContainer.new()
	_overlay_vbox.add_theme_constant_override("separation", _CARD_SEPARATION)
	margin.add_child(_overlay_vbox)


## `backdrop` is the painted scene this node happens in, or null to keep the plain dim over the
## map (which is right for the post-combat reward: it resolves the fight the player is still
## looking at, and swapping in a different place would break that continuity).
func _open_overlay(backdrop: Texture2D = null) -> void:
	_overlay_bg.texture = backdrop
	_overlay_bg.visible = backdrop != null
	_overlay_dim.visible = true
	_clear_overlay_content()


## The map is the run's resting point: every node resolves back to it, and a save taken here
## carries no in-flight combat. Called from the handful of places that finish a step rather
## than from a timer, so the file is written when something actually changed.
func _save_map_progress() -> void:
	RunState.save_run({})


func _close_overlay() -> void:
	_overlay_dim.visible = false
	_overlay_bg.visible = false
	_overlay_bg.texture = null
	_clear_overlay_content()


## The scene an EVENT node happens in. Events are not class-flavoured, so there is no correct
## background to look up — but there is a correct way to choose one: deterministically, from
## the node id, exactly as CombatAudio picks a battle theme. A `randi()` here would make the
## same node in a replayed seed look different, and this port's entire RNG design exists so
## that a replayed seed is identical.
func _event_backdrop(node_id: String) -> Texture2D:
	var names := ["plant", "beast", "aqua", "reptile", "bug", "bird"]
	return BattleBackdrop.class_background(names[absi(node_id.hash()) % names.size()])


func _clear_overlay_content() -> void:
	for c in _overlay_vbox.get_children():
		c.queue_free()


func _add_overlay_title(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 26)
	lbl.add_theme_color_override("font_color", DangoTheme.TEXT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay_vbox.add_child(lbl)


func _add_overlay_body(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_color_override("font_color", DangoTheme.TEXT_DIM)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay_vbox.add_child(lbl)


## One "card": title (+ optional rarity chip) + desc + sub, with a right-aligned action
## button. Shared by reward cards, event option rows, shop item rows, and the treasure reveal
## continue-button — the exact fields shown differ per caller, so callers pass
## already-formatted strings.
##
## `rar` (runloop-ux-backlog P0-2): -1 means "no chip" (nothing currently calls it that way,
## but it keeps this a strictly-additive signature); every real reward/shop/event/treasure
## call site now passes the option's actual `rar` field (0..4) so every choice card shows the
## same rarity chip Result already had, at the screen where it actually changes a decision.
##
## `owned` (runloop-ux-backlog P0-1): a button for something the player has ALREADY bought.
## Godot has no such Button state, so this routes to DangoTheme.style_button(..., owned=true)
## instead of the plain disabled look — see that function's doc comment for why "bought"
## (permanent, a success) must not read identically to "can't afford it yet" (temporary).
## `owned` cards still pass button_disabled=true from the caller (nothing to re-buy), only the
## STYLE differs.
## Card illustration size. Big enough to read at a glance, small enough that the title and
## the text stay the thing the eye lands on first.
const _CARD_ART_PX := 72.0


## `art` is optional and NULL IS NORMAL. A reward the player can take must never depend on an
## image existing — an unmapped or missing illustration leaves the card exactly as it was, text
## only, rather than leaving a hole or refusing to draw the card at all.
func _add_card(title: String, desc: String, sub: String, button_text: String,
		button_disabled: bool, on_pressed: Callable, rar: int = -1, owned: bool = false,
		art: Texture2D = null) -> Button:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", DangoTheme.panel_style(DangoTheme.BG_PANEL_SOFT, 2, 8, 12.0))
	_overlay_vbox.add_child(card)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	card.add_child(row)

	if art != null:
		var thumb := TextureRect.new()
		thumb.texture = art
		thumb.custom_minimum_size = Vector2(_CARD_ART_PX, _CARD_ART_PX)
		# KEEP_ASPECT_COVERED, not STRETCH: these illustrations are square and painted to the
		# edge, so covering crops nothing meaningful, while stretching would distort every one
		# of them the moment the card's height changes.
		thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		thumb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(thumb)

	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_col)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	text_col.add_child(header)

	var title_lbl := Label.new()
	title_lbl.text = title
	title_lbl.add_theme_color_override("font_color", DangoTheme.PRIMARY)
	title_lbl.add_theme_font_size_override("font_size", 18)
	header.add_child(title_lbl)

	if rar >= 0:
		header.add_child(DangoTheme.rarity_chip(rar))

	var desc_lbl := Label.new()
	desc_lbl.text = desc
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_color_override("font_color", DangoTheme.TEXT)
	text_col.add_child(desc_lbl)

	if sub != "":
		var sub_lbl := Label.new()
		sub_lbl.text = sub
		sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sub_lbl.add_theme_color_override("font_color", DangoTheme.TEXT_DIM)
		text_col.add_child(sub_lbl)

	var btn := Button.new()
	btn.text = button_text
	btn.disabled = button_disabled
	btn.custom_minimum_size = Vector2(120, 0)
	DangoTheme.style_button(btn, true, false, null, owned)
	if not button_disabled:
		btn.pressed.connect(on_pressed)
	row.add_child(btn)
	return btn


func _add_continue_button(text: String, on_pressed: Callable) -> void:
	var btn := Button.new()
	btn.text = text
	DangoTheme.style_button(btn, true)
	btn.pressed.connect(on_pressed)
	_overlay_vbox.add_child(btn)


## Shown once, right after a won combat, before the player can interact with the map at all
## (RunState.pending_rewards was populated by apply_combat_result() before CombatView even
## changed scene to this one). If pending_rewards is somehow empty on arrival (e.g. an empty
## roster edge case — RewardGenerator's own "hp" fallback fill can only return {} then), the
## map still has to advance exactly once: after_node() is now ONLY ever called from
## _on_reward_chosen() (see RunState._generate_post_combat_rewards()'s ordering-fix note), so
## nothing else would ever call it for this node.
func _maybe_show_pending_reward() -> void:
	if RunState.pending_rewards.is_empty():
		if RunState.phase == RunState.RunPhase.REWARD:
			RunState.after_node()
			_refresh(true)
		return
	_show_reward_overlay("CHOOSE A REWARD")


## Shared by the post-combat reward overlay and the treasure node's own offer (both populate
## RunState.pending_rewards the same way — see RunState._set_pending_rewards()). Includes a
## REROLL button whenever RunState.reward_reroll_charges > 0 (src/engine.js rerollRewards(),
## engine.js:1163-1166).
## The crypt's own scene. `reptile` is the Origins Kit's bone chamber — the only painting in
## the set that reads as "inside something", which is what a vault needs; every other one is
## an outdoor biome. Named here rather than inlined so the reason travels with the choice.
static func _CRYPT_BACKDROP_TEXTURE() -> Texture2D:
	return BattleBackdrop.class_background("reptile")


## `backdrop` defaults to null so the post-combat reward keeps the plain dim over the map it
## is resolving; the treasure node passes its crypt, because that IS a place the player walked
## into.
func _show_reward_overlay(title: String, backdrop: Texture2D = null) -> void:
	_open_overlay(backdrop)
	_add_overlay_title(title)
	for reward in RunState.pending_rewards:
		var r: Dictionary = reward
		_add_card(String(r.get("title", "")), String(r.get("desc", "")), String(r.get("sub", "")),
			"TAKE", false, func(): _on_reward_chosen(r), int(r.get("rar", 0)), false,
			CardArt.texture_for_reward(String(r.get("t", "")), int(r.get("rar", -1))))
	if RunState.reward_reroll_charges > 0:
		_add_continue_button("REROLL (%d left)" % RunState.reward_reroll_charges,
			func(): _on_reward_reroll(title))


func _on_reward_chosen(reward: Dictionary) -> void:
	RunState.apply_chosen_reward(reward)
	_finish_node()


func _on_reward_reroll(title: String) -> void:
	RunState.reroll_pending_rewards()
	_show_reward_overlay(title)


## Event node: pick one of ContentDB.events at random, let the player choose 1 of its
## 2-3 options, apply the real effect (RunState.apply_event_fx()), show the result
## message, then finish the node (src/engine.js chooseNode() 'event' branch / eventDone()).
func _on_event_node(node_id: String) -> void:
	# WHICH event, and its stream, are RunState's (opened by enter_node). This screen only
	# draws the offer and reports which option was clicked — an index, never the option
	# itself, because the verifier re-derives the offer from the seed.
	if RunState.event_key.is_empty():
		push_error("RunMapController: no playable events in ContentDB — cannot resolve event node")
		_finish_node()
		return
	var ev: Dictionary = ContentDB.events[RunState.event_key]
	_event_node_id = node_id
	_open_overlay(_event_backdrop(node_id))
	_add_overlay_title("%s  %s" % [String(ev.get("icon", "")), String(ev.get("n", "EVENT"))])
	_add_overlay_body(String(ev.get("desc", "")))
	var opts := RunState.event_options()
	for i in opts.size():
		var o: Dictionary = opts[i]
		var index := i
		_add_card(String(o.get("text", "")), String(o.get("desc", "")), "", "CHOOSE", false,
			func(): _on_event_choice(index), RewardGenerator.event_option_rarity(o))


func _on_event_choice(index: int) -> void:
	var msg := RunState.choose_event_option(index)
	# Same backdrop as the offer that led here: the player has not moved, and a scene change
	# between choosing and seeing the outcome would read as a second, unrelated node.
	_save_map_progress()   # the effect is already applied; quitting on the RESULT screen must
		# not hand it back
	_open_overlay(_event_backdrop(_event_node_id))
	_add_overlay_title("RESULT")
	_add_overlay_body(msg)
	_add_continue_button("CONTINUE", func(): _finish_node())


## Shop node: src/data.js genShop()/shopBuy() ported subset (RewardGenerator.
## generate_shop_items(), real src/data.js prices). Items can be bought 0..N times each
## (never twice — `bought` flag), gated on RunState.shards_this_run.
func _on_shop_node(_node_id: String) -> void:
	# The offer was built by RunState.enter_node(); this screen does not generate goods.
	_render_shop()


func _render_shop() -> void:
	# Re-rendered after every purchase, so this doubles as the shop's save point: shards spent
	# and a relic gained must survive a quit even though the node is not finished.
	_save_map_progress()
	_open_overlay(BattleBackdrop.class_background("shop"))
	_add_overlay_title("CHIMERA MERCHANT")
	_add_overlay_body("Gene Shard: %d" % RunState.shards_this_run)
	for i in RunState.shop_items.size():
		var it: Dictionary = RunState.shop_items[i]
		var index := i
		var bought: bool = bool(it.get("bought", false))
		var afford: bool = RunState.shards_this_run >= int(it.get("cost", 0))
		var label := "BOUGHT" if bought else "BUY (%d)" % int(it.get("cost", 0))
		# runloop-ux-backlog P0-1: "bought" and "can't afford" used to share one disabled look
		# (button_disabled = bought or not afford, styled identically) — a player scanning fast
		# could not tell "you already own this" (permanent, a success) from "come back later"
		# (temporary). button_disabled stays the same OR (nothing to press either way); only
		# the STYLE now branches via _add_card's `owned` param.
		_add_card(String(it.get("title", "")), String(it.get("desc", "")), "",
			label, bought or not afford, func(): _on_shop_buy(index), int(it.get("rar", 0)), bought,
			CardArt.texture_for_shop(String(it.get("kind", "")), int(it.get("rar", -1))))
	_add_continue_button("DONE", func(): _finish_node())


func _on_shop_buy(index: int) -> void:
	# `bought` is marked inside try_buy_shop_item() now. Marking it here meant a replay, which
	# has no screen, left every item buyable forever.
	RunState.try_buy_shop_item(index)
	_render_shop()   # rebuild so shard total / afford/bought states stay in sync


## Treasure node: src/engine.js chooseNode() 'treasure' branch (engine.js:402) offers a real
## reward-choice pick at rewardTier=1, exactly like a combat reward — a PREVIOUS pass here
## simplified this to an instant single-card grant with no choice; that deviation is now
## fixed, using the same RunState.pending_rewards overlay the post-combat path uses.
func _on_treasure_node(node_id: String) -> void:
	RunState.generate_treasure_rewards(node_id)
	if RunState.pending_rewards.is_empty():
		_open_overlay(_CRYPT_BACKDROP_TEXTURE())
		_add_overlay_title("ANCIENT CRYPT")
		_add_overlay_body("The vault was empty.")
		_add_continue_button("CONTINUE", func(): _finish_node())
		return
	_show_reward_overlay("ANCIENT CRYPT", _CRYPT_BACKDROP_TEXTURE())
