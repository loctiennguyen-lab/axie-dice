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
	return MockupAssets.tex("assets/node/%s.png" % _tone_key_for_type(node_type))


## The map's plate: the mockup's `assets/bg/crossroad.jpg`.
const _MAP_BG_PATH := "assets/bg/crossroad.jpg"

# ── v2 board: the mockup's frame, fitted to the live region (MAP-13) ────────────
# `run-flow-v2.html` states the board as data on its own 1920x1080 canvas:
# `LANES = { l:780, c:1150, r:1520 }` and `ROWS = { r1:946 ... r7:238 }` (a flat 118px pitch),
# with the node the player stands on at r4 = 592.
#
# Those numbers are kept, but as a REFERENCE FRAME, not as canvas coordinates. The project runs
# `window/stretch/aspect="expand"` (restored 2026-09-20 evening), so the logical canvas keeps
# its 1920 width and GROWS VERTICALLY - a 2387x1540 window lays out in roughly 1920x1238. A y
# copied straight out of the mockup would pin the whole graph to the top 1080 and leave the rest
# of the screen as empty artwork, which is exactly the "graph sits in the upper-left third"
# defect. So `_node_screen_pos()` expresses the mockup position as a fraction of the mockup's
# own graph region and re-applies it to the live one.
#
# At 1920x1080 the two regions are identical by construction, so this reproduces the mockup
# pixel-for-pixel; on a taller window the rows spread and the lanes do not move (MAP-13: the
# canvas width is constant under `expand`, so horizontal placement is already invariant).
const _MOCK_CANVAS := Vector2(1920.0, 1080.0)
const _MOCK_LANE_X: Array[float] = [780.0, 1150.0, 1520.0]
## Empty States Spec §2C (Claude Design, 2026-09-21) re-cuts the rows: r1 946 · r2 822 · r3 698
## · r4 574 · r5 450 · r6 326 · r7 202 — a flat 124px pitch, r4 still the row the player stands
## on. The lanes do not move.
##
## The old 118 pitch did not fit its own contents. Two tokens on a straight lane overlapped by
## 16px even with the caption chip deleted entirely: 53 (half an open token) + 6 (its shelf)
## + 61 (half the here token) + 14 (the ring's outside footprint) = 134 > 118. With the chip in
## the vertical channel the overlap was 52px. 124 clears it — 53 + 6 + 61 + 0 = 120 — but ONLY
## together with §2A and §2B below: the chip has to leave the vertical channel and the ring has
## to stop sticking out. Raising the pitch alone cannot work, because keeping the chip under the
## token needs 170px a row and seven of those do not fit under 1080.
const _MOCK_HERE_Y := 574.0       ## mockup ROWS.r4 - the row the player is standing on
const _MOCK_ROW_PITCH := 124.0    ## r1..r7 at a flat 124px pitch
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
## Empty States Spec §2A — the node label chip: 30 tall, 10px clear of the token's right edge.
const _CHIP_H := 30.0
const _CHIP_GAP := 10.0
## Empty States Spec §2B: the ring is drawn INSIDE the token now. It used to sit at inset -11
## with a 3px black halo outside it, so it added 14px of footprint on every side — half of the
## row overlap the spec measured. Pulled in to +5, radius 19, border 4, and the black halo is
## deleted: the token's own 5px outline already is one, so the halo was a second black ring
## around a black ring.
##
## It loses nothing by moving in. The `here` token is already 16px bigger than an open one, with
## radius 24, a 5px outline and an 8px shelf — the orange ring only has to confirm which node
## you are on, not claim space to do it.
const _RING_INSET := -5.0         ## NEGATIVE = inside the token edge (was 11.0 = outside)
const _RING_BORDER := 4.0
const _RING_RADIUS := 19
const _RING_OUTLINE := 0.0        ## the black halo is gone; the token's own outline is it

# FLAGGED: the mockup's TONE_SKIP (an inert, never-visited sibling node - e.g. a branch the
# player didn't take) has no entry in DangoTheme.NODE_TONES (only battle/elite/event/merchant/
# treasure/visited/fog exist there). Added as "skip" to DangoTheme.NODE_TONES (see that file)
# rather than duplicated here, per this task's "add missing colours to DangoTheme" instruction.

# PADDING CONVENTION. A StyleBoxFlat's `content_margin` is measured from the box's OUTER edge
# and REPLACES the border width - it is not added to it. CSS measures `padding` from INSIDE the
# border. So every padding copied out of the mockup is written here as `border + padding`:
# `padding:19px` on a `4px` border is a content margin of 23, not 19. Getting this backwards
# costs exactly one border width of inset on every surface, which is small enough to survive a
# review and wrong on every panel at once.

# EDGES, back to the mockup's own two-pass stroke. `run-flow-v2.html` draws every edge TWICE:
# a `stroke="#000" stroke-width="14"` casing first, then a 6px coloured core on top of it,
# dashed `9 10` for the inert (skip) and fogged states. A 2026-09-19 pass replaced that with a
# single 4px line on the argument that the casing was "the loudest thing on the screen"; that
# argument was made against a prose restatement of this mockup, and the mockup itself has never
# said anything but 14-under-6. The casing is what makes an edge read as a drawn object rather
# than a hairline, and it is the same pure-black outline rule every other surface follows.
const _EDGE_PAST := Color(0x4A / 255.0, 0x52 / 255.0, 0x5F / 255.0)   # mockup EDGE_STYLE.past
# FLAGGED (token): the mockup's inert/fog edge stroke is #242A34, which DangoTheme has no name
# for. PANEL_RAISED (#262C36) is the nearest named tone - two points apart per channel - and is
# used rather than inlining a second hex literal here. Same missing token as the rail's tier
# chip, which the mockup also fills #242A34.
const _EDGE_CASING_W := 14.0
const _EDGE_CORE_W := 6.0
const _EDGE_DASH := 9.0
const _EDGE_GAP := 10.0

# CONSISTENCY SWEEP 2026-09-20: _EDGE_LIVE, _MUTED, _FOG_INK and _TICK_INK used to duplicate
# DangoTheme.CREAM_HI / CAPTION_MUTED / MUTED_TEXT / INK_ON_SUCCESS hex-for-hex (two of the four
# said so in their own comment). Call sites now read the shared token directly instead of a
# second, locally-named copy of the same colour.
const _BOSS_RIBBON_RED := Color(0xC9 / 255.0, 0x30 / 255.0, 0x2B / 255.0)

@onready var _root: Control = %Root

## The left rail, at the mockup's own inset: `top:28px; left:28px; width:344px; bottom:28px`.
## FLAGGED (conflict): UI law L1 in DangoTheme.gd/t_ui_laws.gd says nothing is positioned
## outside a 48px safe area, and 28 is not 48. The mockup is the source of truth for this
## screen (godot/CLAUDE.md, first section), so 28 is what is built; t_ui_laws will report the
## rail for L1 until somebody reconciles the two. Reported, not quietly rounded to 48.
const _RAIL_INSET := 28.0
const _RAIL_W := 344.0
## The header band, mockup `top:30px; left:396px; right:28px; height:66px`. 396 is the rail's
## own right edge (28 + 344) plus a 24px gap.
const _HEADER_GAP := 24.0
const _HEADER_TOP := 30.0
const _HEADER_H := 66.0

var _content: Control = null

var _graph: RunMapGraph = null
var _edges_layer: Node2D = null
var _nodes_layer: Control = null
var _map_layer: Control = null
var _board: Control = null   ## the full-canvas layout host, named `Content` - see _ready()
var _rail_root: Control = null
var _header_root: Control = null
var _node_visuals: Dictionary = {}   # node_id -> {"node": RunMapNode, "root": Button, "caption": Label|null}
var _ring_tweens: Array[Tween] = []   # the "here" ring's blink loop — killed on every rebuild so
	# a freed token's tween never lingers past its Control (Tween lifetime is NOT tied to the
	# node it animates in Godot 4; leaving this untracked leaked a Tween every _refresh()).


func _ready() -> void:
	# RunMap's scene root is a Node2D (CanvasLayer/Root holds the real Control tree - see the
	# file header), so DangoScreen.build(), which requires a Control host, is called on %Root
	# rather than on `self`.
	#
	# The shell is used HERE ONLY for its plate -> scrim stack. This screen is laid out at the
	# mockup's own 1920x1080 coordinates (rail inset 28, header at 396/30, lanes at
	# 780/1150/1520), and `built["content"]` is inset by DangoScreen.SAFE/RAIL_X and recentres
	# itself on resize - so every one of those numbers would land 48-84px away from where the
	# mockup puts it if it were parented there. `_board` below - named `Content` - is the real,
	# full-canvas layout host; the shell's own column stays in the tree, renamed `ShellContent`,
	# empty and click-through, because DangoScreen owns the node it returns.
	#
	# NO FOOTER BAR: `run-flow-v2.html`'s MAP screen has none. Its exit affordance is SAVE &
	# QUIT at the bottom of the rail, which is where _rebuild_rail() puts it (inside a Control
	# named `Footer`, so UI law L4's "the exit lives in a named footer, never loose on the art"
	# still has something to find).
	#
	# Still FLAGGED for whoever owns DangoScreen.gd next: this scene and Combat.tscn have Node2D
	# roots, so the shell cannot be called on `self`. Either give DangoScreen a Node2D-safe entry
	# point or migrate both roots to Control - that touches six load-bearing combat gates and is
	# its own pass, not a fold-in.
	EventBus.node_entered.connect(_on_node_entered)
	_graph = RunMapGraph.from_data(RunState.map_graph)

	# G2, 20 Sep 2026: DangoScreen.build() now takes this screen's OWN insets after `combat`.
	# The map's mockup is `top:28px; left:28px; bottom:28px` on every edge of the rail column,
	# so 28 is what the shell is told - not the shared RAIL_X/SAFE default of 84/48, which is
	# what had been quietly overriding thirteen screens' margins at once. `with_footer` stays
	# false: no mockup on this screen has a footer bar.
	var built := DangoScreen.build(_root, MockupAssets.tex(_MAP_BG_PATH),
		DangoTheme.Scrim.DEFAULT, false, false, _RAIL_INSET, _RAIL_INSET, _RAIL_INSET)
	_content = built["content"]
	# Renamed so the full-canvas host below can carry the name `Content`, which is what this
	# screen's content region actually is. DangoScreen owns the node it returns, so it is
	# renamed rather than removed.
	_content.name = "ShellContent"
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_board = Control.new()
	_board.name = "Content"
	_board.set_anchors_preset(Control.PRESET_FULL_RECT)
	_board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_board)

	_map_layer = Control.new()
	_map_layer.name = "MapLayer"
	_map_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_map_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_board.add_child(_map_layer)

	_edges_layer = Node2D.new()
	_edges_layer.name = "Edges"
	_map_layer.add_child(_edges_layer)

	_nodes_layer = Control.new()
	_nodes_layer.name = "Nodes"
	_nodes_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_nodes_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_layer.add_child(_nodes_layer)

	# Mockup: `top:28px; left:28px; width:344px; bottom:28px` on the 1920x1080 canvas.
	_rail_root = Control.new()
	_rail_root.name = "Rail"
	_rail_root.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	_rail_root.offset_left = _RAIL_INSET
	_rail_root.offset_right = _RAIL_INSET + _RAIL_W
	_rail_root.offset_top = _RAIL_INSET
	_rail_root.offset_bottom = -_RAIL_INSET
	_board.add_child(_rail_root)

	# Mockup: `top:30px; left:396px; right:28px; height:66px`.
	_header_root = Control.new()
	_header_root.name = "Header"
	_header_root.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_header_root.offset_left = _RAIL_INSET + _RAIL_W + _HEADER_GAP
	_header_root.offset_right = -_RAIL_INSET
	_header_root.offset_top = _HEADER_TOP
	_header_root.offset_bottom = _HEADER_TOP + _HEADER_H
	_board.add_child(_header_root)

	# Under `aspect="expand"` the canvas grows vertically, so the graph region - and every node
	# position fitted into it (MAP-13) - changes with the window. The rail also measures its own
	# height to decide whether the party/relic list needs to scroll. One cheap, un-animated
	# redraw covers both.
	get_viewport().size_changed.connect(func() -> void: _refresh(false))

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


## The rectangle the graph is laid out into: right of the rail, below the header band, inside
## the bottom inset. `size` is read live because `aspect="expand"` lets the canvas grow.
func _graph_region_for(canvas: Vector2) -> Rect2:
	var left := _RAIL_INSET + _RAIL_W + _HEADER_GAP
	var top := _HEADER_TOP + _HEADER_H
	return Rect2(left, top,
		maxf(canvas.x - _RAIL_INSET - left, 1.0),
		maxf(canvas.y - _RAIL_INSET - top, 1.0))


