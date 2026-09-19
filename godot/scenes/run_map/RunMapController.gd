extends Node2D
## RunMap.tscn root. Renders the FULL branching RunMapGraph (RunMapGenerator, architecture
## plan §7) as a real Node2D/Line2D graph — position from `row`/`col`, curved edges, and a
## "torch in a cave" lit/fogged read — per design/ux/combat-screen-shroom-gloom-inspired.md §5.4
## (Decision 4, resolved). Previously (pre-2026-09-18 pass) this only ever rendered the single
## immediately-next reachable row as a flat GridContainer of buttons; that stub is gone.
##
## STRUCTURE: node/edge VISUALS are built ONCE (_build_graph_visuals(), called from _ready()) from
## the graph's static row/col/next_ids data, which never changes for the lifetime of a run. Only
## each node's/edge's STATE (current/reachable/dim/fogged, click-enabled, brightness) is
## re-evaluated on every _refresh() — this is what lets a node's "?" -> real-icon transition
## animate as a crossfade (§10) instead of destroying and recreating the button every time, which
## the old GridContainer-rebuild approach did and which would have made that animation impossible.
##
## RunState.enter_node()/after_node() and their combat/event/shop/treasure branching are
## UNCHANGED — this file only ever reads RunState fields and calls those two existing methods
## exactly where the pre-existing code already did; per this task's constraints, RunState.gd
## itself is never touched.
##
## DEVIATION FLAGGED (per collaboration protocol): the spec's wireframe (§5.4) shows
## "Camera2D pans/zooms" as an ambient annotation but Section 7 (Interaction Map) lists NO new
## input path this spec adds — so this implementation auto-frames the camera (tweened) around
## the current node + the currently-reachable row on every refresh, rather than adding a new
## user-drag-pan/scroll-zoom input the spec never asked for. If free camera panning is wanted
## later, that is new interaction-map scope for a follow-up spec, not silently added here.
##
## DEVIATION FLAGGED #2: the reveal crossfade (§10, "?" -> real icon) can only play when
## RunMapController stays alive across the state change — true for event/shop/treasure nodes
## (RunState.after_node() + _refresh() happen in this same script instance) but NOT for
## battle/elite/boss nodes, where combat fully replaces the scene and a BRAND NEW
## RunMapController is instantiated afterward with no "previous frame" to crossfade from (and
## persisting that "previous fog state" across the scene boundary would require adding a field to
## RunState.gd, which this task's constraints explicitly forbid touching). The STATE itself is
## still always correct after a combat return (freshly built from RunState.current_node_id, which
## RunState.after_node() already advanced before the scene change) — only the animated transition
## is unobservable in that specific path. See task report for detail.

## node_type (RunMapNode.gd: "battle"|"elite"|"event"|"shop"|"treasure"|"boss") -> icon path.
const _NODE_ICON := {
	"battle": preload("res://assets/icons/node/battle.png"),
	"elite": preload("res://assets/icons/node/elite.png"),
	"boss": preload("res://assets/icons/node/boss.png"),
	"event": preload("res://assets/icons/node/event.png"),
	"shop": preload("res://assets/icons/node/merchant.png"),
	"treasure": preload("res://assets/icons/node/treasure.png"),
}

## node-type background wash (Item E, godot-port UI polish pass) — unchanged palette, now
## additionally modulated per lighting tier (_node_wash_color()) instead of applied flat.
const _NODE_COLOR := {
	"battle": Color(0.55, 0.16, 0.16, 0.55),
	"elite": Color(0.65, 0.38, 0.08, 0.6),
	"boss": Color(0.45, 0.05, 0.08, 0.75),
	"event": Color(0.14, 0.32, 0.55, 0.55),
	"shop": Color(0.55, 0.48, 0.08, 0.5),
	"treasure": Color(0.4, 0.16, 0.55, 0.55),
}
const _NODE_PANEL_BORDER_COLOR := Color(0, 0, 0, 1)
const _NODE_PANEL_BORDER_WIDTH := 3
const _NODE_PANEL_CORNER_RADIUS := 10

