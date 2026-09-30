class_name RerollDie
extends Node2D
## One tumbling die. Real cube orientation (Quaternion), drawn with an orthographic
## projection: each visible face is an affine-mapped square, so the face art (class band,
## value, type icon) stays correct at every angle without a 3D viewport.
## `position` is the ground point; `h` lifts the cube off the felt.

# Face frames in cube space: normal N, right U, down V (U x V = N for every face, so no
# face ever renders mirrored). Screen: x right, y down, +z toward the camera.
const FACE_N := [Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(-1, 0, 0), Vector3(0, -1, 0), Vector3(0, 1, 0)]
const FACE_U := [Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(1, 0, 0)]
const FACE_V := [Vector3(0, 1, 0), Vector3(0, 1, 0), Vector3(0, 1, 0), Vector3(0, 1, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]

const BODY := Color("#F3E7D3")
const INK := Color("#1A1206")

var id: Variant
var egg := false
var size := 104.0
var faces: Array = []              # [{type:String, value:int}] × 6
var class_color := Color("#7DC943")
var type_colors: Dictionary = {}
var type_icons: Dictionary = {}    # type -> Texture2D (optional)
var font: Font

# sim state (driven by RerollFX)
var q := Quaternion.IDENTITY
var h := 0.0
var sc := 1.0
var shadow_on := true

var _sb_face: StyleBoxFlat
var _sb_band: StyleBoxFlat
var _sb_icon: StyleBoxFlat


func setup() -> void:
	var bw := 3 if egg else 4
	_sb_face = StyleBoxFlat.new()
	_sb_face.bg_color = BODY
	_sb_face.border_color = Color.BLACK
	_sb_face.set_border_width_all(bw)
	_sb_face.set_corner_radius_all(int(size * 0.18))
	_sb_face.anti_aliasing = true
	_sb_band = StyleBoxFlat.new()
	_sb_band.bg_color = class_color
	_sb_band.border_color = Color.BLACK
	_sb_band.set_border_width_all(bw)
	_sb_band.corner_radius_top_left = int(size * 0.18)
	_sb_band.corner_radius_top_right = int(size * 0.18)
	_sb_icon = StyleBoxFlat.new()
	_sb_icon.border_color = Color.BLACK
	_sb_icon.set_border_width_all(bw - 1)
	_sb_icon.set_corner_radius_all(int(size * 0.3 * 0.24))
	if font == null:
		font = ThemeDB.fallback_font


## Which face index currently points most toward the camera.
func front_face() -> int:
	var best := 0
	var bz := -2.0
	for i in 6:
		var z := (q * (FACE_N[i] as Vector3)).z
		if z > bz:
			bz = z
			best = i
	return best


## Orientation that shows face `n` to the camera, keeping the current twist but pulled to
## within ±`max_tilt_deg` of upright so the number reads.
func target_for(n: int, max_tilt_deg: float = 8.0) -> Quaternion:
	var cur_n: Vector3 = q * (FACE_N[n] as Vector3)
	var align := _arc(cur_n, Vector3(0, 0, 1))
	var qt := align * q
	# twist: face V should point to screen-down (0,1,0)
	var v: Vector3 = qt * (FACE_V[n] as Vector3)
	var ang := atan2(v.x, v.y)     # rotation about +z that brings v onto screen-down
	var keep := clampf(ang, deg_to_rad(-max_tilt_deg), deg_to_rad(max_tilt_deg))
	var fix := Quaternion(Vector3(0, 0, 1), ang - keep + deg_to_rad(randf_range(-3.0, 3.0)))
	return (fix * qt).normalized()


func _arc(a: Vector3, b: Vector3) -> Quaternion:
	a = a.normalized(); b = b.normalized()
	var d := a.dot(b)
	if d > 0.99999:
		return Quaternion.IDENTITY
	if d < -0.99999:
		var axis := Vector3(1, 0, 0).cross(a)
		if axis.length() < 0.01:
			axis = Vector3(0, 1, 0).cross(a)
		return Quaternion(axis.normalized(), PI)
	return Quaternion(a.cross(b).normalized(), acos(d))


func _process(_dt: float) -> void:
	queue_redraw()


func _draw() -> void:
	if faces.size() < 6:
		return
	var s := size
	# perspective-ish growth as the die lifts (design used perspective:1400px)
	var persp := (1400.0 - s * 0.5) / maxf(200.0, 1400.0 - h * 0.5 - s * 0.5)
	var k := persp * sc
	if shadow_on:
		var w := s * 1.1 * clampf(1.0 - h / 900.0, 0.5, 1.0) * sc
		var a := clampf(0.55 - h / 1400.0, 0.15, 0.55) * sc
		var c := Vector2(0, 8.0 + h * 0.08)
		for i in 4:   # fake blur: stacked soft rounded rects
			var g := w * (1.0 + i * 0.09)
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(0, 0, 0, a * (0.42 - i * 0.08))
			sb.set_corner_radius_all(int(g * 0.34))
			draw_style_box(sb, Rect2(c - Vector2(g, g * 0.8) / 2.0, Vector2(g, g * 0.8)))
	var center := Vector2(0, -h * 0.25)
	var order: Array = []
	for i in 6:
		var nz := (q * (FACE_N[i] as Vector3)).z
		if nz > 0.015:
			order.append([nz, i])
	order.sort_custom(func(l, r): return l[0] < r[0])
	for o in order:
		var i: int = o[1]
		var n: Vector3 = q * (FACE_N[i] as Vector3)
		var u: Vector3 = q * (FACE_U[i] as Vector3)
		var v: Vector3 = q * (FACE_V[i] as Vector3)
		var origin := center + Vector2(n.x, n.y) * (s * 0.5) * k
		var xf := Transform2D(Vector2(u.x, u.y) * k, Vector2(v.x, v.y) * k, origin)
		draw_set_transform_matrix(xf)
		_draw_face(i, 0.72 + 0.28 * o[0])
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_face(i: int, light: float) -> void:
	var s := size
	var r := Rect2(Vector2(-s / 2.0, -s / 2.0), Vector2(s, s))
	var f: Dictionary = faces[i]
	var t: String = f.get("type", "dmg")
	var shade := Color(light, light, light)
	_sb_face.bg_color = BODY * shade
	draw_style_box(_sb_face, r)
	_sb_band.bg_color = class_color * shade
	draw_style_box(_sb_band, Rect2(r.position, Vector2(s, s * 0.24)))
	# value + type chip
	var v := int(f.get("value", 0))
	var val := "·" if t == "blank" else ("•" if v <= 0 else str(v))
	var fs := int(s * 0.4)
	var iw := s * 0.3
	var tw := font.get_string_size(val, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var gap := s * 0.06
	var total := tw + gap + iw
	var x0 := -total / 2.0
	var cy := s * 0.12
	var asc := font.get_ascent(fs)
	var desc := font.get_descent(fs)
	draw_string(font, Vector2(x0, cy + (asc - desc) / 2.0), val, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK * shade)
	var ir := Rect2(Vector2(x0 + tw + gap, cy - iw / 2.0), Vector2(iw, iw))
	_sb_icon.bg_color = (type_colors.get(t, Color.WHITE) as Color) * shade
	draw_style_box(_sb_icon, ir)
	var tex: Texture2D = type_icons.get(t)
	if tex:
		draw_texture_rect(tex, ir.grow(-iw * 0.18), false, shade)
	else:
		var gl := t.substr(0, 1).to_upper()
		var gs := int(iw * 0.62)
		var gw := font.get_string_size(gl, HORIZONTAL_ALIGNMENT_LEFT, -1, gs).x
		draw_string(font, Vector2(ir.get_center().x - gw / 2.0, ir.get_center().y + (font.get_ascent(gs) - font.get_descent(gs)) / 2.0), gl, HORIZONTAL_ALIGNMENT_LEFT, -1, gs, INK)