## The live canvas. `_board` is PRESET_FULL_RECT, so its size IS the logical viewport - but it
## is zero until the first layout pass, so the viewport is the fallback on the first paint.
func _canvas_size() -> Vector2:
	if _board != null and _board.size.x > 1.0 and _board.size.y > 1.0:
		return _board.size
	return get_viewport_rect().size


## The centre of a node's token, in canvas pixels (MAP-13).
##
## `rel` (row offset from the current row) never changes lane - only vertical position. Column
## is clamped to the 3 lanes RunMapGenerator.MAX_WIDTH already caps every row at.
##
## The mockup's own LANES/ROWS give the position inside the MOCKUP's graph region; that same
## fraction is then applied to the live region. Identical output at 1920x1080; on a taller
## canvas the rows spread to fill instead of leaving a void under the graph.
func _node_screen_pos(node: RunMapNode, current_row: int) -> Vector2:
	var lane := clampi(node.col, 0, _MOCK_LANE_X.size() - 1)
	var rel := node.row - current_row
	var window := _row_window(current_row)
	# The band is drawn CENTRED in the graph region, and the centre of a full band is the
	# current row — so at a full window this is `_MOCK_HERE_Y - rel * pitch`, the mockup's own
	# arithmetic, unchanged. (Not a coincidence worth trusting silently: the mock region is
	# y 96..1052, whose centre is 574, and 574 is exactly `_MOCK_HERE_Y`.) Near either end of
	# the run the band has slid, its centre is no longer the current row, and this is what
	# keeps the drawn rows filling the frame instead of hugging one edge of it.
	var centre_rel := float(window.x + window.y) * 0.5
	var mock := _graph_region_for(_MOCK_CANVAS)
	var mock_centre_y := mock.position.y + mock.size.y * 0.5
	var mock_pos := Vector2(_MOCK_LANE_X[lane],
		mock_centre_y - (float(rel) - centre_rel) * _MOCK_ROW_PITCH)
	var live := _graph_region_for(_canvas_size())
	var frac := (mock_pos - mock.position) / mock.size
	return live.position + frac * live.size


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


# ===========================================================================
# Edges - drawn in TWO PASSES, exactly as `run-flow-v2.html` draws them: every edge's 14px
# pure-black casing first, in one group, and only then every edge's 6px coloured core on top.
# One pass per edge (casing, core, next edge's casing, ...) is NOT the same picture: at a lane
# crossing the later edge's casing paints over the earlier edge's core and punches a black gap
# through a line the player is reading.
#
# EDGE_STYLE in the mockup is four entries: past (#4A525F solid), live (#FFC79B solid), and
# skip/fog (both #242A34, dashed `9 10`). Skip and fog share a style there, so they share one
# here too.
# ===========================================================================

func _rebuild_edges(current_row: int, _reachable: Array) -> void:
	for c in _edges_layer.get_children():
		c.queue_free()
	if _graph == null:
		return
	var edges: Array[Dictionary] = []
	for row in _graph.rows:
		for raw_node in row:
			var from_node: RunMapNode = raw_node
			if not _in_window(from_node, current_row):
				continue
			for next_id in from_node.next_ids:
				var to_node := _graph.find_node(next_id)
				if to_node == null or not _in_window(to_node, current_row):
					continue
				edges.append(_edge_spec(from_node, to_node, current_row))

	# Pass 1 - every casing. Always solid and always full width, including under a dashed core:
	# the mockup's casing path carries no `stroke-dasharray`.
	for e in edges:
		var casing := Line2D.new()
		casing.width = _EDGE_CASING_W
		casing.default_color = Color.BLACK
		casing.antialiased = true
		_round_caps(casing)
		casing.points = PackedVector2Array([e["a"], e["b"]])
		_edges_layer.add_child(casing)

	# Pass 2 - every core.
	for e in edges:
		if bool(e["dashed"]):
			_draw_dashed_line(_edges_layer, e["a"], e["b"], e["color"], _EDGE_CORE_W,
				_EDGE_DASH, _EDGE_GAP)
		else:
			var core := Line2D.new()
			core.width = _EDGE_CORE_W
			core.default_color = e["color"]
			core.antialiased = true
			_round_caps(core)
			core.points = PackedVector2Array([e["a"], e["b"]])
			_edges_layer.add_child(core)


## One edge's endpoints and core style. The mockup's own sample board is what pins the mapping:
## the step INTO the current node is drawn `past` (grey, solid), not highlighted - the live
## cream stroke is reserved for the branches leading OUT of it, which are the choices the player
## is actually being asked to make. A 2026-09-19 pass painted the incoming edge PRIMARY instead;
## that is the loudest colour in the system spent on the one edge that is already decided.
func _edge_spec(from_node: RunMapNode, to_node: RunMapNode, current_row: int) -> Dictionary:
	var a := _node_screen_pos(from_node, current_row)
	var b := _node_screen_pos(to_node, current_row)
	var color: Color
	var dashed := false
	if from_node.id == RunState.current_node_id:
		color = DangoTheme.CREAM_HI                    # EDGE_STYLE.live
	elif from_node.visited and (to_node.visited or to_node.id == RunState.current_node_id):
		color = _EDGE_PAST                             # EDGE_STYLE.past
	else:
		color = DangoTheme.PANEL_RAISED                # EDGE_STYLE.skip / .fog - see the token note
		dashed = true
	return {"a": a, "b": b, "color": color, "dashed": dashed}


