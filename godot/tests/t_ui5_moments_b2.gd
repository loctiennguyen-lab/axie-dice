extends Node
## UI-05 b23 lane M2: the six run moments (core-reveal, core-taken, reward-taken, treasure-open, level-up,
## anchor-awaken) play from motion_ui3.json, end in their final state, skip at once, drop motion / flashes under
## the accessibility settings and never hang when a node is freed mid-way.
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


func _wait(tl: UI3Motion.Timeline, sec: float) -> void:
	var t := 0.0
	while tl.running() and t < sec:
		await get_tree().process_frame
		t += get_process_delta_time()


func _burst_count(n: Node) -> int:
	var k := 0
	for c in n.get_children():
		if c is CPUParticles2D:
			k += 1
	return k


func _ready() -> void:
	print("=== t_ui5_moments_b2: start ===")
	var was_m := MetaState.reduce_motion
	var was_f := MetaState.reduce_flash
	MetaState.reduce_motion = false
	MetaState.reduce_flash = false
	_host = Control.new()
	add_child(_host)
	await get_tree().process_frame
	# 1 core-taken plays to its end state
	var card := _node("card")
	var other := _node("other")
	var tl := UI3Motion.play_timeline("core-taken", {"card": card, "others": [other]}, {"host": _host})
	_ok(tl.running(), "core-taken running")
	await _wait(tl, 3.0)
	_ok(tl.done and not tl.skipped, "core-taken ends by itself (done %s skipped %s)" % [tl.done, tl.skipped])
	_ok(card.scale.x < 0.2 and is_equal_approx(card.rotation_degrees, -12.0), "core-taken: card ends small and rotated (%s)" % card.scale)
	_ok(other.modulate.a < 0.01 and is_equal_approx(other.position.y, 360.0), "core-taken: the other card dropped away")
	# fly: with fly_to the card ends on the target
	var fc := _node("fc")
	var tlf := UI3Motion.play_timeline("core-taken", {"card": fc}, {"host": _host, "fly_to": Vector2(900, 700)})
	await _wait(tlf, 3.0)
	_ok(fc.get_global_rect().get_center().distance_to(Vector2(900, 700)) < 40.0, "core-taken: card lands on the slot (%s)" % fc.get_global_rect().get_center())
	# 2 skip = end state at once
	var rc := _node("rc")
	var tls := UI3Motion.play_timeline("reward-taken", {"card": rc}, {"host": _host, "skip": true})
	_ok(tls.done and tls.skipped and rc.scale.x < 0.2, "reward-taken: skip jumps to the end")
	# 3 treasure-open: cards rise, title ends in place
	var cs: Array = [_node("c1"), _node("c2"), _node("c3")]
	var tt := _node("title")
	var tlt := UI3Motion.play_timeline("treasure-open", {"card1": cs[0], "card2": cs[1], "card3": cs[2], "choose": tt},
		{"host": _host, "only": ["card_1", "card_2", "card_3", "choose"]})
	await _wait(tlt, 3.0)
	_ok(tlt.done and cs[2].modulate.a > 0.99 and is_equal_approx(cs[2].position.y, 300.0) and tt.modulate.a > 0.99, "treasure-open: three cards + title end in place")
	# 4 level-up: tag and hop end in place
	var ax := _node("axie")
	var tag := _node("tag")
	var tll := UI3Motion.play_timeline("level-up", {"axie": ax, "tag": tag}, {"host": _host})
	await _wait(tll, 3.0)
	_ok(tll.done and is_equal_approx(ax.position.y, 300.0) and tag.modulate.a > 0.99 and is_equal_approx(tag.position.y, 256.0), "level-up: Axie back at rest, tag risen")
	# 5 core-reveal: tier picks the sparks (Crystal only: last-flip shake)
	var shook := [0]
	var n1 := _node("n1")
	var k1 := _node("k1")
	var tlr := UI3Motion.play_timeline("core-reveal", {"name1": n1, "card1": k1}, {"host": _host, "tier": 2, "delay_ms": -840.0 + 100.0,
		"only": ["name_1", "sparks_1", "shake_last"], "shake": func(_px: float, _s: float) -> void: shook[0] += 1})
	await _wait(tlr, 3.0)
	_ok(shook[0] == 1, "core-reveal Crystal shakes once (%d)" % shook[0])
	var k0 := _node("k0")
	var tl0 := UI3Motion.play_timeline("core-reveal", {"card1": k0}, {"host": _host, "tier": 0, "delay_ms": -840.0, "only": ["sparks_1", "shake_last"],
		"shake": func(_px: float, _s: float) -> void: shook[0] += 1})
	await _wait(tl0, 3.0)
	_ok(shook[0] == 1, "core-reveal Moss does not shake")
	# 6 anchor-awaken table plays on plain nodes
	var tile := _node("tile")
	var tla := UI3Motion.play_timeline("anchor-awaken", {"tile": tile, "scrim": _node("scrim")}, {"host": _host})
	await _wait(tla, 4.0)
	_ok(tla.done and tile.scale.x == 1.0 and tile.modulate.a > 0.99, "anchor-awaken: tile slams in and rests")
	# 7 Reduce motion: no scale / position change, no bursts
	MetaState.reduce_motion = true
	var rm := _node("rm")
	var tlm := UI3Motion.play_timeline("core-taken", {"card": rm}, {"host": _host, "fly_to": Vector2(900, 700)})
	await _wait(tlm, 3.0)
	_ok(tlm.done and is_equal_approx(rm.scale.x, 1.0) and rm.position.is_equal_approx(Vector2(300, 300)) and _burst_count(rm) == 0, "reduce motion: card neither scales nor flies, no sparks")
	var rt := _node("rt")
	var tlr2 := UI3Motion.play_timeline("treasure-open", {"card1": rt, "vault": _node("vault")}, {"host": _host, "only": ["card_1", "shards", "stars"]})
	await _wait(tlr2, 3.0)
	_ok(is_equal_approx(rt.position.y, 300.0) and rt.scale.is_equal_approx(Vector2.ONE) and rt.modulate.a > 0.99, "reduce motion: reward card only fades in")
	MetaState.reduce_motion = false
	# 8 Reduce flashing: the flash / ray layers draw nothing
	MetaState.reduce_flash = true
	var fl := _node("fl")
	fl.modulate.a = 0.0
	var tlfl := UI3Motion.play_timeline("treasure-open", {"flash": fl, "rays": _node("rays")}, {"host": _host})
	await _wait(tlfl, 3.0)
	_ok(tlfl.done and fl.modulate.a == 0.0, "reduce flashing: the screen flash never shows")
	var shk := [0]
	var rk := _node("rk")
	var tlk := UI3Motion.play_timeline("core-reveal", {"card1": rk}, {"host": _host, "tier": 2, "delay_ms": -840.0 + 100.0,
		"only": ["sparks_1", "sparks_2", "sparks_3", "shake_last"], "shake": func(_px: float, _s: float) -> void: shk[0] += 1})
	await _wait(tlk, 3.0)
	_ok(shk[0] == 0 and _burst_count(rk) == 0, "reduce flashing: core-reveal has no Crystal shake and no sparks (%d, %d)" % [shk[0], _burst_count(rk)])
	var tt2 := _node("tt2")
	var tlt2 := UI3Motion.play_timeline("treasure-open", {"card1": tt2}, {"host": _host, "only": ["shake"], "shake": func(_px: float, _s: float) -> void: shk[0] += 1})
	await _wait(tlt2, 3.0)
	_ok(shk[0] == 0, "reduce flashing: treasure-open does not shake")
	MetaState.reduce_flash = false
	# 9 a node freed mid-moment never hangs the timeline
	var gone := _node("gone")
	var tlg := UI3Motion.play_timeline("core-taken", {"card": gone}, {"host": _host})
	await get_tree().create_timer(0.2).timeout
	gone.free()
	await _wait(tlg, 3.5)
	_ok(tlg.done, "freed target: the watchdog ends the moment")
	MetaState.reduce_motion = was_m
	MetaState.reduce_flash = was_f
	if _fails.is_empty():
		print("t_ui5_moments_b2: PASS — %d checks OK" % _checks)
	else:
		for f in _fails:
			print("t_ui5_moments_b2: FAIL — %s" % f)
	get_tree().quit(0 if _fails.is_empty() else 1)
