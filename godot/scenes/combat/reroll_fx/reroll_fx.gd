class_name RerollFX
extends CanvasLayer
## Reroll presentation for combat — port of "Godot Combat Reroll FX v2" (Claude Design).
##
## The roll RESULT is decided before play() is called. This node only performs it and snaps
## every die to the face it was given. Sequence (1x):
##   1 wind-up   0.26s  cards shake/lift/squash, tray pops open, board dims
##   2 toss      ~0.8s  cubes fly out of their cards 35 ms apart, dust + thud on every bounce,
##                      screen shake on the first hit
##   3 tease     0.55s  when every other die has stopped, the last Axie die keeps spinning under
##                      a spotlight while the rest of the screen goes darker
##   4 lock      0.3s/die  snap to result, bits in the face-type colour, tally chip ticks up,
##                      click pitch rises per die; MAX = tilted tag + gold flash + extra bits
##   5 grade     0.5–1.1s  NICE / GREAT / PERFECT / JACKPOT stamp + power delta vs last roll
##   6 collect   0.52s  cubes arc back into their cards, card punch + flash + chip (+2/−1/NEW/MAX)
##
## Usage (see README.md):
##   fx.play([{id=0, card=$Card0, faces=[{type="dmg",value=3}, ...6], final=4, prev=1,
##             class_color=Color("#7DC943")}, ...], {rerolls_left=1})
##   fx.die_returned.connect(func(id, face, is_max): card_for(id).show_face(face))
##   fx.finished.connect(_on_reroll_done)

signal started
signal die_locked(id: Variant, face_index: int, is_max: bool)
## Fired when a cube lands back in its card. Update the card's shown face HERE, not before.
signal die_returned(id: Variant, face_index: int, is_max: bool)
## Emitted on every screen shake. Hook your Camera2D/board here if you shake elsewhere.
signal shake_requested(amplitude: float)
signal finished(grade: Dictionary)

const DESIGN := Vector2(1920, 1080)
const TYPE_COLORS := {
	"dmg": Color("#F54540"), "shield": Color("#31C6FF"), "heal": Color("#3FCD3C"),
	"mana": Color("#BF6BFF"), "poison": Color("#A8D84A"), "buff": Color("#FF9345"),
	"debuff": Color("#FF8FC7"), "summon": Color("#FFD76A"),
}
const TALLY_ORDER := ["dmg", "shield", "heal", "poison", "mana", "buff", "debuff", "summon"]
const EGG_CLASS := Color("#39C5F3")
# Physics bounds of the felt, in design px (1920×1080 artboard).
const TRAY_RECT := Rect2(360, 110, 1200, 600)
const FELT := { "L": 383.0, "R": 1537.0, "T": 179.0, "B": 687.0 }
const STAMP_POS := Vector2(960, 432)
const GRAVITY := 2600.0

## 1.0 = normal. 2.5 = the design's slow-mo review speed.
@export var slowmo: float = 1.0
## Settings → "Fast reroll": no tease, no grade stamp, shorter hold.
@export var fast_mode: bool = false
@export var screen_shake: bool = true
## Gold full-screen flashes (MAX / big grade). Off for "Reduce flashing".
@export var flashes: bool = true
@export var sound: bool = true
## Optional: this camera's offset is shaken too.
@export var shake_camera: Camera2D
## Baloo 2 ExtraBold recommended (the game's display font). Falls back to the theme font.
@export var display_font: Font
## Optional type icons: {"dmg": preload("res://assets/fx/dmg.png"), ...}
@export var type_icons: Dictionary = {}
@export var reroll_icon: Texture2D

var type_colors: Dictionary = TYPE_COLORS.duplicate()

var _stage := "idle"
var _run := 0
var _entries: Array = []
var _bodies: Array = []        # Dictionary per die (sim state + node)
var _hero: Dictionary = {}
var _teasing := false
var _first_hit := false
var _lock_n := 0
var _arrived := 0
var _last_thud := 0
var _grade: Dictionary = {}
var _tally_n: Dictionary = {}
var _cards: Dictionary = {}    # id -> {card, base_pos, base_rot, base_scale, base_mod}
var _shake_seq := 0

var _u := 1.0                  # design → viewport scale
var _off := Vector2.ZERO       # design → viewport offset

# nodes
var _root: Node2D
var _dim: ColorRect
var _spot: ColorRect
var _spot_mat: ShaderMaterial
var _flash: ColorRect
var _tray: Panel
var _tray_count: Label
var _tally_box: HBoxContainer
var _tally_chips: Dictionary = {}
var _world: Node2D
var _bits: RerollFxBits
var _tags: Node2D
var _stamp: VBoxContainer
var _stamp_main: Label
var _stamp_sub: Label
var _stamp_panel: PanelContainer
var _chips_layer: Node2D
var _sfx: RerollSfx


func _ready() -> void:
	layer = 20
	_build()
	get_viewport().size_changed.connect(_fit)
	_fit()


func is_playing() -> bool:
	return _stage != "idle"


## entries: Array of Dictionary
##   id           any key you use for the unit / die
##   card         Control — the die card on the deck (cube launches from and returns to it)
##   faces        Array of 6 {type:String, value:int}
##   final        int face index already decided by the game logic
##   prev         int face index shown before this reroll (for +2 / −1 / NEW chips and grade)
##   class_color  Color of the Axie class band
##   egg          bool — small egg die (no delta chip, not graded). Default false.
##   rest_position  optional Vector2 — the card's resting local position, if it may be
##                  mid-tween when play() is called (restored there afterwards)
## opts: {rerolls_left:int}
func play(entries: Array, opts: Dictionary = {}) -> void:
	if _stage != "idle":
		skip()
		return
	if entries.is_empty():
		return
	_run += 1
	_entries = entries
	_sfx.enabled = sound
	_bits.time_scale = slowmo
	_bits.clear()
	for c in _world.get_children():
		c.queue_free()
	for c in _tags.get_children():
		c.queue_free()
	_tally_n = {}
	_lock_n = 0
	_arrived = 0
	_teasing = false
	_first_hit = false
	_grade = _grade_of(entries)
	_tray_count.text = "×%d" % int(opts.get("rerolls_left", 0))
	_tray_count.get_parent().visible = opts.has("rerolls_left")
	_build_tally(entries)
	_stamp.modulate.a = 0.0
	_capture_cards(entries)
	_stage = "open"
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP   # the board is locked while the tray is up
	started.emit()
	_sfx.play("open")
	_open_tray(true)
	_windup(entries)
	_later(0.26, _toss)