## `stroke-linecap:round`, which the mockup sets once on the whole `<g>` and therefore applies
## to the casing, to a solid core AND to every dash of a dashed one. Godot spells it per end of
## a Line2D, and the default LINE_CAP_NONE ends a stroke in a hard rectangle - at 14px wide that
## reads as a square chip bitten out of the joint where an edge meets a node, on every edge.
func _round_caps(line: Line2D) -> void:
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND


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
		_round_caps(seg)
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
	# The CURRENT node is built LAST (drawn on top of every other token). This was FIXED
	# 2026-09-20 for a specific overlap — a neighbour's caption chip sitting below its own token
	# landed inside the current token's rect, and whichever row was iterated later won — and
	# that overlap is GONE as of Empty States Spec §2A: the chip now sits beside its token, out
	# of the vertical channel entirely. The ordering stays anyway, because "the node you are
	# standing on is the thing on top" is the right rule on its own merits and costs nothing.
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

	var border: int = int(_TOKEN_BORDER[bucket])
	var radius: int = int(_TOKEN_RADIUS[bucket])

	var plate := Panel.new()
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.size = Vector2(size, size)
	var sb := StyleBoxFlat.new()
	sb.bg_color = tone[0]
	sb.border_color = Color.BLACK
	sb.set_border_width_all(border)
	sb.set_corner_radius_all(radius)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 0
	sb.shadow_offset = Vector2(0, _TOKEN_SHELF[bucket])
	plate.add_theme_stylebox_override("panel", sb)
	btn.add_child(plate)

	# MAP-08's three flat blocks. In the mockup they are `inset:0` children of a plate with
	# `overflow:hidden`, so they live INSIDE the border and CSS clips them to its inner radius.
	#
	# They used to be full-size `ColorRect`s under `plate.clip_contents = true`, which is not the
	# same thing twice over: `clip_contents` clips to the plate's RECTANGLE, not to its rounded
	# stylebox, and the rects ran the full width so they covered the black border as well. Every
	# node on the map rendered as a hard-cornered, single-tone sticker — R4 and R2 in one line of
	# layout. They are styled panels inset by the border now, carrying the inner radius on the
	# two corners each one actually touches.
	var inner_side: float = maxf(size - border * 2.0, 0.0)
	var inner_radius: int = maxi(radius - border, 0)

	var top_band := Panel.new()
	top_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_band.position = Vector2(border, border)
	top_band.size = Vector2(inner_side, inner_side * 0.44)
	var top_sb := StyleBoxFlat.new()
	top_sb.bg_color = tone[1]
	top_sb.corner_radius_top_left = inner_radius
	top_sb.corner_radius_top_right = inner_radius
	top_band.add_theme_stylebox_override("panel", top_sb)
	plate.add_child(top_band)

	var lip_band := Panel.new()
	lip_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lip_band.size = Vector2(inner_side, inner_side * 0.19)
	lip_band.position = Vector2(border, border + inner_side - lip_band.size.y)
	var lip_sb := StyleBoxFlat.new()
	lip_sb.bg_color = tone[2]
	lip_sb.corner_radius_bottom_left = inner_radius
	lip_sb.corner_radius_bottom_right = inner_radius
	lip_band.add_theme_stylebox_override("panel", lip_sb)
	plate.add_child(lip_band)

	# Ring - Empty States Spec §2B: `inset:5px; border-radius:19px; border:4px solid #FF9345`,
	# no black halo. `ring_wrap` is kept as the node the blink tween drives (and as the seam for
	# an outline should one ever come back) but is now a zero-width pass-through, so the orange
	# ring lands 5px INSIDE the token edge and the whole thing has no footprint outside it.
	#
	# This MUST be toggled with `visible`, not modulate, because the blink tween animates
	# modulate:a continuously; hiding it via modulate alone would leave the tween fighting a
	# static alpha and eventually showing the ring on every node on the board.
	var ring_wrap := Panel.new()
	ring_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring_wrap.position = Vector2(-(_RING_INSET + _RING_OUTLINE), -(_RING_INSET + _RING_OUTLINE))
	var wrap_side := size + (_RING_INSET + _RING_OUTLINE) * 2.0
	ring_wrap.size = Vector2(wrap_side, wrap_side)
	var wrap_sb := StyleBoxFlat.new()
	wrap_sb.bg_color = Color(0, 0, 0, 0)
	wrap_sb.border_color = Color.BLACK
	wrap_sb.set_border_width_all(int(_RING_OUTLINE))
	wrap_sb.set_corner_radius_all(_RING_RADIUS + int(_RING_OUTLINE))
	ring_wrap.add_theme_stylebox_override("panel", wrap_sb)
	ring_wrap.visible = bucket == "here"
	btn.add_child(ring_wrap)

	var ring := Panel.new()
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.position = Vector2(_RING_OUTLINE, _RING_OUTLINE)
	ring.size = Vector2(size + _RING_INSET * 2.0, size + _RING_INSET * 2.0)
	var ring_sb := StyleBoxFlat.new()
	ring_sb.bg_color = Color(0, 0, 0, 0)
	ring_sb.border_color = DangoTheme.PRIMARY
	ring_sb.set_border_width_all(int(_RING_BORDER))
	ring_sb.set_corner_radius_all(_RING_RADIUS)
	ring.add_theme_stylebox_override("panel", ring_sb)
	ring_wrap.add_child(ring)

	if ring_wrap.visible:
		# Empty States Spec §2B: `1.8s ease-in-out`, opacity 1 <-> .35. Driven on the WRAPPER so
		# a future outline would blink with it rather than against it.
		var tw := create_tween()
		tw.set_loops()
		tw.tween_property(ring_wrap, "modulate:a", 0.35, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(ring_wrap, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
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
		icon.texture = _node_icon(node.node_type)
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
		# DRAWN, not typed. The mockup puts U+2713 here and none of this project's six fonts
		# carries that codepoint (their cmaps were read directly), so the build shipped a plain
		# letter "V" rather than a tofu box — and a "V" on a green disc reads as a letter, not
		# as "done" (bug report 2026-09-21, comparing the build against the mockup). A check
		# mark is two line segments; it does not need a font, and drawing it removes the whole
		# dependency on a glyph nobody ships. Waiting for a font with U+2713 was never the only
		# way out, it was just the first one considered.
		#
		# Points are in the badge's own 30x30 space, inside its 3px border. Round caps and a
		# round joint so the short arm does not end in a hard corner at this size.
		var mark := Line2D.new()
		mark.points = PackedVector2Array([Vector2(9.0, 15.5), Vector2(13.2, 20.0),
			Vector2(21.0, 10.5)])
		mark.width = 3.4
		mark.default_color = DangoTheme.INK_ON_SUCCESS
		mark.antialiased = true
		mark.begin_cap_mode = Line2D.LINE_CAP_ROUND
		mark.end_cap_mode = Line2D.LINE_CAP_ROUND
		mark.joint_mode = Line2D.LINE_JOINT_ROUND
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
		chip_sb.content_margin_left = 15.0   # `padding:0 12px` on a 3px border
		chip_sb.content_margin_right = 15.0
		chip_sb.content_margin_top = 4.0
		chip_sb.content_margin_bottom = 4.0
		chip.add_theme_stylebox_override("panel", chip_sb)
		chip.custom_minimum_size.y = _CHIP_H
		caption = DangoTheme.display_label(text, 14,
			DangoTheme.INK_ON_PRIMARY if bucket == "here" else DangoTheme.INK, 800, 0.08)
		chip.add_child(caption)
		_nodes_layer.add_child(chip)
		# Empty States Spec §2A: the chip moves OUT of the vertical channel to the token's right
		# edge, vertically centred, 10px from that edge (border included). Under the token it
		# cost 30 + 3 shelf + 9 gap of the row pitch and was the single largest contributor to
		# the 52px overlap; beside it, it costs none.
		#
		# It fits horizontally by measurement, not by hope: lanes are 370px apart, the widest
		# token is 122, leaving 248px of clear width. The widest chip ("YOU ARE HERE") is ~152px
		# and starts 71px from the token's centre, so it ends ~223px out — 94px short of the
		# next lane's token.
		var min_size := chip.get_combined_minimum_size()
		chip.position = Vector2(center.x + size * 0.5 + _CHIP_GAP,
			center.y - min_size.y * 0.5)

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
# Lead Axie — DELETED 2026-09-20 (FIX-PASS-03 G-03 / MAP-01).
#
# The decorative back-view Axie that stood bobbing on the current node is gone, along with
# its contact shadow. Player position is now carried by MAP-08's ring and MAP-10's
# `YOU ARE HERE` chip and by nothing else.
#
# This also closes, rather than works around, the geometry conflict that had been open in
# docs/design-handoff-v2/README.md: the sprite was 132px wide against a 118px row pitch and
# a 106px "open" token, so its ears overhung the neighbouring node on a straight lane. Two
# passes tried to fix that overlap (z-order, then a vertical clip that was reverted for
# erasing the sprite almost entirely). There is no overlap to arbitrate once the sprite is
# not drawn. Party art still appears in the rail, in Result and in combat.
# ===========================================================================

# ===========================================================================
# Header band - mockup `top:30px; left:396px; right:28px; height:66px`: "THE PATH" at Baloo 44
# with a Work Sans subline under it on the left, the boss ribbon right-aligned on the same
# 66px baseline.
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
	title_col.add_theme_constant_override("separation", 5)   # mockup: subline `margin-top:5px`
	row.add_child(title_col)

	var title := DangoTheme.display_label("THE PATH", 44, DangoTheme.CREAM_RAISED, 800, 0.01)
	# Mockup: `text-shadow: 0 3px 0 rgba(0,0,0,.6)` - the same hard shelf every surface uses,
	# on type. Godot spells it as a font shadow with an explicit 0 outline size, which is what
	# keeps it a solid offset copy rather than a blur.
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.add_theme_constant_override("shadow_outline_size", 0)
	title_col.add_child(title)

	# Mockup: `13px; font-weight:600; color:#EDF1F6; text-shadow:0 1px 3px rgba(0,0,0,.9)`.
	# Work Sans SemiBold via prose_label(), not the theme's default Medium - this line sits
	# directly on the painted plate, where the weight is most of what keeps it readable. Godot's
	# font shadow is hard-edged, so the 3px blur is spent as a 1px offset at the mockup's own
	# alpha, the same equivalence ResultView._screen_shadow() makes for the same declaration.
	var sub := DangoTheme.prose_label("Pick the next node. Fog lifts one row ahead.", 13,
		DangoTheme.TEXT, 600)
	sub.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	sub.add_theme_constant_override("shadow_offset_x", 0)
	sub.add_theme_constant_override("shadow_offset_y", 1)
	sub.add_theme_constant_override("shadow_outline_size", 0)
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

	# Mockup: height 66, `padding:0 18px 0 12px`, radius 16, 4px black, shelf `0 6px 0`, gap 14.
	var ribbon := PanelContainer.new()
	ribbon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var ribbon_sb := StyleBoxFlat.new()
	ribbon_sb.bg_color = _BOSS_RIBBON_RED
	ribbon_sb.border_color = Color.BLACK
	ribbon_sb.set_border_width_all(4)
	ribbon_sb.set_corner_radius_all(16)
	ribbon_sb.shadow_color = DangoTheme.SHELF_DEEP
	ribbon_sb.shadow_size = 0
	ribbon_sb.shadow_offset = Vector2(0, 6)
	ribbon_sb.content_margin_left = 12.0
	ribbon_sb.content_margin_right = 18.0
	ribbon_sb.content_margin_top = 0.0
	ribbon_sb.content_margin_bottom = 0.0
	ribbon.add_theme_stylebox_override("panel", ribbon_sb)
	ribbon.custom_minimum_size = Vector2(0, _HEADER_H)
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
	icon_tex.texture = _node_icon("boss")
	icon_tex.custom_minimum_size = Vector2(28, 28)
	icon_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE   # see _build_token()'s icon for why
	icon_center.add_child(icon_tex)
	ribbon_row.add_child(icon_panel)

	# R10 - the two lines are ONE block with NO gap between them. They were reading as an
	# eyebrow floating at the top of the 66px banner and a title sitting at its bottom, about
	# 14px apart, because this VBox took the theme's default separation and both labels then
	# added Baloo's own leading on top of it. The mockup sets the eyebrow at line-height:1 and
	# the title at 1.1, immediately under it, with no spacer at all.
	var text_col := VBoxContainer.new()
	text_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text_col.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	text_col.add_theme_constant_override("separation", 0)
	ribbon_row.add_child(text_col)

	# FLAGGED (token): the mockup inks this eyebrow #FFC3C0, a pale warm pink DangoTheme has no
	# name for. `ink_on()` on the ribbon's own red returns CREAM, which is the same idea from
	# the system's own vocabulary; the hex is reported rather than inlined here.
	var eyebrow := DangoTheme.display_label("ROW %d - %d ROWS AWAY" % [final_row, rows_away],
		11, DangoTheme.ink_on(_BOSS_RIBBON_RED), 800, 0.2)
	# R10: line-height 1 on the eyebrow, and LEFT - it was centring over the title because the
	# VBox stretches its children and the label then centred inside that width. The mockup's
	# block is `align-items:flex-start`, so the two lines share a left edge.
	eyebrow.add_theme_constant_override("line_spacing", 0)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	text_col.add_child(eyebrow)

	var name_lbl := DangoTheme.display_label(boss_name, 25, DangoTheme.CREAM_RAISED, 800, 0.02)
	name_lbl.add_theme_constant_override("line_spacing",
		DangoTheme.leading_for(DangoTheme.FONT_DISPLAY, 25, 1.1))   # R10: line-height 1.1
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	text_col.add_child(name_lbl)


# ===========================================================================
# Left rail - the mockup's own column: a content-hugging run card (identity, stats, party,
# relics), a flexible spacer, and SAVE & QUIT pinned to the bottom of the rail as its own
# object. A 2026-09-19 pass merged SAVE & QUIT into the card as an interior row; the mockup
# has never drawn it that way - `<div style="flex:1 1 auto">` then the button is exactly a
# spacer and a separate, bottom-pinned object, and that is what is rebuilt here.
#
# The v1 "THIS RUN" trail panel, daily-mission line and node-type legend stay deleted: the
# mockup's rail has none of them.
# ===========================================================================

func _rebuild_rail() -> void:
	for c in _rail_root.get_children():
		c.queue_free()

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 12)   # mockup: the rail column's `gap:12px`
	_rail_root.add_child(vbox)

	# Mockup: radius 18, 4px black, shelf `0 7px 0`, `padding:19px 19px 17px` - written as
	# 4+19 / 4+17, see the padding convention at the top of this file. surface_style() takes one
	# vertical pad for both edges, so the bottom is set after the fact.
	var card := PanelContainer.new()
	card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var card_sb := DangoTheme.surface_style(DangoTheme.Surface.PANEL_DEEP, 18, 4, 7.0,
		Vector2(23, 23))
	card_sb.content_margin_bottom = 21.0
	card.add_theme_stylebox_override("panel", card_sb)
	vbox.add_child(card)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 0)
	card.add_child(content)
	_build_rail_head(content)
	# Measured with only the head in `content` so this is the head's own height plus the card's
	# chrome (border/content margins) - BEFORE the scrollable section below adds anything.
	var card_and_head_h: float = card.get_combined_minimum_size().y

	# PARTY + RELICS. The mockup's card hugs its content and never scrolls, and at five roster
	# members and a normal relic count it does fit. A long relic list is the run state where it
	# stops fitting, and UI law L2 says a region that overflows shows a real scrollbar rather
	# than being sliced by the rail's bottom edge. ScrollContainer, unlike every other Container
	# here, does NOT propagate its child's minimum size upward - its own minimum size is just
	# `custom_minimum_size` - so it is sized explicitly below to whichever is SMALLER: the
	# content's natural height (-> hugs, no bar, pixel-identical to the non-scrolling case) or
	# the space actually left in the rail (-> caps and scrolls).
	var scroll_inner := _build_rail_scrollable()
	var natural_h: float = scroll_inner.get_combined_minimum_size().y
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.clip_contents = true
	# SIZE_EXPAND_FILL ON THE CHILD, and it has to be EXPAND — plain FILL does nothing here.
	# ScrollContainer is the one Container in Godot that does not stretch its child to its own
	# width on the non-scrolling axis unless the child asks to EXPAND; without this the child
	# is laid out at its own minimum width and the rest of the card is dead space. Measured at
	# 1920x1080: the ScrollContainer was 298 wide and its content 228, so every party row and
	# every relic row rendered 70px narrower than the header above them — the HP bars stopped
	# short, the relic rules wrapped a line early, and the RELICS divider ended in mid-air
	# while the divider under the stats (which is NOT in here) ran the full width. That
	# mismatch between two dividers in the same card is what the bug report saw as "Party và
	# Relics đang bị co lại quá" (2026-09-21).
	scroll_inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(scroll_inner)
	content.add_child(scroll)
	DangoTheme.style_scrollbars(scroll)

	var spacer := Control.new()
	spacer.name = "RailSpacer"
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# UI law L4 wants the screen's exit inside something named `Footer` rather than loose on the
	# art. The mockup gives this screen no footer BAR, so the rail's own bottom object is it.
	var footer := PanelContainer.new()
	footer.name = "Footer"
	footer.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	footer.size_flags_vertical = Control.SIZE_SHRINK_END
	vbox.add_child(footer)
	var save_quit := _build_save_quit_button()
	footer.add_child(save_quit)

	var rail_h: float = _rail_root.size.y if _rail_root.size.y > 0.0 else 1024.0
	# Everything below the scroll inside the rail column: the card -> spacer gap, the spacer ->
	# button gap (the rail's own 12px twice, since the flexible spacer is a real item between
	# them) and the 52px button itself.
	var reserved_below := 12.0 + 12.0 + save_quit.custom_minimum_size.y
	var max_scroll_h: float = maxf(rail_h - card_and_head_h - reserved_below, 40.0)
	scroll.custom_minimum_size.y = minf(natural_h, max_scroll_h)

	# `natural_h` above is measured BEFORE this frame has been laid out, and since R3 the relic
	# rule is a wrapping Label - which only knows its own height once something has given it a
	# width. Measured at width 0 it reports one word per line, which is taller than the real
	# two lines and would cap a list that fits into a scrollbar it does not need. Re-measure
	# once, deferred, after the layout pass; on every later rebuild the widths are already real
	# and this second pass lands on the same number. Guarded because _rebuild_rail() frees and
	# rebuilds this whole subtree on every _refresh().
	var remeasure := func() -> void:
		if not is_instance_valid(scroll) or not is_instance_valid(scroll_inner):
			return
		scroll.custom_minimum_size.y = minf(scroll_inner.get_combined_minimum_size().y,
			max_scroll_h)
	remeasure.call_deferred()


## SAVE & QUIT - mockup: height 52, radius 14, `rgba(27,31,39,.92)` (PANEL_ON_ART), 4px black,
## shelf `0 6px 0`, Baloo 16 at `letter-spacing:.18em` in #8C95A4 (MUTED_TEXT).
func _build_save_quit_button() -> Button:
	var save_quit := Button.new()
	save_quit.text = "SAVE & QUIT"
	save_quit.custom_minimum_size = Vector2(0, 60)   # mockup `height:52px;border:4px`
	save_quit.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	save_quit.add_theme_font_size_override("font_size", 16)
	DangoTheme.apply_tracking(save_quit, 0.18, 16)
	var sq_sb := StyleBoxFlat.new()
	sq_sb.bg_color = DangoTheme.PANEL_ON_ART
	sq_sb.border_color = Color.BLACK
	sq_sb.set_border_width_all(4)
	sq_sb.set_corner_radius_all(14)
	sq_sb.shadow_color = DangoTheme.SHELF_DEEP
	sq_sb.shadow_size = 0
	sq_sb.shadow_offset = Vector2(0, 6)
	for state_key in ["normal", "pressed", "disabled"]:
		save_quit.add_theme_stylebox_override(state_key, sq_sb)
	# Mockup hover: `color:#F3E7D3; background:#242A34`. PANEL_RAISED stands in for #242A34 -
	# see the edge-colour token note at the top of this file.
	var sq_hover := sq_sb.duplicate() as StyleBoxFlat
	sq_hover.bg_color = DangoTheme.PANEL_RAISED
	save_quit.add_theme_stylebox_override("hover", sq_hover)
	save_quit.add_theme_color_override("font_color", DangoTheme.MUTED_TEXT)
	save_quit.add_theme_color_override("font_hover_color", DangoTheme.CREAM)
	save_quit.add_theme_color_override("font_pressed_color", DangoTheme.CREAM)
	save_quit.pressed.connect(_on_save_and_quit_pressed)
	return save_quit


