class_name RerollFxBits
extends Node2D
## Cheap one-shot bits (black-outlined diamonds) and expanding rings, drawn in one _draw().
## Same look as the design's DOM pool. GPUParticles2D would also work, but the hard black
## outline is the game's art style and is easier to guarantee this way.

const MAX_BITS := 160

var time_scale := 1.0   # >1 = slow motion (matches RerollFX.slowmo)

var _bits: Array = []
var _rings: Array = []


## Burst `count` bits from `pos`. dist = travel radius in px, scale = bit size multiplier.
func burst(pos: Vector2, colors: Array, count: int, dist: float, scale_mult: float = 1.0) -> void:
	for i in count:
		if _bits.size() >= MAX_BITS:
			_bits.pop_front()
		var g := randf() * TAU
		var d := dist * (0.55 + randf() * 0.55)
		_bits.append({
			"from": pos,
			"to": pos + Vector2(cos(g) * d, sin(g) * d * 0.72),
			"rot0": PI / 4.0,
			"rot1": PI / 4.0 + deg_to_rad(randf() * 270.0),
			"col": colors[i % colors.size()],
			"size": 12.0 * scale_mult,
			"t": 0.0,
			"dur": (0.4 + randf() * 0.25) * time_scale,
		})
	queue_redraw()


## Expanding rounded-square outline (the "lock" ring). half = half-size of the start square.
func ring(pos: Vector2, half: float, color: Color, grow: float, dur: float = 0.45) -> void:
	_rings.append({ "pos": pos, "half": half, "col": color, "grow": grow, "t": 0.0, "dur": dur * time_scale })
	queue_redraw()


## Ring shaped like a card rect (card punch on return).
func rect_ring(rect: Rect2, color: Color, grow: Vector2, dur: float = 0.42) -> void:
	_rings.append({ "rect": rect, "col": color, "growv": grow, "t": 0.0, "dur": dur * time_scale })
	queue_redraw()


func clear() -> void:
	_bits.clear()
	_rings.clear()
	queue_redraw()


func _process(dt: float) -> void:
	if _bits.is_empty() and _rings.is_empty():
		return
	for b in _bits:
		b.t += dt
	for r in _rings:
		r.t += dt
	_bits = _bits.filter(func(b): return b.t < b.dur)
	_rings = _rings.filter(func(r): return r.t < r.dur)
	queue_redraw()


func _draw() -> void:
	for r in _rings:
		var p: float = r.t / r.dur
		var e := 1.0 - pow(1.0 - p, 2.0)
		var col: Color = r.col
		col.a = 1.0 - e
		if r.has("rect"):
			var rc: Rect2 = r.rect
			var gv: Vector2 = r.growv
			var s := Vector2.ONE.lerp(gv, e)
			var sz := rc.size * s
			_rounded_outline(Rect2(rc.get_center() - sz / 2.0, sz), 15.0, col, 5.0)
		else:
			var h: float = r.half * lerpf(0.6, r.grow, e)
			_rounded_outline(Rect2(r.pos - Vector2(h, h), Vector2(h, h) * 2.0), h * 0.6, col, 5.0)
	for b in _bits:
		var p: float = b.t / b.dur
		# cubic-bezier(.1,.8,.3,1)-ish ease-out for travel, ease-in for fade
		var e := 1.0 - pow(1.0 - p, 3.0)
		var pos: Vector2 = (b.from as Vector2).lerp(b.to, e)
		var rot := lerpf(b.rot0, b.rot1, e)
		var s: float = b.size * lerpf(1.0, 0.3, e)
		var a := 1.0 - p * p
		draw_set_transform(pos, rot, Vector2.ONE)
		var outer := Rect2(Vector2(-s / 2.0, -s / 2.0), Vector2(s, s))
		draw_rect(outer, Color(0, 0, 0, a))
		var c: Color = b.col
		c.a = a
		draw_rect(outer.grow(-2.0), c)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _rounded_outline(r: Rect2, radius: float, col: Color, w: float) -> void:
	var sb := StyleBoxFlat.new()
	sb.draw_center = false
	sb.set_border_width_all(int(w))
	sb.border_color = col
	sb.set_corner_radius_all(int(radius))
	draw_style_box(sb, r)