# --- Graph layout (spec §5.4 rule 1: "x = col * COL_SPACING, y = -row * ROW_SPACING") ---
const _COL_SPACING := 170.0
const _ROW_SPACING := 190.0
const _NODE_SIZE := Vector2(112, 112)

# --- Edge curves (spec §5.4 rule 2 — reuses TargetLinesLayer's quadratic-bezier technique) ---
const _EDGE_STEPS := 16
const _EDGE_WOBBLE_AMP := 16.0     # deterministic per-edge lateral wobble amplitude, px
const _EDGE_WIDTH := 3.0
const _EDGE_COLOR := Color(0.86, 0.8, 0.66)   # warm cave-rope tone
const _EDGE_ALPHA_CURRENT := 0.95
const _EDGE_ALPHA_REACHABLE := 0.82
const _EDGE_ALPHA_VISITED := 0.5
const _EDGE_ALPHA_FAINT := 0.2     # never fully hidden — rule 2: "existence/shape is never hidden"
const _EDGE_REVEAL_DURATION := 0.4   # spec §10 "RunMap edge/fog reveal on after_node(): 400ms ease out"

# --- Torch-glow pool (third reuse of the GradientTexture2D radial-falloff technique, see spec §8
# dependency note — kept as its own independent call site rather than a shared helper, an
# implementation-detail choice this spec's §15 explicitly leaves open to ui-programmer) ---
const _GLOW_SIZE := Vector2(200.0, 200.0)
const _GLOW_ALPHA_CURRENT := 0.55
const _GLOW_ALPHA_REACHABLE := 0.4
const _GLOW_ALPHA_NONE := 0.0
const _HOVER_GLOW_BUMP := 0.2         # spec §7.2/§10: "hover brightens further... 120ms ease out"
const _HOVER_DURATION := 0.12

# --- "?" fog reveal (spec §10: "300ms ease out") ---
const _REVEAL_DURATION := 0.3
const _FOG_FONT_SIZE := 40

# --- Camera auto-frame (see DEVIATION note above) ---
const _CAMERA_MARGIN := Vector2(240.0, 280.0)

## The camera frames a WINDOW of rows around the player, not the whole map.
##
## Two wrong answers were tried first and both are worth recording, because each looks right on
## paper:
##
##   1. ORIGINAL: frame only the current node and the ones reachable right now. The rows further
##      ahead are still DRAWN (fogged "?" cards, which the spec wants), so they sat outside the
##      framed box and got sliced in half by the screen edge — one of them landed on top of the
##      status bar.
##   2. "FIX" THAT MADE IT WORSE: frame every rendered node. That removes the clipping, but an
##      18-row map spans ~3300 world units against a 1080-tall viewport, so every node shrinks to
##      roughly 30px — a map you can see all of and cannot read or click. A 30-row full run is
##      half that again.
##
## A window gets both: nodes stay at a usable size, and the rows outside it are entirely
## off-screen rather than half-cut. Looking a few rows ahead is also what the map is FOR — a
## Slay-the-Spire-style route choice is made two or three rows out, not thirty.
const _CAMERA_ROWS_AHEAD := 3
const _CAMERA_ROWS_BEHIND := 1

## Zoom is a MULTIPLIER in Godot 4: `screen_size = world_size * zoom`, so bigger zooms IN. The
## code here used to compute `box / viewport`, which is the inverse of a fit — it magnified
## exactly when it needed to pull back. The clamps below are in that corrected space: never
## magnify past 1:1 (the art has no detail to gain), never shrink a node below readable.
const _CAMERA_ZOOM_MIN := 0.45
const _CAMERA_ZOOM_MAX := 1.0
const _CAMERA_REFRAME_DURATION := 0.4

@onready var _status_label: Label = %StatusLabel
@onready var _map_world: Node2D = %MapWorld
@onready var _camera: Camera2D = %MapCamera