func _on_save_and_quit_pressed() -> void:
	RunState.save_run({})
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")


## The identity/stats half of the card - always fully visible, never scrolled.
func _build_rail_head(content: VBoxContainer) -> void:
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	content.add_child(head)
	# FLAGGED: no run-display-name field exists on RunState; this is flavour text (matches the
	# mockup + the game's Lunacia setting), not derived data.
	var run_name := DangoTheme.display_label("LUNACIA RUN", 28, DangoTheme.CREAM_RAISED, 800, 0.01)
	run_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(run_name)

	# Mockup: height 27 + a 3px border either side -> 33, `padding:0 11px` (-> 3+11), radius 8,
	# Baloo 13 on PRIMARY.
	var mode_chip := PanelContainer.new()
	mode_chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mode_chip.custom_minimum_size.y = 33.0
	mode_chip.add_theme_stylebox_override("panel",
		DangoTheme.solid_chip_style(DangoTheme.PRIMARY, 8, 3, Vector2(14, 3)))
	var mode_lbl := DangoTheme.display_label("%s - A%d" % [RunState.mode.to_upper(), RunState.ascension],
		13, DangoTheme.INK_ON_PRIMARY, 800, 0.06)
	mode_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mode_chip.add_child(mode_lbl)
	head.add_child(mode_chip)

	content.add_child(_spacer(7.0))   # mockup: seed line `margin-top:7px`
	var seed_lbl := DangoTheme.display_label("SEED %d" % RunState.run_seed, 12,
		DangoTheme.CAPTION_MUTED, 800, 0.14)
	content.add_child(seed_lbl)

	content.add_child(_spacer(17.0))

	# R11 - the rule is the CELL's own LEFT BORDER, not a bar drawn beside it.
	#
	# This used to be a ColorRect at `size_flags_vertical = SIZE_FILL` followed by a 14px
	# spacer. It drew as a ~40px stub next to the numerals instead of a full-height rule
	# spanning value AND caption, and the first of the two did not register at all, so POWER
	# and ROW read as one cell. A stretched sibling depends on the row resolving its height
	# before the ColorRect is measured; a border on the cell cannot get that wrong, because it
	# is painted by the cell it belongs to and is exactly as tall as the cell is.
	#
	# Same defect and same remedy as N23 on the Result ribbon.
	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 0)
	content.add_child(stats_row)
	var total_rows := _graph.rows.size() if _graph != null else 0
	var stat_defs := [
		["POWER", str(RunState.power_level), DangoTheme.CREAM_RAISED],
		["ROW", "%d / %d" % [maxi(_current_row(), 0), total_rows], DangoTheme.CREAM_RAISED],
		["SHARD", str(RunState.shards_this_run), DangoTheme.CREAM_HI],
	]
	for i in stat_defs.size():
		# The cell is a PanelContainer so it can carry its own left border + padding (R11).
		# Cell 1 gets neither; cells 2 and 3 get both.
		var cell_frame := PanelContainer.new()
		cell_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cell_sb := StyleBoxFlat.new()
		cell_sb.draw_center = false          # the rail's own fill shows through; only the rule
		cell_sb.border_color = DangoTheme.primary_divider_alpha()
		cell_sb.border_width_left = 2 if i > 0 else 0
		cell_sb.content_margin_left = 14.0 if i > 0 else 0.0
		cell_frame.add_theme_stylebox_override("panel", cell_sb)
		stats_row.add_child(cell_frame)

		var cell := VBoxContainer.new()
		cell.add_theme_constant_override("separation", 6)   # mockup: caption `margin-top:6px`
		cell_frame.add_child(cell)
		var value := DangoTheme.display_label(String(stat_defs[i][1]), 30, stat_defs[i][2])
		value.add_theme_constant_override("line_spacing", 0)   # R11: value line-height 1
		cell.add_child(value)
		var key := DangoTheme.display_label(String(stat_defs[i][0]), 11,
			DangoTheme.CAPTION_MUTED, 800, 0.14)
		cell.add_child(key)

	content.add_child(_rule(17.0, 15.0))

	var party_caption := DangoTheme.display_label("PARTY", 12, DangoTheme.CAPTION_MUTED, 800, 0.2)
	content.add_child(party_caption)
	content.add_child(_spacer(12.0))


## The PARTY + RELICS half - the part whose length depends on run state (roster size never
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
	var relic_caption := DangoTheme.display_label("RELICS", 12, DangoTheme.CAPTION_MUTED, 800, 0.2)
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
	wrap.add_theme_constant_override("separation", 0)
	wrap.add_child(_spacer(margin_top))
	var line := ColorRect.new()
	line.color = DangoTheme.primary_divider_alpha()
	line.custom_minimum_size = Vector2(0, 2)
	wrap.add_child(line)
	wrap.add_child(_spacer(margin_bottom))
	return wrap


# BORDER-BOX CONVENTION — the sibling of the PADDING one above, and it bit this rail on five
# surfaces at once. `run-flow-v2.html` sets no `box-sizing` anywhere (checked: the string does
# not appear in the file), so every `width`/`height` in it is a CONTENT box and its `border`
# adds OUTSIDE that. Godot draws a StyleBoxFlat's border INSIDE the Control's rect. So a
# mockup `height:23px; border:2px` is 27 rendered pixels and has to be written as 27 here —
# typing 23 gives a 19px interior and a chip four pixels short.
#
# Measured, not inferred: the party portrait reads 51px across in the reference capture
# (2900px wide, so 77 raw pixels / 1.5104), against the 46 this file was setting. 46 + 3 + 3
# = 52. Every number below carries its mockup source and its arithmetic.

## `line-height:1.1` — the ratio run-flow-v2.html states on the party name, the party HP number
## and the relic name. Kept as one constant so the three cannot drift apart.
const _RAIL_LINE_TIGHT := 1.1

## mockup `width:46px;height:46px;border:3px solid #000` -> 46 + 3 + 3.
const _PORTRAIT_TILE := 52.0
## See the long comment in _build_party_row(): the smallest inset whose square corners still
## fall inside the tile's OUTER curve, so the black frame drawn last repaints over them.
const _PORTRAIT_ART_INSET := 4.0


## One party row - mockup: 46px portrait tile (radius 13, 3px black), name 17 and HP 16 on one
## line, a 9px HP bar 5px under it, and a tier chip 23px tall on the right. Row gap 11.
func _build_party_row(entry: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 11)

	var hero_key := String(entry.get("hero_key", ""))
	var hero_def: Dictionary = ContentDB.heroes.get(hero_key, {})
	var cls := String(hero_def.get("cls", "plant"))

	# mockup `width:46px;height:46px;border:3px` -> 52 outer. See the BORDER-BOX note above.
	var portrait_wrap := Control.new()
	portrait_wrap.custom_minimum_size = Vector2(_PORTRAIT_TILE, _PORTRAIT_TILE)
	portrait_wrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER   # see the relic icon fix below
	var portrait_bg := Panel.new()
	portrait_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var pbg_sb := StyleBoxFlat.new()
	pbg_sb.bg_color = DangoTheme.class_color(cls)
	pbg_sb.border_color = Color.BLACK
	pbg_sb.set_border_width_all(3)
	pbg_sb.set_corner_radius_all(13)
	portrait_bg.add_theme_stylebox_override("panel", pbg_sb)
	portrait_wrap.add_child(portrait_bg)
	var portrait_tex: Texture2D = MockupAssets.tex("assets/portrait/%s.png" % cls)
	if portrait_tex != null:
		# INSET, and the black frame is re-drawn OVER it below. The art used to be a full-rect
		# child painted on top of `portrait_bg`, which is why the tile had no visible outline
		# along its bottom edge and its bottom corners came out square: an opaque, COVER-scaled
		# portrait simply painted over the border, and `clip_contents` clips to the RECT, so it
		# cannot round what it lets through. (Same fact DangoTheme.inner_radius()'s own comment
		# records: clipping is not a substitute for a radius.)
		#
		# How far in the art starts is geometry, not taste, and the first pass solved the
		# wrong inequality. The `frame` Panel below is drawn LAST with radius 13 and a 3px
		# black border, so it repaints the whole 10..13 annulus. The art therefore only has
		# to stay inside the OUTER curve (r = 13), not the inner one (r = 10):
		#   art corner (d, d) -> distance to the arc centre (13, 13) is (13 - d) * sqrt(2)
		#   (13 - d) * sqrt(2) <= 13  ->  d >= 13 * (1 - 1/sqrt(2)) = 3.81  ->  d = 4
		# The old value 6 solved for the inner curve and cost 2px of art on every side: 40px
		# of portrait in a 52px tile where the mockup shows 46. At 4 the art's corners land
		# under the frame's border and nothing pokes out of the tile's silhouette.
		#
		# Still a 2px deviation from the mockup, which fills the full 46 because CSS
		# `overflow:hidden` gives it a ROUNDED clip. Godot has that only via canvas groups
		# (`clip_children`), and those do not draw under the Compatibility renderer every QA
		# capture in this repo is taken through, so it could not be verified on a render.
		var art := Control.new()
		art.set_anchors_preset(Control.PRESET_FULL_RECT)
		art.offset_left = _PORTRAIT_ART_INSET
		art.offset_top = _PORTRAIT_ART_INSET
		art.offset_right = -_PORTRAIT_ART_INSET
		art.offset_bottom = -_PORTRAIT_ART_INSET
		art.clip_contents = true
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait_wrap.add_child(art)
		var portrait_img := TextureRect.new()
		portrait_img.texture = portrait_tex
		portrait_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		portrait_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE   # see _build_token()'s icon
		portrait_img.set_anchors_preset(Control.PRESET_FULL_RECT)
		art.add_child(portrait_img)
		# The outline, last, so nothing can paint over it. Border only — a fill here would hide
		# the portrait it is framing.
		var frame := Panel.new()
		frame.set_anchors_preset(Control.PRESET_FULL_RECT)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var frame_sb := StyleBoxFlat.new()
		frame_sb.bg_color = Color(0, 0, 0, 0)
		frame_sb.border_color = Color.BLACK
		frame_sb.set_border_width_all(3)
		frame_sb.set_corner_radius_all(13)
		portrait_wrap.add_child(frame)
		frame.add_theme_stylebox_override("panel", frame_sb)
	row.add_child(portrait_wrap)

	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text_col.add_theme_constant_override("separation", 5)   # mockup: HP bar `margin-top:5px`
	row.add_child(text_col)

	# FLAGGED: the mockup sets `align-items:baseline` on this line, so the 17px name and the
	# 16px HP number sit on ONE baseline. Godot's BoxContainer has no baseline alignment - only
	# begin/center/end on the cross axis - so they are centre-aligned here instead. The two
	# sizes are close enough that the drift is about a pixel, but it is a real deviation.
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	text_col.add_child(name_row)
	# `line-height:1.1` — the mockup states it on BOTH labels in this row, and it is the whole
	# difference between the rail the mockup draws and the loose one the build was drawing.
	# Baloo 2 reports a ~1.61em line box, so an unclamped 17px name occupies 27px where the
	# design asks for 19. Eight dead pixels a row, five rows, plus the same again in every relic
	# row — that is the "wasted band" this rail was reported for (2026-09-21).
	var name_lbl := DangoTheme.display_label(String(hero_def.get("n", hero_key)), 17, DangoTheme.CREAM_RAISED)
	var name_box := DangoTheme.line_box(name_lbl, 17, _RAIL_LINE_TIGHT)
	name_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(name_box)

	# No live HP field persists on RunState.roster between nodes (the party rests fully between
	# fights in this build - see report). max_hp is base + this run's permanent bonus_hp;
	# hp == max_hp is therefore always accurate here, not a placeholder.
	var base_hp: int = int(entry.get("max_hp", 0))
	if base_hp <= 0:
		base_hp = int(hero_def.get("max_hp", 10))
	var max_hp: int = base_hp + int(entry.get("bonus_hp", 0))
	var hp_color := DangoTheme.hp_color(1.0)
	var hp_lbl := DangoTheme.display_label("%d/%d" % [max_hp, max_hp], 16, hp_color)
	name_row.add_child(DangoTheme.line_box(hp_lbl, 16, _RAIL_LINE_TIGHT))

	# mockup `height:9px;border:2px` -> 13 outer. See the BORDER-BOX note above; at 9 the
	# bar rendered a 5px interior, which is why it read as a hairline next to the mockup's.
	var bar_wrap := Panel.new()
	bar_wrap.custom_minimum_size = Vector2(0, 13)
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
	# INSIDE the 2px border, which is where the mockup puts it: its `position:absolute;inset:0`
	# sits in the PADDING box of a bordered element, not over the border. Full-rect here paints
	# the fill across the border too — measured 13 green rows in a 13px bar, i.e. no outline at
	# all, which is the same "the art ate the frame" defect as the portrait above.
	bar_fill.offset_left = 2.0
	bar_fill.offset_top = 2.0
	bar_fill.offset_right = -2.0
	bar_fill.offset_bottom = -2.0
	bar_wrap.add_child(bar_fill)
	text_col.add_child(bar_wrap)

	# FLAGGED (token): the mockup fills this chip #242A34; PANEL_RAISED (#262C36) stands in.
	var tier_chip := PanelContainer.new()
	tier_chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tier_chip.custom_minimum_size.y = 27.0   # mockup `height:23px;border:2px`
	tier_chip.add_theme_stylebox_override("panel",
		DangoTheme.solid_chip_style(DangoTheme.PANEL_RAISED, 6, 2, Vector2(10, 2)))
	var tier_lbl := DangoTheme.display_label("T%d" % int(entry.get("tier", 1)), 12, DangoTheme.CHIP_INK_ON_WELL)
	tier_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tier_chip.add_child(tier_lbl)
	row.add_child(tier_chip)

	return row