## Tap-to-skip: during the toss every die snaps to its result; during the hold it collects now.
func skip() -> void:
	if _stage == "toss":
		for b in _bodies:
			if b.phase == "wait" or (b.phase == "fly" and not b.inside):
				b.x = FELT.L + 140.0 + randf() * (FELT.R - FELT.L - 280.0)
				b.y = FELT.T + 100.0 + randf() * (FELT.B - FELT.T - 200.0)
				b.inside = true
				b.vx = 0.0; b.vy = 0.0
				b.phase = "fly"
				b.node.visible = true
			if b.phase == "fly":
				b.hero = false
				_begin_settle(b, 0.14)
	elif _stage == "hold":
		_collect()


# ── sequence ────────────────────────────────────────────────────────────────

func _windup(entries: Array) -> void:
	var n := 0
	for e in entries:
		if e.get("egg", false):
			continue
		var cd: Dictionary = _cards.get(e.id, {})
		var card: Control = cd.get("card")
		if card == null:
			continue
		var dir := -1.0 if n % 2 == 0 else 1.0
		n += 1
		var t := _card_tween(card)
		# shake-in-place, lift, then squash just before the throw
		t.tween_property(card, "rotation", deg_to_rad(3.0 * dir), 0.045 * slowmo)
		t.parallel().tween_property(card, "position:y", cd.base_pos.y - 10.0, 0.045 * slowmo)
		t.parallel().tween_property(card, "scale", cd.base_scale * 1.04, 0.045 * slowmo)
		t.tween_property(card, "rotation", deg_to_rad(-3.0 * dir), 0.045 * slowmo)
		t.parallel().tween_property(card, "position:y", cd.base_pos.y - 14.0, 0.045 * slowmo)
		t.tween_property(card, "rotation", deg_to_rad(2.0 * dir), 0.04 * slowmo)
		t.tween_property(card, "rotation", 0.0, 0.1 * slowmo).set_ease(Tween.EASE_IN)
		t.parallel().tween_property(card, "position:y", cd.base_pos.y + 4.0, 0.1 * slowmo).set_ease(Tween.EASE_IN)
		t.parallel().tween_property(card, "scale", cd.base_scale * Vector2(1.07, 0.94), 0.1 * slowmo).set_ease(Tween.EASE_IN)


func _toss() -> void:
	var main_ids: Array = []
	for e in _entries:
		if not e.get("egg", false):
			main_ids.append(e.id)
	var hero_id: Variant = main_ids[main_ids.size() - 1] if main_ids.size() > 1 and not fast_mode else null
	var now := Time.get_ticks_msec()
	_bodies.clear()
	_hero = {}
	var n := 0
	for e in _entries:
		var egg: bool = e.get("egg", false)
		var size := 62.0 if egg else 104.0
		var c := _card_center(e.id)
		var tx := FELT.L + 140.0 + randf() * (FELT.R - FELT.L - 280.0)
		var ty := FELT.T + 100.0 + randf() * (FELT.B - FELT.T - 200.0)
		var ft := 0.5 + randf() * 0.12
		var d := RerollDie.new()
		d.id = e.id
		d.egg = egg
		d.size = size
		d.faces = e.faces
		d.class_color = EGG_CLASS if egg else e.get("class_color", Color("#7DC943"))
		d.type_colors = type_colors
		d.type_icons = type_icons
		d.font = _font()
		d.setup()
		d.visible = false
		d.position = c
		# start showing the previous face, randomly twisted
		d.q = d.target_for(int(e.get("prev", 0)), 20.0)
		_world.add_child(d)
		var sgn := func() -> float: return -1.0 if randf() < 0.5 else 1.0
		var b := {
			"id": e.id, "egg": egg, "size": size, "r": size * 0.56, "node": d,
			"x": c.x, "y": c.y, "h": 0.0, "sc": 1.0,
			"vx": (tx - c.x) / ft, "vy": (ty - c.y) / ft, "vh": GRAVITY * ft / 2.0,
			# angular velocity, rad/s, world axes
			"w": Vector3(sgn.call() * deg_to_rad(520.0 + randf() * 600.0), sgn.call() * deg_to_rad(520.0 + randf() * 600.0), deg_to_rad(randf_range(-200.0, 200.0))),
			"inside": false, "grounded": false, "age": 0.0, "phase": "wait",
			"launch_at": now + int(n * 35 * slowmo),
			"hero": e.id == hero_id,
			"min_t": 0.75 if egg else 0.95 + main_ids.find(e.id) * 0.1 + (0.55 if e.id == hero_id else 0.0),
			"final": int(e.final), "max": false, "entry": e,
		}
		if b.hero:
			_hero = b
		_bodies.append(b)
		n += 1
		# the card fades while its die is out
		var cd: Dictionary = _cards.get(e.id, {})
		if cd.has("card"):
			var card: Control = cd.card
			var t := _card_tween(card)
			t.tween_property(card, "rotation", 0.0, 0.08 * slowmo)
			t.parallel().tween_property(card, "position:y", cd.base_pos.y, 0.08 * slowmo)
			t.parallel().tween_property(card, "scale", cd.base_scale, 0.08 * slowmo)
			t.parallel().tween_property(card, "modulate:a", cd.base_mod.a * 0.3, 0.12 * slowmo)
	_stage = "toss"
	_sfx.play("toss")


