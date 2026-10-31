extends Node
## UI-05 b23 lane M3: the eleven meta moments (land-tier-up, currency-gain, run-end-win/lose, echo-open-normal/dup/rare/mythic,
## open-10, pass-level-up, daily-claim) exist, validate, play to their end state, skip, drop motion / flashes under the
## accessibility settings, never hang on a freed node, and the PROPOSAL rows never run.
const IDS := ["land-tier-up", "currency-gain", "run-end-win", "run-end-lose", "echo-open-normal", "echo-open-dup",
	"echo-open-rare", "echo-open-mythic", "open-10", "pass-level-up", "daily-claim"]
var _fails: Array[String] = []
var _checks := 0
var _host: Control


func _ok(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_fails.append(m)


func _node(n: String) -> Control:
	var c := Control.new()
	c.name = n
	c.size = Vector2(100, 100)
	c.position = Vector2(300, 300)
	c.pivot_offset = Vector2(50, 50)
	_host.add_child(c)
	return c


func _label(n: String) -> Label:
	var l := Label.new()
	l.name = n
	_host.add_child(l)
	return l


func _wait(tl: UI3Motion.Timeline, sec: float) -> void:
	var t := 0.0
	while tl.running() and t < sec:
		await get_tree().process_frame
		t += get_process_delta_time()


func _bursts(n: Node) -> int:
	var k := 0
	for c in n.get_children():
		if c is CPUParticles2D:
			k += 1
	return k


func _ready() -> void:
	print("=== t_ui5_moments_b3: start ===")
	var was_m := MetaState.reduce_motion
	var was_f := MetaState.reduce_flash
	MetaState.reduce_motion = false
	MetaState.reduce_flash = false
	_host = Control.new()
	add_child(_host)
	await get_tree().process_frame
	# 1 table
	for id in IDS:
		_ok(UI3Motion.has_moment(id), "'%s' missing" % id)
		var errs := UI3Motion.validate_moment(id, UI3Motion.table().get(id, {}))
		_ok(errs.is_empty(), "'%s' invalid: %s" % [id, errs])
		for l in UI3Motion.layers(id):
			var ld: Dictionary = l
			if ld.has("particles") or ld.has("shake") or ld.has("hitstop_ms"):
				_ok(ld.get("reduce") == "removed", "%s.%s must be removed under Reduce motion" % [id, ld.get("name")])
	for pr in [["echo-open-rare", "rays"], ["echo-open-rare", "sparks"], ["echo-open-mythic", "rays"], ["echo-open-mythic", "sparks"],
			["echo-open-mythic", "hitstop"], ["echo-open-mythic", "gold_ring"], ["echo-open-mythic", "shake"]]:
		var pl := UI3Motion.layer(pr[0], pr[1])
		_ok(bool(pl.get("proposal", false)) and bool(pl.get("flash", false)) and pl.get("reduce") == "removed", "%s.%s must be a PROPOSAL flash row, removed" % pr)
	_ok(not UI3Motion.proposals_enabled, "proposals must be off by default")
	# 2 PROPOSAL rows do not run
	var mc := _node("mc")
	var shook := [0]
	var tlp := UI3Motion.play_timeline("echo-open-mythic", {"card": mc, "rays": _node("rays"), "ring": _node("ring")}, {"host": _host,
		"shake": func(_p: float, _s: float) -> void: shook[0] += 1})
	await _wait(tlp, 5.0)
	_ok(tlp.done and shook[0] == 0 and _bursts(mc) == 0 and not Engine.time_scale < 1.0, "PROPOSAL rows ran (shake %d, bursts %d)" % [shook[0], _bursts(mc)])
	_ok(UI3Motion.timeline_sec("echo-open-mythic") < 2.0, "PROPOSAL rows count toward the length")
	# 3 echo card flip ends upright; delay offset
	var card := _node("card")
	var tl := UI3Motion.play_timeline("echo-open-normal", {"card": card}, {"host": _host, "only": ["card_flip"], "delay_ms": -1200.0})
	_ok(card.scale.x < 0.05, "card starts edge-on")
	await _wait(tl, 3.0)
	_ok(tl.done and is_equal_approx(card.scale.x, 1.0) and card.modulate.a > 0.99, "echo card ends flipped in")
	# 4 open-10: cards in order, last pops back to 1
	var cs: Array = []
	for i in 10:
		cs.append(_node("c%d" % i))
	var tl10 := UI3Motion.play_timeline("open-10", {"cards": cs, "last_card": cs[9]}, {"host": _host, "only": ["cards_flip", "last_pop"]})
	await _wait(tl10, 4.0)
	_ok(tl10.done and is_equal_approx((cs[9] as Control).scale.x, 1.0) and is_equal_approx((cs[0] as Control).scale.x, 1.0), "open-10 ends with every card flipped in")
	# 5 count rows
	var lab := _label("amt")
	var tlc := UI3Motion.play_timeline("run-end-win", {"shards": lab}, {"host": _host, "counts": {"shards_count": [0, 1234]}, "only": ["shards_count"]})
	await _wait(tlc, 3.0)
	_ok(lab.text == "+1,234", "count text '%s'" % lab.text)
	var lab2 := _label("amt2")
	var tlk := UI3Motion.play_timeline("currency-gain", {"chip": lab2}, {"host": _host, "counts": {"chip_count": [0, 1500]}, "only": ["chip_count"], "skip": true})
	_ok(tlk.skipped and lab2.text == "1,500", "skip jumps the count to its end ('%s')" % lab2.text)
	_ok(UI3Motion.commas(-1234567) == "-1,234,567" and UI3Motion.commas(12) == "12", "commas")
	# 6 skip every id: done at once
	for id in IDS:
		var n := _node("sk")
		var tls := UI3Motion.play_timeline(id, {"card": n, "plate": n, "banner": n}, {"host": _host, "skip": true})
		_ok(tls.done and tls.skipped, "%s: skip not done" % id)
	# 7 Reduce motion: no scale / move, no bursts
	MetaState.reduce_motion = true
	var rm := _node("rm")
	var tlr := UI3Motion.play_timeline("land-tier-up", {"diorama": rm, "banner": rm, "shake": rm}, {"host": _host})
	await _wait(tlr, 4.0)
	_ok(tlr.done and rm.scale.is_equal_approx(Vector2.ONE) and rm.position.is_equal_approx(Vector2(300, 300)) and _bursts(rm) == 0, "reduce motion: no move / burst")
	var rr := _node("rr")
	var tlr2 := UI3Motion.play_timeline("daily-claim", {"rows": [rr]}, {"host": _host})
	await _wait(tlr2, 3.0)
	_ok(rr.scale.is_equal_approx(Vector2.ONE), "reduce motion: daily rows do not pop")
	MetaState.reduce_motion = false
	# 8 Reduce flashing: last-card pop and the land flash / hit-stop / shake are dropped
	MetaState.reduce_flash = true
	var lp := _node("lp")
	var tlf := UI3Motion.play_timeline("open-10", {"last_card": lp}, {"host": _host, "only": ["last_pop"]})
	await _wait(tlf, 3.0)
	_ok(lp.scale.is_equal_approx(Vector2.ONE), "reduce flashing: no pop on the last card")
	var fl := _node("fl")
	fl.modulate.a = 0.0
	var sh := [0]
	var tlz := UI3Motion.play_timeline("land-tier-up", {"diorama_flash": fl, "shake": fl}, {"host": _host, "only": ["land_flash", "shake", "hitstop"],
		"shake": func(_p: float, _s: float) -> void: sh[0] += 1})
	await _wait(tlz, 3.0)
	_ok(fl.modulate.a == 0.0 and sh[0] == 0 and is_equal_approx(Engine.time_scale, 1.0), "reduce flashing: land flash / shake / hit-stop dropped")
	MetaState.reduce_flash = false
	# 9 a node freed mid-moment never hangs
	var gone := _node("gone")
	var tlg := UI3Motion.play_timeline("run-end-win", {"plate": gone, "title": gone}, {"host": _host})
	await get_tree().create_timer(0.2).timeout
	gone.free()
	await _wait(tlg, 4.5)
	_ok(tlg.done, "freed target: the watchdog ends the moment")
	MetaState.reduce_motion = was_m
	MetaState.reduce_flash = was_f
	if _fails.is_empty():
		print("t_ui5_moments_b3: PASS — %d checks OK" % _checks)
	else:
		for f in _fails:
			print("t_ui5_moments_b3: FAIL — %s" % f)
	get_tree().quit(0 if _fails.is_empty() else 1)