var _graph: RunMapGraph = null
var _glow_layer: Node2D
var _edges_layer: Node2D
var _nodes_layer: Node2D
var _glow_texture: GradientTexture2D
var _node_visuals: Dictionary = {}   # node_id -> {node, button, glow, tier, fogged, glow_base_alpha}
var _edge_visuals: Dictionary = {}   # "from_id->to_id" -> {line, alpha}


func _ready() -> void:
	EventBus.node_entered.connect(_on_node_entered)
	_graph = RunMapGraph.from_data(RunState.map_graph)

	_glow_layer = Node2D.new()
	_edges_layer = Node2D.new()
	_nodes_layer = Node2D.new()
	_map_world.add_child(_glow_layer)     # render order: glow (bottom) -> edges -> nodes (top)
	_map_world.add_child(_edges_layer)
	_map_world.add_child(_nodes_layer)

	_build_glow_texture()
	if _graph != null:
		_build_graph_visuals()
	_refresh(false)   # initial paint — no reveal/reframe animation on first load

	_build_overlay_ui()
	# Post-combat reward cards, if any, take priority over normal map interaction — see
	# RunState._generate_post_combat_rewards()'s ordering note for why this scene (not
	# Combat.tscn) is where that overlay has to live.
	_maybe_show_pending_reward()


