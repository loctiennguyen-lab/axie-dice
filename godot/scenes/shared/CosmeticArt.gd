class_name CosmeticArt
extends RefCounted
## Loader for cosmetic art (Cosmetics v7): dice skins and avatar frames.
## Source of truth is assets/cosmetics/cosmetics_manifest.json (one `dice` object, one `frames`
## object, ids kept from earlier versions).
##
## Dice layers: "plate" (Common/Uncommon/Rare) or "base" + "glow" (Epic+) + "max" (Mythic).
## `glow` is drawn with additive blend, `max` is drawn normally on top (Mythic max-level overlay).
## Frames: `base`, plus separate animated layers for Epic+ frames (v8). Each layer is driven by
## `frames.<id>.anim.<layer>` in the manifest (spin | pulse | sweep, durations from the art spec).
## With MetaState.reduce_flash on, the reduced values from the spec are used (no big brightness
## swings, slower spin). The old combined `*_anim.png` is only a static fallback when a layer file
## is missing. Single-image layers cannot stagger sparkles: the whole layer twinkles together.
## Ids that have no art (fx_*, std_* placeholder pool ids, titles) return empty results.

const ROOT := "res://assets/cosmetics/"
const MANIFEST := ROOT + "cosmetics_manifest.json"

static var _cache: Dictionary = {}


static func manifest() -> Dictionary:
	if _cache.is_empty():
		var f := FileAccess.open(MANIFEST, FileAccess.READ)
		if f != null:
			var d: Variant = JSON.parse_string(f.get_as_text())
			if d is Dictionary:
				_cache = d
	return _cache


## True while Epic+ frame layers are not delivered as separate files (v7 state).
static func animation_pending() -> bool:
	return String((manifest().get("animated_layers", {}) as Dictionary).get("status", "")) == "pending"


## Animation spec for a frame layer: Array of {type: spin|pulse|sweep, ...}. Empty = static.
static func anim_spec(id: String, layer: String) -> Array:
	var f: Variant = (manifest().get("frames", {}) as Dictionary).get(id, null)
	if f is Dictionary:
		return ((f as Dictionary).get("anim", {}) as Dictionary).get(layer, [])
	return []


static func has_art(id: String) -> bool:
	return (manifest().get("dice", {}) as Dictionary).has(id) or (manifest().get("frames", {}) as Dictionary).has(id)


## Layer list for a die skin or frame: [{"layer": "base", "path": "res://...", "add": false}, ...]
## in draw order. Empty when the id has no art.
static func layers(id: String) -> Array:
	var m := manifest()
	var entry: Variant = (m.get("dice", {}) as Dictionary).get(id, (m.get("frames", {}) as Dictionary).get(id, null))
	var out: Array = []
	if not (entry is Dictionary):
		return out
	var missing := false
	for rel in (entry as Dictionary).get("files", []):
		var p := ROOT + String(rel)
		if not ResourceLoader.exists(p):
			missing = true
			continue
		var stem := p.get_file().get_basename()
		var layer := stem.trim_prefix(id + "_")
		out.append({"layer": layer, "path": p, "add": layer == "glow"})
	if missing:
		# fallback: old combined overlay, shown static
		for rel in (entry as Dictionary).get("preview_files", []):
			var p := ROOT + String(rel)
			if ResourceLoader.exists(p):
				out.append({"layer": "anim", "path": p, "add": false})
	return out


## Control that stacks the layers of `id` at `px` x `px`. Returns null when there is no art.
static func make_node(id: String, px: float) -> Control:
	var ls := layers(id)
	if ls.is_empty():
		return null
	var root := Control.new()
	root.name = "Cosmetic_" + id
	root.custom_minimum_size = Vector2(px, px)
	root.size = Vector2(px, px)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var animated: Array = []
	for l in ls:
		var tex := load(String(l.path)) as Texture2D
		if tex == null:
			continue
		var tr := TextureRect.new()
		tr.name = String(l.layer)
		tr.texture = tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if l.add:
			var mat := CanvasItemMaterial.new()
			mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			tr.material = mat
		var spec := anim_spec(id, String(l.layer)) if id.begins_with("frame_") else []
		if spec.is_empty():
			tr.set_anchors_preset(Control.PRESET_FULL_RECT)
		else:
			tr.set_anchors_preset(Control.PRESET_TOP_LEFT)
			tr.position = Vector2.ZERO
			tr.size = Vector2(px, px)
			tr.pivot_offset = Vector2(px, px) / 2.0
			animated.append([tr, spec])
		root.add_child(tr)
	if not animated.is_empty():
		root.tree_entered.connect(_start_anims.bind(root, animated, px / 256.0))
	return root


static func _start_anims(root: Control, animated: Array, k: float) -> void:
	var reduce: bool = MetaState.reduce_flash
	for old in root.get_meta("tweens", []):
		if old is Tween:
			(old as Tween).kill()
	var tweens: Array = []
	for pair in animated:
		var tr: TextureRect = pair[0]
		tr.rotation = 0.0
		tr.position = Vector2.ZERO
		tr.modulate.a = 1.0
		for sp in (pair[1] as Array):
			var tw := root.create_tween().set_loops()
			tweens.append(tw)
			match String(sp.type):
				"spin":
					var per := float(sp.reduce_period if reduce else sp.period)
					tw.tween_property(tr, "rotation", TAU, per).from(0.0)
				"pulse":
					var lo := float(sp.reduce_lo if reduce else sp.lo)
					var hi := float(sp.reduce_hi if reduce else sp.hi)
					var half := float(sp.period) / 2.0
					tr.modulate.a = lo
					tw.tween_property(tr, "modulate:a", hi, half).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
					tw.tween_property(tr, "modulate:a", lo, half).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				"sweep":
					var peak := float(sp.reduce_peak if reduce else sp.peak)
					var t_in := float(sp["in"])
					var t_out := float(sp.out)
					var total := t_in + float(sp.hold) + t_out
					tr.modulate.a = 0.0
					tw.tween_method(_sweep_step.bind(tr, sp, peak, k), 0.0, total, total)
					tw.tween_interval(float(sp.rest))
	root.set_meta("tweens", tweens)


static func _sweep_step(t: float, tr: TextureRect, sp: Dictionary, peak: float, k: float) -> void:
	var t_in := float(sp["in"])
	var t_hold := float(sp.hold)
	var t_out := float(sp.out)
	var u := 0.0  # -1 .. 1 travel
	var a := 0.0
	if t < t_in:
		var f := t / t_in
		u = -1.0 + f
		a = f
	elif t < t_in + t_hold:
		u = 0.0
		a = 1.0
	else:
		var f := clampf((t - t_in - t_hold) / t_out, 0.0, 1.0)
		u = f
		a = 1.0 - f
	if t_hold == 0.0:
		# short sheen/glint: one smooth pass, fade in then out around the centre
		a = 1.0 - absf(u)
	tr.position = Vector2(u * float(sp.dx), u * float(sp.dy)) * k
	tr.modulate.a = a * peak