func _process(delta: float) -> void:
	if _stage == "idle" or _stage == "open" or _bodies.is_empty():
		return
	var dt := minf(0.033, delta) / slowmo
	var now := Time.get_ticks_msec()
	for b in _bodies:
		if b.phase == "wait":
			if now >= b.launch_at:
				b.phase = "fly"
				b.node.visible = true
			else:
				continue
		match b.phase:
			"fly": _step(b, dt)
			"settle": _settle_step(b, dt)
			"collect": _collect_step(b, dt)
	_collide()
	for b in _bodies:
		_draw_body(b)
	_update_tease()
	if _stage == "toss" and _bodies.all(func(x): return x.phase == "locked"):
		_stage = "hold"
		var show_grade: bool = _grade.get("on", false) and not fast_mode
		if show_grade:
			_later(0.15, func(): if _stage == "hold": _slam(_grade))
		var hold := 1.25 if show_grade else (0.3 if fast_mode else 0.52)
		_later(hold, func(): if _stage == "hold": _collect())


func _step(b: Dictionary, dt: float) -> void:
	b.age += dt
	if not b.grounded:
		b.vh -= GRAVITY * dt
		b.h += b.vh * dt
		if b.h <= 0.0 and b.vh < 0.0:
			b.h = 0.0
			var imp: float = -b.vh
			if imp > 150.0:
				b.vh = imp * 0.4
				b.vx *= 0.72; b.vy *= 0.72
				b.w = (b.w as Vector3) * 0.72 + Vector3(deg_to_rad(randf_range(-240.0, 240.0)), 0, 0)
				if not _first_hit:
					_first_hit = true
					_shake(4.0)
				# dust puff where it hits the felt
				_bits.burst(Vector2(b.x, b.y + b.size * 0.35), [Color("#F3E7D3"), Color("#BFD3CC")],
					2 if b.egg else 4, 30.0 if b.egg else 46.0, 0.6 if b.egg else 0.85)
				_thud()
			else:
				b.vh = 0.0
				b.grounded = true
	if b.h <= 0.0:
		var f := exp(-3.2 * dt)
		b.vx *= f; b.vy *= f
		b.w = (b.w as Vector3) * exp(-2.4 * dt)
	if b.hero and b.age < b.min_t:
		# keep the last die spinning hard until the tease has played
		var w: Vector3 = b.w
		if w.length() < deg_to_rad(560.0) * 1.2:
			b.w = (w.normalized() if w.length() > 0.01 else Vector3(0, 1, 0)) * deg_to_rad(560.0) * 1.2
	b.x += b.vx * dt
	b.y += b.vy * dt
	var wv: Vector3 = b.w
	if wv.length() > 0.0001:
		var nd: RerollDie = b.node
		nd.q = (Quaternion(wv.normalized(), wv.length() * dt) * nd.q).normalized()
	_walls(b)
	var sp := Vector2(b.vx, b.vy).length()
	if (b.grounded and sp < 80.0 and b.age > b.min_t) or b.age > b.min_t + 1.0:
		_begin_settle(b, 0.42 if b.hero else 0.3)


func _walls(b: Dictionary) -> void:
	if not b.inside:
		if b.y < FELT.B - b.r and b.x > FELT.L + b.r and b.x < FELT.R - b.r:
			b.inside = true
		else:
			return
	var w: Vector3 = b.w
	if b.x < FELT.L + b.r:
		b.x = FELT.L + b.r; b.vx = absf(b.vx) * 0.6; w.y += 2.8
	if b.x > FELT.R - b.r:
		b.x = FELT.R - b.r; b.vx = -absf(b.vx) * 0.6; w.y -= 2.8
	if b.y < FELT.T + b.r:
		b.y = FELT.T + b.r; b.vy = absf(b.vy) * 0.6; w.x += 2.8
	if b.y > FELT.B - b.r:
		b.y = FELT.B - b.r; b.vy = -absf(b.vy) * 0.6; w.x -= 2.8
	b.w = w


func _collide() -> void:
	for i in _bodies.size():
		for j in range(i + 1, _bodies.size()):
			var a: Dictionary = _bodies[i]
			var b: Dictionary = _bodies[j]
			if a.phase != "fly" or b.phase != "fly" or not a.inside or not b.inside or a.h > 40.0 or b.h > 40.0:
				continue
			var dx: float = b.x - a.x
			var dy: float = b.y - a.y
			var d := maxf(0.001, sqrt(dx * dx + dy * dy))
			var m: float = a.r + b.r
			if d >= m:
				continue
			var nx := dx / d
			var ny := dy / d
			var push := (m - d) / 2.0
			a.x -= nx * push; a.y -= ny * push
			b.x += nx * push; b.y += ny * push
			var rel: float = (b.vx - a.vx) * nx + (b.vy - a.vy) * ny
			if rel < 0.0:
				var j2 := -rel * 0.85
				a.vx -= nx * j2; a.vy -= ny * j2
				b.vx += nx * j2; b.vy += ny * j2
				a.w = (a.w as Vector3) + Vector3(0, 3.8, 0) * signf((a.w as Vector3).y if (a.w as Vector3).y != 0.0 else 1.0)
				b.w = (b.w as Vector3) + Vector3(0, 3.8, 0) * signf((b.w as Vector3).y if (b.w as Vector3).y != 0.0 else 1.0)


func _begin_settle(b: Dictionary, dur: float) -> void:
	var nd: RerollDie = b.node
	var to: Quaternion = nd.target_for(b.final)
	var from: Quaternion = nd.q
	var dq := (to * from.inverse()).normalized()
	if dq.w < 0.0:
		dq = -dq
	var ang := 2.0 * acos(clampf(dq.w, -1.0, 1.0))
	var axis := Vector3(dq.x, dq.y, dq.z)
	axis = axis.normalized() if axis.length() > 0.0001 else Vector3(0, 0, 1)
	var w: Vector3 = b.w
	# keep rolling the way it was already spinning instead of snapping backwards
	if w.length() > 3.5 and axis.dot(w) < 0.0:
		ang -= TAU
	b.phase = "settle"
	b.st = 0.0
	b.sd = dur
	b.q_from = from
	b.s_axis = axis
	b.s_ang = ang
	b.h_from = b.h


