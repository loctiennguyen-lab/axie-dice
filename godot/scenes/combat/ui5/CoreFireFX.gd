class_name CoreFireFX
extends Control
## UI-06 L2: what the player sees when `core_fired(id, uid, amount, kind)` arrives in combat (moments/moment-core-firing,
## motion-ui06.md "Core firing"). One fire = socket ring + a few motes curving socket -> unit, then a light skill-clip burst + a number at the
## unit. Cores use the cream `fire_ring` and the family emblem in front of the number; an Anchor (`a_*`) uses the gold
## `anchor_fire` and no emblem, so it never reads as a Core. Pure view: it only listens to what CombatView forwards
## (CoreHooks.mute already keeps previews / forecasts from emitting, so nothing here has to know about them).
## Several fires queue 180 ms apart, at most MAX_LIVE are on screen at once.
## Reduce motion: no motes / burst, socket pulse only. Reduce flashing: ring alpha <= 0.12 (the ring still draws).
## Test hooks: live / max_seen / queued() / log (one {id, uid, anchor, amount, kind} per fire that STARTED).

const MAX_LIVE := 6
const GAP_MSEC := 180
const LIFE_SEC := 1.4
const MOTES := 5

var panel: CorePanel = null
## Callable(uid:int) -> Vector2 global point of the unit, or Vector2(-1, -1) when the unit is not on screen.
var unit_pos: Callable
## Callable(uid:int, kind:String, anchor:bool): the burst when the last mote lands (CombatView plays a skill clip).
var burst: Callable
var live := 0
var max_seen := 0
var log: Array = []
var _queue: Array = []
var _last_start := -100000


func _init() -> void:
	name = "CoreFireFX"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	set_process(false)


func setup(p_panel: CorePanel, p_unit_pos: Callable) -> CoreFireFX:
	panel = p_panel
	unit_pos = p_unit_pos
	return self


func queued() -> int:
	return _queue.size()


## Entry point (CombatView._on_core_fired). Starts at once when allowed, else waits its turn.
func fire(core_id: String, uid: int, amount: int, kind: String) -> void:
	_queue.append({"id": core_id, "uid": uid, "amount": amount, "kind": kind})
	_pump()


func _pump() -> void:
	while not _queue.is_empty() and live < MAX_LIVE and Time.get_ticks_msec() - _last_start >= GAP_MSEC:
		_start(_queue.pop_front())
	set_process(not _queue.is_empty())


func _process(_dt: float) -> void:
	_pump()


func _slot_of(core_id: String) -> Control:
	if panel == null or not is_instance_valid(panel):
		return null
	var s: Control = panel._slot_by_id.get(core_id)
	return s if s != null and is_instance_valid(s) and s.is_inside_tree() and s.is_visible_in_tree() else null


func _local(p: Vector2) -> Vector2:
	return p - global_position


func _start(e: Dictionary) -> void:
	_last_start = Time.get_ticks_msec()
	var id := String(e["id"])
	var anchor := id.begins_with("a_")
	live += 1
	max_seen = maxi(max_seen, live)
	log.append({"id": id, "uid": int(e["uid"]), "anchor": anchor, "amount": int(e["amount"]), "kind": String(e["kind"])})
	var col := UI3Theme.color("anchor_fire") if anchor else UI3Theme.color(CoreFeedback.color_token(String(e["kind"])))
	var slot := _slot_of(id)
	var holder := Control.new()
	holder.name = "AnchorFireFX" if anchor else "CoreFire"
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(holder)
	var tw := holder.create_tween()
	tw.tween_interval(LIFE_SEC)
	tw.tween_callback(func() -> void:
		live = maxi(live - 1, 0)
		holder.queue_free()
		_pump())
	var noflash := CombatView.flashes_suppressed()
	var nomove := CombatView.motion_suppressed()
	var from := Vector2(-1, -1)
	if slot != null:
		from = _local(slot.get_global_rect().get_center())
		_ring(holder, slot, col, noflash, nomove)
		if anchor:
			_anchor_pulse(holder, slot, col, noflash, nomove, anchor)
	var uv: Vector2 = unit_pos.call(int(e["uid"])) if unit_pos.is_valid() else Vector2(-1, -1)
	var has_unit := uv.x >= 0.0 and uv.y >= 0.0
	var to := _local(uv) if has_unit else Vector2(-1, -1)
	if has_unit and from.x >= 0.0 and not nomove:
		_motes(holder, from, to, col, int(e["uid"]), String(e["kind"]), anchor)
	if SHOW_NUMBER and has_unit and int(e["amount"]) > 0:
		_number(holder, to, e, col, anchor, nomove)