## One relic row - mockup: a 34px rarity-filled tile (radius 10, 3px black) holding a 20px
## glyph, then the name at Baloo 14 over an 11px Work Sans effect line.
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

	# mockup `width:34px;height:34px;border:3px` -> 40 outer. See the BORDER-BOX note.
	var icon_panel := Panel.new()
	icon_panel.custom_minimum_size = Vector2(40, 40)
	# Without this, HBoxContainer's default cross-axis SIZE_FILL stretches the icon to match
	# the row's full height - a rounded square becomes a tall pill. Same fix as the chips above.
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
	text_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text_col.add_theme_constant_override("separation", 0)
	row.add_child(text_col)
	var name_lbl := DangoTheme.display_label(relic_name.to_upper(), 14,
		DangoTheme.CREAM_RAISED, 800, 0.04)
	# `line-height:1.1`, same reason as the party row — unclamped this pushed the description
	# 7px away from its own title and made every relic read as two unrelated lines.
	text_col.add_child(DangoTheme.line_box(name_lbl, 14, _RAIL_LINE_TIGHT))
	# R3, 20 Sep 2026. The mockup's row is `font-size:11px; font-weight:600; line-height:1.35;
	# color:#6F7887` with NO width cap and NO ellipsis - it WRAPS. The claim in the note this
	# replaces (that the mockup draws one clipped line) is not in the markup; the build shipped
	# "RULE: whenever you c..." and the review measured 261px of available width in the rail,
	# which fits the mockup's own two lines. The rail already caps and scrolls on genuine
	# overflow (_rebuild_rail()), so a long rule costs scroll, not a sliced word.
	var desc_lbl := DangoTheme.prose_label(relic_desc, 11, DangoTheme.CAPTION_MUTED, 600)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# `line-height:1.35` on an 11px line. leading_for() is the project's own conversion from a
	# CSS ratio to Godot's absolute `line_spacing` pixel constant - see DangoTheme.
	desc_lbl.add_theme_constant_override("line_spacing",
		DangoTheme.leading_for(DangoTheme.FONT_UI_SEMI, 11, 1.35))
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

## Reward card, mockup: `width:440px`, radius 20, 5px black, shelf `0 8px 0`, on CREAM.
const _REWARD_CARD_W := 440.0
const _REWARD_CARD_GAP := 28
## Shop panel, mockup: `top:58px; right:64px; width:1100px`.
const _SHOP_PANEL_W := 1100.0
const _SHOP_PANEL_TOP := 58.0
const _SHOP_MERCHANT_H := 520.0   ## SHP-01, mockup `height:520px`
const _SHOP_PANEL_RIGHT := 64.0
## Event option list, mockup: `top:398px; width:1040px`, centred, `gap:14px`.
const _EVENT_LIST_W := 1040.0
const _EVENT_LIST_TOP := 398.0
## Treasure, mockup: art 240 square and a 470-wide card, `gap:44px`, at `top:276px`.
## The gutter a centred header/row block is inset to - see _screen_header().
const _SCREEN_GUTTER := 80.0
const _TREASURE_ART := 240.0
const _TREASURE_CARD_W := 470.0
const _TREASURE_ROW_TOP := 276.0   ## TRS-01, the mockup's own `top:276px` for the pair

## Reward `t` -> the card's header-band kind label, the mockup's `w.kind` slot ("RELIC",
## "TIER UP"). Derived from reward_generator.gd's own seven `t` values; an unlisted type falls
## back to "REWARD" rather than to an empty band.
const _REWARD_KIND := {
	"relic": "RELIC", "level": "TIER UP", "ascend": "ASCEND", "hp": "MAX HP",
	"reroll": "REROLL", "chaos": "CHAOS DEAL", "curse": "CURSE PACT",
}

## Event option `fx` -> the glyph in its accent strip, the mockup's `o.icon` slot. FLAGGED: the
## option data in ContentDB.gd carries no icon field, so this table is authored here from each
## fx's own meaning, the same way reward_generator.gd's `_EVENT_FX_RARITY` is. Every path goes
## through MockupAssets, so an entry that stops resolving fails the asset gate rather than
## silently drawing nothing.
const _EVENT_FX_ICON := {
	"bless_reroll": "assets/fx/reroll.svg", "gamble_legend": "assets/fx/dmg.png",
	"pray": "assets/fx/heal.png", "rest": "assets/fx/heal.png", "forge": "assets/fx/dmg.png",
	"meditate": "assets/fx/mana.svg", "chest": "assets/fx/chest.png",
	"shards60": "assets/fx/shard.png", "bet_small": "assets/fx/shard.png",
	"bet_big": "assets/fx/shard.png", "shards30": "assets/fx/shard.png",
	"dip": "assets/fx/mana.svg", "drink": "assets/fx/mana.svg", "leave": "assets/fx/blank.svg",
}


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


## `backdrop` overrides the plate; a null means the mockup's own REWARD plate,
## `assets/bg/rocky.jpg`. Nothing in this file passes one today - the treasure node has its own
## screen now - but the parameter is kept so the entry point's signature does not move.
func _show_reward_overlay(title: String, backdrop: Texture2D = null) -> void:
	var plate: Texture2D = backdrop if backdrop != null else MockupAssets.tex("assets/bg/rocky.jpg")
	var host := _open_screen(plate)

	# Mockup: header block at `top:82px`, centred. Chip 38 tall, title 64 at `margin-top:14px`,
	# subline 15 at `margin-top:4px`.
	var head := _screen_header(host, 82.0, 0)
	head.add_child(_eyebrow_chip(_cleared_eyebrow(), DangoTheme.SUCCESS, 38.0, 16, 0.2))
	head.add_child(_spacer(14.0))
	var title_lbl := DangoTheme.display_label(title, 64, DangoTheme.CREAM_RAISED, 800, 0.02)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(title_lbl)
	head.add_child(_spacer(4.0))
	var sub := Label.new()
	sub.text = "Taking a reward ends the node. You keep it for the rest of the run."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 15)
	# FLAGGED (token): the mockup's subline ink is #A6B0BF; CHIP_INK_ON_WELL (#A9B3C2) is the
	# nearest named tone and is used rather than inlining a second hex.
	sub.add_theme_color_override("font_color", DangoTheme.CHIP_INK_ON_WELL)
	head.add_child(sub)

	# Mockup: the card row at `top:288px`, centred, `gap:28px`. `_overlay_vbox` is the card host
	# on every one of these screens; here the mockup lays the cards out ACROSS, so the box runs
	# horizontally (BoxContainer.vertical, which VBoxContainer only presets rather than seals).
	# RWD-02 — the three cards sit ACROSS, not stacked.
	#
	# This was a `VBoxContainer` with `vertical = false` set after construction. Godot refuses
	# that: `BoxContainer::set_vertical()` opens with `ERR_FAIL_COND_MSG(is_fixed, ...)`, and
	# both HBoxContainer and VBoxContainer are fixed — the assignment prints an error and leaves
	# the box vertical. The reward screen shipped as three full-width cards stacked down the
	# page, two of them off the bottom of the screen, which is the single furthest any screen in
	# this build was from its mockup. An HBoxContainer is a row by construction.
	_overlay_vbox = HBoxContainer.new()
	_overlay_vbox.name = "RewardRow"
	_overlay_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_overlay_vbox.add_theme_constant_override("separation", _REWARD_CARD_GAP)
	_overlay_vbox.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_overlay_vbox.grow_vertical = Control.GROW_DIRECTION_END
	_overlay_vbox.offset_left = _SCREEN_GUTTER    # see _screen_header() on the inset
	_overlay_vbox.offset_right = -_SCREEN_GUTTER
	_overlay_vbox.offset_top = 288.0
	_overlay_vbox.offset_bottom = 288.0
	host.add_child(_overlay_vbox)

	for reward in RunState.pending_rewards:
		var r: Dictionary = reward
		_add_reward_card(r)

	# Mockup: the footer row sits at `bottom:96px`, centred, `gap:13px`.
	# DECIDED 2026-09-21 by the project owner: NO SKIP BUTTON. Choosing a reward stays
	# mandatory. This was flagged as a gap - the mockup draws SKIP beside REROLL and this build
	# has no skip-a-reward path, because `RunState.after_node()` is only ever reached through
	# `_on_reward_chosen()`. The answer is that the mockup is wrong here, not the build: a skip
	# would need a new engine rule, and the owner does not want one. The button is not drawn,
	# and this is now a recorded decision rather than an open question - do not "restore" it
	# from the mockup on a later pass.
	if RunState.reward_reroll_charges > 0:
		var footer := HBoxContainer.new()
		footer.name = "RewardFooter"
		footer.alignment = BoxContainer.ALIGNMENT_CENTER
		footer.add_theme_constant_override("separation", 13)
		footer.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		footer.offset_left = _SCREEN_GUTTER        # see _screen_header() on the inset
		footer.offset_right = -_SCREEN_GUTTER
		footer.offset_top = -(96.0 + 56.0)
		footer.offset_bottom = -96.0
		host.add_child(footer)
		footer.add_child(_build_reroll_button(title))


## REROLL REWARDS - mockup: height 56, `padding:0 20px`, radius 13 on PANEL_RAISED, 4px black,
## shelf `0 5px 0`; a 21px glyph, the label at Baloo 18, and the charge count in a PRIMARY pill.
##
## A PanelContainer carries the look and a chromeless Button sits over it, rather than the
## Button carrying the look directly: a Button's minimum size comes from its own text and icon
## and ignores Control children entirely, so a Button holding this three-part row would report
## a minimum width of zero and collapse inside the centred footer.
func _build_reroll_button(title: String) -> Control:
	var wrap := PanelContainer.new()
	wrap.name = "RerollButton"
	wrap.custom_minimum_size.y = 56.0
	wrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var sb := StyleBoxFlat.new()
	sb.bg_color = DangoTheme.PANEL_RAISED
	sb.border_color = Color.BLACK
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(13)
	sb.shadow_color = DangoTheme.SHELF
	sb.shadow_size = 0
	sb.shadow_offset = Vector2(0, 5)
	sb.content_margin_left = 24.0   # mockup `padding:0 20px` on a 4px border
	sb.content_margin_right = 24.0
	wrap.add_theme_stylebox_override("panel", sb)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 11)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(row)

	row.add_child(_mockup_icon("assets/fx/reroll.svg", 21.0))
	var lbl := DangoTheme.display_label("REROLL REWARDS", 18, DangoTheme.CREAM, 800, 0.12)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(lbl)

	var count := PanelContainer.new()
	count.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	count.custom_minimum_size.y = 28.0
	count.add_theme_stylebox_override("panel",
		DangoTheme.solid_chip_style(DangoTheme.PRIMARY, 8, 2, Vector2(12, 2)))
	var count_lbl := DangoTheme.display_label("\u00d7%d" % RunState.reward_reroll_charges, 16,
		DangoTheme.INK_ON_PRIMARY)
	count_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count.add_child(count_lbl)
	row.add_child(count)

	var hit := _hit_button()
	hit.pressed.connect(func(): _on_reward_reroll(title))
	# Mockup hover on this control is a fill change (`background:#FF9345`), so it is swapped on
	# the panel the hit button covers rather than on the hit button itself.
	var hover := sb.duplicate() as StyleBoxFlat
	hover.bg_color = DangoTheme.PRIMARY
	hit.mouse_entered.connect(func(): wrap.add_theme_stylebox_override("panel", hover))
	hit.mouse_exited.connect(func(): wrap.add_theme_stylebox_override("panel", sb))
	wrap.add_child(hit)
	return wrap


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