func _settle_step(b: Dictionary, dt: float) -> void:
	b.st += dt
	var p := minf(1.0, b.st / b.sd)
	var c1 := 1.3
	var e := 1.0 + (c1 + 1.0) * pow(p - 1.0, 3) + c1 * pow(p - 1.0, 2)   # back-out overshoot
	var nd: RerollDie = b.node
	nd.q = (Quaternion(b.s_axis, b.s_ang * e) * (b.q_from as Quaternion)).normalized()
	b.h = b.h_from * (1.0 - p)
	var f := exp(-9.0 * dt)
	b.vx *= f; b.vy *= f
	b.x += b.vx * dt; b.y += b.vy * dt
	_walls(b)
	if p >= 1.0:
		b.phase = "locked"
		_lock_fx(b)


func _lock_fx(b: Dictionary) -> void:
	var faces: Array = b.entry.faces
	var f: Dictionary = faces[b.final]
	var mx := _die_max(faces)
	b.max = not b.egg and int(f.value) > 0 and int(f.value) >= mx
	var pos := Vector2(b.x, b.y)
	var col: Color = type_colors.get(f.type, Color.WHITE)
	_bits.ring(pos, b.size * 0.7, Color("#FFD76A") if b.max else Color("#FFF8EA"), 1.9 if b.max else 1.45)
	_bits.burst(pos, [col, Color("#FFF8EA")], 4 if b.egg else 8, 50.0 if b.egg else 84.0, 0.7 if b.egg else 1.0)
	if b.max:
		_bits.burst(pos, [Color("#FFD76A"), col, Color("#FFF8EA")], 16, 170.0, 1.35)
		_flash_screen(0.26)
		_sfx.play("max")
		_max_tag(pos + Vector2(0, -b.size * 0.95))
	_sfx.play("lock", _lock_n)
	_lock_n += 1
	var add := int(f.value) if int(f.value) > 0 else (0 if f.type == "blank" else 1)
	_tally_add(f.type, add)
	_shake(8.0 if b.hero else 7.0 if b.max else 2.0 if b.egg else 4.0)
	die_locked.emit(b.id, b.final, b.max)


func _update_tease() -> void:
	var tease := false
	if _stage == "toss" and not _hero.is_empty() and (_hero.phase == "fly" or _hero.phase == "settle") and _hero.age > 0.45:
		tease = _bodies.all(func(x): return x.hero or x.phase == "locked")
	if tease:
		_spot_mat.set_shader_parameter("center", _to_view(Vector2(_hero.x, _hero.y - _hero.h * 0.25)))
		_spot_mat.set_shader_parameter("radius", 140.0 * _u)
		_spot_mat.set_shader_parameter("softness", 90.0 * _u)
	if tease != _teasing:
		var t := create_tween()
		t.tween_method(func(v): _spot_mat.set_shader_parameter("fade", v),
			1.0 if _teasing else 0.0, 1.0 if tease else 0.0, 0.22 * slowmo)
		if not _hero.is_empty():
			(_hero.node as RerollDie).z_index = 6 if tease else 0
		if tease:
			_sfx.play("spin")
	_teasing = tease


func _collect() -> void:
	if _stage == "collect":
		return
	_stage = "collect"
	_open_tray(false)
	var st := create_tween()
	st.tween_property(_stamp, "modulate:a", 0.0, 0.15)
	if _teasing:
		_spot_mat.set_shader_parameter("fade", 0.0)
	_teasing = false
	_sfx.play("whoosh")
	for tag in _tags.get_children():
		var tt := create_tween()
		tt.tween_property(tag, "modulate:a", 0.0, 0.12)
	var n := 0
	for b in _bodies:
		b.phase = "collect"
		b.ct = -n * 0.045
		b.cd = 0.36
		b.c0 = Vector2(b.x, b.y)
		b.c1 = _card_center(b.id)
		(b.node as RerollDie).z_index = 3
		n += 1


func _collect_step(b: Dictionary, dt: float) -> void:
	b.ct += dt
	if b.ct < 0.0:
		return
	var p := minf(1.0, b.ct / b.cd)
	var e := 2.0 * p * p if p < 0.5 else 1.0 - pow(-2.0 * p + 2.0, 2) / 2.0
	var c0: Vector2 = b.c0
	var c1: Vector2 = b.c1
	b.x = lerpf(c0.x, c1.x, e)
	b.y = lerpf(c0.y, c1.y, e)
	b.h = sin(PI * p) * 260.0
	b.sc = lerpf(1.0, 0.8 if b.egg else 0.55, e)
	if p >= 1.0:
		b.phase = "done"
		(b.node as RerollDie).visible = false
		_arrive(b)


func _arrive(b: Dictionary) -> void:
	_arrived += 1
	_sfx.play("pop", _arrived)
	_land_card(b)
	if not b.egg:
		var faces: Array = b.entry.faces
		var prev: Dictionary = faces[int(b.entry.get("prev", 0))]
		var nf: Dictionary = faces[b.final]
		var d := {}
		if b.max:
			d = {"text": "MAX", "color": Color("#FFD76A")}
		elif prev.type != nf.type:
			d = {"text": "NEW", "color": type_colors.get(nf.type, Color.WHITE)}
		elif int(nf.value) > int(prev.value):
			d = {"text": "+%d" % (int(nf.value) - int(prev.value)), "color": Color("#3FCD3C")}
		elif int(nf.value) < int(prev.value):
			d = {"text": "−%d" % (int(prev.value) - int(nf.value)), "color": Color("#F54540")}
		if not d.is_empty():
			_delta_chip(b.id, d.text, d.color)
	die_returned.emit(b.id, b.final, b.max)
	if _arrived == _bodies.size():
		_stage = "idle"
		_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var rid := _run
		get_tree().create_timer(0.7 * slowmo).timeout.connect(func():
			if rid == _run and _stage == "idle":
				for c in _world.get_children(): c.queue_free())
		finished.emit(_grade)


