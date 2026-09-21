class_name SkillVfxLayer
extends Control
## Plays the Origins skill VFX sheets as a 2D additive overlay over the 3D stage.
##
## WHY 2D OVER THE STAGE AND NOT A Sprite3D IN IT
## ----------------------------------------------
## Two reasons, and the second is the one that decides it.
##  1. This is how the kit itself plays them. Its web runtime composites the same sheets on a
##     DOM canvas with `mix-blend-mode: plus-lighter` over the mixer Axies; the captures are
##     authored for that, not for a lit 3D scene.
##  2. CombatStage3D is a SubViewportContainer, whose children are meant to be SubViewports.
##     A Control child of one does not reliably render. The overlay therefore lives beside the
##     stage under UnitVisualsRoot, which is exactly where the nameplates and head HUDs already
##     sit, and it uses the same CombatStage3D.get_unit_screen_pos() + stage-offset rebasing
##     CombatView._layout_unit_visuals() uses. Added as UnitVisualsRoot's FIRST child so it
##     draws over the 3D stage but UNDER the portraits and numbers - a hit number hidden behind
##     a flash is a number the player did not read.
##
## HOW A CLIP IS PLACED
## --------------------
## Each capture stores two points in crop space: `attacker` (where the attacking Axie stood)
## and `anchor` (where the defender stood). Those two points are what make the clip
## placeable - line them up with the two units' screen positions and the whole effect, orb,
## travel and burst, lands where it should. Solving two point-to-point constraints on a rigid
## image gives a similarity transform: uniform scale from the ratio of the two distances,
## rotation from the angle between them, translation from the attacker point.
##
## Scale is CLAMPED (_MIN_SCALE.._MAX_SCALE). Two adjacent party members are ~1.5m apart while
## the capture separation is ~400px, so an unclamped self-target or neighbour-target would
## shrink a whole skill to a few pixels, and a cross-field shot on a wide screen would blow it
## up past the playfield. The clamp costs geometric exactness on those two extremes and buys
## an effect that is always legible, which is the point of drawing it.
##
## MEMORY
## ------
## These sheets are big (up to 6440x2506). Textures are loaded on first use and cached, and
## the cache is capped at _CACHE_MAX with oldest-first eviction that SKIPS anything currently
## on screen. A fight touches at most one class per unit and a handful of actions, so the cap
## is comfortable in practice; it exists so a long run cannot accumulate all 42.

const _MIN_SCALE := 0.45
const _MAX_SCALE := 2.2
const _CACHE_MAX := 10

## One clip in flight. Kept as plain Dictionaries rather than nodes: this layer draws them all
## in one _draw(), so a node each would buy nothing and cost a tree churn per attack.
var _active: Array[Dictionary] = []
static var _tex_cache: Dictionary = {}
static var _tex_order: Array[String] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# Additive on the WHOLE layer, not per draw call: the captures are additive plates, and
	# `blend` in every clip.json says so.
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat
	set_process(false)


## `attacker_pos` / `target_pos` are in THIS control's local space. Returns false when the clip
## is unknown or the geometry is degenerate, so a caller can tell "no art for this" from
## "played it".
func play(clip_key: String, attacker_pos: Vector2, target_pos: Vector2) -> bool:
	var meta := SkillVfxCatalog.clip(clip_key)
	if meta.is_empty():
		return false
	var tex := _texture_for(clip_key)
	if tex == null:
		return false

	var a_pt := _pair(meta.get("attacker"))
	var b_pt := _pair(meta.get("anchor"))
	var clip_span := a_pt.distance_to(b_pt)
	var screen_span := attacker_pos.distance_to(target_pos)
	if clip_span < 1.0:
		return false   # a capture with both anchors on one pixel has no direction to give

	var scale := clampf(screen_span / clip_span, _MIN_SCALE, _MAX_SCALE)
	var rot := 0.0
	if screen_span > 1.0:
		rot = (target_pos - attacker_pos).angle() - (b_pt - a_pt).angle()

	_active.append({
		"key": clip_key, "tex": tex, "meta": meta,
		"origin": attacker_pos, "attacker_pt": a_pt,
		"scale": scale, "rot": rot,
		"t": 0.0,
		"fps": maxf(1.0, float(meta.get("fps", 30.0))),
		"frames": maxi(1, int(meta.get("frames", 1))),
	})
	set_process(true)
	queue_redraw()
	return true