## Torch-glow gradient (shared by every node's glow TextureRect, tinted per-instance via
## `modulate` — see _create_node_visual()). Same GradientTexture2D radial-falloff pattern as
## CombatView._build_gradient_textures()'s vignette.
func _build_glow_texture() -> void:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1.0))
	g.set_color(1, Color(1, 1, 1, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 1.0)
	tex.width = 256
	tex.height = 256
	_glow_texture = tex


func _build_graph_visuals() -> void:
	for row in _graph.rows:
		for node in row:
			_create_node_visual(node as RunMapNode)
	for row in _graph.rows:
		for node in row:
			var from_node := node as RunMapNode
			for next_id in from_node.next_ids:
				var to_node := _graph.find_node(next_id)
				if to_node != null:
					_create_edge_visual(from_node, to_node)


func _node_world_pos(node: RunMapNode) -> Vector2:
	return Vector2(float(node.col) * _COL_SPACING, -float(node.row) * _ROW_SPACING)


func _create_node_visual(node: RunMapNode) -> void:
	var pos := _node_world_pos(node)

	var glow := TextureRect.new()
	glow.texture = _glow_texture
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.size = _GLOW_SIZE
	glow.position = pos - _GLOW_SIZE * 0.5
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.modulate = Color(DangoTheme.PRIMARY.r, DangoTheme.PRIMARY.g, DangoTheme.PRIMARY.b, 0.0)
	_glow_layer.add_child(glow)

	var btn := Button.new()
	btn.custom_minimum_size = _NODE_SIZE
	btn.size = _NODE_SIZE
	btn.position = pos - _NODE_SIZE * 0.5
	btn.expand_icon = true
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	btn.clip_text = true
	btn.mouse_entered.connect(func(): _on_node_hover(node.id, true))
	btn.mouse_exited.connect(func(): _on_node_hover(node.id, false))
	btn.pressed.connect(func(): _on_node_pressed(node.id, node.node_type))
	_nodes_layer.add_child(btn)

	_node_visuals[node.id] = {
		"node": node, "button": btn, "glow": glow,
		"tier": "", "fogged": false, "glow_base_alpha": 0.0,
	}


## Edge geometry built ONCE (static row/col data never changes for the run) — quadratic-bezier
## sampled with a small deterministic lateral wobble (spec §5.4 rule 2: "seeded from
## hash(from.id, to.id) so edges read as hand-cut cave paths ... deterministic, so it never
## jitters between redraws"). Mirrors TargetLinesLayer._draw()'s bezier-sampling math.
func _create_edge_visual(from_node: RunMapNode, to_node: RunMapNode) -> void:
	var line := Line2D.new()
	line.width = _EDGE_WIDTH
	line.default_color = _EDGE_COLOR
	line.antialiased = true
	line.modulate = Color(1, 1, 1, 0.0)

	var from_pos := _node_world_pos(from_node)
	var to_pos := _node_world_pos(to_node)
	var dir := to_pos - from_pos
	if dir.length() > 0.001:
		var h := hash("%s|%s" % [from_node.id, to_node.id])
		var wobble := (float(h % 2001) - 1000.0) / 1000.0 * _EDGE_WOBBLE_AMP
		var perp := Vector2(-dir.y, dir.x).normalized()
		var mid := (from_pos + to_pos) * 0.5 + perp * wobble
		var pts := PackedVector2Array()
		for i in _EDGE_STEPS + 1:
			var t := float(i) / float(_EDGE_STEPS)
			var inv := 1.0 - t
			pts.append(from_pos * (inv * inv) + mid * (2.0 * inv * t) + to_pos * (t * t))
		line.points = pts
	else:
		line.points = PackedVector2Array([from_pos, to_pos])

	_edges_layer.add_child(line)
	_edge_visuals["%s->%s" % [from_node.id, to_node.id]] = {"line": line, "alpha": -1.0}


# ===========================================================================
# State refresh — the single "read RunState, redraw" entry point (mirrors CombatView.gd's own
# "_rebuild_all()" discipline). Never rebuilds a node/edge; only updates its state.
# ===========================================================================

func _refresh(animate: bool = true) -> void:
	_status_label.text = "Power level: %d — visited: %d" % [
		RunState.power_level, RunState.visited_node_ids.size()]
	for id in _node_visuals.keys():
		_apply_node_state(id, animate)
	for key in _edge_visuals.keys():
		_apply_edge_state(key, animate)
	_update_camera(animate)


func _current_row() -> int:
	if RunState.current_node_id == "":
		return 0
	var cur := _graph.find_node(RunState.current_node_id)
	return cur.row if cur != null else 0


## The row the player can act on RIGHT NOW — current.next_ids, or the graph's single start node
## if nothing has been entered yet (identical semantics to the old _current_choices(), now
## returning ids instead of RunMapNode objects since callers here need both click-enable AND
## fog-exemption checks).
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


## Section 5.4 rule 4 (the resolved pillar exception), applied literally: a node is fogged only
## if it is 2+ rows beyond current_node_id AND not visited/current/reachable-now. Visited nodes
## and the currently-reachable row are NEVER fogged (rules 3/4); every other non-fogged,
## non-clickable node (e.g. an unchosen sibling exactly one row out) still shows its real icon —
## just dim and inert — since rule 4's own wording scopes the exception strictly to "2+ rows
## beyond", not to every non-reachable node.
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


func _apply_node_state(id: String, animate: bool) -> void:
	var entry: Dictionary = _node_visuals[id]
	var node: RunMapNode = entry["node"]
	var btn: Button = entry["button"]
	var glow: TextureRect = entry["glow"]
	var current_row := _current_row()
	var reachable := _reachable_now_ids()
	var tier := _node_tier(node, current_row, reachable)
	var fogged := tier == "fog"
	var was_fogged: bool = entry.get("fogged", false)

	# Only the row the player is actually choosing from right now is clickable/focusable — a
	# disabled Button also gets FOCUS_NONE here so Tab order skips it entirely (spec §11 checklist
	# item: "re-verify Tab order... still follows a sane reading order").
	btn.disabled = tier != "reachable"
	btn.focus_mode = Control.FOCUS_ALL if tier == "reachable" else Control.FOCUS_NONE

	var style := _make_node_style(node.node_type, tier)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("disabled", style)
	btn.add_theme_stylebox_override("focus", style)

	var glow_alpha := _GLOW_ALPHA_NONE
	if tier == "current":
		glow_alpha = _GLOW_ALPHA_CURRENT
	elif tier == "reachable":
		glow_alpha = _GLOW_ALPHA_REACHABLE
	entry["glow_base_alpha"] = glow_alpha

	if animate and was_fogged and not fogged:
		_play_reveal_transition(btn, glow, node, glow_alpha)
	else:
		_set_node_content(btn, node, fogged)
		glow.modulate.a = glow_alpha

	entry["tier"] = tier
	entry["fogged"] = fogged
	_node_visuals[id] = entry


## Sets a node's icon/caption for its CURRENT fog state — "?" (Label text, no new art asset per
## spec §5.3 table) when fogged, the real _NODE_ICON + type/id caption otherwise.
func _set_node_content(btn: Button, node: RunMapNode, fogged: bool) -> void:
	if fogged:
		btn.icon = null
		btn.text = "?"
		btn.add_theme_font_size_override("font_size", _FOG_FONT_SIZE)
		btn.add_theme_color_override("font_color", DangoTheme.TEXT_DIM)
	else:
		btn.icon = _NODE_ICON.get(node.node_type)
		# visual-polish-backlog P0-2: this used to also print node.id (e.g. "r1_c0") as a
		# second line — a technical graph key with no meaning to a player, read in the wild as
		# a debug label leaking into the UI. node_type.capitalize() is the whole caption now.
		btn.text = node.node_type.capitalize()
		btn.remove_theme_font_size_override("font_size")
		btn.add_theme_color_override("font_color", DangoTheme.TEXT)


## "?" -> real icon reveal (spec §10: "Crossfade Label('?') out, _NODE_ICON in, 300ms ease out").
## Approximated as a quick fade-out/content-swap/fade-in on the button itself (a single Button
## cannot cross-dissolve two icons at once without a second overlapping node) — reads as a soft
## reveal rather than a hard cut, which is what the spec asks for; the glow brightens in parallel.
func _play_reveal_transition(btn: Button, glow: TextureRect, node: RunMapNode, glow_alpha: float) -> void:
	var tw := create_tween()
	tw.tween_property(btn, "modulate:a", 0.0, _REVEAL_DURATION * 0.5)
	tw.tween_callback(func(): _set_node_content(btn, node, false))
	tw.tween_property(btn, "modulate:a", 1.0, _REVEAL_DURATION * 0.5)
	var gt := create_tween()
	gt.tween_property(glow, "modulate:a", glow_alpha, _REVEAL_DURATION).set_ease(Tween.EASE_OUT)


## Hover brighten (spec §7.2/§10) — a temporary bump on top of the node's resting glow alpha,
## distinct from the ambient reachable-row glow (mirrors the existing enemy-intent-hover pattern,
## CombatView._on_enemy_intent_hover()).
func _on_node_hover(id: String, entering: bool) -> void:
	var entry: Dictionary = _node_visuals.get(id, {})
	if entry.is_empty():
		return
	var glow: TextureRect = entry["glow"]
	var base: float = entry.get("glow_base_alpha", 0.0)
	var target := clampf(base + _HOVER_GLOW_BUMP, 0.0, 1.0) if entering else base
	var tw := create_tween()
	tw.tween_property(glow, "modulate:a", target, _HOVER_DURATION).set_ease(Tween.EASE_OUT)


func _on_node_pressed(id: String, node_type: String) -> void:
	if not _reachable_now_ids().has(id):
		return   # defensive — the button should already be disabled for any non-reachable node
	RunState.enter_node(id, node_type)


func _apply_edge_state(key: String, animate: bool) -> void:
	var entry: Dictionary = _edge_visuals[key]
	var line: Line2D = entry["line"]
	var ids := key.split("->")
	var from_node := _graph.find_node(ids[0])
	var to_node := _graph.find_node(ids[1])
	if from_node == null or to_node == null:
		return
	var reachable := _reachable_now_ids()
	var target_alpha := _edge_alpha(from_node, to_node, reachable)
	var prev_alpha: float = entry.get("alpha", -1.0)
	if animate and prev_alpha >= 0.0 and target_alpha > prev_alpha + 0.05:
		var tw := create_tween()
		tw.tween_property(line, "modulate:a", target_alpha, _EDGE_REVEAL_DURATION).set_ease(Tween.EASE_OUT)
	else:
		line.modulate.a = target_alpha
	entry["alpha"] = target_alpha
	_edge_visuals[key] = entry


## Edge brightness tiers — rule 2: edges are ALWAYS drawn (existence/shape never hidden), only
## alpha varies. Brightest when touching the current node, bright for the reachable-now row,
## medium for a fully-visited edge, faint (never zero) otherwise.
func _edge_alpha(from_node: RunMapNode, to_node: RunMapNode, reachable_ids: Array[String]) -> float:
	if from_node.id == RunState.current_node_id or to_node.id == RunState.current_node_id:
		return _EDGE_ALPHA_CURRENT
	if reachable_ids.has(from_node.id) or reachable_ids.has(to_node.id):
		return _EDGE_ALPHA_REACHABLE
	if from_node.visited and to_node.visited:
		return _EDGE_ALPHA_VISITED
	return _EDGE_ALPHA_FAINT


## Item E lineage — black-border + rounded-corner + node-type-colored wash, same convention
## CombatView.gd's die slots/panels use, now modulated per lighting tier via _node_wash_color().
func _make_node_style(node_type: String, tier: String) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = _node_wash_color(node_type, tier)
	sb.border_color = _NODE_PANEL_BORDER_COLOR
	sb.set_border_width_all(_NODE_PANEL_BORDER_WIDTH)
	sb.set_corner_radius_all(_NODE_PANEL_CORNER_RADIUS)
	return sb


## Rule 2 (accessibility, spec §12): brightness/wash is decorative reinforcement only — a node's
## clickability (tier=="reachable") and its icon are never gated by this, only how "lit" it reads.
func _node_wash_color(node_type: String, tier: String) -> Color:
	var base: Color = _NODE_COLOR.get(node_type, Color(0.2, 0.2, 0.22, 0.5))
	match tier:
		"current", "reachable":
			return base
		"fog":
			var c := base
			c.a = base.a * 0.4
			return _toward_grey(c, 0.6)
		_:   # "dim" — visited or an inert unchosen node
			var c := base
			c.a = base.a * 0.55
			return _toward_grey(c, 0.25)


## Manual desaturation (lerp toward the color's own luminance-grey) — avoids depending on any
## Color method not verified against this project's pinned Godot 4.7.2 (VERSION.md flags 4.4-4.7
## as a training-data gap; this uses only plain arithmetic, no version-specific API).
func _toward_grey(c: Color, amount: float) -> Color:
	var l := 0.299 * c.r + 0.587 * c.g + 0.114 * c.b
	var grey := Color(l, l, l, c.a)
	return c.lerp(grey, amount)


## Auto-frames the camera around EVERY rendered node — not just current+reachable (see
## visual-polish-backlog P0-1, fixed 2026-09-19). The previous version only put
## current_node_id + the reachable-now row into the fit box, so any node 2+ rows out (still
## drawn, per rule 3/4 — dim or fogged "?", never hidden) sat outside the framed box and got
## clipped at the viewport edge; on a fresh run (single reachable point) the fit box was also
## tiny, so the whole graph read as a narrow sliver in the middle of empty background art.
## _build_graph_visuals() already instantiates a button/glow for every node in _graph.rows up
## front (see that function + this file's header STRUCTURE note) — _node_visuals is therefore
## already the full "rendered so far" set, not a per-frame subset, so iterating it here frames
## the whole graph rather than only what is currently interactable.
## (see this file's header DEVIATION note — no user-drag pan/zoom input is added, only this
## automatic reframe).
func _update_camera(animate: bool) -> void:
	if _graph == null or _camera == null:
		return

	# The window: rows around where the player actually is. See _CAMERA_ROWS_AHEAD.
	var current_row := _current_row()
	var pts: Array = []
	for entry in _node_visuals.values():
		var n: RunMapNode = entry["node"]
		var d := n.row - current_row
		if d < -_CAMERA_ROWS_BEHIND or d > _CAMERA_ROWS_AHEAD:
			continue
		pts.append(_node_world_pos(n))
	if pts.is_empty():
		# Nothing in the window (a map shape this code has not seen) — fall back to everything
		# rather than to an empty frame showing the player nothing at all.
		for entry in _node_visuals.values():
			pts.append(_node_world_pos(entry["node"]))
	if pts.is_empty():
		return

	var min_x: float = pts[0].x
	var max_x: float = pts[0].x
	var min_y: float = pts[0].y
	var max_y: float = pts[0].y
	for p in pts:
		min_x = minf(min_x, p.x)
		max_x = maxf(max_x, p.x)
		min_y = minf(min_y, p.y)
		max_y = maxf(max_y, p.y)

	var center := Vector2((min_x + max_x) * 0.5, (min_y + max_y) * 0.5)
	# `pts` are node CENTRES. Adding a full _NODE_SIZE covers the half sticking out on each side;
	# without it the outermost node in the window is framed to its middle and clipped in half.
	var box_size := Vector2(max_x - min_x, max_y - min_y) + _NODE_SIZE + _CAMERA_MARGIN
	var vp_size := get_viewport_rect().size
	# FIT: viewport / box. The inverse of what this line used to be — see the zoom comment above.
	var zoom_factor := clampf(
		minf(vp_size.x / maxf(box_size.x, 1.0), vp_size.y / maxf(box_size.y, 1.0)),
		_CAMERA_ZOOM_MIN, _CAMERA_ZOOM_MAX)
	var target_zoom := Vector2.ONE * zoom_factor

	if animate and is_inside_tree():
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(_camera, "position", center, _CAMERA_REFRAME_DURATION).set_ease(Tween.EASE_OUT)
		tw.tween_property(_camera, "zoom", target_zoom, _CAMERA_REFRAME_DURATION).set_ease(Tween.EASE_OUT)
	else:
		_camera.position = center
		_camera.zoom = target_zoom


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
## never before it. This IS the path where the "?" -> icon crossfade is actually observable
## for the combat-return case too — see this file's header DEVIATION note #2 (that note's
## caveat about a brand-new RunMapController instance having no prior-frame fog state still
## applies; the reveal is still functionally correct, only unanimated on that first paint).
func _finish_node() -> void:
	_close_overlay()
	RunState.after_node()
	_refresh(true)
	# AFTER after_node(), not before: that call is what advances power_level and the phase, and
	# a save taken ahead of it would resume the player onto a node they had already finished.
	_save_map_progress()


# ===========================================================================
# Reward / event / shop / treasure overlays (checklist step 4, reward-system pass —
# design/gdd/godot-port-rule-spec.md §9). Built procedurally at runtime, same convention
# this file already uses for graph node/edge visuals, rather than hand-laying every card/
# button in RunMap.tscn — the number of reward cards/shop items/event options varies per
# node, so a static scene tree can't describe it. One shared dim+panel overlay is reused
# for all four flows; each flow just clears and repopulates its content VBox.
# ===========================================================================

const _OVERLAY_DIM_COLOR := Color(0, 0, 0, 0.68)
const _OVERLAY_PANEL_MIN_WIDTH := 620.0
const _CARD_SEPARATION := 14

var _overlay_dim: ColorRect
var _overlay_bg: TextureRect     # painted scene behind the dim — see _build_overlay_ui()
var _event_node_id: String = ""   # so the RESULT screen reuses the offer's own backdrop
var _overlay_vbox: VBoxContainer
var _shop_items: Array = []
var _shop_rng: Rng = null


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
func _add_card(title: String, desc: String, sub: String, button_text: String,
		button_disabled: bool, on_pressed: Callable, rar: int = -1, owned: bool = false) -> Button:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", DangoTheme.panel_style(DangoTheme.BG_PANEL_SOFT, 2, 8, 12.0))
	_overlay_vbox.add_child(card)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	card.add_child(row)

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


## Deterministic per-node RNG salt scheme: each of the 4 overlay flows below uses a
## different constant (601 is reserved for RunState._generate_post_combat_rewards()'s own
## reward roll) so a node that could theoretically be re-entered never draws the same
## stream twice from the same run_seed.
func _node_rng(node_id: String, salt: int) -> Rng:
	return Rng.new(Rng.derive_combat_seed(RunState.run_seed, node_id, salt))


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
			"TAKE", false, func(): _on_reward_chosen(r), int(r.get("rar", 0)))
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
## 2-3 options, apply the real effect (RunState.apply_event_effect()), show the result
## message, then finish the node (src/engine.js chooseNode() 'event' branch / eventDone()).
func _on_event_node(node_id: String) -> void:
	var rng := _node_rng(node_id, 501)
	# Only events whose options actually DO something — see ContentDB.playable_event_keys().
	# Offering an option whose effect is unported means the player chooses and nothing
	# happens, which is indistinguishable from a bug.
	var keys := ContentDB.playable_event_keys()
	if keys.is_empty():
		push_error("RunMapController: no playable events in ContentDB — cannot resolve event node")
		_finish_node()
		return
	var key: String = keys[rng.next_int(keys.size())]
	var ev: Dictionary = ContentDB.events[key]
	_event_node_id = node_id
	_open_overlay(_event_backdrop(node_id))
	_add_overlay_title("%s  %s" % [String(ev.get("icon", "")), String(ev.get("n", "EVENT"))])
	_add_overlay_body(String(ev.get("desc", "")))
	for opt in ContentDB.playable_event_options(key):
		var o: Dictionary = opt
		_add_card(String(o.get("text", "")), String(o.get("desc", "")), "", "CHOOSE", false,
			func(): _on_event_choice(o, rng), RewardGenerator.event_option_rarity(o))


