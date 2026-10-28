class_name UI3Motion
extends RefCounted
## Data-driven "moments" (UI-04 polish prep). One place that says WHEN something moves, for HOW LONG, with
## WHICH curve. The numbers live in `res://assets/data/ui/motion_ui3.json`, so a new Claude Design
## motion.md becomes a JSON edit, not a hunt through tween calls.
##
## A moment (all fields optional except `in` or `out`):
##   "in":  { "ms", "trans", "ease", "delay_ms", "props": { prop: {"from", "to", "trans", "ease"} } }
##   "hold_ms": pause between in and out (opts.hold_ms overrides it, e.g. a banner that lives COMBO_FLOAT_SEC)
##   "out": same shape as "in"
##   "shake": { "px", "ms" }          position jitter, runs next to the "in" phase
##   "particles": { "texture", "amount", "lifetime_ms", "spread_deg", "color_token", "speed" }  one-shot burst
##   "particles2": same shape as "particles", a second emitter (e.g. crit = face_dmg burst + fragments)
##   particles extras: "gravity" (px/s^2 down), "direction_deg" (0 = right, -90 = up), "ring" (true = radial 360)
##   "hitstop_ms": Engine.time_scale 0.05 for that long (UI-04 Big hit / boss phase / victory). Off when reduced.
##   "sweep": { "delay_ms" }          light sweep across the node (text colour @ 8%, 120 px wide, rotated 18 deg,
##                                    parent clip). Off when reduced or MetaState.reduce_flash.
##   "sfx": event name in gacha_timing.json "sfx" (played through UI3Gacha.play_sfx, so tests stay silent)
##   "skippable": true -> opts.skip jumps straight to the final state
##   "shake_target": "screen" -> the "shake" numbers are for the caller's screen shake (CombatStage3D.shake), the node
##                    itself is not shaken. Read them with UI3Motion.screen_shake(id).
##   particles extras (UI-05): "delay_ms" (burst later), "size_px" (texture scaled to that size), "spread_full"
##                    (true = spread_deg is the whole cone as in motion-batch1.md, Godot gets half of it).
##   sweep extras (UI-05): "ms", "width", "alpha", "color_token".
##   "layers": UI-05 timeline (keyframe layers, shake, hit-stop, particles), played with play_timeline(). See there.
## Reduce motion (opts.reduced, or MetaState.reduce_motion via UI3Motion.reduced(), applied automatically):
## no shake, no particles, no delays, phases cut to <= 120 ms alpha fades, scale/offset/rotation just jump.
##   "hide_on_done" / "free_on_done": what happens to the node after the last phase
## Props: scale (number or [x, y]), alpha (modulate:a), offset ([x, y] added to the node position),
## rotation_deg. "trans"/"ease" are the Godot names without prefix: "BACK", "CUBIC", "OUT", "IN_OUT".
## "from" is applied immediately; a missing "from" starts at the node's current value.
##
## play(moment_id, node, opts) returns the Tween (or null when nothing animates). opts keys:
##   hold_ms, skip, reduced, on_done (Callable), scale_ms (float multiplier on every duration),
##   instant (bool, same as skip). Unknown moment id: push_error and return null (no crash).
## Everything here is UI only. It never touches game state, seeds or the action log.

const TABLE_PATH := "res://assets/data/ui/motion_ui3.json"

## Moments played so far, newest last. Tests read UI3Motion.played instead of waiting for pixels.
static var played: Array[String] = []
## Tests set this to true to fill `played` (capped at 64 entries). Off in the game so it never grows.
static var record := false
static var _table: Dictionary = {}
static var _loaded := false

const _TRANS := {
	"LINEAR": Tween.TRANS_LINEAR, "SINE": Tween.TRANS_SINE, "QUINT": Tween.TRANS_QUINT,
	"QUART": Tween.TRANS_QUART, "QUAD": Tween.TRANS_QUAD, "EXPO": Tween.TRANS_EXPO,
	"ELASTIC": Tween.TRANS_ELASTIC, "CUBIC": Tween.TRANS_CUBIC, "CIRC": Tween.TRANS_CIRC,
	"BOUNCE": Tween.TRANS_BOUNCE, "BACK": Tween.TRANS_BACK, "SPRING": Tween.TRANS_SPRING,
}
const _EASE := {
	"IN": Tween.EASE_IN, "OUT": Tween.EASE_OUT, "IN_OUT": Tween.EASE_IN_OUT, "OUT_IN": Tween.EASE_OUT_IN,
}
const PROPS := ["scale", "alpha", "offset", "rotation_deg"]


## True when the player turned on Settings -> Reduce motion (MetaState.reduce_motion). Every motion site
## (shake, hit-stop, particles, slides, scale pops) asks this one function, so the UI-04 motion table
## and any new effect get the setting for free. UI only: never read it from rules or replay code.
static func reduced() -> bool:
	return MetaState.reduce_motion


## Longest a state change may take with Reduce motion on (a short fade so the change is still visible).
const REDUCED_MAX_SEC := 0.12


## The whole table (cached). Keys starting with "_" are notes.
static func table() -> Dictionary:
	if not _loaded:
		_loaded = true
		var f := FileAccess.open(TABLE_PATH, FileAccess.READ)
		if f == null:
			push_error("UI3Motion: cannot open %s" % TABLE_PATH)
		else:
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY:
				_table = parsed
			else:
				push_error("UI3Motion: %s is not a JSON object" % TABLE_PATH)
	return _table


## Test hook: forget the cache so the next call re-reads the file (or `override`).
## `override` null = re-read the file; any Dictionary (even empty, to simulate a failed load) is used as is.
static func reset_table(override: Variant = null) -> void:
	if override is Dictionary:
		_table = override
		_loaded = true
	else:
		_table = {}
		_loaded = false
	played.clear()


static func has_moment(id: String) -> bool:
	return not id.begins_with("_") and table().has(id) and typeof(table()[id]) == TYPE_DICTIONARY