## Liam 2/11: ONE number per fire. CombatView's float note ("Bastion +3 Shield", name + number, merged per unit) owns it, so the
## FX draws ring / line / dot only. Flip this to move the number back here (then drop the float note's amount).
const SHOW_NUMBER := false


## Socket flash: a soft halo + a thick ring drawn in code (a transparent StyleBoxFlat Panel did not show on screen).
class RingFX extends Control:
	var col := Color.WHITE
	var ring_w := 4.0

	func _draw() -> void:
		var c := size * 0.5
		var rad := maxf(size.x, size.y) * 0.5
		draw_circle(c, rad * 1.45, Color(col.r, col.g, col.b, 0.14))
		draw_circle(c, rad * 1.15, Color(col.r, col.g, col.b, 0.22))
		draw_arc(c, rad, 0.0, TAU, 48, col, ring_w, true)


func _ring(holder: Control, slot: Control, col: Color, noflash: bool, nomove: bool) -> void:
	var r := RingFX.new()
	r.name = "FireRing"
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.col = col.lightened(0.1)
	r.ring_w = 5.0 * maxf(UI3Theme.layout_scale(), 0.5) + 2.0
	var rc := slot.get_global_rect()
	r.position = _local(rc.position)
	r.size = rc.size
	r.pivot_offset = rc.size * 0.5
	var a0 := 0.12 if noflash else 1.0
	r.modulate.a = a0
	r.scale = Vector2.ONE * 0.85
	holder.add_child(r)
	var tw := r.create_tween().set_parallel(true)
	if not nomove:
		tw.tween_property(r, "scale", Vector2.ONE * 1.35, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(r, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## Anchor only (motion-ui06 "Anchor fires"): gold glow behind / around the AnchorTile (outside the ring) and the tile
## itself pops 1 -> 1.25 -> 1 in 160 ms. Reduce motion: no pop, glow only fades. Reduce flashing: glow alpha <= 0.12.
func _anchor_pulse(holder: Control, slot: Control, col: Color, noflash: bool, nomove: bool, glow := true) -> void:
	var rc := slot.get_global_rect()
	var g := TextureRect.new()
	g.name = "AnchorPulse"
	g.texture = UI6Assets.fx("pulse", 128)
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	g.stretch_mode = TextureRect.STRETCH_SCALE
	g.modulate = Color(col.r, col.g, col.b, 0.12 if noflash else 0.9)
	var side := maxf(rc.size.x, rc.size.y) * 2.4
	g.size = Vector2.ONE * side
	g.position = _local(rc.get_center()) - g.size * 0.5
	g.pivot_offset = g.size * 0.5
	g.scale = Vector2.ONE * (1.0 if nomove else 0.7)
	g.visible = glow
	holder.add_child(g)
	var tw := g.create_tween().set_parallel(true)
	if not nomove:
		tw.tween_property(g, "scale", Vector2.ONE * 1.25, 0.36).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(g, "modulate:a", 0.0, 0.36).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if not nomove:
		slot.pivot_offset = slot.size * 0.5
		var pt := slot.create_tween()
		pt.tween_property(slot, "scale", Vector2.ONE * 1.25, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pt.tween_property(slot, "scale", Vector2.ONE, 0.08)


## polish 3/11 P1 #4 (Liam): no dotted line / arrow / running dot. 4 soft glowing motes with a short tail fly a curve from the
## socket to the unit (~0.35 s); the last one to land calls `burst(uid, kind, anchor)` (CombatView plays a light official skill clip).
## Drawn in code (soft circles), one layer node named "FireMote" for all motes. Size follows the layout scale (~12 px at 1280).
class MoteLayer extends Control:
	var col := Color.WHITE
	var r := 8.0
	var cap := 1.0
	var motes: Array = []   ## {pos, hist:Array[Vector2], a}

	func _draw() -> void:
		for m in motes:
			var a: float = float(m["a"]) * cap
			if a <= 0.0:
				continue
			var hist: Array = m["hist"]
			var n := hist.size()
			for k in n:
				var f := float(k + 1) / float(n + 1)
				draw_circle(hist[k], r * (0.2 + 0.7 * f), Color(col.r, col.g, col.b, 0.5 * f * f * a))
			var p: Vector2 = m["pos"]
			draw_circle(p, r * 1.9, Color(col.r, col.g, col.b, 0.28 * a))
			draw_circle(p, r, Color(col.r, col.g, col.b, a))
			draw_circle(p, r * 0.4, Color(1, 1, 1, 0.8 * a))


func _motes(holder: Control, from: Vector2, to: Vector2, col: Color, uid: int, kind: String, anchor: bool) -> void:
	var ls := maxf(UI3Theme.layout_scale(), 0.5)
	var dist := from.distance_to(to)
	var mid := from.lerp(to, 0.5)
	# One arc bowing sideways (away from the screen centre), so the cluster reads as a streak, not a dotted column.
	var perp := (to - from).orthogonal().normalized()
	var centre_x := get_viewport_rect().size.x * 0.5
	if (mid + perp * 10.0).distance_to(Vector2(centre_x, mid.y)) < mid.distance_to(Vector2(centre_x, mid.y)):
		perp = -perp
	var bulge := maxf(60.0 * ls, dist * 0.35)
	var layer := MoteLayer.new()
	layer.name = "FireMote"
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.col = col
	layer.r = 12.0 * ls   # ~6 px radius core, halo ~11 px: reads as 12-14 px dots at 1280
	layer.cap = 0.5 if CombatView.flashes_suppressed() else 1.0
	holder.add_child(layer)
	var n := MOTES
	for i in n:
		var m := {"pos": from, "hist": [], "a": 0.0}
		layer.motes.append(m)
		var last := i == n - 1
		var jitter := (float(i) - float(n - 1) * 0.5) * 5.0 * ls   # a few px across the stream
		var mid_i := mid + perp * (bulge * (0.92 + 0.04 * float(i)) + jitter)
		var tw := holder.create_tween()
		tw.tween_interval(0.006 * i)
		tw.tween_callback(func() -> void: m["a"] = 1.0)
		tw.tween_method(func(t: float) -> void:
			var q := from.lerp(mid_i, t).lerp(mid_i.lerp(to, t), t)
			var h: Array = m["hist"]
			h.append(m["pos"])
			if h.size() > 7:
				h.pop_front()
			m["pos"] = q
			layer.queue_redraw(), 0.0, 1.0, 0.32).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_callback(func() -> void:
			m["a"] = 0.0
			layer.queue_redraw()
			if last and burst.is_valid():
				burst.call(uid, kind, anchor))


func _number(holder: Control, at: Vector2, e: Dictionary, col: Color, anchor: bool, nomove: bool) -> void:
	var kind := String(e["kind"])
	var ncol: Color = col if anchor else UI3Theme.color(CoreFeedback.color_token(kind))
	var row := HBoxContainer.new()
	row.name = "FireNumber"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 4)
	var fpx := UI3Theme.size_of("fire_num")
	if not anchor:
		var def = RelicRegistry.get_def(String(e["id"]))
		if def != null and String(def.core_axis) != "":
			var em := TextureRect.new()
			em.name = "FamilyEmblem"
			em.texture = UI6Assets.family(String(def.core_axis), fpx * 0.6)
			em.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			em.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			em.custom_minimum_size = Vector2.ONE * fpx * 0.6
			em.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(em)
	var l := UI3.label("+%d" % int(e["amount"]), "LabelDisplay")
	l.name = "Amount"
	l.add_theme_font_size_override("font_size", fpx)
	l.add_theme_color_override("font_color", ncol)
	l.add_theme_color_override("font_outline_color", UI3Theme.color("plate_ink"))
	l.add_theme_constant_override("outline_size", 8)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(l)
	holder.add_child(row)
	row.reset_size()
	row.position = at - row.size * 0.5
	row.pivot_offset = row.size * 0.5
	row.modulate.a = 0.0
	var tw := row.create_tween()
	if nomove:
		tw.tween_property(row, "modulate:a", 1.0, 0.1)
		tw.tween_interval(0.6)
		tw.tween_property(row, "modulate:a", 0.0, 0.1)
		return
	row.scale = Vector2.ONE * 1.4
	tw.tween_interval(0.28)
	tw.set_parallel(true)
	tw.tween_property(row, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(row, "modulate:a", 1.0, 0.2)
	tw.chain().tween_interval(0.5)
	tw.chain().tween_property(row, "position:y", row.position.y - 24.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(row, "modulate:a", 0.0, 0.4)