## One reward card. Mockup: 440 wide, radius 20, 5px black, shelf `0 8px 0`; a 46px header band
## filled with the rarity colour (kind on the left, rarity on the right), then a 22/22/20 body
## holding a 132px icon tile, the name at 31, the description at 14 over a 84px floor, and the
## TAKE button at 60 tall.
func _add_reward_card(r: Dictionary) -> PanelContainer:
	var rar := int(r.get("rar", 0))
	var accent := DangoTheme.rarity_color(rar)
	var kind := String(_REWARD_KIND.get(String(r.get("t", "")), "REWARD"))

	var card := _cream_card(20, 5, 8.0)
	card.custom_minimum_size.x = _REWARD_CARD_W
	card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_overlay_vbox.add_child(card)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	card.add_child(col)

	var band := PanelContainer.new()
	band.custom_minimum_size.y = 46.0
	var band_sb := StyleBoxFlat.new()
	band_sb.bg_color = accent
	band_sb.border_color = Color.BLACK
	band_sb.border_width_bottom = 4
	# The band is full-bleed against the card's inner edge, and Godot's `clip_contents` clips to
	# a plain RECT rather than to the card's rounded one - so the band carries the card's own
	# inner radius (20 minus its 5px border) on its top corners itself.
	band_sb.corner_radius_top_left = 15
	band_sb.corner_radius_top_right = 15
	band_sb.content_margin_left = 16.0
	band_sb.content_margin_right = 16.0
	band.add_theme_stylebox_override("panel", band_sb)
	col.add_child(band)

	var band_row := HBoxContainer.new()
	band_row.add_theme_constant_override("separation", 10)
	band.add_child(band_row)
	var kind_lbl := DangoTheme.display_label(kind, 15, DangoTheme.ink_on(accent), 800, 0.14)
	kind_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kind_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	band_row.add_child(kind_lbl)
	var rar_lbl := DangoTheme.display_label(DangoTheme.rarity_name(rar).to_upper(), 14,
		DangoTheme.ink_on(accent), 800, 0.12)
	rar_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	band_row.add_child(rar_lbl)

	var body := MarginContainer.new()
	body.add_theme_constant_override("margin_left", 22)
	body.add_theme_constant_override("margin_right", 22)
	body.add_theme_constant_override("margin_top", 22)
	body.add_theme_constant_override("margin_bottom", 20)
	col.add_child(body)

	var body_col := VBoxContainer.new()
	body_col.add_theme_constant_override("separation", 0)
	body.add_child(body_col)

	# 132px icon tile on CREAM_RAISED, radius 30, 4px black, holding a 78px illustration.
	var tile := PanelContainer.new()
	tile.custom_minimum_size = Vector2(132, 132)
	tile.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tile.add_theme_stylebox_override("panel",
		DangoTheme.surface_style(DangoTheme.Surface.CREAM_RAISED, 30, 4, 0.0, Vector2(-1, -1)))
	body_col.add_child(tile)
	var tile_center := CenterContainer.new()
	tile.add_child(tile_center)
	tile_center.add_child(_tex_icon(
		CardArt.texture_for_reward(String(r.get("t", "")), rar), 78.0))

	body_col.add_child(_spacer(18.0))
	var name_lbl := DangoTheme.display_label(String(r.get("title", "")), 31, DangoTheme.INK,
		800, 0.02)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_col.add_child(name_lbl)

	body_col.add_child(_spacer(10.0))
	# The mockup gives this block `min-height:84px` so three cards of unequal copy still line
	# their TAKE buttons up. `sub` is folded into the same block - the mockup has one prose slot
	# per card, not two.
	var desc_text := String(r.get("desc", ""))
	var sub_text := String(r.get("sub", ""))
	if sub_text != "":
		desc_text += "\n" + sub_text
	var desc := Label.new()
	desc.text = desc_text
	desc.custom_minimum_size.y = 84.0
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 14)
	desc.add_theme_color_override("font_color", DangoTheme.INK_ON_CREAM_SOFT)
	body_col.add_child(desc)

	body_col.add_child(_spacer(14.0))
	var take := _flat_button("TAKE", DangoTheme.PRIMARY, 60.0, 20, 13, 0.16)
	take.pressed.connect(func(): _on_reward_chosen(r))
	body_col.add_child(take)
	return card


func _on_reward_chosen(reward: Dictionary) -> void:
	RunState.apply_chosen_reward(reward)
	_finish_node()


func _on_reward_reroll(title: String) -> void:
	RunState.reroll_pending_rewards()
	_show_reward_overlay(title)


# ---------------------------------------------------------------------------------------
# SHOP
# ---------------------------------------------------------------------------------------

## Shop node: src/data.js genShop()/shopBuy() ported subset. The offer was built by
## RunState.enter_node(); this screen does not generate goods.
func _on_shop_node(_node_id: String) -> void:
	_render_shop()


## Mockup: the merchant's plate bottom-left and one 1100-wide panel on the right holding a
## PRIMARY header (name, row line, shard purse), the item list, and LEAVE THE SHOP.
##
## FLAGGED: the mockup also stands a merchant creature (`assets/mon/dryad-mage.png`) beside
## that plate. Per this task's art rule the build keeps whatever creature its own merchant data
## chooses rather than the mockup's - and this build's merchant node has no creature at all
## (MonsterArt has no merchant entry; the shop is a node type, not an encounter). Drawing the
## The merchant sprite IS drawn (SHP-01) — see the comment at its TextureRect below for why the
## previous pass's reasoning for leaving it out did not hold.
func _render_shop() -> void:
	# Re-rendered after every purchase, so this doubles as the shop's save point: shards spent
	# and a relic gained must survive a quit even though the node is not finished.
	_save_map_progress()
	var host := _open_screen(MockupAssets.tex("assets/bg/shop.jpg"))

	# SHP-01's merchant. Mockup: `left:84px; bottom:110px; height:520px; object-fit:contain`.
	#
	# This was left out of the last pass on the reading that drawing it would be "taking the
	# mockup's art". It is not: `assets/mon/dryad-mage.png` is a path into THIS repo's own set
	# (`assets/monsters/dryad-mage.png`, which `MockupAssets` already resolves and
	# `t_mockup_assets.gd` already gates). The shop had a speech bubble with nobody speaking it
	# and 800px of empty plate beside it — which reads as a missing asset, which is what it was.
	var merchant := TextureRect.new()
	merchant.name = "MerchantArt"
	merchant.texture = MockupAssets.tex("assets/mon/dryad-mage.png")
	merchant.mouse_filter = Control.MOUSE_FILTER_IGNORE
	merchant.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	merchant.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	merchant.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	merchant.grow_vertical = Control.GROW_DIRECTION_BEGIN
	merchant.offset_left = 84.0
	merchant.offset_right = 84.0 + _SHOP_MERCHANT_H
	merchant.offset_top = -(110.0 + _SHOP_MERCHANT_H)
	merchant.offset_bottom = -110.0
	host.add_child(merchant)

	# Mockup: `left:78px; bottom:44px; width:372px; padding:14px 16px`, radius 14 on PANEL.
	var speech := PanelContainer.new()
	speech.name = "MerchantPlate"
	speech.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	# Height comes from the content, and the plate is pinned by its BOTTOM edge, so it has to
	# grow upward from it - a zero-height box anchored to the bottom otherwise clamps to its
	# minimum size by pushing its bottom edge off the canvas.
	speech.grow_vertical = Control.GROW_DIRECTION_BEGIN
	speech.grow_horizontal = Control.GROW_DIRECTION_END
	speech.offset_left = 78.0
	speech.offset_right = 78.0 + 372.0
	speech.offset_bottom = -44.0
	speech.offset_top = -44.0
	var speech_sb := DangoTheme.surface_style(DangoTheme.Surface.PANEL, 14, 4, 5.0,
		Vector2(20, 18))   # mockup `padding:14px 16px` on a 4px border
	speech.add_theme_stylebox_override("panel", speech_sb)
	host.add_child(speech)
	var speech_col := VBoxContainer.new()
	speech_col.add_theme_constant_override("separation", 5)
	speech.add_child(speech_col)
	var speech_head := DangoTheme.display_label("CHIMERA MERCHANT", 14, DangoTheme.MUTED_TEXT,
		800, 0.2)
	speech_head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speech_col.add_child(speech_head)
	var quote := Label.new()
	quote.text = "\"Genes for shards. No refunds, no questions.\""
	quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quote.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quote.add_theme_font_size_override("font_size", 14)
	quote.add_theme_color_override("font_color", DangoTheme.INFO_TEXT_ON_WELL)
	speech_col.add_child(quote)

	# Mockup: `top:58px; right:64px; width:1100px`, radius 20 on PANEL, 5px black, shelf 7.
	var panel := PanelContainer.new()
	panel.name = "ShopPanel"
	panel.clip_contents = true
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	# Width is pinned (1100, right edge 64 in); height comes from the content and grows DOWN
	# from the 58px top edge.
	panel.grow_vertical = Control.GROW_DIRECTION_END
	panel.offset_left = -(_SHOP_PANEL_RIGHT + _SHOP_PANEL_W)
	panel.offset_right = -_SHOP_PANEL_RIGHT
	panel.offset_top = _SHOP_PANEL_TOP
	panel.offset_bottom = _SHOP_PANEL_TOP
	# 5px of content margin, matching the border: the PRIMARY header band below is full-bleed
	# and would otherwise paint over the panel's own black outline.
	var panel_sb := DangoTheme.surface_style(DangoTheme.Surface.PANEL, 20, 5, 7.0,
		Vector2(5, 5))
	panel_sb.content_margin_bottom = 5.0
	panel.add_theme_stylebox_override("panel", panel_sb)
	DangoTheme.clip_to_frame(panel)   # G3
	host.add_child(panel)

	var panel_col := VBoxContainer.new()
	panel_col.add_theme_constant_override("separation", 0)
	panel.add_child(panel_col)
	panel_col.add_child(_build_shop_header())

	# Body: `padding:18px 20px`, item rows at `gap:11px`.
	var body := MarginContainer.new()
	body.add_theme_constant_override("margin_left", 20)
	body.add_theme_constant_override("margin_right", 20)
	body.add_theme_constant_override("margin_top", 18)
	body.add_theme_constant_override("margin_bottom", 18)
	panel_col.add_child(body)

	_overlay_vbox = VBoxContainer.new()
	_overlay_vbox.name = "ShopItems"
	_overlay_vbox.add_theme_constant_override("separation", 11)
	body.add_child(_overlay_vbox)

	for i in RunState.shop_items.size():
		_add_shop_row(RunState.shop_items[i], i)

	# Footer: `padding:4px 20px 20px`, the button 60 tall on PRIMARY.
	var foot := MarginContainer.new()
	foot.add_theme_constant_override("margin_left", 20)
	foot.add_theme_constant_override("margin_right", 20)
	foot.add_theme_constant_override("margin_top", 4)
	foot.add_theme_constant_override("margin_bottom", 20)
	panel_col.add_child(foot)
	var leave := _flat_button("LEAVE THE SHOP", DangoTheme.PRIMARY, 60.0, 22, 14, 0.18)
	leave.pressed.connect(func(): _finish_node())
	foot.add_child(leave)