static func moment_ids() -> Array[String]:
	var out: Array[String] = []
	for k in table().keys():
		if has_moment(String(k)):
			out.append(String(k))
	out.sort()
	return out


## Problems in one moment definition, as readable strings (empty = fine). Used by the loader test and
## by tools/check_tokens.sh style checks on a candidate motion table.
static func validate_moment(id: String, m: Dictionary) -> Array[String]:
	var errs: Array[String] = []
	if not m.has("in") and not m.has("out"):
		errs.append("%s: needs an 'in' or an 'out' phase" % id)
	for ph in ["in", "out"]:
		if not m.has(ph):
			continue
		var p: Variant = m[ph]
		if typeof(p) != TYPE_DICTIONARY:
			errs.append("%s.%s: not an object" % [id, ph])
			continue
		var pd: Dictionary = p
		if float(pd.get("ms", -1)) < 0.0:
			errs.append("%s.%s: 'ms' missing or negative" % [id, ph])
		_check_curve(id + "." + ph, pd, errs)
		for prop in (pd.get("props", {}) as Dictionary).keys():
			if not PROPS.has(String(prop)):
				errs.append("%s.%s: unknown prop '%s'" % [id, ph, prop])
			else:
				_check_curve("%s.%s.%s" % [id, ph, prop], (pd["props"] as Dictionary)[prop], errs)
	if m.has("hold_ms") and float(m["hold_ms"]) < 0.0:
		errs.append("%s: hold_ms negative" % id)
	for pk in ["particles", "particles2"]:
		var pt: Variant = m.get(pk)
		if pt == null:
			continue
		if typeof(pt) != TYPE_DICTIONARY:
			errs.append("%s.%s: not an object" % [id, pk])
		else:
			var tex := String((pt as Dictionary).get("texture", ""))
			if tex == "" or not ResourceLoader.exists(tex):
				errs.append("%s.%s.texture '%s' not found" % [id, pk, tex])
			var ct := String((pt as Dictionary).get("color_token", ""))
			if ct != "" and not ((UI3Theme.tokens().get("color", {}) as Dictionary).has(ct)):
				errs.append("%s.%s.color_token '%s' is not a colour token" % [id, pk, ct])
	var sfx := String(m.get("sfx", ""))
	if sfx != "" and not ((UI3Gacha.timing().get("sfx", {}) as Dictionary).has(sfx)):
		errs.append("%s.sfx '%s' not in gacha_timing.json sfx" % [id, sfx])
	if m.has("layers"):
		if typeof(m["layers"]) != TYPE_ARRAY:
			errs.append("%s.layers: not an array" % id)
		else:
			for l in m["layers"]:
				errs.append_array(validate_layer(id, l))
	return errs


## Problems in one UI-05 timeline layer (see play_timeline).
static func validate_layer(id: String, l: Variant) -> Array[String]:
	var errs: Array[String] = []
	if typeof(l) != TYPE_DICTIONARY:
		errs.append("%s.layers: a layer is not an object" % id)
		return errs
	var ld: Dictionary = l
	var nm := "%s.layers.%s" % [id, ld.get("name", "?")]
	if not ld.has("name"):
		errs.append("%s: layer without a name" % nm)
	if float(ld.get("delay_ms", 0.0)) < 0.0:
		errs.append("%s: negative delay_ms" % nm)
	if not LAYER_REDUCE.has(String(ld.get("reduce", "fade"))):
		errs.append("%s: unknown reduce '%s'" % [nm, ld.get("reduce")])
	var kinds := 0
	for k in ["kf", "shake", "hitstop_ms", "particles"]:
		if ld.has(k):
			kinds += 1
	if kinds != 1:
		errs.append("%s: needs exactly one of kf / shake / hitstop_ms / particles" % nm)
	if ld.has("kf"):
		if float(ld.get("ms", -1)) <= 0.0:
			errs.append("%s: 'ms' missing" % nm)
		_check_curve(nm, ld, errs)
		var last_t := -1.0
		for f in (ld["kf"] as Array):
			if typeof(f) != TYPE_DICTIONARY or not (f as Dictionary).has("t"):
				errs.append("%s: keyframe without 't'" % nm)
				continue
			var t := float(f["t"])
			if t < last_t or t < 0.0 or t > 1.0:
				errs.append("%s: keyframe t out of order or outside 0..1" % nm)
			last_t = t
			for pk in (f as Dictionary).keys():
				if pk != "t" and not KF_PROPS.has(String(pk)):
					errs.append("%s: unknown keyframe prop '%s'" % [nm, pk])
	if ld.has("shake"):
		var sh: Variant = ld["shake"]
		if typeof(sh) != TYPE_DICTIONARY or float((sh as Dictionary).get("px", 0)) <= 0.0 or float((sh as Dictionary).get("ms", 0)) <= 0.0:
			errs.append("%s: shake needs px and ms" % nm)
	if ld.has("hitstop_ms") and (float(ld["hitstop_ms"]) <= 0.0 or float(ld["hitstop_ms"]) > HITSTOP_MAX_MS):
		errs.append("%s: hitstop_ms outside 1..%d" % [nm, int(HITSTOP_MAX_MS)])
	if ld.has("particles"):
		var pt: Variant = ld["particles"]
		var tex := String((pt as Dictionary).get("texture", "")) if typeof(pt) == TYPE_DICTIONARY else ""
		if tex == "" or not ResourceLoader.exists(tex):
			errs.append("%s: particle texture '%s' not found" % [nm, tex])
	var ct := String(ld.get("color_token", ""))
	if ct != "" and not ((UI3Theme.tokens().get("color", {}) as Dictionary).has(ct)):
		errs.append("%s: color_token '%s' is not a colour token" % [nm, ct])
	return errs