func _draw_body(b: Dictionary) -> void:
	var nd: RerollDie = b.node
	if b.phase == "wait" or b.phase == "done":
		return
	nd.position = Vector2(b.x, b.y)
	nd.h = b.h
	nd.sc = b.sc


# ── card reactions ──────────────────────────────────────────────────────────

func _capture_cards(entries: Array) -> void:
	for id in _cards:
		_restore_card(id)
	_cards.clear()
	for e in entries:
		var card: Control = e.get("card")
		if card == null or not is_instance_valid(card):
			continue
		_cards[e.id] = {
			"card": card, "base_pos": e.get("rest_position", card.position), "base_rot": card.rotation,
			"base_scale": card.scale, "base_mod": card.modulate, "tween": null,
		}
		card.pivot_offset = Vector2(card.size.x / 2.0, card.size.y)   # squash from the bottom


func _card_tween(card: Control) -> Tween:
	for id in _cards:
		var cd: Dictionary = _cards[id]
		if cd.card == card:
			if cd.tween and (cd.tween as Tween).is_valid():
				(cd.tween as Tween).kill()
			var t := card.create_tween()
			cd.tween = t
			return t
	return card.create_tween()


func _land_card(b: Dictionary) -> void:
	var cd: Dictionary = _cards.get(b.id, {})
	if not cd.has("card"):
		return
	var card: Control = cd.card
	var col: Color = type_colors.get((b.entry.faces[b.final] as Dictionary).type, Color.WHITE)
	var base_mod: Color = cd.base_mod
	card.modulate = Color(base_mod.r * 1.9, base_mod.g * 1.9, base_mod.b * 1.9, base_mod.a)   # flash
	card.scale = cd.base_scale * Vector2(1.12, 0.9)
	card.position.y = cd.base_pos.y + 6.0
	var t := _card_tween(card)
	t.tween_interval(0.07 * slowmo)
	t.tween_property(card, "scale", cd.base_scale, 0.34 * slowmo).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(card, "position:y", cd.base_pos.y, 0.34 * slowmo).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(card, "modulate", base_mod, 0.28 * slowmo)
	var r := _card_rect(b.id)
	_bits.rect_ring(r, col, Vector2(1.32, 1.4))
	if b.max:
		_bits.burst(r.get_center(), [col], 6, 110.0, 1.0)
	if not b.egg:
		_shake(5.0 if b.max else 2.0)


func _restore_card(id: Variant) -> void:
	var cd: Dictionary = _cards.get(id, {})
	if not cd.has("card") or not is_instance_valid(cd.card):
		return
	var card: Control = cd.card
	if cd.tween and (cd.tween as Tween).is_valid():
		(cd.tween as Tween).kill()
	card.position = cd.base_pos
	card.rotation = cd.base_rot
	card.scale = cd.base_scale
	card.modulate = cd.base_mod


func _card_rect(id: Variant) -> Rect2:
	var cd: Dictionary = _cards.get(id, {})
	if not cd.has("card") or not is_instance_valid(cd.card):
		return Rect2(Vector2(960, 980) - Vector2(90, 79), Vector2(180, 158))
	var card: Control = cd.card
	var xf := card.get_global_transform_with_canvas()
	# use the resting transform (position/scale restored) so the target does not wobble
	var tl := xf.origin
	var sz := card.size * xf.get_scale()
	var r := Rect2((tl - _off) / _u, sz / _u)
	return r


func _card_center(id: Variant) -> Vector2:
	var r := _card_rect(id)
	var hh := minf(r.size.y, 158.0)
	return Vector2(r.get_center().x, r.position.y + hh / 2.0)


func _delta_chip(id: Variant, text: String, color: Color) -> void:
	var r := _card_rect(id)
	var chip := _chip_label(text, color, 24, Color("#1A1206"))
	_chips_layer.add_child(chip)
	chip.reset_size()
	var base := Vector2(r.get_center().x, r.position.y - 28.0) - chip.size / 2.0
	chip.pivot_offset = chip.size / 2.0
	chip.position = base + Vector2(0, 12)
	chip.scale = Vector2(0.6, 0.6)
	chip.modulate.a = 0.0
	var k := slowmo
	var t := chip.create_tween()
	t.tween_property(chip, "modulate:a", 1.0, 0.26 * k)
	t.parallel().tween_property(chip, "position:y", base.y - 8.0, 0.26 * k)
	t.parallel().tween_property(chip, "scale", Vector2(1.18, 1.18), 0.26 * k)
	t.tween_property(chip, "scale", Vector2.ONE, 0.19 * k)
	t.parallel().tween_property(chip, "position:y", base.y - 4.0, 0.19 * k)
	t.tween_property(chip, "position:y", base.y - 12.0, 1.06 * k)
	t.tween_property(chip, "modulate:a", 0.0, 0.38 * k)
	t.parallel().tween_property(chip, "position:y", base.y - 26.0, 0.38 * k)
	t.tween_callback(chip.queue_free)


# ── tray / overlays ─────────────────────────────────────────────────────────