## The shop panel's PRIMARY header band - `padding:18px 24px`, a 4px black bottom rule, the
## merchant's name at 38 over a 13px row line, and the shard purse on a cream pill at the right.
func _build_shop_header() -> PanelContainer:
	var head := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = DangoTheme.PRIMARY
	sb.border_color = Color.BLACK
	sb.border_width_bottom = 4
	# The panel clips to a plain RECT, not to its rounded corners, so the band carries the
	# panel's own inner radius (20 minus its 5px border) on its top corners itself.
	sb.corner_radius_top_left = 15
	sb.corner_radius_top_right = 15
	sb.content_margin_left = 24.0
	sb.content_margin_right = 24.0
	sb.content_margin_top = 18.0
	sb.content_margin_bottom = 22.0   # 18 padding + this band's own 4px bottom rule
	head.add_theme_stylebox_override("panel", sb)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	head.add_child(row)

	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text_col.add_theme_constant_override("separation", 3)
	row.add_child(text_col)
	text_col.add_child(DangoTheme.display_label("CHIMERA MERCHANT", 38,
		DangoTheme.INK_ON_PRIMARY, 800, 0.02))
	var sub := Label.new()
	sub.text = "Row %d - stock refreshes every merchant node" % maxi(_current_row(), 0)
	sub.add_theme_font_size_override("font_size", 13)
	# FLAGGED (token): the mockup inks this line #5A3310, a mid-brown on Kam orange that
	# DangoTheme has no name for. INK_ON_PRIMARY (#2A1505) is the named ink for this fill.
	sub.add_theme_color_override("font_color", DangoTheme.INK_ON_PRIMARY)
	text_col.add_child(sub)

	# Purse: height 52, `padding:0 16px`, radius 12 on CREAM, 4px black, 28px glyph, Baloo 30.
	var purse := PanelContainer.new()
	purse.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	purse.custom_minimum_size.y = 52.0
	var purse_sb := DangoTheme.surface_style(DangoTheme.Surface.CREAM, 12, 4, 0.0,
		Vector2(20, 4))   # mockup `padding:0 16px` on a 4px border
	purse.add_theme_stylebox_override("panel", purse_sb)
	row.add_child(purse)
	var purse_row := HBoxContainer.new()
	purse_row.add_theme_constant_override("separation", 9)
	purse.add_child(purse_row)
	purse_row.add_child(_mockup_icon("assets/fx/shard.png", 28.0))
	var purse_lbl := DangoTheme.display_label(str(RunState.shards_this_run), 30, DangoTheme.INK)
	purse_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	purse_row.add_child(purse_lbl)
	return head


## One shop row. Mockup: `padding:14px 16px`, radius 14 on CREAM, 4px black, shelf `0 4px 0`;
## a 62px rarity-filled icon tile, the name at 22 beside a rarity chip, the rule text at 14,
## and a 178x56 action button on the right.
##
## FLAGGED: the mockup's row also carries an "MP 18" cost tag between the name and the rarity
## chip, for an ACTIVE item. This build's shop sells relics, a Serum and an Instinct - none of
## them an active with a mana cost, and `generate_shop_items()` writes no `mp` field - so that
## tag is not drawn.
func _add_shop_row(raw: Dictionary, index: int) -> PanelContainer:
	var it: Dictionary = raw
	var rar := int(it.get("rar", 0))
	var bought := bool(it.get("bought", false))
	var cost := int(it.get("cost", 0))
	var afford := RunState.shards_this_run >= cost

	# No clip: this row lives inside the clipped ShopPanel, and it has no full-bleed child that
	# would need one. See _cream_card()'s note on nested canvas groups.
	var card := _cream_card(14, 4, 4.0, false)
	var card_sb := card.get_theme_stylebox("panel") as StyleBoxFlat
	card_sb.content_margin_left = 20.0   # mockup `padding:14px 16px` on a 4px border
	card_sb.content_margin_right = 20.0
	card_sb.content_margin_top = 18.0
	card_sb.content_margin_bottom = 18.0
	_overlay_vbox.add_child(card)

	# `_card_button()` in tests/t_runloop_ui.gd reads this row as PanelContainer > child(0) >
	# a Button among ITS direct children. That is exactly the mockup's own row shape, so the
	# action button below stays a direct child of this HBox.
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	card.add_child(row)

	var tile := Panel.new()
	tile.custom_minimum_size = Vector2(62, 62)
	tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var tile_sb := StyleBoxFlat.new()
	tile_sb.bg_color = DangoTheme.rarity_color(rar)
	tile_sb.border_color = Color.BLACK
	tile_sb.set_border_width_all(3)
	tile_sb.set_corner_radius_all(14)
	tile.add_theme_stylebox_override("panel", tile_sb)
	var tile_center := CenterContainer.new()
	tile_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	tile.add_child(tile_center)
	tile_center.add_child(_tex_icon(
		CardArt.texture_for_shop(String(it.get("kind", "")), rar), 36.0))
	row.add_child(tile)

	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text_col.add_theme_constant_override("separation", 5)
	row.add_child(text_col)

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 9)
	text_col.add_child(name_row)
	var name_lbl := DangoTheme.display_label(String(it.get("title", "")), 22, DangoTheme.INK,
		800, 0.01)
	name_row.add_child(name_lbl)
	name_row.add_child(_solid_rarity_chip(rar, 22.0, 12, 6, 2, 0.1))

	var desc := Label.new()
	desc.text = String(it.get("desc", ""))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 14)
	desc.add_theme_color_override("font_color", DangoTheme.INK_ON_CREAM_SOFT)
	text_col.add_child(desc)

	row.add_child(_build_shop_buy_button(index, cost, bought, afford))
	return card


## The 178x56 action button. Three states, three fills, and they must not collapse into one:
## "bought" is permanent and a success (SUCCESS), "can't afford it yet" is temporary
## (DISABLED_FILL), and a buyable item is the loud one (PRIMARY). Both of the first two end up
## `disabled` - there is nothing to press either way - which is why the STYLE has to carry the
## difference rather than the enabled flag.
func _build_shop_buy_button(index: int, cost: int, bought: bool, afford: bool) -> Button:
	var fill := DangoTheme.PRIMARY
	if bought:
		fill = DangoTheme.SUCCESS
	elif not afford:
		fill = DangoTheme.list_state_fill(DangoTheme.ListState.UNAFFORDABLE)
	var ink := DangoTheme.ink_on(fill)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(178, 56)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.disabled = bought or not afford
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = Color.BLACK
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(13)
	sb.shadow_color = DangoTheme.SHELF
	sb.shadow_size = 0
	sb.shadow_offset = Vector2(0, 4)
	for state_key in ["normal", "hover", "pressed", "disabled"]:
		btn.add_theme_stylebox_override(state_key, sb)
	if not btn.disabled:
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.pressed.connect(func(): _on_shop_buy(index))

	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	btn.add_child(row)

	if not bought:
		# The mockup hides the shard glyph on an OWNED button and shows it otherwise.
		row.add_child(_mockup_icon("assets/fx/shard.png", 20.0))
		var price := DangoTheme.display_label(str(cost), 24, ink)
		price.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(price)
	# FLAGGED: the mockup puts a check mark where the price goes on an OWNED row. None of this
	# project's six fonts carries U+2713 (their cmaps were read directly), so an owned button
	# shows its word alone rather than a tofu box beside it.
	var label := DangoTheme.display_label("OWNED" if bought else "BUY", 13, ink, 800, 0.08)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	return btn


func _on_shop_buy(index: int) -> void:
	# `bought` is marked inside try_buy_shop_item() now. Marking it here meant a replay, which
	# has no screen, left every item buyable forever.
	RunState.try_buy_shop_item(index)
	_render_shop()   # rebuild so shard total / afford/bought states stay in sync


# ---------------------------------------------------------------------------------------
# EVENT
# ---------------------------------------------------------------------------------------

## Event node: RunState.enter_node() already picked WHICH event and opened its stream. This
## screen only draws the offer and reports which option was clicked - an index, never the
## option itself, because the verifier re-derives the offer from the seed.
func _on_event_node(_node_id: String) -> void:
	if RunState.event_key.is_empty():
		push_error("RunMapController: no playable events in ContentDB - cannot resolve event node")
		_finish_node()
		return
	var ev: Dictionary = ContentDB.events[RunState.event_key]
	var host := _event_screen(String(ev.get("n", "EVENT")), String(ev.get("desc", "")))

	# Mockup: the option list at `top:398px`, 1040 wide, centred, `gap:14px`.
	_overlay_vbox = VBoxContainer.new()
	_overlay_vbox.name = "EventOptions"
	_overlay_vbox.add_theme_constant_override("separation", 14)
	_overlay_vbox.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_overlay_vbox.grow_vertical = Control.GROW_DIRECTION_END
	# EVT-02: 1040 wide, CENTRED. Anchored at the canvas midline rather than offset from a
	# hardcoded 1920 - the width is a mockup number, the canvas width is not ours to assume.
	_overlay_vbox.anchor_left = 0.5
	_overlay_vbox.anchor_right = 0.5
	_overlay_vbox.offset_left = -_EVENT_LIST_W * 0.5
	_overlay_vbox.offset_right = _EVENT_LIST_W * 0.5
	_overlay_vbox.offset_top = _EVENT_LIST_TOP
	_overlay_vbox.offset_bottom = _EVENT_LIST_TOP
	host.add_child(_overlay_vbox)

	var opts := RunState.event_options()
	for i in opts.size():
		_add_event_option(opts[i], i)


## The event screen's plate and header, shared by the offer and by the outcome that follows it:
## the player has not moved, and a different picture between choosing and seeing the result
## would read as a second, unrelated node.
##
## Mockup: `assets/bg/deep-forest.jpg`, then a centred column at `top:104px` with `gap:13px` -
## a 92px icon tile on #31C6FF (SHIELD_BLUE) with 5px black and a `0 6px 0` shelf, the name at
## 58, and the description at 16.
##
## FLAGGED: the mockup sets that tile's glyph from the event's own icon, and ContentDB writes
## those as emoji ("⛩" for the shrine). None of this project's six fonts carries U+26E9, so
## the tile holds `assets/node/event.png` at the mockup's 44px instead of a tofu box.
func _event_screen(title: String, body: String) -> Control:
	var host := _open_screen(MockupAssets.tex("assets/bg/deep-forest.jpg"))
	var head := _screen_header(host, 104.0, 13)

	var tile := PanelContainer.new()
	tile.custom_minimum_size = Vector2(92, 92)
	tile.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var tile_sb := DangoTheme.solid_chip_style(DangoTheme.SHIELD_BLUE, 24, 5, Vector2(5, 5))
	tile_sb.shadow_color = DangoTheme.SHELF_DEEP
	tile_sb.shadow_size = 0
	tile_sb.shadow_offset = Vector2(0, 6)
	tile.add_theme_stylebox_override("panel", tile_sb)
	head.add_child(tile)
	var tile_center := CenterContainer.new()
	tile.add_child(tile_center)
	tile_center.add_child(_mockup_icon("assets/node/event.png", 44.0))

	var title_lbl := DangoTheme.display_label(title, 58, DangoTheme.CREAM_RAISED, 800, 0.02)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(title_lbl)

	var sub := Label.new()
	sub.text = body
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.add_theme_font_size_override("font_size", 16)
	sub.add_theme_color_override("font_color", DangoTheme.CHIP_INK_ON_WELL)
	head.add_child(sub)
	return host