static func _check_curve(where: String, d: Variant, errs: Array[String]) -> void:
	if typeof(d) != TYPE_DICTIONARY:
		return
	var dd: Dictionary = d
	if dd.has("trans") and not _TRANS.has(String(dd["trans"])):
		errs.append("%s: unknown trans '%s'" % [where, dd["trans"]])
	if dd.has("ease") and not _EASE.has(String(dd["ease"])):
		errs.append("%s: unknown ease '%s'" % [where, dd["ease"]])


## Total running time of a moment in seconds (in + hold + out), after opts.hold_ms / scale_ms.
static func duration_sec(id: String, opts: Dictionary = {}) -> float:
	if not has_moment(id):
		return 0.0
	var m: Dictionary = table()[id]
	var k := float(opts.get("scale_ms", 1.0))
	var hold := float(opts.get("hold_ms", m.get("hold_ms", 0.0)))
	var red := bool(opts.get("reduced", false)) or reduced()
	var total := 0.0
	for ph in ["in", "out"]:
		if m.has(ph):
			if red:
				total += minf(float((m[ph] as Dictionary).get("ms", 0.0)) * k, REDUCED_MAX_SEC * 1000.0)
			else:
				total += (float((m[ph] as Dictionary).get("delay_ms", 0.0)) + float((m[ph] as Dictionary).get("ms", 0.0))) * k
	if m.has("in") and m.has("out"):
		total += hold * k
	return total / 1000.0


## Play moment `id` on `node`. See the header for opts. Returns the Tween, or null (skipped / nothing to run).
static func play(id: String, node: CanvasItem, opts: Dictionary = {}) -> Tween:
	if node == null or not is_instance_valid(node):
		return null
	if not has_moment(id):
		# Missing table or unknown id: never leave a banner up or a chip stacked. Honour the caller's
		# end-state flags, then call on_done (deferred, so callers see the same ordering as a real tween).
		push_error("UI3Motion: unknown moment '%s'" % id)
		if bool(opts.get("hide_on_done", false)):
			node.visible = false
		var cb0: Variant = opts.get("on_done")
		if cb0 is Callable and (cb0 as Callable).is_valid():
			(cb0 as Callable).call_deferred()
		if bool(opts.get("free_on_done", false)):
			node.queue_free()
		return null
	if record and played.size() < 64:
		played.append(id)
	var m: Dictionary = table()[id]
	var red := bool(opts.get("reduced", false)) or reduced()
	if red:
		m = _reduced_moment(m)
	var skip := bool(opts.get("skip", false)) or bool(opts.get("instant", false)) \
		or (red and not bool(m.get("_has_alpha", false)))
	var k := float(opts.get("scale_ms", 1.0))
	if red:
		k = minf(k, 1.0)
	var base_pos: Vector2 = node.position if node is Control or node is Node2D else Vector2.ZERO
	var sfx := String(m.get("sfx", ""))
	if sfx != "":
		UI3Gacha.play_sfx(node, sfx)
	if not red and m.has("hitstop_ms") and node.is_inside_tree() and not bool(opts.get("skip", false)):
		hitstop(node, float(m["hitstop_ms"]))
	if not red and not MetaState.reduce_flash and m.has("sweep") and node is Control and node.is_inside_tree() \
			and not bool(opts.get("skip", false)):
		var sw: Dictionary = m["sweep"]
		sweep(node as Control, float(sw.get("delay_ms", 0.0)) * float(opts.get("scale_ms", 1.0)), float(sw.get("ms", 400.0)),
			float(sw.get("width", 120.0)), float(sw.get("alpha", 0.08)), String(sw.get("color_token", "text")),
			bool(sw.get("fade", false)))
	# Start state of the first phase that names a "from".
	for ph in ["in", "out"]:
		if m.has(ph):
			_apply_from(node, m[ph] as Dictionary, base_pos)
	if red and m.has("in"):
		_settle(node, m["in"] as Dictionary, base_pos)
	if skip or not node.is_inside_tree():
		_finish_state(node, m, base_pos)
		if red:
			_settle(node, (m["out"] if m.has("out") else m["in"]) as Dictionary, base_pos)
		_after(node, m, opts)
		return null
	var tw := node.create_tween()
	tw.set_parallel(false)
	var first := true
	for ph in ["in", "out"]:
		if not m.has(ph):
			continue
		var p: Dictionary = m[ph]
		if ph == "out" and m.has("in"):
			var hold := float(opts.get("hold_ms", m.get("hold_ms", 0.0))) * k / 1000.0
			if hold > 0.0:
				tw.tween_interval(hold)
		var delay := float(p.get("delay_ms", 0.0)) * k / 1000.0
		if delay > 0.0:
			tw.tween_interval(delay)
		_phase(tw, node, p, k, base_pos)
		if first and m.has("shake") and String(m.get("shake_target", "")) != "screen":
			_shake(tw, node, m["shake"] as Dictionary, k, base_pos)
		first = false
		if ph == "in":
			for pk in ["particles", "particles2"]:
				if m.has(pk):
					tw.parallel().tween_callback(_burst.bind(node, m[pk] as Dictionary))
	tw.set_parallel(false)
	if red and m.has("out"):
		tw.tween_callback(_settle.bind(node, m["out"] as Dictionary, base_pos))
	tw.tween_callback(_after.bind(node, m, opts))
	return tw


static func _phase(tw: Tween, node: CanvasItem, p: Dictionary, k: float, base_pos: Vector2) -> void:
	var sec := float(p.get("ms", 0.0)) * k / 1000.0
	var props: Dictionary = p.get("props", {})
	tw.set_parallel(true)
	if props.is_empty():
		tw.tween_interval(sec)
	for pn in props.keys():
		var spec: Dictionary = props[pn]
		if not spec.has("to"):
			continue
		var tn := _tween_prop(String(pn), node, spec["to"], base_pos)
		if tn.is_empty():
			continue
		var t := tw.tween_property(node, String(tn["path"]), tn["value"], sec)
		t.set_trans(_TRANS.get(String(spec.get("trans", p.get("trans", "LINEAR"))), Tween.TRANS_LINEAR))
		t.set_ease(_EASE.get(String(spec.get("ease", p.get("ease", "IN_OUT"))), Tween.EASE_IN_OUT))
	tw.set_parallel(false)