func _open_tray(on: bool) -> void:
	var t := create_tween()
	var k := slowmo
	if on:
		_tray.visible = true
		_tray.mouse_filter = Control.MOUSE_FILTER_STOP
		_tray.modulate.a = 0.0
		_tray.scale = Vector2(0.94, 0.94)
		_tray.position = TRAY_RECT.position + Vector2(0, 40)
		t.tween_property(_tray, "modulate:a", 1.0, 0.2 * k)
		t.parallel().tween_property(_tray, "scale", Vector2.ONE, 0.3 * k).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.parallel().tween_property(_tray, "position", TRAY_RECT.position, 0.3 * k).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.parallel().tween_property(_dim, "color:a", 0.5, 0.25 * k)
	else:
		_tray.mouse_filter = Control.MOUSE_FILTER_IGNORE
		t.tween_property(_tray, "modulate:a", 0.0, 0.2 * k)
		t.parallel().tween_property(_tray, "scale", Vector2(0.94, 0.94), 0.3 * k)
		t.parallel().tween_property(_tray, "position", TRAY_RECT.position + Vector2(0, 40), 0.3 * k)
		t.parallel().tween_property(_dim, "color:a", 0.0, 0.25 * k)
		t.tween_callback(func(): if _stage != "open": _tray.visible = false)


func _build_tally(entries: Array) -> void:
	for c in _tally_box.get_children():
		c.queue_free()
	_tally_chips.clear()
	var present := {}
	for e in entries:
		present[String((e.faces[int(e.final)] as Dictionary).type)] = true
	for ty in TALLY_ORDER:
		if not present.has(ty):
			continue
		var chip := PanelContainer.new()
		chip.add_theme_stylebox_override("panel", _sb(Color("#4A2A0E"), 3, 10, Vector2(5, 0), Vector2(11, 0)))
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 6)
		chip.add_child(hb)
		var ic := Panel.new()
		ic.custom_minimum_size = Vector2(22, 22)
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ic.add_theme_stylebox_override("panel", _sb(type_colors.get(ty, Color.WHITE), 2, 7))
		hb.add_child(ic)
		var tex: Texture2D = type_icons.get(ty)
		if tex:
			var tr := TextureRect.new()
			tr.texture = tex
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.position = Vector2(4, 4)
			tr.size = Vector2(14, 14)
			ic.add_child(tr)
		var lb := _label("0", 21, Color("#A07A52"))
		lb.custom_minimum_size.x = 18
		hb.add_child(lb)
		chip.custom_minimum_size.y = 34
		_tally_box.add_child(chip)
		_tally_chips[ty] = {"chip": chip, "label": lb}