## One event option. Mockup: radius 16 on CREAM, 5px black, shelf `0 6px 0`, contents clipped;
## a 74px accent strip with a 34px glyph on the left, a 16/20 body with the choice at 24 beside
## a risk tag, the outcome line at 15 under it, and a 64px arrow column on the right.
##
## Same PanelContainer + chromeless hit Button shape as the reroll control, and for the same
## reason: a Button ignores Control children when it reports its minimum size, so a Button built
## around this row would report zero height and collapse inside the option list.
##
## FLAGGED: ContentDB's option data has no tag/accent field. The tag is derived from
## RewardGenerator.event_option_rarity() - the same UI-only risk heuristic that already drives
## every choice card's rarity chip - so SAFE/HIGH RISK and the strip colour follow the option's
## own stakes rather than being authored twice.
##
## FLAGGED: the mockup's hover is `transform:translateX(8px)`. Godot Controls in a Container
## cannot be offset without fighting the container's own layout, so the hover state is the
## pointing-hand cursor alone.
func _add_event_option(raw: Dictionary, index: int) -> Control:
	var o: Dictionary = raw
	var rar := RewardGenerator.event_option_rarity(o)
	var risky := rar >= 3
	var accent := DangoTheme.DANGER if risky else DangoTheme.SUCCESS
	var tag := "HIGH RISK" if risky else "SAFE"

	var card := _cream_card(16, 5, 6.0)
	card.name = "EventOption%d" % index
	_overlay_vbox.add_child(card)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(row)

	# The strip is full-bleed against the card's inner edge, and Godot's `clip_contents` is a
	# plain rect rather than a rounded one, so the strip carries the card's own INNER radius
	# (16 minus the 5px border) on its outer corners itself.
	var strip := PanelContainer.new()
	strip.custom_minimum_size.x = 74.0
	var strip_sb := StyleBoxFlat.new()
	strip_sb.bg_color = accent
	strip_sb.border_color = Color.BLACK
	strip_sb.border_width_right = 4
	strip_sb.corner_radius_top_left = 11
	strip_sb.corner_radius_bottom_left = 11
	strip.add_theme_stylebox_override("panel", strip_sb)
	row.add_child(strip)
	var strip_center := CenterContainer.new()
	strip.add_child(strip_center)
	strip_center.add_child(_mockup_icon(
		String(_EVENT_FX_ICON.get(String(o.get("fx", "")), "assets/fx/blank.svg")), 34.0))

	var body := MarginContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("margin_left", 20)
	body.add_theme_constant_override("margin_right", 20)
	body.add_theme_constant_override("margin_top", 16)
	body.add_theme_constant_override("margin_bottom", 16)
	row.add_child(body)

	var body_col := VBoxContainer.new()
	body_col.add_theme_constant_override("separation", 5)
	body.add_child(body_col)

	var head_row := HBoxContainer.new()
	head_row.add_theme_constant_override("separation", 10)
	body_col.add_child(head_row)
	head_row.add_child(DangoTheme.display_label(String(o.get("text", "")), 24, DangoTheme.INK,
		800, 0.01))

	var tag_chip := PanelContainer.new()
	tag_chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tag_chip.custom_minimum_size.y = 24.0
	tag_chip.add_theme_stylebox_override("panel",
		DangoTheme.solid_chip_style(accent, 7, 2, Vector2(11, 2)))
	var tag_lbl := DangoTheme.display_label(tag, 12, DangoTheme.ink_on(accent), 800, 0.1)
	tag_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tag_chip.add_child(tag_lbl)
	head_row.add_child(tag_chip)

	var desc := Label.new()
	desc.text = String(o.get("desc", ""))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 15)
	desc.add_theme_color_override("font_color", DangoTheme.INK_ON_CREAM_SOFT)
	body_col.add_child(desc)

	var arrow_wrap := CenterContainer.new()
	arrow_wrap.custom_minimum_size.x = 64.0
	row.add_child(arrow_wrap)
	# U+2192 IS in Baloo 2's cmap - checked directly, unlike the check mark and the shrine gate.
	arrow_wrap.add_child(DangoTheme.display_label("\u2192", 30, DangoTheme.INK))

	var hit := _hit_button()
	hit.pressed.connect(func(): _on_event_choice(index))
	card.add_child(hit)
	return card


func _on_event_choice(index: int) -> void:
	var msg := RunState.choose_event_option(index)
	_save_map_progress()   # the effect is already applied; quitting on the outcome screen must
		# not hand it back
	# FLAGGED: the mockup has no screen for an event's OUTCOME - it stops at the offer. This
	# build has to show what the choice did, so the outcome reuses the event screen's own plate
	# and header shape with the result message and one CONTINUE button in place of the options.
	var ev: Dictionary = ContentDB.events.get(RunState.event_key, {})
	var host := _event_screen(String(ev.get("n", "EVENT")), msg)

	var foot := HBoxContainer.new()
	foot.name = "EventOutcomeFooter"
	foot.alignment = BoxContainer.ALIGNMENT_CENTER
	foot.set_anchors_preset(Control.PRESET_TOP_WIDE)
	foot.grow_vertical = Control.GROW_DIRECTION_END
	foot.offset_left = _SCREEN_GUTTER              # see _screen_header() on the inset
	foot.offset_right = -_SCREEN_GUTTER
	foot.offset_top = _EVENT_LIST_TOP
	foot.offset_bottom = _EVENT_LIST_TOP
	host.add_child(foot)
	var cont := _flat_button("CONTINUE", DangoTheme.PRIMARY, 60.0, 20)
	cont.custom_minimum_size.x = 340.0
	cont.pressed.connect(func(): _finish_node())
	foot.add_child(cont)


# ---------------------------------------------------------------------------------------
# TREASURE
# ---------------------------------------------------------------------------------------

## Treasure node: src/engine.js chooseNode() 'treasure' branch offers a real reward-choice pick
## at rewardTier=1, exactly like a combat reward - which is why this screen shows the offer
## rather than granting one thing outright.
##
## Mockup: `assets/bg/temple.jpg`, a gold ANCIENT CRYPT pill and "A SEALED GENE VAULT" at
## `top:96px`, then `assets/node/treasure.png` at 240 square beside a 470-wide card,
## `gap:44px`, at `top:276px`.
##
## FLAGGED: the mockup's card carries a second button, "SMASH" for 60 shard, beside TAKE IT.
## There is no smash-a-relic-for-shards rule in this port (RunState has no such call), so that
## button is not drawn. FLAGGED: the mockup shows exactly one relic; this build's treasure is a
## CHOICE of rewards, so the column holds one card per pending reward — and is capped and
## scrolled when three of them do not fit, rather than clipped by the bottom of the screen.
func _on_treasure_node(node_id: String) -> void:
	RunState.generate_treasure_rewards(node_id)
	var host := _open_screen(MockupAssets.tex("assets/bg/temple.jpg"))

	var head := _screen_header(host, 96.0, 0)
	# The pill's gold is the treasure node tone's own top block (#FFC445), not a new colour.
	var crypt_gold: Color = DangoTheme.node_tone("treasure")[1]
	head.add_child(_eyebrow_chip("ANCIENT CRYPT", crypt_gold, 38.0, 16, 0.2))
	head.add_child(_spacer(14.0))
	var title := DangoTheme.display_label("A SEALED GENE VAULT", 58, DangoTheme.CREAM_RAISED,
		800, 0.02)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(title)

	# TRS-01 centres the art and the card "as a pair". The row therefore FILLS the space under
	# the header rather than hanging off a fixed `top:276`: with one card that is the mockup's
	# own position, and with the three this build offers the pair stays on screen instead of
	# running the third card off the bottom edge.
	var row := HBoxContainer.new()
	row.name = "TreasureRow"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 44)
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = _SCREEN_GUTTER               # see _screen_header() on the inset
	row.offset_right = -_SCREEN_GUTTER
	row.offset_top = _TREASURE_ROW_TOP
	row.offset_bottom = -DangoScreen.SAFE
	host.add_child(row)

	var art := _mockup_icon("assets/node/treasure.png", _TREASURE_ART)
	art.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(art)

	_overlay_vbox = VBoxContainer.new()
	_overlay_vbox.name = "TreasureCards"
	_overlay_vbox.add_theme_constant_override("separation", 14)
	_overlay_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_overlay_vbox)

	if RunState.pending_rewards.is_empty():
		var empty := PanelContainer.new()
		empty.custom_minimum_size.x = _TREASURE_CARD_W
		empty.add_theme_stylebox_override("panel",
			DangoTheme.surface_style(DangoTheme.Surface.PANEL, 20, 5, 7.0, Vector2(27, 27)))
		_overlay_vbox.add_child(empty)
		var empty_col := VBoxContainer.new()
		empty_col.add_theme_constant_override("separation", 20)
		empty.add_child(empty_col)
		var empty_lbl := Label.new()
		empty_lbl.text = "The vault was empty."
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_font_size_override("font_size", 15)
		empty_lbl.add_theme_color_override("font_color", DangoTheme.MUTED_TEXT)
		empty_col.add_child(empty_lbl)
		var cont := _flat_button("CONTINUE", DangoTheme.PRIMARY, 56.0, 20)
		cont.pressed.connect(func(): _finish_node())
		empty_col.add_child(cont)
		return

	for reward in RunState.pending_rewards:
		_add_treasure_card(reward)

	# The mockup draws exactly one card, so it never has to answer this; this build's treasure
	# is a real choice of three. A column that does not fit is capped and scrolls (CLAUDE.md
	# rule 3) rather than being clipped by the screen edge with no bar to say so.
	var avail: float = row.size.y if row.size.y > 0.0 \
		else get_viewport_rect().size.y - _TREASURE_ROW_TOP - DangoScreen.SAFE
	if _overlay_vbox.get_combined_minimum_size().y > avail:
		row.remove_child(_overlay_vbox)
		var capped := DangoScreen.fit_or_scroll(_overlay_vbox, avail)
		capped.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(capped)


## One treasure card. Mockup: 470 wide, radius 20, 5px black, shelf `0 7px 0`; a 46px header
## band in the rarity colour ("RELIC - BETTER THAN USUAL ROLL" / "RARE"), then a 22px body with
## a 78px icon tile beside the name, the rule text at 15, and TAKE IT at 56 tall.
func _add_treasure_card(raw: Dictionary) -> PanelContainer:
	var r: Dictionary = raw
	var rar := int(r.get("rar", 0))
	var accent := DangoTheme.rarity_color(rar)
	var kind := String(_REWARD_KIND.get(String(r.get("t", "")), "REWARD"))

	var card := _cream_card(20, 5, 7.0)
	card.custom_minimum_size.x = _TREASURE_CARD_W
	_overlay_vbox.add_child(card)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	card.add_child(col)

	var band := PanelContainer.new()
	band.custom_minimum_size.y = 46.0
	var band_sb := StyleBoxFlat.new()
	band_sb.bg_color = accent
	band_sb.border_color = Color.BLACK
	band_sb.border_width_bottom = 4
	# The band is full-bleed against the card's inner edge, and Godot's `clip_contents` clips to
	# a plain RECT rather than to the card's rounded one - so the band carries the card's own
	# inner radius (20 minus its 5px border) on its top corners itself.
	band_sb.corner_radius_top_left = 15
	band_sb.corner_radius_top_right = 15
	band_sb.content_margin_left = 16.0
	band_sb.content_margin_right = 16.0
	band.add_theme_stylebox_override("panel", band_sb)
	col.add_child(band)
	var band_row := HBoxContainer.new()
	band_row.add_theme_constant_override("separation", 10)
	band.add_child(band_row)
	# "BETTER THAN USUAL ROLL" is the mockup's own wording for what a treasure node actually is
	# here: RunState.generate_treasure_rewards() rolls at rewardTier 1, a tier above a normal
	# node's offer.
	var kind_lbl := DangoTheme.display_label("%s - BETTER THAN USUAL ROLL" % kind, 14,
		DangoTheme.ink_on(accent), 800, 0.12)
	kind_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kind_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	band_row.add_child(kind_lbl)
	var rar_lbl := DangoTheme.display_label(DangoTheme.rarity_name(rar).to_upper(), 14,
		DangoTheme.ink_on(accent), 800, 0.12)
	rar_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	band_row.add_child(rar_lbl)

	var body := MarginContainer.new()
	body.add_theme_constant_override("margin_left", 22)
	body.add_theme_constant_override("margin_right", 22)
	body.add_theme_constant_override("margin_top", 22)
	body.add_theme_constant_override("margin_bottom", 22)
	col.add_child(body)
	var body_col := VBoxContainer.new()
	body_col.add_theme_constant_override("separation", 0)
	body.add_child(body_col)

	var head_row := HBoxContainer.new()
	head_row.add_theme_constant_override("separation", 15)
	body_col.add_child(head_row)
	var tile := PanelContainer.new()
	tile.custom_minimum_size = Vector2(78, 78)
	tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tile.add_theme_stylebox_override("panel",
		DangoTheme.surface_style(DangoTheme.Surface.CREAM_RAISED, 18, 4, 0.0, Vector2(-1, -1)))
	head_row.add_child(tile)
	var tile_center := CenterContainer.new()
	tile.add_child(tile_center)
	tile_center.add_child(_tex_icon(
		CardArt.texture_for_reward(String(r.get("t", "")), rar), 46.0))

	var name_col := VBoxContainer.new()
	name_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name_col.add_theme_constant_override("separation", 3)
	head_row.add_child(name_col)
	name_col.add_child(DangoTheme.display_label(String(r.get("title", "")), 28, DangoTheme.INK,
		800, 0.01))
	var sub_text := String(r.get("sub", ""))
	if sub_text != "":
		var sub := Label.new()
		sub.text = sub_text
		sub.add_theme_font_size_override("font_size", 13)
		sub.add_theme_color_override("font_color", DangoTheme.INK_ON_CREAM_MUTED)
		name_col.add_child(sub)

	body_col.add_child(_spacer(16.0))
	var desc := Label.new()
	desc.text = String(r.get("desc", ""))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 15)
	desc.add_theme_color_override("font_color", DangoTheme.INK_ON_CREAM_SOFT)
	body_col.add_child(desc)

	body_col.add_child(_spacer(20.0))
	var take := _flat_button("TAKE IT", DangoTheme.PRIMARY, 56.0, 20, 13, 0.14)
	take.pressed.connect(func(): _on_reward_chosen(r))
	body_col.add_child(take)
	return card