static func _shake(tw: Tween, node: CanvasItem, s: Dictionary, k: float, base_pos: Vector2) -> void:
	if not (node is Control or node is Node2D):
		return
	var px := float(s.get("px", 0.0))
	var sec := float(s.get("ms", 0.0)) * k / 1000.0
	if px <= 0.0 or sec <= 0.0:
		return
	# Deterministic wobble (no RNG: UI only, but tests stay stable): +px, -px, +px/2, 0 over `sec`.
	var steps := [Vector2(px, 0), Vector2(-px, 0), Vector2(px * 0.5, 0), Vector2.ZERO]
	var seq := node.create_tween()
	for st in steps:
		seq.tween_property(node, "position", base_pos + (st as Vector2), sec / float(steps.size()))


static func _burst(node: CanvasItem, pt: Dictionary) -> void:
	if not is_instance_valid(node) or not node.is_inside_tree():
		return
	var dl := float(pt.get("delay_ms", 0.0))
	if dl > 0.0:
		var later := pt.duplicate()
		later.erase("delay_ms")
		var nw: WeakRef = weakref(node)
		node.get_tree().create_timer(dl / 1000.0).timeout.connect(func() -> void:
			var n: CanvasItem = nw.get_ref()
			if n != null and not reduced():
				_burst(n, later))
		return
	var tex_path := String(pt.get("texture", ""))
	if tex_path == "" or not ResourceLoader.exists(tex_path):
		return
	var cp := CPUParticles2D.new()
	cp.texture = load(tex_path)
	cp.one_shot = true
	cp.explosiveness = 1.0
	cp.amount = int(pt.get("amount", 8))
	cp.lifetime = float(pt.get("lifetime_ms", 600)) / 1000.0
	cp.spread = float(pt.get("spread_deg", 180.0)) * (0.5 if bool(pt.get("spread_full", false)) else 1.0)
	var spx := float(pt.get("size_px", 0.0))
	if spx > 0.0 and cp.texture != null and cp.texture.get_width() > 0:
		cp.scale_amount_min = spx / float(cp.texture.get_width()) * 0.7
		cp.scale_amount_max = spx / float(cp.texture.get_width()) * 1.3
	cp.initial_velocity_min = float(pt.get("speed", 120.0)) * 0.6
	cp.initial_velocity_max = float(pt.get("speed", 120.0))
	cp.gravity = Vector2(0.0, float(pt.get("gravity", 0.0)))
	if pt.has("direction_deg"):
		cp.direction = Vector2.RIGHT.rotated(deg_to_rad(float(pt["direction_deg"])))
	if bool(pt.get("ring", false)):
		cp.spread = 180.0
	var ct := String(pt.get("color_token", ""))
	if ct != "":
		cp.color = UI3Theme.color(ct)
	cp.z_index = 1
	cp.emitting = true
	node.add_child(cp)
	cp.position = (node as Control).size * 0.5 if node is Control else Vector2.ZERO
	cp.finished.connect(cp.queue_free)


static func _tween_prop(pname: String, node: CanvasItem, v: Variant, base_pos: Vector2) -> Dictionary:
	match pname:
		"scale":
			if node is Control or node is Node2D:
				return {"path": "scale", "value": _vec(v)}
		"alpha":
			return {"path": "modulate:a", "value": float(v)}
		"offset":
			if node is Control or node is Node2D:
				return {"path": "position", "value": base_pos + _vec(v)}
		"rotation_deg":
			if node is Control or node is Node2D:
				return {"path": "rotation", "value": deg_to_rad(float(v))}
	return {}


static func _vec(v: Variant) -> Vector2:
	if v is Array and (v as Array).size() >= 2:
		return Vector2(float(v[0]), float(v[1]))
	return Vector2(float(v), float(v))


static func _apply_from(node: CanvasItem, p: Dictionary, base_pos: Vector2) -> void:
	var props: Dictionary = p.get("props", {})
	for pn in props.keys():
		var spec: Dictionary = props[pn]
		if not spec.has("from"):
			continue
		var tn := _tween_prop(String(pn), node, spec["from"], base_pos)
		if not tn.is_empty():
			node.set_indexed(NodePath(String(tn["path"])), tn["value"])


## Reduce motion: a copy of the moment with no shake, no particles, no delays, only alpha tweens, every phase
## at most REDUCED_MAX_SEC. Scale / offset / rotation are not animated: they jump to their "to" value
## (the in phase at the start, the out phase when the node is done). `_has_alpha` marks whether any fade is left.
static func _reduced_moment(m: Dictionary) -> Dictionary:
	var r: Dictionary = m.duplicate(true)
	r.erase("shake")
	r.erase("particles")
	r.erase("particles2")
	r.erase("hitstop_ms")
	r.erase("sweep")
	var has_alpha := false
	for ph in ["in", "out"]:
		if not r.has(ph):
			continue
		var p: Dictionary = r[ph]
		p["ms"] = minf(float(p.get("ms", 0.0)), REDUCED_MAX_SEC * 1000.0)
		p["delay_ms"] = 0.0
		p["trans"] = "LINEAR"
		p["ease"] = "IN_OUT"
		var kept := {}
		for pn in (p.get("props", {}) as Dictionary).keys():
			var spec: Dictionary = (p["props"] as Dictionary)[pn]
			if String(pn) == "alpha":
				var a: Dictionary = spec.duplicate()
				a["trans"] = "LINEAR"
				a["ease"] = "IN_OUT"
				kept[pn] = a
				has_alpha = true
			elif spec.has("to"):
				# Non-alpha end state is applied by the settle step instead of being tweened.
				p.get_or_add("_settle", {})[pn] = spec["to"]
		p["props"] = kept
		r[ph] = p
	r["_has_alpha"] = has_alpha
	r["_reduced"] = true
	return r


