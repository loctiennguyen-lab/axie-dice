extends Node
## UI-05 b1: boss intro band (boss-intro--default). One band only: the pre-combat camera reveal (BossIntro) shows no
## band, just "Click or [Space] to skip"; the band shows at the START of the boss fight over the arena
## (U5BossBand on the Ui5Moments layer) with the real boss HUD facts (HP, SHELL, ENRAGE) and the rhythm row,
## pinned 24 px from the top, then hands over to the Your turn band. Click / Space / the End turn key skip it and
## never reach the fight. Not on a resumed fight, not with disable_juice_for_tests. Reduce motion: no unfold.
## Text stays >= 14 real px at 1280.
const BandUi := preload("res://scenes/run_map/ui5/BossIntroBand.gd")

var _guard := SaveGuard.new()
var _checks := 0
var _fails: Array[String] = []
var _space_seen := 0   # Space presses that got past the band
var _click_seen := 0


func _input(event: InputEvent) -> void:
	if event is InputEventKey and (event as InputEventKey).pressed and (event as InputEventKey).keycode == KEY_SPACE:
		_space_seen += 1
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_click_seen += 1


func _t(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame


func _texts(n: Node, out: Array) -> Array:
	if n == null:
		return out
	if n is Label and (n as Label).is_visible_in_tree():
		out.append((n as Label).text)
	for c in n.get_children():
		_texts(c, out)
	return out


func _min_text_ok(root: Node, scale: float, tag: String) -> void:
	for l in root.find_children("*", "Label", true, false):
		var lab := l as Label
		if lab.is_visible_in_tree():
			_t(float(lab.get_theme_font_size("font_size")) * scale >= 14.0 - 0.01,
				"%s: '%s' is %d px logical (>= 14 real)" % [tag, lab.text.left(20), lab.get_theme_font_size("font_size")])


func _roster() -> Array:
	var out: Array = []
	var keys := ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	for i in keys.size():
		out.append({"persistent_id": i + 1, "hero_key": keys[i], "tier": 1,
			"max_hp": ContentDB.heroes[keys[i]]["max_hp"], "muts": [], "growth": {}, "bonus_hp": 0})
	return out


func _fight(boss_key: String, asc := 6) -> CombatView:
	RunState.pending_combat = {"node_id": "band_boss", "kind": "boss", "pw": 9, "ascension": asc,
		"roster_snapshot": _roster(), "relic_ids": [], "combat_seed": 24680, "boss_key": boss_key}
	var v: CombatView = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	add_child(v)
	return v


func _moments(v: Node) -> Control:
	return v.get_node_or_null("Ui5Moments/Root") as Control


func _band_of(v: Node) -> U5BossBand:
	var r := _moments(v)
	if r == null:
		return null
	for c in r.get_children():
		if c is U5BossBand and not c.is_queued_for_deletion():
			return c
	return null


## Frames until the band's timeline runs (after the warm-up frames), then `extra` seconds.
func _until_playing(b: U5BossBand, extra: float) -> void:
	var n := 0
	while is_instance_valid(b) and b.run == null and n < 60:
		await get_tree().process_frame
		n += 1
	if extra > 0.0:
		await get_tree().create_timer(extra).timeout


func _bands_in_tree() -> int:
	return get_tree().root.find_children("BossIntroBand", "", true, false).filter(
		func(n: Node) -> bool: return not n.is_queued_for_deletion() and (n as CanvasItem).is_visible_in_tree()).size()


func _space() -> InputEventKey:
	var ev := InputEventKey.new()
	ev.keycode = KEY_SPACE
	ev.physical_keycode = KEY_SPACE
	ev.pressed = true
	return ev


func _ready() -> void:
	_guard.capture()
	await get_tree().process_frame
	var was_juice := CombatView.disable_juice_for_tests
	var was_rm := MetaState.reduce_motion
	MetaState.reduce_flash = true   # the reveal cuts in
	MetaState.reduce_motion = false
	MetaState.runs_with_battle = 99
	KeyBindings.reset_registration()

	# 1. The pre-combat camera reveal carries no band (it hands off to the fight), only the skip hint.
	var a := BossIntro.new()
	_t(a.setup("frost_lord"), "setup(frost_lord)")
	add_child(a)
	await _frames(4)
	_t(a.find_child("BossIntroBand", true, false) == null, "the camera reveal shows no band (one band only, in the fight)")
	_t(a.find_child("BossName", true, false) == null and a.find_child("Facts", true, false) == null, "no name / facts on the reveal")
	var hint: Control = a.skip_hint
	_t(hint != null and _texts(hint, []) == ["Click or", "Space", "to skip"], "reveal skip hint reads 'Click or Space to skip' (%s)" % [_texts(hint, [])])
	var hr := hint.get_global_rect()
	_t(absf(a.size.x - hr.end.x - UI3Theme.space("screen")) < 1.0 and absf(a.size.y - hr.end.y - UI3Theme.space("screen")) < 1.0,
		"reveal skip hint 24 px from the bottom-right corner")
	_t(a.find_children("*", "Button", true, false).is_empty(), "no buttons on the reveal (click anywhere / Space)")
	a.queue_free()
	await _frames(2)

	# 2. The band component (lane D) with HUD facts and a muted tail.
	var band2 := BandUi.new()
	band2.setup({"name": "FROST LORD", "facts": [{"text": "HP 167", "node": "Hp"},
		{"text": "SHELL 42", "color": "shell", "node": "Shell"},
		{"text": "ENRAGE IN 9", "color": "attrition", "sub": "then +20%/turn", "node": "Enrage"}],
		"rhythm": ["Prep", "Strike", "Hollow"], "rhythm_now": 1})
	add_child(band2)
	await _frames(2)
	_t(_texts(band2.find_child("Enrage", true, false), []) == ["ENRAGE IN 9", "then +20%/turn"], "fact chip with a muted tail")
	_t(((band2.find_child("Shell", true, false) as Node).find_child("Text", true, false) as Label).get_theme_color("font_color")
		.is_equal_approx(UI3Theme.color("shell")), "fact colour from a token")
	_t(bool(band2.rhythm_row.get_child(1).get_meta("now", false)), "rhythm_now marks the step")
	band2.queue_free()

	# 3. Tests run with juice off: no band (test pacing).
	CombatView.disable_juice_for_tests = true
	var q := _fight("frost_lord")
	await _frames(6)
	_t(_band_of(q) == null, "disable_juice_for_tests: no boss band")
	q.queue_free()
	await _frames(3)

	# 4. The real fight start, juice on: the band over the arena with the boss HUD facts.
	CombatView.disable_juice_for_tests = false
	var v := _fight("frost_lord")
	await _frames(2)
	var b := _band_of(v)
	_t(b != null, "a new boss fight opens on the boss band")
	if b == null:
		await _end(v, was_juice, was_rm)
		return
	_t(not v._boss_band_due, "the band is shown once (flag cleared)")
	var root := _moments(v)
	_t(root.find_child("TurnBanner", false, false) == null, "no Your turn band while the boss band shows")
	await _until_playing(b, 0.45)
	var boss: Unit = null
	for e in v._combat.enemies:
		if e.is_boss:
			boss = e
	var band := b.band
	_t(band.name == "BossIntroBand" and is_equal_approx(band.get_global_rect().position.y, float(UI3Theme.space("screen"))),
		"band pinned 24 px from the top (%s)" % band.get_global_rect().position.y)
	_t(absf(band.size.x - root.size.x) < 0.5, "band spans the full width")
	_t(_bands_in_tree() == 1, "exactly one BossIntroBand on screen (%d)" % _bands_in_tree())
	var nm := band.find_child("BossName", true, false) as Label
	_t(nm != null and nm.text == String(BossIntroData.info("frost_lord")["name"]), "band name is the boss name (%s)" % (nm.text if nm else "?"))
	_t(_texts(band.find_child("BossTag", true, false), []).has("BOSS"), "BOSS tag")
	var facts := band.find_child("Facts", true, false)
	var hs: Dictionary = v._combat.hud_state()
	_t(_texts(facts.find_child("Hp", true, false), []) == ["HP %d" % boss.max_hp], "HP fact is the boss max HP (%s)" % [_texts(facts, [])])
	var shell_max := int(boss.custom_state.get("shell_max", 0))
	_t((facts.find_child("Shell", true, false) != null) == (shell_max > 0), "SHELL fact only when the boss has a Shell (%d)" % shell_max)
	if shell_max > 0:
		_t(_texts(facts.find_child("Shell", true, false), []) == ["SHELL %d" % shell_max], "SHELL fact value")
	var clock: Dictionary = hs.get("clock", {})
	_t(bool(clock.get("active", false)), "A6 boss fight has the boss clock (test setup)")
	if bool(clock.get("active", false)):
		var tab := HudKit.clock_tab(clock, int(hs["turn"]), 0)
		_t(_texts(facts.find_child("Enrage", true, false), []) == [String(tab["text"]), String(tab["right"])],
			"ENRAGE fact = the HUD clock words (%s)" % [_texts(facts.find_child("Enrage", true, false), [])])
	_t(facts.find_child("PhaseChip", true, false) == null, "one-phase boss: no phase chip")
	var rhythm := band.find_child("Rhythm", true, false) as Control
	_t(rhythm.visible and _texts(rhythm, []) == ["Prep", "Strike", "Hollow"] and bool(rhythm.get_child(0).get_meta("now", false)),
		"rhythm row, Prep current on turn 1")
	_t(nm.get_index() == 1 and facts.get_index() == 2 and rhythm.get_index() == 3, "band order tag / name / facts / rhythm")
	_t(_texts(b.hint, []) == ["Click or", "Space", "to skip"], "fight skip hint reads 'Click or Space to skip' (%s)" % [_texts(b.hint, [])])
	var r2 := b.hint.get_global_rect()
	_t(absf(root.size.x - r2.end.x - UI3Theme.space("screen")) < 1.0 and absf(root.size.y - r2.end.y - UI3Theme.space("screen")) < 1.0,
		"fight skip hint 24 px from the bottom-right corner")
	_t(band.modulate.a > 0.9 and is_equal_approx(band.scale.y, 1.0), "band unfolded and held (a %.2f, scale %.2f)" % [band.modulate.a, band.scale.y])
	# Space skips the band only: the turn is not ended, then the Your turn band follows.
	var seen0 := _space_seen
	var turn0: int = v._combat.turn
	get_viewport().push_input(_space())
	await _frames(2)
	_t(_band_of(v) == null, "Space skipped the boss band")
	_t(_space_seen == seen0 and v._combat.turn == turn0 and v._combat.phase == CombatEngine.CombatPhase.EXECUTE,
		"the skip Space did not reach the fight (turn %d, phase %d)" % [v._combat.turn, v._combat.phase])
	_t(root.find_child("TurnBanner", false, false) is U5TurnBanner, "the Your turn band follows the boss band")
	_t(_bands_in_tree() == 0, "no band left after the skip")
	v.queue_free()
	await _frames(3)

	# 5. A click skips it too and does not pick a die; a band left alone ends by itself.
	var w := _fight("frost_lord")
	await _frames(2)
	await _until_playing(_band_of(w), 0.3)
	var c0 := _click_seen
	var mb := InputEventMouseButton.new()
	mb.button_index = MOUSE_BUTTON_LEFT
	mb.pressed = true
	mb.position = Vector2(960, 980)
	get_viewport().push_input(mb)
	await _frames(2)
	_t(_band_of(w) == null and _click_seen == c0 and w._selected_die_uid == -1, "a click skips the band and picks nothing")
	w.queue_free()
	await _frames(3)
	var x := _fight("frost_lord")
	await _frames(2)
	await _until_playing(_band_of(x), 0.0)
	var t0 := Time.get_ticks_msec()
	while _band_of(x) != null and Time.get_ticks_msec() - t0 < 4000:
		await get_tree().process_frame
	var took := Time.get_ticks_msec() - t0
	_t(_band_of(x) == null and took > 1500, "the band holds about 2 s, then ends by itself (%d ms)" % took)
	_t(_moments(x).find_child("TurnBanner", false, false) is U5TurnBanner, "then the Your turn band")
	x.queue_free()
	await _frames(3)

	# 6. Reduce motion: no unfold (scale stays 1), only alpha; it still ends.
	MetaState.reduce_motion = true
	var y := _fight("frost_lord")
	await _frames(2)
	var by := _band_of(y)
	_t(by != null, "Reduce motion: the band still shows")
	var min_sy := 1.0
	var t1 := Time.get_ticks_msec()
	while is_instance_valid(by) and _band_of(y) != null and Time.get_ticks_msec() - t1 < 4000:
		min_sy = minf(min_sy, by.band.scale.y)
		await get_tree().process_frame
	_t(is_equal_approx(min_sy, 1.0), "Reduce motion: the band never scaled (min scale.y %.2f)" % min_sy)
	_t(_band_of(y) == null, "Reduce motion: the band still ends")
	MetaState.reduce_motion = false
	y.queue_free()
	await _frames(3)

	# 7. A resumed boss fight has no band.
	var z := _fight("frost_lord")
	await _frames(2)
	var snap: Dictionary = z._combat.to_data()
	z.queue_free()
	await _frames(2)
	RunState.pending_combat = {}
	RunState.resume_combat = snap
	var zr: CombatView = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	add_child(zr)
	await _frames(6)
	_t(not zr._boss_band_due and _band_of(zr) == null, "a resumed boss fight has no band")
	zr.queue_free()
	await _frames(3)

	# 8. Two-phase boss: "2 phases" chip, no rhythm row. 1280: the text floor holds.
	UI3Theme.set_scale_override(2.0 / 3.0)
	var g := _fight("agony")
	await _frames(2)
	var bg := _band_of(g)
	_t(bg != null, "agony fight opens on the band")
	if bg != null:
		await _until_playing(bg, 0.45)
		_t(bg.band.find_child("PhaseChip", true, false) != null, "agony: phase chip")
		_t(not (bg.band.find_child("Rhythm", true, false) as Control).visible, "agony: no rhythm row (it runs its own phases)")
		_min_text_ok(bg.band, 2.0 / 3.0, "1280 band")
		_min_text_ok(bg.hint, 2.0 / 3.0, "1280 hint")
		_t(bg.band.get_global_rect().end.x <= _moments(g).size.x + 0.5, "1280: band inside the canvas")
	UI3Theme.set_scale_override(-1.0)
	await _end(g, was_juice, was_rm)


func _end(v: Node, was_juice: bool, was_rm: bool) -> void:
	if is_instance_valid(v):
		v.queue_free()
	await _frames(3)
	CombatView.disable_juice_for_tests = was_juice
	MetaState.reduce_motion = was_rm
	MetaState.reduce_flash = false
	RunState.pending_combat = {}
	_guard.restore()
	if _fails.is_empty():
		print("t_boss_intro_band: PASS - %d checks OK" % _checks)
		get_tree().quit(0)
	else:
		for f in _fails:
			print("t_boss_intro_band: FAIL - " + f)
		get_tree().quit(1)
