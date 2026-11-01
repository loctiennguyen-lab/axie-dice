class_name CoreFireFX
extends Control
## UI-06 L2: what the player sees when `core_fired(id, uid, amount, kind)` arrives in combat (moments/moment-core-firing,
## motion-ui06.md "Core firing"). One fire = socket ring + dotted line socket -> unit + travelling dot + a number at the
## unit. Cores use the cream `fire_ring` and the family emblem in front of the number; an Anchor (`a_*`) uses the gold
## `anchor_fire` and no emblem, so it never reads as a Core. Pure view: it only listens to what CombatView forwards
## (CoreHooks.mute already keeps previews / forecasts from emitting, so nothing here has to know about them).
## Several fires queue 180 ms apart, at most MAX_LIVE are on screen at once.
## Reduce motion: no line / dot, number only fades. Reduce flashing: ring alpha <= 0.12 (the ring still draws).
## Test hooks: live / max_seen / queued() / log (one {id, uid, anchor, amount, kind} per fire that STARTED).

const MAX_LIVE := 6
const GAP_MSEC := 180
const LIFE_SEC := 1.4

var panel: CorePanel = null
## Callable(uid:int) -> Vector2 global point of the unit, or Vector2(-1, -1) when the unit is not on screen.
var unit_pos: Callable
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
	var col := UI3Theme.color("anchor_fire") if anchor else UI3Theme.color("fire_ring")
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
			_anchor_pulse(holder, slot, col, noflash, nomove)
	var uv: Vector2 = unit_pos.call(int(e["uid"])) if unit_pos.is_valid() else Vector2(-1, -1)
	var has_unit := uv.x >= 0.0 and uv.y >= 0.0
	var to := _local(uv) if has_unit else Vector2(-1, -1)
	if has_unit and from.x >= 0.0 and not nomove:
		_line(holder, from, to, col)
	if has_unit and int(e["amount"]) > 0:
		_number(holder, to, e, col, anchor, nomove)


func _ring(holder: Control, slot: Control, col: Color, noflash: bool, nomove: bool) -> void:
	var r := Panel.new()
	r.name = "FireRing"
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := UI3Theme.flat(Color(0, 0, 0, 0), UI3Theme.radius("s"), 4, col)
	r.add_theme_stylebox_override("panel", sb)
	var rc := slot.get_global_rect()
	r.position = _local(rc.position)
	r.size = rc.size
	r.pivot_offset = rc.size * 0.5
	var a0 := 0.12 if noflash else 1.0
	r.modulate.a = a0
	r.scale = Vector2.ONE * 0.9
	holder.add_child(r)
	var tw := r.create_tween().set_parallel(true)
	if not nomove:
		tw.tween_property(r, "scale", Vector2.ONE * 1.3, 0.36).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(r, "modulate:a", 0.0, 0.36).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## Anchor only (motion-ui06 "Anchor fires"): gold glow behind / around the AnchorTile (outside the ring) and the tile
## itself pops 1 -> 1.25 -> 1 in 160 ms. Reduce motion: no pop, glow only fades. Reduce flashing: glow alpha <= 0.12.
func _anchor_pulse(holder: Control, slot: Control, col: Color, noflash: bool, nomove: bool) -> void:
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


func _line(holder: Control, from: Vector2, to: Vector2, col: Color) -> void:
	var ink := Line2D.new()
	ink.name = "FireLineInk"
	ink.width = 10
	ink.default_color = UI3Theme.color("plate_ink")
	var l := Line2D.new()
	l.name = "FireLine"
	l.width = 4
	l.default_color = UI3Theme.color("anchor_fire") if col == UI3Theme.color("anchor_fire") else UI3Theme.color("fire_line")
	for n in [ink, l]:
		(n as Line2D).points = PackedVector2Array([from, from])
		(n as Line2D).modulate.a = 0.0
		holder.add_child(n)
	var dot := TextureRect.new()
	dot.name = "FireDot"
	dot.texture = UI6Assets.fx("pulse", 32)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.custom_minimum_size = Vector2(32, 32)
	dot.size = Vector2(32, 32)
	dot.position = from - dot.size * 0.5
	holder.add_child(dot)
	var tw := holder.create_tween().set_parallel(true)
	tw.tween_method(func(t: float) -> void:
		var p := from.lerp(to, t)
		for n in [ink, l]:
			(n as Line2D).points = PackedVector2Array([from, p])
		dot.position = p - dot.size * 0.5, 0.0, 1.0, 0.22).set_delay(0.04).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for n in [ink, l]:
		tw.tween_property(n, "modulate:a", 1.0, 0.07).set_delay(0.04)
		tw.tween_property(n, "modulate:a", 0.0, 0.2).set_delay(0.28)
	tw.tween_property(dot, "modulate:a", 0.0, 0.05).set_delay(0.26)


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