static func _settle(node: CanvasItem, p: Dictionary, base_pos: Vector2) -> void:
	for pn in (p.get("_settle", {}) as Dictionary).keys():
		var tn := _tween_prop(String(pn), node, (p["_settle"] as Dictionary)[pn], base_pos)
		if not tn.is_empty():
			node.set_indexed(NodePath(String(tn["path"])), tn["value"])


## Skip / reduced motion: put the node in the state the LAST phase ends in.
static func _finish_state(node: CanvasItem, m: Dictionary, base_pos: Vector2) -> void:
	var last: Dictionary = m["out"] if m.has("out") else m["in"]
	for pn in (last.get("props", {}) as Dictionary).keys():
		var spec: Dictionary = last["props"][pn]
		if not spec.has("to"):
			continue
		var tn := _tween_prop(String(pn), node, spec["to"], base_pos)
		if not tn.is_empty():
			node.set_indexed(NodePath(String(tn["path"])), tn["value"])


static func _after(node: CanvasItem, m: Dictionary, opts: Dictionary) -> void:
	if not is_instance_valid(node):
		return
	if bool(m.get("hide_on_done", false)):
		node.visible = false
	var cb: Variant = opts.get("on_done")
	if cb is Callable and (cb as Callable).is_valid():
		(cb as Callable).call()
	if bool(m.get("free_on_done", false)):
		node.queue_free()


## Hit-stop: Engine.time_scale 0.05 for `ms` of real time, then back to 1. UI-05 crit / big hit / boss phase.
## Call sites never need to reset it; a second call while one runs is ignored. The restore timer lives on the
## SceneTree (not on `node`), runs while paused and ignores time_scale, so freeing the scene (or the node) mid
## hit-stop still restores 1.0. end_hitstop() restores at once (scene exit, skip).
static func hitstop(node: Node, ms: float) -> void:
	if reduced() or MetaState.reduce_flash or Engine.time_scale < 0.5 or node == null or not is_instance_valid(node) \
			or not node.is_inside_tree() or ms <= 0.0:
		return
	hitstop_count += 1
	_hitstop_serial += 1
	var serial := _hitstop_serial
	_hitstop_active = true
	Engine.time_scale = HITSTOP_SCALE
	var t := node.get_tree().create_timer(minf(ms, HITSTOP_MAX_MS) / 1000.0, true, false, true)   # ignore_time_scale
	t.timeout.connect(func() -> void:
		if _hitstop_serial == serial:
			end_hitstop())


## Ends a running hit-stop now (no-op when none runs). Safe to call from _exit_tree of anything that started one.
static func end_hitstop() -> void:
	if _hitstop_active:
		_hitstop_active = false
		Engine.time_scale = 1.0


static func hitstop_active() -> bool:
	return _hitstop_active


const HITSTOP_SCALE := 0.05
## Longest hit-stop a table row may ask for (a typo like 600 would freeze the game for 12 s of game time).
const HITSTOP_MAX_MS := 200.0
## Hit-stops started so far (tests read it; never reset by the game).
static var hitstop_count := 0
static var _hitstop_active := false
static var _hitstop_serial := 0