## How long the clip runs, for callers that need to sequence against it. 0.0 when unknown.
static func clip_duration(clip_key: String) -> float:
	var meta := SkillVfxCatalog.clip(clip_key)
	if meta.is_empty():
		return 0.0
	var fps := maxf(1.0, float(meta.get("fps", 30.0)))
	return float(meta.get("frames", 1)) / fps


## When the clip's own capture says the blow lands — Origins' `peakFrame`. Callers can line the
## damage number up with the burst instead of with a fixed guess.
static func clip_peak_time(clip_key: String) -> float:
	var meta := SkillVfxCatalog.clip(clip_key)
	if meta.is_empty():
		return 0.0
	var fps := maxf(1.0, float(meta.get("fps", 30.0)))
	return float(meta.get("peak_frame", 0)) / fps


func is_playing() -> bool:
	return not _active.is_empty()


func stop_all() -> void:
	_active.clear()
	set_process(false)
	queue_redraw()


func _process(delta: float) -> void:
	var i := _active.size() - 1
	while i >= 0:
		var e: Dictionary = _active[i]
		e["t"] = float(e["t"]) + delta
		if int(float(e["t"]) * float(e["fps"])) >= int(e["frames"]):
			_active.remove_at(i)
		i -= 1
	if _active.is_empty():
		set_process(false)
	queue_redraw()


func _draw() -> void:
	for e in _active:
		var meta: Dictionary = e["meta"]
		var cols := maxi(1, int(meta.get("cols", 1)))
		var fw := float(meta.get("frame_w", 1))
		var fh := float(meta.get("frame_h", 1))
		var f := clampi(int(float(e["t"]) * float(e["fps"])), 0, int(e["frames"]) - 1)
		var src := Rect2(float(f % cols) * fw, float(f / cols) * fh, fw, fh)
		var s := float(e["scale"])
		draw_set_transform(e["origin"], float(e["rot"]), Vector2(s, s))
		# Drawn at -attacker_pt so the clip's own attacker point lands on this transform's
		# origin, which _play() set to the attacking unit's screen position.
		draw_texture_rect_region(e["tex"], Rect2(-(e["attacker_pt"] as Vector2), Vector2(fw, fh)),
			src)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _pair(v: Variant) -> Vector2:
	if typeof(v) == TYPE_ARRAY and (v as Array).size() >= 2:
		return Vector2(float((v as Array)[0]), float((v as Array)[1]))
	return Vector2.ZERO


func _texture_for(key: String) -> Texture2D:
	if _tex_cache.has(key):
		return _tex_cache[key]
	var path := SkillVfxCatalog.atlas_path(key)
	if not ResourceLoader.exists(path):
		return null
	var tex: Texture2D = load(path)
	if tex == null:
		return null
	_tex_cache[key] = tex
	_tex_order.append(key)
	_evict_if_needed()
	return tex


## Oldest-first, but never a sheet that is still on screen — evicting a playing clip's texture
## would blank it mid-burst.
func _evict_if_needed() -> void:
	while _tex_order.size() > _CACHE_MAX:
		var victim := ""
		for k in _tex_order:
			var in_use := false
			for e in _active:
				if String(e["key"]) == k:
					in_use = true
					break
			if not in_use:
				victim = k
				break
		if victim == "":
			return   # everything cached is playing; let the cap slip rather than break a clip
		_tex_order.erase(victim)
		_tex_cache.erase(victim)