func _tally_add(ty: String, add: int) -> void:
	_tally_n[ty] = int(_tally_n.get(ty, 0)) + add
	var c: Dictionary = _tally_chips.get(ty, {})
	if c.is_empty():
		return
	var chip: PanelContainer = c.chip
	var lb: Label = c.label
	var from := int(lb.text)
	var to: int = _tally_n[ty]
	# the number ticks up rather than jumping
	var t := chip.create_tween()
	t.tween_method(func(v): lb.text = str(int(round(v))), float(from), float(to), 0.16 * slowmo)
	lb.add_theme_color_override("font_color", Color("#1A1206"))
	(chip.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Color("#F3E7D3")
	chip.pivot_offset = chip.size / 2.0
	var p := chip.create_tween()
	p.tween_property(chip, "scale", Vector2(1.25, 1.25), 0.06 * slowmo)
	p.tween_property(chip, "scale", Vector2.ONE, 0.2 * slowmo).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _max_tag(pos: Vector2) -> void:
	var tag := _chip_label("MAX!", Color("#FFD76A"), 24, Color("#1A1206"), 4)
	var holder := Node2D.new()
	holder.position = pos
	_tags.add_child(holder)
	holder.add_child(tag)
	tag.reset_size()
	tag.position = -tag.size / 2.0
	tag.pivot_offset = tag.size / 2.0
	tag.rotation = deg_to_rad(10.0)
	tag.scale = Vector2(0.4, 0.4)
	var t := tag.create_tween()
	t.tween_property(tag, "rotation", deg_to_rad(-8.0), 0.3 * slowmo).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(tag, "scale", Vector2.ONE, 0.3 * slowmo).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _slam(g: Dictionary) -> void:
	_stamp_main.text = g.text
	_stamp_sub.text = g.sub
	_stamp_sub.add_theme_color_override("font_color", g.sub_fg)
	(_stamp_panel.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = g.bg
	_stamp.reset_size()
	_stamp.pivot_offset = _stamp.size / 2.0
	_stamp.position = STAMP_POS - _stamp.size / 2.0
	_stamp.modulate.a = 0.0
	_stamp.scale = Vector2(2.6, 2.6)
	_stamp.rotation = deg_to_rad(-1.0)
	var k := slowmo
	var t := _stamp.create_tween()
	t.tween_property(_stamp, "modulate:a", 1.0, 0.1 * k)
	t.parallel().tween_property(_stamp, "scale", Vector2.ONE, 0.22 * k).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(_stamp, "rotation", deg_to_rad(-6.0), 0.22 * k).set_ease(Tween.EASE_IN)
	t.tween_callback(func():
		var big: bool = g.big
		_shake(12.0 if big else 7.0)
		_bits.burst(STAMP_POS, [Color("#FFD76A"), Color("#FF9345"), Color("#FFF8EA"), Color("#3FCD3C"), Color("#31C6FF")],
			32 if big else 18, 360.0 if big else 250.0, 1.5)
		if big:
			_flash_screen(0.35)
		_sfx.play("grade", g.tier))
	t.tween_property(_stamp, "scale", Vector2(1.06, 1.06), 0.12 * k).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(_stamp, "rotation", deg_to_rad(-5.0), 0.12 * k)
	t.tween_property(_stamp, "scale", Vector2.ONE, 0.18 * k)


func _flash_screen(op: float) -> void:
	if not flashes:
		return
	_flash.color.a = op
	var t := create_tween()
	t.tween_property(_flash, "color:a", 0.0, 0.4 * slowmo).set_ease(Tween.EASE_OUT)


func _shake(amp: float) -> void:
	if not screen_shake:
		return
	shake_requested.emit(amp)
	_shake_seq += 1
	var seq := _shake_seq
	var steps := [Vector2(1, -0.6), Vector2(-0.8, 0.9), Vector2(0.5, -0.4), Vector2.ZERO]
	for n in steps.size():
		var v: Vector2 = steps[n] * amp
		get_tree().create_timer(n * 0.04 * slowmo).timeout.connect(func():
			if seq != _shake_seq:
				return
			offset = v * _u
			if shake_camera:
				shake_camera.offset = v)


func _thud() -> void:
	var t := Time.get_ticks_msec()
	if t - _last_thud < 55:
		return
	_last_thud = t
	_sfx.play("thud")


# ── grade ───────────────────────────────────────────────────────────────────

## Average of (rolled value / die max) over the Axie dice; a buff/debuff face counts 0.6.
func _grade_of(entries: Array) -> Dictionary:
	var sc := 0.0
	var max_n := 0
	var now := 0
	var prev := 0
	var n := 0
	for e in entries:
		if e.get("egg", false):
			continue
		n += 1
		var faces: Array = e.faces
		var mx := _die_max(faces)
		var f: Dictionary = faces[int(e.final)]
		var v := int(f.value)
		if v > 0 and v >= mx:
			max_n += 1
		# a face with no number (buff/debuff/summon) counts 0.6; a blank face counts 0
		sc += (float(v) / mx) if (v > 0 and mx > 0) else (0.0 if String(f.type) == "blank" else 0.6)
		now += v
		prev += int((faces[int(e.get("prev", 0))] as Dictionary).value)
	var avg := sc / n if n > 0 else 0.0
	var dv := now - prev
	var t: Array = []
	if n >= 3 and max_n == n:
		t = ["JACKPOT!!", Color("#FFD76A"), 3]
	elif avg >= 0.85 or max_n >= 3:
		t = ["PERFECT!", Color("#FFD76A"), 2]
	elif avg >= 0.68:
		t = ["GREAT ROLL!", Color("#FF9345"), 1]
	elif avg >= 0.52:
		t = ["NICE ROLL", Color("#7DE07A"), 0]
	if t.is_empty():
		return {"on": false, "tier": -1, "avg": avg, "max_count": max_n, "power_delta": dv}
	var dtxt := ("+%d" % dv) if dv > 0 else (("−%d" % -dv) if dv < 0 else "±0")
	return {
		"on": true, "text": t[0], "bg": t[1], "tier": t[2], "big": t[2] >= 2,
		"sub": (("%d MAX  ·  " % max_n) if max_n > 0 else "") + dtxt + " POWER VS LAST ROLL",
		"sub_fg": Color("#7DE07A") if dv > 0 else (Color("#FF8A85") if dv < 0 else Color("#C6CEDA")),
		"avg": avg, "max_count": max_n, "power_delta": dv,
	}


func _die_max(faces: Array) -> int:
	var mx := 0
	for f in faces:
		mx = maxi(mx, int(f.value))
	return mx


# ── build ───────────────────────────────────────────────────────────────────

func _build() -> void:
	_dim = ColorRect.new()
	_dim.color = Color(8 / 255.0, 9 / 255.0, 13 / 255.0, 0.0)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			skip())
	add_child(_dim)

	_root = Node2D.new()
	add_child(_root)

	# tray: wooden frame + felt
	_tray = Panel.new()
	_tray.position = TRAY_RECT.position
	_tray.size = TRAY_RECT.size
	_tray.pivot_offset = TRAY_RECT.size / 2.0
	var wood := _sb(Color("#7A4A22"), 5, 40)
	wood.shadow_color = Color(0, 0, 0, 0.55)
	wood.shadow_size = 0
	wood.shadow_offset = Vector2(0, 12)
	_tray.add_theme_stylebox_override("panel", wood)
	_tray.visible = false
	_tray.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tray.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			skip())
	_root.add_child(_tray)
	var lip := Panel.new()   # inner highlight / bottom lip of the wood
	lip.position = Vector2(5, 5)
	lip.size = TRAY_RECT.size - Vector2(10, 10)
	var lsb := StyleBoxFlat.new()
	lsb.draw_center = false
	lsb.border_width_top = 7
	lsb.border_width_bottom = 9
	lsb.border_color = Color("#A56B35")
	lsb.set_corner_radius_all(35)
	lip.add_theme_stylebox_override("panel", lsb)
	lip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tray.add_child(lip)
	var felt := Panel.new()
	felt.position = Vector2(19, 65)
	felt.size = Vector2(TRAY_RECT.size.x - 38, TRAY_RECT.size.y - 84)
	felt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fsb := _sb(Color("#1B3E45"), 4, 26)
	felt.add_theme_stylebox_override("panel", fsb)
	_tray.add_child(felt)
	var glow := TextureRect.new()   # radial felt highlight
	var gt := GradientTexture2D.new()
	var gr := Gradient.new()
	gr.set_color(0, Color("#27555D"))
	gr.set_color(1, Color(0x1B / 255.0, 0x3E / 255.0, 0x45 / 255.0, 0.0))
	gt.gradient = gr
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.42)
	gt.fill_to = Vector2(0.5, 1.0)
	gt.width = 256; gt.height = 128
	glow.texture = gt
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.position = Vector2(8, 8)
	glow.size = felt.size - Vector2(16, 16)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	felt.add_child(glow)
	var dash := Panel.new()
	dash.position = Vector2(12, 12)
	dash.size = felt.size - Vector2(24, 24)
	var dsb := StyleBoxFlat.new()
	dsb.draw_center = false
	dsb.set_border_width_all(2)
	dsb.border_color = Color(243 / 255.0, 231 / 255.0, 211 / 255.0, 0.15)
	dsb.set_corner_radius_all(18)
	dash.add_theme_stylebox_override("panel", dsb)
	dash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	felt.add_child(dash)

	# header: REROLL ×n · tally · TAP TO SKIP
	var head := HBoxContainer.new()
	head.position = Vector2(20, 19)
	head.size = Vector2(TRAY_RECT.size.x - 40, 36)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tray.add_child(head)
	var left := PanelContainer.new()
	left.add_theme_stylebox_override("panel", _sb(Color("#F3E7D3"), 3, 11, Vector2(9, 0), Vector2(5, 0)))
	var lhb := HBoxContainer.new()
	lhb.add_theme_constant_override("separation", 9)
	left.add_child(lhb)
	if reroll_icon:
		var ri := TextureRect.new()
		ri.texture = reroll_icon
		ri.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ri.custom_minimum_size = Vector2(20, 20)
		ri.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lhb.add_child(ri)
	lhb.add_child(_label("REROLL", 20, Color("#1A1206")))
	var cnt := PanelContainer.new()
	cnt.add_theme_stylebox_override("panel", _sb(Color("#FF9345"), 2, 7, Vector2(8, 0), Vector2(8, 0)))
	_tray_count = _label("×0", 15, Color("#2A1505"))
	cnt.add_child(_tray_count)
	cnt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lhb.add_child(cnt)
	var left_wrap := HBoxContainer.new()
	left_wrap.add_child(left)
	left_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(left_wrap)
	_tally_box = HBoxContainer.new()
	_tally_box.add_theme_constant_override("separation", 8)
	_tally_box.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_child(_tally_box)
	var right := HBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.alignment = BoxContainer.ALIGNMENT_END
	right.add_theme_constant_override("separation", 8)
	right.add_child(_label("TAP TO SKIP", 14, Color("#F0D4AE")))
	var key := PanelContainer.new()
	key.add_theme_stylebox_override("panel", _sb(Color("#4A2A0E"), 2, 7, Vector2(8, 0), Vector2(8, 0)))
	key.add_child(_label("R", 14, Color("#F3E7D3")))
	right.add_child(key)
	head.add_child(right)

	_spot = ColorRect.new()
	_spot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_spot_mat = ShaderMaterial.new()
	_spot_mat.shader = preload("spotlight.gdshader")
	_spot.material = _spot_mat
	_spot.z_index = 5
	add_child(_spot)   # full viewport, above tray + other dice

	_world = Node2D.new()
	_root.add_child(_world)
	_bits = RerollFxBits.new()
	_bits.z_index = 7
	_root.add_child(_bits)
	_tags = Node2D.new()
	_tags.z_index = 8
	_root.add_child(_tags)

	_stamp = VBoxContainer.new()
	_stamp.alignment = BoxContainer.ALIGNMENT_CENTER
	_stamp.add_theme_constant_override("separation", 10)
	_stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stamp.z_index = 9
	_stamp_panel = PanelContainer.new()
	var ssb := _sb(Color("#FFD76A"), 5, 18, Vector2(38, 12), Vector2(38, 8))
	ssb.shadow_color = Color(0, 0, 0, 0.55)
	ssb.shadow_offset = Vector2(0, 8)
	ssb.shadow_size = 1
	_stamp_panel.add_theme_stylebox_override("panel", ssb)
	_stamp_main = _label("", 72, Color("#1A1206"))
	_stamp_panel.add_child(_stamp_main)
	_stamp.add_child(_stamp_panel)
	var sub := PanelContainer.new()
	sub.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	sub.add_theme_stylebox_override("panel", _sb(Color("#12161D"), 3, 10, Vector2(14, 4), Vector2(14, 4)))
	_stamp_sub = _label("", 19, Color("#C6CEDA"))
	sub.add_child(_stamp_sub)
	_stamp.add_child(sub)
	_stamp.modulate.a = 0.0
	_root.add_child(_stamp)

	_chips_layer = Node2D.new()
	_chips_layer.z_index = 9
	_root.add_child(_chips_layer)

	_flash = ColorRect.new()
	_flash.color = Color(1.0, 0.843, 0.416, 0.0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.z_index = 10
	add_child(_flash)

	_sfx = RerollSfx.new()
	add_child(_sfx)


func _fit() -> void:
	var vs := get_viewport().get_visible_rect().size
	# fit the 1920×1080 artboard; extra width is margin, extra height stays below the tray
	_u = minf(vs.x / DESIGN.x, vs.y / DESIGN.y)
	_off = Vector2((vs.x - DESIGN.x * _u) / 2.0, 0.0)
	_root.scale = Vector2(_u, _u)
	_root.position = _off
	for r in [_dim, _spot, _flash]:
		(r as ColorRect).position = Vector2.ZERO
		(r as ColorRect).size = vs
	_spot_mat.set_shader_parameter("rect_size", vs)


func _to_view(p: Vector2) -> Vector2:
	return p * _u + _off


func _later(sec: float, f: Callable) -> void:
	var rid := _run
	get_tree().create_timer(sec * slowmo).timeout.connect(func(): if rid == _run: f.call())


func _font() -> Font:
	return display_font if display_font else ThemeDB.fallback_font


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", _font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _chip_label(text: String, bg: Color, size: int, fg: Color, border: int = 3) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := _sb(bg, border, 11, Vector2(14, 3), Vector2(14, 3))
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_offset = Vector2(0, 5)
	sb.shadow_size = 1
	p.add_theme_stylebox_override("panel", sb)
	p.add_child(_label(text, size, fg))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


func _sb(bg: Color, border: int, radius: int, pad_lt: Vector2 = Vector2.ZERO, pad_rb: Vector2 = Vector2(-1, -1)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = Color.BLACK
	s.set_border_width_all(border)
	s.set_corner_radius_all(radius)
	s.anti_aliasing = true
	if pad_rb.x < 0.0:
		pad_rb = pad_lt
	s.content_margin_left = pad_lt.x
	s.content_margin_top = pad_lt.y
	s.content_margin_right = pad_rb.x
	s.content_margin_bottom = pad_rb.y
	return s