## Light sweep (motion.md): one translucent plate (text colour at 8%, 120 px wide, rotated 18 deg) tweened across
## `parent` with clip_contents on. No shader. Skipped when Reduce motion or reduce_flash is on.
static func sweep(parent: Control, delay_ms := 0.0, ms := 400.0, width := 120.0, alpha := 0.08,
		color_token := "text", fade := false) -> void:
	if reduced() or MetaState.reduce_flash or not parent.is_inside_tree():
		return
	parent.clip_contents = true
	var bar := ColorRect.new()
	bar.name = "LightSweep"
	bar.color = Color(UI3Theme.color(color_token), alpha)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.size = Vector2(width, maxf(parent.size.y * 1.6, 120.0))
	bar.rotation = deg_to_rad(18.0)
	bar.position = Vector2(-width - 40.0, -parent.size.y * 0.3)
	parent.add_child(bar)
	var tw := bar.create_tween()
	if delay_ms > 0.0:
		tw.tween_interval(delay_ms / 1000.0)
	tw.tween_property(bar, "position:x", parent.size.x + width + 40.0, ms / 1000.0).set_trans(Tween.TRANS_SINE)
	if fade:
		tw.parallel().tween_property(bar, "modulate:a", 0.0, ms / 1000.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_callback(bar.queue_free)


# ---------------------------------------------------------------- UI-05 timelines

## UI-05 moment timelines (design/handoffs/ui-05-figma/round-1/motion-batch1.md, moments/*.html). A moment's
## "layers" array is the table, one row per layer, in the same units:
##   keyframes: {"name", "target", "delay_ms", "ms", "trans", "ease", "kf": [{"t": 0..1, prop: value}, ...],
##               "reduce": "fade" | "cap" | "removed" | "kept", "flash": true (= off with Reduce flashing)}
##              props: alpha, scale (number or [x, y]), scale_x, scale_y, x, y (px added to the rest position),
##              rot (degrees). "t" is a share of the layer's TIME (the tables say "fade last 200 ms", "hold 650 ms"),
##              and trans/ease shape every segment between two keyframes (BACK / ELASTIC overshoot inside a
##              segment). A prop missing from the first / last keyframe uses the node's value before the moment.
##   shake:     {"name", "delay_ms", "shake": {"px", "ms"}}               -> opts.shake Callable(px, sec), or the
##                                                                          "shake" target node wobbles
##   hit-stop:  {"name", "delay_ms", "hitstop_ms"}                         -> UI3Motion.hitstop
##   particles: {"name", "target", "delay_ms", "particles": {...}}        -> one burst at the target's centre
## A layer whose target is not in `targets` is skipped (3D nodes and other lanes' nodes stay in the table as data).
## Reduce motion: "removed" layers, shake, hit-stop and particles do not run; "fade" plays only alpha (see
## _fade_plan: in <= 120 ms, out <= 120 ms at the time the table fades the layer); "cap" keeps the keyframes but at
## most 120 ms; "kept" plays as is. Delays stay (the order of the moment is kept).
## Returns a Timeline: skip() jumps every layer to its end state (no late particles / shake / hit-stop).
const KF_PROPS := ["alpha", "scale", "scale_x", "scale_y", "x", "y", "rot"]
const LAYER_REDUCE := ["fade", "cap", "removed", "kept"]


class Timeline:
	extends RefCounted
	signal finished
	var id := ""
	var skipped := false
	var done := false
	var _pending := 0
	var _tweens: Array[Tween] = []
	var _finals: Array[Callable] = []
	var _on_done: Callable

	func running() -> bool:
		return not done

	## Jump every layer to its end state now. Late bursts, shakes and hit-stops are dropped.
	func skip() -> void:
		if done:
			return
		skipped = true
		for tw in _tweens:
			if tw != null and tw.is_valid():
				tw.kill()
		for f in _finals:
			if f.is_valid():
				f.call()
		_finish()

	func _one_done() -> void:
		_pending -= 1
		if _pending <= 0:
			_finish()

	func _finish() -> void:
		if done:
			return
		done = true
		if _on_done.is_valid():
			_on_done.call()
		finished.emit()


## The layers of moment `id` (empty when it has none).
static func layers(id: String) -> Array:
	if not has_moment(id):
		return []
	var l: Variant = (table()[id] as Dictionary).get("layers", [])
	return l if l is Array else []


## One layer of moment `id` by name ({} when missing).
static func layer(id: String, layer_name: String) -> Dictionary:
	for l in layers(id):
		if l is Dictionary and String((l as Dictionary).get("name", "")) == layer_name:
			return l
	return {}


## Screen shake numbers of moment `id`: {"px", "ms", "delay_ms"} from its "shake" (or {} when it has none).
static func screen_shake(id: String) -> Dictionary:
	if not has_moment(id):
		return {}
	var sh: Variant = (table()[id] as Dictionary).get("shake")
	return (sh as Dictionary) if sh is Dictionary else {}


## Seconds until the last layer of `id` ends (delay + ms), without hit-stop. Reduced: the reduced timings.
static func timeline_sec(id: String, red := false) -> float:
	var end := 0.0
	for l in layers(id):
		var ld: Dictionary = l
		var r := String(ld.get("reduce", "fade"))
		var d := float(ld.get("delay_ms", 0.0))
		var ms := float(ld.get("ms", 0.0))
		if ld.has("shake"):
			ms = float((ld["shake"] as Dictionary).get("ms", 0.0))
		if red:
			if r == "removed" or ld.has("shake") or ld.has("hitstop_ms") or ld.has("particles"):
				continue
			if r == "fade":
				ms = _reduced_fade_end_ms(ld)
			elif r == "cap":
				ms = minf(ms, REDUCED_MAX_SEC * 1000.0)
		end = maxf(end, d + ms)
	return end / 1000.0


## Play the "layers" of moment `id`. targets: layer target name -> CanvasItem. opts: reduced, skip, on_done,
## host (Node used for timers, shake and hit-stop; default the first target), shake (Callable(px, sec)),
## only / except (Array of layer names: play just these / all but these).
static func play_timeline(id: String, targets: Dictionary, opts: Dictionary = {}) -> Timeline:
	var run := Timeline.new()
	run.id = id
	var cb: Variant = opts.get("on_done")
	if cb is Callable:
		run._on_done = cb
	if not has_moment(id):
		push_error("UI3Motion: unknown moment '%s'" % id)
		(func() -> void: run._finish()).call_deferred()
		return run
	if record and played.size() < 64:
		played.append(id)
	var red := bool(opts.get("reduced", false)) or reduced()
	var host: Node = null
	var h: Variant = opts.get("host")
	if h is Node and is_instance_valid(h):
		host = h
	else:
		for t in targets.values():
			if t is Node and is_instance_valid(t):
				host = t
				break
	var only: Array = opts.get("only", [])
	var except: Array = opts.get("except", [])
	var picked: Array = []
	var first_delay := {}   # target -> lowest delay among its keyframe layers (only that one fills backwards)
	var rest := {}          # target -> its state before any layer touched it
	for l in layers(id):
		var ld: Dictionary = l
		var lname := String(ld.get("name", ""))
		if (not only.is_empty() and not only.has(lname)) or except.has(lname):
			continue
		if red and String(ld.get("reduce", "fade")) == "removed":
			continue
		picked.append(ld)
		var tg := String(ld.get("target", ""))
		if ld.has("kf") and targets.get(tg) is CanvasItem and is_instance_valid(targets[tg]):
			first_delay[tg] = minf(float(first_delay.get(tg, INF)), float(ld.get("delay_ms", 0.0)))
			if not rest.has(tg):
				rest[tg] = _snapshot(targets[tg] as CanvasItem)
	for ld in picked:
		var tg := String(ld.get("target", ""))
		var fill := float(ld.get("delay_ms", 0.0)) <= float(first_delay.get(tg, INF))
		_play_layer(run, ld, targets, host, red, opts, rest.get(tg, {}), fill)
	if bool(opts.get("skip", false)):
		run.skip()
	elif run._pending <= 0:
		(func() -> void: run._finish()).call_deferred()
	elif host != null and host.is_inside_tree():
		# Watchdog: a tween dies without `finished` when its node is freed (a plate rebuilt mid-moment). The moment
		# still ends, so nothing waits on it forever (U5SkipCatcher would keep eating Space).
		host.get_tree().create_timer(timeline_sec(id, red) + WATCHDOG_SLACK_SEC, true, false, true).timeout.connect(
			func() -> void:
				if not run.done:
					run.skip())   # captures only `run`; its finals hold WeakRefs
	return run


## Real seconds a timeline may overrun its table length (hit-stops, slow frames) before the watchdog ends it.
const WATCHDOG_SLACK_SEC := 1.0


static func _play_layer(run: Timeline, l: Dictionary, targets: Dictionary, host: Node, red: bool, opts: Dictionary,
		rest: Dictionary = {}, fill_back := true) -> void:
	var rmode := String(l.get("reduce", "fade"))
	if bool(l.get("flash", false)) and MetaState.reduce_flash:
		return
	var delay := float(l.get("delay_ms", 0.0)) / 1000.0
	if l.has("kf"):
		var node: Variant = targets.get(String(l.get("target", "")))
		if not (node is CanvasItem) or not is_instance_valid(node):
			return
		if red and rmode == "removed":
			return
		var ci: CanvasItem = node
		var tracks := _kf_tracks(ci, l["kf"] as Array, rest)
		var sec := float(l.get("ms", 0.0)) / 1000.0
		tracks["_trans"] = _TRANS.get(String(l.get("trans", "LINEAR")), Tween.TRANS_LINEAR)
		tracks["_ease"] = _EASE.get(String(l.get("ease", "IN_OUT")), Tween.EASE_IN_OUT)
		if red and rmode == "fade":
			tracks = _fade_tracks(tracks, l)
			sec = _reduced_fade_end_ms(l) / 1000.0
		elif red and rmode == "cap":
			sec = minf(sec, REDUCED_MAX_SEC)
		if fill_back:
			_kf_apply(ci, tracks, 0.0)   # the first layer on a node shows its start state during its delay (WAAPI fill)
		var cw: WeakRef = weakref(ci)   # skip() / the watchdog can run after the node is gone: never capture it
		var final := func() -> void:
			var c: CanvasItem = cw.get_ref()
			if c != null:
				_kf_apply(c, tracks, 1.0)
		run._finals.append(final)
		var tw := ci.create_tween()
		if delay > 0.0:
			tw.tween_interval(delay)
			if not fill_back:
				tw.tween_callback(func() -> void:
					var c: CanvasItem = cw.get_ref()
					if c != null:
						_kf_apply(c, tracks, 0.0))
		tw.tween_method(func(p: float) -> void:
			var c: CanvasItem = cw.get_ref()
			if c != null:
				_kf_apply(c, tracks, p), 0.0, 1.0, maxf(sec, 0.001))   # linear time; easing is per segment
		_track(run, tw)
		return
	# Side effects: never under Reduce motion, never after a skip.
	if red or host == null or not is_instance_valid(host):
		return
	var fx := Callable()
	var hw: WeakRef = weakref(host)
	if l.has("hitstop_ms"):
		var ms := float(l["hitstop_ms"])
		fx = func() -> void:
			var hn: Node = hw.get_ref()
			if not run.skipped and hn != null:
				hitstop(hn, ms)
	elif l.has("shake"):
		var sh: Dictionary = l["shake"]
		var px := float(sh.get("px", 0.0))
		var ssec := float(sh.get("ms", 0.0)) / 1000.0
		var shake_cb: Variant = opts.get("shake")
		var sn: Variant = targets.get("shake")
		var snw: WeakRef = weakref(sn) if sn is CanvasItem else null
		fx = func() -> void:
			if run.skipped:
				return
			if shake_cb is Callable and (shake_cb as Callable).is_valid():
				(shake_cb as Callable).call(px, ssec)
			elif snw != null and snw.get_ref() != null:
				wobble(snw.get_ref() as CanvasItem, px, ssec)
	elif l.has("particles"):
		var pnode: Variant = targets.get(String(l.get("target", "")))
		if not (pnode is CanvasItem) or not is_instance_valid(pnode):
			return
		var pt: Dictionary = (l["particles"] as Dictionary).duplicate()
		pt.erase("delay_ms")
		var pw: WeakRef = weakref(pnode)
		fx = func() -> void:
			var pn: CanvasItem = pw.get_ref()
			if not run.skipped and pn != null and not reduced():
				_burst(pn, pt)
	if not fx.is_valid():
		return
	if delay <= 0.0:
		fx.call()
		return
	var tw2 := host.create_tween()
	tw2.tween_interval(delay)
	tw2.tween_callback(fx)
	_track(run, tw2)


static func _track(run: Timeline, tw: Tween) -> void:
	run._tweens.append(tw)
	run._pending += 1
	tw.finished.connect(func() -> void: run._one_done())   # the lambda keeps `run` alive while the tween lives


## Deterministic decaying wobble (+px, -px, +px/2, -px/4, 0) on a Control / Node2D. No RNG: tests stay stable.
static func wobble(node: CanvasItem, px: float, sec: float) -> void:
	if not (node is Control or node is Node2D) or px <= 0.0 or sec <= 0.0 or reduced():
		return
	var base: Vector2 = node.get("position")
	var steps := [Vector2(px, 0), Vector2(-px, px * 0.5), Vector2(px * 0.5, -px * 0.25), Vector2(-px * 0.25, 0), Vector2.ZERO]
	var tw := node.create_tween()
	for st in steps:
		tw.tween_property(node, "position", base + (st as Vector2), sec / float(steps.size()))


## prop -> Array of [t, value] (sorted), with the node's current value filled in at t = 0 / 1 when a keyframe
## at that end does not name the prop.
## The values the keyframe props start from when a keyframe does not name them (taken before any layer runs).
static func _snapshot(node: CanvasItem) -> Dictionary:
	var out := {"alpha": node.modulate.a}
	if node is Control or node is Node2D:
		out["position"] = node.get("position")
		out["scale"] = node.get("scale")
		out["rot"] = rad_to_deg(float(node.get("rotation")))
	return out


static func _kf_tracks(node: CanvasItem, kf: Array, rest: Dictionary = {}) -> Dictionary:
	var tracks := {}
	for f in kf:
		var fd: Dictionary = f
		for pk in fd.keys():
			if pk == "t":
				continue
			if not tracks.has(pk):
				tracks[pk] = []
			(tracks[pk] as Array).append([float(fd["t"]), fd[pk]])
	if rest.is_empty():
		rest = _snapshot(node)
	var base: Vector2 = rest.get("position", Vector2.ZERO)
	var out := {"_base": base}
	for pk in tracks.keys():
		var pts: Array = tracks[pk]
		var cur: Variant = _kf_current(rest, String(pk))
		if float(pts[0][0]) > 0.0:
			pts.push_front([0.0, cur])
		if float(pts[pts.size() - 1][0]) < 1.0:
			pts.append([1.0, pts[pts.size() - 1][1]])
		out[pk] = pts
	return out


static func _kf_current(rest: Dictionary, pk: String) -> Variant:
	var sc: Vector2 = rest.get("scale", Vector2.ONE)
	match pk:
		"alpha":
			return float(rest.get("alpha", 1.0))
		"scale", "scale_x":
			return sc.x
		"scale_y":
			return sc.y
		"rot":
			return float(rest.get("rot", 0.0))
	return 0.0   # x / y are offsets from the rest position


static func _kf_value(pts: Array, p: float, trans: int = Tween.TRANS_LINEAR, ease: int = Tween.EASE_IN_OUT) -> Variant:
	if pts.size() == 1:
		return pts[0][1]
	var i := 0
	while i < pts.size() - 2 and p > float(pts[i + 1][0]):
		i += 1
	var t0 := float(pts[i][0])
	var t1 := float(pts[i + 1][0])
	var lin := 1.0 if is_equal_approx(t0, t1) else clampf((p - t0) / (t1 - t0), 0.0, 1.0)
	var u: float = Tween.interpolate_value(0.0, 1.0, lin, 1.0, trans, ease)   # may overshoot 0..1 (BACK, ELASTIC)
	var a: Variant = pts[i][1]
	var b: Variant = pts[i + 1][1]
	if a is Array or b is Array:
		var va := _vec(a)
		var vb := _vec(b)
		return [lerpf(va.x, vb.x, u), lerpf(va.y, vb.y, u)]
	return lerpf(float(a), float(b), u)


static func _kf_apply(node: CanvasItem, tracks: Dictionary, p: float) -> void:
	var base: Vector2 = tracks.get("_base", Vector2.ZERO)
	var off := Vector2.ZERO
	var moved := false
	var sc := Vector2(-1, -1)
	var trans: int = tracks.get("_trans", Tween.TRANS_LINEAR)
	var ease: int = tracks.get("_ease", Tween.EASE_IN_OUT)
	for pk in tracks.keys():
		if String(pk).begins_with("_"):
			continue
		var v: Variant = _kf_value(tracks[pk], p, trans, ease)
		match String(pk):
			"alpha":
				node.modulate.a = clampf(float(v), 0.0, 1.0)
			"scale":
				var vv := _vec(v)
				sc = Vector2(vv.x, vv.y)
			"scale_x":
				sc.x = float(v)
			"scale_y":
				sc.y = float(v)
			"x":
				off.x = float(v)
				moved = true
			"y":
				off.y = float(v)
				moved = true
			"rot":
				if node is Control or node is Node2D:
					node.set("rotation", deg_to_rad(float(v)))
	if (node is Control or node is Node2D):
		if sc.x >= 0.0 or sc.y >= 0.0:
			var cur: Vector2 = node.get("scale")
			node.set("scale", Vector2(sc.x if sc.x >= 0.0 else cur.x, sc.y if sc.y >= 0.0 else cur.y))
		if moved:
			node.set("position", base + off)


## Reduce motion "fade" plan for one layer: only alpha, start -> peak in <= 120 ms (none when it starts at its peak),
## hold until the table's last keyframe at the peak, then peak -> end in <= 120 ms (none when it ends at the peak).
## "reduce_from" / "reduce_to" override the start / end alpha (a band that slides in at full alpha fades in instead).
static func _fade_plan(l: Dictionary) -> Dictionary:
	var ms := float(l.get("ms", 0.0))
	var cap := minf(ms, REDUCED_MAX_SEC * 1000.0)
	var pts: Array = []
	for f in (l.get("kf", []) as Array):
		if (f as Dictionary).has("alpha"):
			pts.append([float(f["t"]), float(f["alpha"])])
	if pts.is_empty():
		pts = [[0.0, 0.0], [1.0, 1.0]]
	var peak := 0.0
	for pt in pts:
		peak = maxf(peak, float(pt[1]))
	var t_peak_end := 0.0
	for pt in pts:
		if float(pt[1]) >= peak - 0.0001:
			t_peak_end = float(pt[0])
	var start := float(l.get("reduce_from", pts[0][1]))
	var end_a := float(l.get("reduce_to", pts[pts.size() - 1][1]))
	peak = maxf(peak, maxf(start, end_a))
	var fade_in := cap if start < peak - 0.0001 else 0.0
	var fade_out := cap if end_a < peak - 0.0001 else 0.0
	var hold_end := maxf(t_peak_end * ms, fade_in) if fade_out > 0.0 else fade_in
	var total := maxf(hold_end + fade_out, 1.0)
	return {"start": start, "peak": peak, "end": end_a, "fade_in": fade_in, "hold_end": hold_end, "total": total}


static func _fade_tracks(tracks: Dictionary, l: Dictionary) -> Dictionary:
	var pl := _fade_plan(l)
	var total := float(pl["total"])
	var out := {"_base": tracks.get("_base", Vector2.ZERO)}
	out["alpha"] = [[0.0, pl["start"]], [float(pl["fade_in"]) / total, pl["peak"]],
		[float(pl["hold_end"]) / total, pl["peak"]], [1.0, pl["end"]]]
	return out


## Length in ms of a "fade" layer under Reduce motion (see _fade_plan).
static func _reduced_fade_end_ms(l: Dictionary) -> float:
	return float(_fade_plan(l)["total"])
