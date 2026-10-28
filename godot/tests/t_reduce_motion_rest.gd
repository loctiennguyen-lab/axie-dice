extends Node
## Reduce motion on the remaining sites: combat stage action/death/march, UI3.Spinner, GachaReveal flip.
## With the setting ON nothing may tween position/scale/rotation; the callbacks the game waits on still fire.
## UI-05 b1 lane E: the ten combat moments (motion_ui3.json rows = motion-batch1.md tables), the hit-stop always
## giving Engine.time_scale back (also when the node / scene is freed), and the moment players under Reduce motion.
var _fails: Array[String] = []
var _checks := 0


func _ok(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_fails.append(m)


func _ready() -> void:
	print("=== t_reduce_motion_rest: start ===")
	var was := MetaState.reduce_motion
	var was_juice := CombatView.disable_juice_for_tests
	CombatView.disable_juice_for_tests = false
	await _stage_slot_case()
	await _spinner_case()
	await _gacha_case()
	_moment_table_case()
	await _hitstop_case()
	await _timeline_reduced_case()
	await _turn_banner_case()
	await _victory_case()
	await _skip_case()
	await _combat_hooks_case()
	MetaState.reduce_motion = was
	CombatView.disable_juice_for_tests = was_juice
	if _fails.is_empty():
		print("t_reduce_motion_rest: PASS — %d checks OK" % _checks)
	else:
		for f in _fails:
			print("t_reduce_motion_rest: FAIL — %s" % f)
	get_tree().quit(0 if _fails.is_empty() else 1)


func _stage_slot_case() -> void:
	var stage := (load("res://scenes/shared/CombatStage3D.tscn") as PackedScene).instantiate() as CombatStage3D
	add_child(stage)
	var slot := Node3D.new()
	stage.add_child(slot)
	slot.position = Vector3(1, 0, 2)
	var entry := {"slot": slot, "rest_pos": Vector3(1, 0, 2)}
	# Reduce ON: neither a lunge face nor a cast face leaves an action tween behind.
	MetaState.reduce_motion = true
	for face in ["dmg", "shield"]:
		stage._play_action_motion(1, entry, face, -1, "")
		_ok(entry.get("action_tween") == null, "reduced %s created an action tween" % face)
		await get_tree().create_timer(0.1).timeout
		_ok(slot.position.is_equal_approx(Vector3(1, 0, 2)) and slot.scale.is_equal_approx(Vector3.ONE), "reduced %s moved the slot" % face)
	# Reduce OFF: the lunge tween is still there.
	MetaState.reduce_motion = false
	stage._play_action_motion(1, entry, "dmg", -1, "")
	_ok(entry.get("action_tween") is Tween, "normal lunge lost its tween")
	stage._stop_action_motion(entry)
	# Death: reduced must still hide the slot, without scaling it.
	MetaState.reduce_motion = true
	slot.visible = true
	stage._start_death_fade(1, entry)
	await get_tree().create_timer(0.3).timeout
	_ok(not slot.visible, "reduced death did not hide the slot")
	_ok(slot.scale.is_equal_approx(Vector3.ONE), "reduced death scaled the slot")
	# Victory march: still resolves quickly, position untouched.
	slot.visible = true
	stage._units[7] = {"slot": slot, "rest_pos": slot.position, "character": null}
	var p0 := slot.position
	var t0 := Time.get_ticks_msec()
	await stage.play_victory_march([7], 3.0, 5.0)
	_ok(Time.get_ticks_msec() - t0 < 1500, "reduced victory march still waited its full duration")
	_ok(slot.position.is_equal_approx(p0), "reduced victory march slid the slot")
	stage.queue_free()


func _spinner_case() -> void:
	var sp := UI3.Spinner.new()
	add_child(sp)
	MetaState.reduce_motion = true
	await get_tree().process_frame
	await get_tree().process_frame
	_ok(is_zero_approx(sp.rotation), "reduced spinner rotates")
	_ok(sp.modulate.a >= 0.3 and sp.modulate.a <= 1.0, "reduced spinner has no alpha indicator")
	MetaState.reduce_motion = false
	MetaState.reduce_flash = false
	await get_tree().process_frame
	await get_tree().process_frame
	_ok(not is_zero_approx(sp.rotation), "normal spinner stopped rotating")
	sp.queue_free()


func _gacha_case() -> void:
	MetaState.reduce_motion = true
	var host := Control.new()
	add_child(host)
	var cards: Array = []
	for i in 2:
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(100, 100)
		var col := VBoxContainer.new()
		col.add_child(Label.new())
		card.add_child(col)
		host.add_child(card)
		cards.append(card)
	var r := GachaReveal.new()
	add_child(r)
	var max_dev := 0.0
	r.start(cards, 1, false, false, host)
	for _i in 240:
		await get_tree().process_frame
		for c in cards:
			max_dev = maxf(max_dev, absf((c as Control).scale.x - 1.0))
		if not r.running:
			break
	_ok(not r.running, "reduced gacha never finished")
	_ok(max_dev < 0.001, "reduced gacha flipped card scale (%f)" % max_dev)
	_ok(r.events.has("flip:0") and r.events.has("flip:1"), "reduced gacha skipped flip events")
	r.queue_free()
	host.queue_free()



# ---------------------------------------------------------------- UI-05 lane E

## The ten moments of motion-batch1.md (11 ids: the turn banner has two). Every row: [layer, delay_ms, ms, trans,
## ease, reduce]. Copied from the tables; a change there must change this list and motion_ui3.json together.
const TABLE := {
	"hit": [["enemy_flash", 0, 120, "LINEAR", "IN_OUT", "kept"], ["knockback", 0, 160, "QUAD", "OUT", "removed"],
		["number", 0, 700, "BACK", "OUT", "fade"], ["hp_fill", 60, 240, "CUBIC", "OUT", "cap"],
		["hp_trail", 360, 200, "QUAD", "IN", "cap"]],
	"crit": [["enemy_flash", 0, 120, "LINEAR", "IN_OUT", "kept"], ["knockback", 0, 200, "QUAD", "OUT", "removed"],
		["tag", 0, 760, "BACK", "OUT", "fade"], ["number", 0, 800, "BACK", "OUT", "fade"],
		["sweep", 40, 260, "CUBIC", "OUT", "removed"], ["hp", 60, 260, "CUBIC", "OUT", "cap"]],
	"big_hit": [["flash", 0, 120, "LINEAR", "IN_OUT", "kept"], ["launched", 0, 520, "QUAD", "OUT", "fade"],
		["tag", 0, 1000, "ELASTIC", "OUT", "fade"], ["number", 0, 1000, "BACK", "OUT", "fade"],
		["sweep", 60, 360, "CUBIC", "OUT", "removed"], ["plate_pop", 200, 360, "BACK", "OUT", "fade"]],
	"axie_ko": [["last_flash", 0, 120, "LINEAR", "IN_OUT", "kept"], ["tips_over", 120, 520, "BACK", "OUT", "fade"],
		["vignette", 0, 600, "SINE", "IN_OUT", "cap"], ["label", 160, 1100, "CUBIC", "OUT", "fade"],
		["hp", 0, 200, "CUBIC", "OUT", "cap"], ["stamp", 280, 260, "BACK", "OUT", "fade"],
		["card_dims", 280, 200, "LINEAR", "IN_OUT", "cap"]],
	"shield_gain": [["bubble", 0, 520, "BACK", "OUT", "fade"], ["number", 60, 700, "BACK", "OUT", "fade"],
		["segment", 120, 240, "CUBIC", "OUT", "cap"]],
	"turn_banner_player": [["band_in", 0, 240, "EXPO", "OUT", "fade"], ["band_out", 740, 240, "QUAD", "IN", "fade"],
		["label_punch", 120, 300, "BACK", "OUT", "removed"]],
	"turn_banner_enemy": [["band_in", 0, 240, "EXPO", "OUT", "fade"], ["band_out", 740, 240, "QUAD", "IN", "fade"],
		["label_punch", 120, 300, "BACK", "OUT", "removed"]],
	"intent_reveal": [["pills", 0, 160, "BACK", "OUT", "fade"], ["border_flash", 320, 360, "LINEAR", "IN_OUT", "removed"],
		["strip", 320, 200, "CUBIC", "OUT", "fade"]],
	"boss_phase": [["segment", 0, 200, "CUBIC", "OUT", "cap"], ["tick", 0, 300, "LINEAR", "IN_OUT", "cap"],
		["flash", 80, 160, "LINEAR", "IN_OUT", "cap"], ["roar", 80, 600, "ELASTIC", "OUT", "removed"],
		["band", 200, 1400, "BACK", "OUT", "fade"]],
	"victory": [["scrim", 0, 300, "SINE", "IN_OUT", "cap"], ["rays", 120, 4000, "LINEAR", "IN_OUT", "removed"],
		["band", 0, 420, "BACK", "OUT", "fade"], ["sub", 420, 240, "CUBIC", "OUT", "fade"],
		["hint", 900, 200, "LINEAR", "IN_OUT", "kept"]],
	"defeat": [["tint", 0, 500, "SINE", "IN_OUT", "cap"], ["darken", 200, 700, "SINE", "IN_OUT", "cap"],
		["sinks", 0, 600, "QUAD", "IN", "removed"], ["panel", 700, 320, "CUBIC", "OUT", "fade"]],
}
## [id, shake px, shake ms, shake delay, hit-stop ms (0 = none)]
const SHAKES := [["hit", 4, 120, 0, 0], ["crit", 6, 160, 0, 40], ["big_hit", 10, 220, 0, 60], ["axie_ko", 6, 160, 0, 0],
	["boss_phase", 12, 300, 80, 80], ["victory", 6, 160, 420, 0]]
## [id, layer, texture file, amount, life ms, speed, spread, gravity, size, delay]
const PARTICLES := [
	["hit", "sparks", "face_dmg.png", 8, 400, 420, 70, 900, 24, 0],
	["crit", "sparks", "face_dmg.png", 14, 500, 520, 90, 900, 28, 0],
	["crit", "stars", "cur_fragment.png", 6, 700, 300, 140, 500, 28, 60],
	["big_hit", "sparks", "face_dmg.png", 20, 600, 640, 120, 600, 30, 0],
	["big_hit", "stars", "cur_fragment.png", 12, 900, 380, 180, 420, 32, 80],
	["shield_gain", "glints", "face_shield.png", 6, 700, 160, 60, -120, 22, 0],
	["boss_phase", "shards", "face_shield.png", 16, 800, 520, 160, 700, 30, 80],
	["victory", "shards", "cur_shard.png", 24, 1400, 760, 120, 900, 32, 420],
	["victory", "stars", "cur_fragment.png", 18, 1600, 640, 160, 700, 28, 500],
]


func _moment_table_case() -> void:
	UI3Motion.reset_table()
	for id in TABLE.keys():
		_ok(UI3Motion.has_moment(id), "motion row '%s' missing" % id)
		_ok(UI3Motion.validate_moment(id, UI3Motion.table().get(id, {})).is_empty(),
			"motion row '%s' invalid: %s" % [id, UI3Motion.validate_moment(id, UI3Motion.table().get(id, {}))])
		for want in TABLE[id]:
			var l := UI3Motion.layer(id, String(want[0]))
			_ok(not l.is_empty(), "%s: no layer '%s'" % [id, want[0]])
			if l.is_empty():
				continue
			var got := [String(l["name"]), int(l.get("delay_ms", 0)), int(l.get("ms", 0)), String(l.get("trans", "")),
				String(l.get("ease", "")), String(l.get("reduce", ""))]
			_ok(got == want, "%s.%s is %s, table says %s" % [id, want[0], got, want])
	for sk in SHAKES:
		var sl := UI3Motion.layer(String(sk[0]), "shake")
		var sh: Dictionary = sl.get("shake", {})
		_ok(int(sh.get("px", 0)) == int(sk[1]) and int(sh.get("ms", 0)) == int(sk[2]) and int(sl.get("delay_ms", -1)) == int(sk[3]),
			"%s shake is %s @%s, table says +-%d px %d ms @%d" % [sk[0], sh, sl.get("delay_ms"), sk[1], sk[2], sk[3]])
		_ok(sl.get("reduce") == "removed", "%s shake survives Reduce motion" % sk[0])
		var scr := UI3Motion.screen_shake(String(sk[0]))
		_ok(scr.is_empty() or (int(scr.get("px", 0)) == int(sk[1]) and int(scr.get("ms", 0)) == int(sk[2])),
			"%s screen_shake() differs from its shake layer" % sk[0])
		var hs := UI3Motion.layer(String(sk[0]), "hitstop")
		_ok(int(hs.get("hitstop_ms", 0)) == int(sk[4]), "%s hit-stop is %s, table says %d" % [sk[0], hs.get("hitstop_ms"), sk[4]])
	for pt in PARTICLES:
		var l := UI3Motion.layer(String(pt[0]), String(pt[1]))
		var p: Dictionary = l.get("particles", {})
		var got := [String(p.get("texture", "")).get_file(), int(p.get("amount", 0)), int(p.get("lifetime_ms", 0)),
			int(p.get("speed", 0)), int(p.get("spread_deg", 0)), int(p.get("gravity", 0)), int(p.get("size_px", 0)),
			int(l.get("delay_ms", 0))]
		_ok(got == pt.slice(2), "%s.%s particles %s, table says %s" % [pt[0], pt[1], got, pt.slice(2)])
		_ok(l.get("reduce") == "removed", "%s.%s particles survive Reduce motion" % [pt[0], pt[1]])
	# Big numbers: text_hero 56 scaled by the tween, never a 72 size (Liam 28/10).
	_ok(UI3Theme.size_of("text_hero") == 56, "text_hero is not 56")
	var big := UI3Motion.layer("big_hit", "number")
	_ok(String(big.get("size_token", "")) == "text_hero" and _kf_max(big, "scale") > 1.9, "big hit number is not text_hero scaled ~1.95")
	var vb := UI3Motion.layer("victory", "band")
	_ok(String(vb.get("size_token", "")) == "text_hero" and is_equal_approx(float(vb.get("label_scale", 0)), 1.3), "Victory is not text_hero x 1.3")
	_ok(not JSON.stringify(UI3Motion.table()).contains("\"size\":72"), "a 72 size crept back in")


func _kf_max(l: Dictionary, prop: String) -> float:
	var m := 0.0
	for f in (l.get("kf", []) as Array):
		m = maxf(m, float((f as Dictionary).get(prop, 0.0)))
	return m


## Hit-stop always gives time_scale back: when its node is freed mid-stop, when the scene goes, after a skip.
func _hitstop_case() -> void:
	MetaState.reduce_motion = false
	MetaState.reduce_flash = false
	Engine.time_scale = 1.0
	var n := Node.new()
	add_child(n)
	UI3Motion.hitstop(n, 80.0)
	_ok(Engine.time_scale < 0.5, "hit-stop did not slow time")
	n.free()   # the node that started it is gone at once
	await _real_wait(0.25)
	_ok(is_equal_approx(Engine.time_scale, 1.0), "time_scale stuck at %f after the node was freed" % Engine.time_scale)
	# A whole moment host freed mid hit-stop (scene change): crit has a 40 ms hit-stop at 0.
	var host := Control.new()
	add_child(host)
	var run := UI3Motion.play_timeline("crit", {"fx": host}, {"host": host, "only": ["hitstop"]})
	_ok(Engine.time_scale < 0.5, "crit timeline did not hit-stop")
	host.queue_free()
	await _real_wait(0.2)
	_ok(is_equal_approx(Engine.time_scale, 1.0), "time_scale stuck at %f after the moment host was freed" % Engine.time_scale)
	_ok(run != null, "no timeline")
	# end_hitstop() restores at once (scene exit / U5SkipCatcher._exit_tree).
	var n2 := Node.new()
	add_child(n2)
	UI3Motion.hitstop(n2, 150.0)
	UI3Motion.end_hitstop()
	_ok(is_equal_approx(Engine.time_scale, 1.0), "end_hitstop did not restore time_scale")
	await _real_wait(0.2)
	_ok(is_equal_approx(Engine.time_scale, 1.0), "a stale restore timer changed time_scale")
	# A typo'd huge hit-stop is capped (never 12 s of frozen game).
	UI3Motion.hitstop(n2, 5000.0)
	await _real_wait(UI3Motion.HITSTOP_MAX_MS / 1000.0 + 0.15)
	_ok(is_equal_approx(Engine.time_scale, 1.0), "hit-stop not capped at %d ms" % int(UI3Motion.HITSTOP_MAX_MS))
	# Reduce motion: no hit-stop at all.
	MetaState.reduce_motion = true
	var before := UI3Motion.hitstop_count
	UI3Motion.hitstop(n2, 60.0)
	_ok(is_equal_approx(Engine.time_scale, 1.0) and UI3Motion.hitstop_count == before, "Reduce motion still hit-stops")
	n2.queue_free()
	Engine.time_scale = 1.0


## Real-time wait (a hit-stop slows game-time timers 20x).
func _real_wait(sec: float) -> void:
	await get_tree().create_timer(sec, true, false, true).timeout


## Reduce motion on a full big-hit timeline: no shake / hit-stop / particles / sweep, scale never animates,
## every fade <= 120 ms (a label still stays up as long as the table holds it, so it can be read).
func _timeline_reduced_case() -> void:
	MetaState.reduce_motion = true
	var r := Control.new()
	r.size = Vector2(1920, 1080)
	add_child(r)
	var tag := U5Moments.pill("x", "accent", "text_ink", "btn_s", "text_title")
	var num := U5Moments.hero_label("19", "text_hero", "text")
	var fx := Control.new()
	var flash := U5Moments.overlay("text_on_viewport")
	for c in [tag, num, fx, flash]:
		r.add_child(c)
	var shakes := [0]
	var max_scale := [0.0]
	var t0 := Time.get_ticks_msec()
	var run := UI3Motion.play_timeline("big_hit", {"tag": tag, "number": num, "fx": fx, "flash": flash, "sweep": flash},
		{"host": r, "shake": func(_px: float, _s: float) -> void: shakes[0] += 1})
	while not run.done and Time.get_ticks_msec() - t0 < 3000:
		max_scale[0] = maxf(max_scale[0], maxf(absf(tag.scale.x - 1.0), absf(num.scale.x - 1.0)))
		await get_tree().process_frame
	_ok(run.done, "reduced big hit never finished")
	_ok(Time.get_ticks_msec() - t0 < int(UI3Motion.timeline_sec("big_hit") * 1000.0) + 200, "reduced big hit took %d ms" % (Time.get_ticks_msec() - t0))
	_ok(shakes[0] == 0, "reduced big hit shook the screen")
	_ok(is_equal_approx(Engine.time_scale, 1.0) and r.find_children("*", "CPUParticles2D", true, false).is_empty(),
		"reduced big hit hit-stopped or burst particles")
	_ok(max_scale[0] < 0.001, "reduced big hit scaled the tag / number (%f)" % max_scale[0])
	_ok(UI3Motion.timeline_sec("big_hit", true) <= UI3Motion.timeline_sec("big_hit"), "reduced big hit is longer than the normal one")
	for id in TABLE.keys():
		for l in UI3Motion.layers(id):
			var ld: Dictionary = l
			if ld.has("kf") and ld.get("reduce") == "fade":
				var pl := UI3Motion._fade_plan(ld)
				_ok(float(pl["fade_in"]) <= 120.001 and float(pl["total"]) - float(pl["hold_end"]) <= 120.001,
					"%s.%s reduced fade > 120 ms: %s" % [id, ld["name"], pl])
	# Normal motion: the same timeline shakes once and pops the number past 1.5.
	MetaState.reduce_motion = false
	shakes[0] = 0
	max_scale[0] = 0.0
	num.scale = Vector2.ONE
	var run2 := UI3Motion.play_timeline("big_hit", {"number": num, "fx": fx}, {"host": r,
		"shake": func(_px: float, _s: float) -> void: shakes[0] += 1})
	t0 = Time.get_ticks_msec()
	while not run2.done and Time.get_ticks_msec() - t0 < 3000:
		max_scale[0] = maxf(max_scale[0], num.scale.x)
		await get_tree().process_frame
	_ok(shakes[0] == 1, "big hit shook %d times (want 1)" % shakes[0])
	_ok(max_scale[0] > 1.5, "big hit number never popped past 1.5 (%f)" % max_scale[0])
	await _real_wait(0.1)
	_ok(is_equal_approx(Engine.time_scale, 1.0), "big hit left time_scale at %f" % Engine.time_scale)
	r.queue_free()


## Turn banner: slides in from -1920 normally; with Reduce motion it only fades (x never moves) and still ends.
func _turn_banner_case() -> void:
	var r := Control.new()
	r.size = Vector2(1920, 1080)
	add_child(r)
	MetaState.reduce_motion = true
	var done := [0]
	var b := U5TurnBanner.show_on(r, true, func() -> void: done[0] += 1)
	var min_x := 0.0
	var max_x := 0.0
	var t0 := Time.get_ticks_msec()
	while is_instance_valid(b) and Time.get_ticks_msec() - t0 < 3000:
		min_x = minf(min_x, b.position.x)
		max_x = maxf(max_x, b.position.x)
		await get_tree().process_frame
	_ok(not is_instance_valid(b), "reduced turn banner never went away")
	_ok(is_zero_approx(min_x) and is_zero_approx(max_x), "reduced turn banner slid (%f..%f)" % [min_x, max_x])
	_ok(done[0] == 1, "reduced turn banner on_done ran %d times" % done[0])
	MetaState.reduce_motion = false
	var b2 := U5TurnBanner.show_on(r, false)
	_ok(b2.position.x < -1000.0, "turn banner does not start off screen (x %f)" % b2.position.x)
	_ok(b2.label.text == "Enemy turn", "enemy banner text '%s'" % b2.label.text)
	b2.finish()
	await get_tree().process_frame
	_ok(not is_instance_valid(b2) or b2.is_queued_for_deletion(), "skipped turn banner still up")
	r.queue_free()


## Victory band with Reduce motion: the band never drops (y stays), no rays, no confetti; a press ends it.
func _victory_case() -> void:
	var r := Control.new()
	r.size = Vector2(1920, 1080)
	add_child(r)
	MetaState.reduce_motion = true
	var vb := U5VictoryBand.show_on(r, "Fight 4 of 18 cleared")
	var band := vb.get_node("Band") as Control
	var y0 := band.position.y
	var rays := vb.get_node("Rays") as Control
	var moved := 0.0
	var t0 := Time.get_ticks_msec()
	while vb.playing() and Time.get_ticks_msec() - t0 < 3000:
		moved = maxf(moved, absf(band.position.y - y0))
		await get_tree().process_frame
	_ok(not vb.playing(), "reduced victory never settled")
	_ok(moved < 0.001, "reduced Victory band dropped (%f px)" % moved)
	_ok(rays.modulate.a < 0.01, "reduced victory shows the rays")
	_ok(vb.find_children("*", "CPUParticles2D", true, false).is_empty(), "reduced victory threw confetti")
	_ok((vb.get_node("ContinueHint") as Control).modulate.a > 0.99, "continue hint not shown")
	_ok(is_equal_approx((band.get_node("Title") as Control).scale.x, 1.3), "Victory title not held at 1.3")
	vb.queue_free()
	# Normal: first press jumps to the end state and is eaten.
	MetaState.reduce_motion = false
	var vb2 := U5VictoryBand.show_on(r, "")
	await get_tree().process_frame
	_ok(vb2.playing(), "victory not playing")
	var ev := InputEventKey.new()
	ev.keycode = KEY_SPACE
	ev.pressed = true
	get_viewport().push_input(ev)
	await get_tree().process_frame
	_ok(not vb2.playing(), "Space did not jump the victory to its end state")
	_ok(is_zero_approx((vb2.get_node("Band") as Control).offset_top - 330.0) or (vb2.get_node("Band") as Control).position.y > 300.0,
		"skipped Victory band not in place")
	vb2.queue_free()
	r.queue_free()


## A click / Space skips the running skippable moments (Space is eaten, a click is not).
func _skip_case() -> void:
	MetaState.reduce_motion = false
	var c := U5SkipCatcher.new()
	add_child(c)
	var r := Control.new()
	add_child(r)
	var lbl := U5Moments.hero_label("Knocked out", "text_banner", "danger_text")
	r.add_child(lbl)
	var run := UI3Motion.play_timeline("axie_ko", {"label": lbl}, {"host": r, "only": ["label"]})
	c.add(run)
	_ok(c.running(), "catcher does not see the moment")
	var ev := InputEventKey.new()
	ev.keycode = KEY_SPACE
	ev.pressed = true
	get_viewport().push_input(ev)
	await get_tree().process_frame
	_ok(run.done and not c.running(), "Space did not skip the moment")
	_ok(lbl.modulate.a < 0.01, "skipped label not at its end state (alpha %f)" % lbl.modulate.a)
	c.queue_free()
	r.queue_free()



## The real CombatView hooks with juice on: a crit, a Your-turn start, a knockout and a boss phase put their moment
## nodes on the Ui5Moments layer; freeing the whole scene in the middle of a big-hit hit-stop gives time_scale back.
func _combat_hooks_case() -> void:
	MetaState.reduce_motion = false
	MetaState.reduce_flash = false
	var guard := SaveGuard.new()
	guard.capture()
	RunState.start_new_run(424242, ["plant1", "beast1", "aqua1", "reptile1", "bug1"], "short", 6, false)
	RunState.enter_node("r4_c0", "battle")
	var scene: CombatView = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(scene)
	for _i in 20:
		await get_tree().process_frame
	var e: Unit = scene._combat.enemies[0]
	var a: Unit = scene._combat.party[1]
	scene._on_hit_landed(a.uid, e.uid, 1, true)
	scene._on_float_text(e.uid, "CRIT -1", "dmg", 2)
	await _real_wait(CombatView.impact_delay() + 0.1)
	var root := scene.get_node_or_null("Ui5Moments/Root") as Control
	_ok(root != null, "no Ui5Moments layer after a hit")
	if root == null:
		scene.queue_free()
		guard.restore()
		return
	_ok(root.find_child("CritTag", false, false) != null, "crit did not show the CRIT tag")
	_ok(root.find_child("HitNumber", false, false) != null, "crit did not pop the number")
	_ok(U5Moments.skippable_running(scene), "crit is not skippable")
	scene._on_turn_phase_changed(0, 2)   # ROLL -> EXECUTE: a turn starts
	await get_tree().process_frame
	_ok(root.find_child("TurnBanner", false, false) is U5TurnBanner, "turn start did not show the Your turn band")
	var hp0 := a.hp
	a.hp = 0
	scene._on_unit_died(a.uid)
	await get_tree().process_frame
	_ok(root.find_child("KnockedOut", false, false) != null, "knockout did not say Knocked out")
	_ok(root.find_child("KoStamp", false, false) != null, "knockout did not stamp the DieCard")
	a.hp = hp0
	await get_tree().process_frame
	await get_tree().process_frame
	_ok(root.find_child("KoStamp", false, false) == null, "OUT stamp stayed on a revived Axie")
	scene._on_boss_phase_changed(e.uid)
	await get_tree().process_frame
	_ok(root.find_child("PhaseBand", false, false) != null, "boss phase did not show the Phase band")
	await _real_wait(0.3)
	U5Moments.on_hit(scene, e.uid, "big_hit")
	_ok(Engine.time_scale < 0.5, "big hit did not hit-stop")
	scene.queue_free()
	await _real_wait(0.3)
	_ok(is_equal_approx(Engine.time_scale, 1.0), "time_scale %f after the combat scene was freed mid hit-stop" % Engine.time_scale)
	guard.restore()
