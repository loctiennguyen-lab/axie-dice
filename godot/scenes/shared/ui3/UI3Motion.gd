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
##   "sfx": event name in gacha_timing.json "sfx" (played through UI3Gacha.play_sfx, so tests stay silent)
##   "skippable": true -> opts.skip jumps straight to the final state
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
	var pt: Variant = m.get("particles")
	if pt != null:
		if typeof(pt) != TYPE_DICTIONARY:
			errs.append("%s.particles: not an object" % id)
		else:
			var tex := String((pt as Dictionary).get("texture", ""))
			if tex == "" or not ResourceLoader.exists(tex):
				errs.append("%s.particles.texture '%s' not found" % [id, tex])
			var ct := String((pt as Dictionary).get("color_token", ""))
			if ct != "" and not ((UI3Theme.tokens().get("color", {}) as Dictionary).has(ct)):
				errs.append("%s.particles.color_token '%s' is not a colour token" % [id, ct])
	var sfx := String(m.get("sfx", ""))
	if sfx != "" and not ((UI3Gacha.timing().get("sfx", {}) as Dictionary).has(sfx)):
		errs.append("%s.sfx '%s' not in gacha_timing.json sfx" % [id, sfx])
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
		if first and m.has("shake"):
			_shake(tw, node, m["shake"] as Dictionary, k, base_pos)
		first = false
		if ph == "in" and m.has("particles"):
			tw.parallel().tween_callback(_burst.bind(node, m["particles"] as Dictionary))
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
	if not node.is_inside_tree():
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
	cp.spread = float(pt.get("spread_deg", 180.0))
	cp.initial_velocity_min = float(pt.get("speed", 120.0)) * 0.6
	cp.initial_velocity_max = float(pt.get("speed", 120.0))
	cp.gravity = Vector2.ZERO
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