func _on_event_choice(opt: Dictionary, rng: Rng) -> void:
	var msg := RunState.apply_event_effect(String(opt.get("fx", "")), rng)
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
func _on_shop_node(node_id: String) -> void:
	_shop_rng = _node_rng(node_id, 502)
	_shop_items = RewardGenerator.generate_shop_items(_shop_rng, RunState.owned_relic_ids)
	_render_shop()


func _render_shop() -> void:
	# Re-rendered after every purchase, so this doubles as the shop's save point: shards spent
	# and a relic gained must survive a quit even though the node is not finished.
	_save_map_progress()
	_open_overlay(BattleBackdrop.class_background("shop"))
	_add_overlay_title("CHIMERA MERCHANT")
	_add_overlay_body("Gene Shard: %d" % RunState.shards_this_run)
	for item in _shop_items:
		var it: Dictionary = item
		var bought: bool = bool(it.get("bought", false))
		var afford: bool = RunState.shards_this_run >= int(it.get("cost", 0))
		var label := "BOUGHT" if bought else "BUY (%d)" % int(it.get("cost", 0))
		# runloop-ux-backlog P0-1: "bought" and "can't afford" used to share one disabled look
		# (button_disabled = bought or not afford, styled identically) — a player scanning fast
		# could not tell "you already own this" (permanent, a success) from "come back later"
		# (temporary). button_disabled stays the same OR (nothing to press either way); only
		# the STYLE now branches via _add_card's `owned` param.
		_add_card(String(it.get("title", "")), String(it.get("desc", "")), "",
			label, bought or not afford, func(): _on_shop_buy(it), int(it.get("rar", 0)), bought)
	_add_continue_button("DONE", func(): _finish_node())


func _on_shop_buy(item: Dictionary) -> void:
	if RunState.try_buy_shop_item(item, _shop_rng):
		item["bought"] = true
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
