extends Node
## UI-05 b1 lane D: boss intro band (boss-intro--default). The band is pinned 24 px from the top over the full width,
## BOSS tag + name at text_hero + facts + the rhythm (Prep current) for rhythm bosses; the only hint is
## "Click or [Space] to skip" bottom right (no other key shown, no Fight button); the overlay joins ui3_modal;
## facts and names come from game data; text stays >= 14 real px at 1280.
const BandUi := preload("res://scenes/run_map/ui5/BossIntroBand.gd")

var _guard := SaveGuard.new()
var _checks := 0
var _fails: Array[String] = []


func _t(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame


func _texts(n: Node, out: Array) -> Array:
	if n is Label and (n as Label).is_visible_in_tree():
		out.append((n as Label).text)
	for c in n.get_children():
		_texts(c, out)
	return out


func _intro(key: String) -> BossIntro:
	var i := BossIntro.new()
	_t(i.setup(key), "setup(%s)" % key)
	add_child(i)
	await _frames(4)
	return i


func _min_text_ok(root: Node, scale: float, tag: String) -> void:
	for l in root.find_children("*", "Label", true, false):
		var lab := l as Label
		if lab.is_visible_in_tree():
			_t(float(lab.get_theme_font_size("font_size")) * scale >= 14.0 - 0.01,
				"%s: '%s' is %d px logical (>= 14 real)" % [tag, lab.text.left(20), lab.get_theme_font_size("font_size")])


func _ready() -> void:
	_guard.capture()
	await get_tree().process_frame
	MetaState.reduce_flash = true   # cut in: the band is at full size at once
	var data := BossIntroData.info("frost_lord")

	var a := await _intro("frost_lord")
	var band: Control = a.plate
	_t(band != null and band.name == "BossIntroBand", "band exists")
	_t(is_equal_approx(band.get_global_rect().position.y, float(UI3Theme.space("screen"))), "band pinned 24 px from the top")
	_t(is_equal_approx(band.size.x, a.size.x), "band spans the full width")
	var nm := band.find_child("BossName", true, false) as Label
	_t(nm != null and nm.text == String(data["name"]), "name from ContentDB (%s)" % (nm.text if nm != null else "?"))
	_t(nm.get_theme_font_size("font_size") == UI3Theme.size_of("text_hero"), "name at text_hero")
	_t(band.find_child("BossTag", true, false) != null and _texts(band.find_child("BossTag", true, false), []).has("BOSS"), "BOSS tag")
	var facts := band.find_child("Facts", true, false)
	_t(facts != null and facts.find_child("ClassChip", true, false) != null and facts.find_child("Threat", true, false) != null,
		"facts: class + threat")
	_t(_texts(facts, []).has(String(data["threat"])) and _texts(facts, []).has(String(data["cls"]))
		and _texts(facts, []).has(String(data["title"])), "facts text from BossIntroData (title, class, threat)")
	_t(facts.find_child("PhaseChip", true, false) == null, "one-phase boss: no phase chip")
	var rhythm := band.find_child("Rhythm", true, false) as Control
	_t(rhythm != null and rhythm.visible and rhythm.get_child_count() == 3, "rhythm boss: 3 steps")
	_t(_texts(rhythm, []) == ["Prep", "Strike", "Hollow"] and bool(rhythm.get_child(0).get_meta("now", false))
		and not bool(rhythm.get_child(1).get_meta("now", false)), "Prep is the current step (turn 1)")
	# Order (README): tag, name, facts, rhythm.
	var col := band.get_child(0)
	_t(nm.get_index() == 1 and facts.get_index() == 2 and rhythm.get_index() == 3, "band order tag / name / facts / rhythm")

	var hint: Control = a.skip_hint
	_t(hint != null and hint.name == "SkipHint", "skip hint")
	_t(_texts(hint, []) == ["Click or", "Space", "to skip"], "skip hint reads 'Click or Space to skip' (%s)" % [_texts(hint, [])])
	var r := hint.get_global_rect()
	_t(absf(a.size.x - r.end.x - UI3Theme.space("screen")) < 1.0 and absf(a.size.y - r.end.y - UI3Theme.space("screen")) < 1.0,
		"skip hint 24 px from the bottom-right corner")
	_t(a.find_children("*", "Button", true, false).is_empty(), "no buttons on the intro (click anywhere / Space)")
	_t(a.is_in_group("ui3_modal") and UI3Tooltip.modal_open(get_tree()), "intro counts as a modal")
	_t(band.get_global_rect().end.y < a.size.y * 0.5, "band stays in the top half (%.0f)" % band.get_global_rect().end.y)
	a.queue_free()
	await _frames(2)

	# Two-phase boss with no rhythm (Agony): phase chip, no rhythm row.
	var b := await _intro("agony")
	_t(b.plate.find_child("PhaseChip", true, false) != null, "agony: phase chip")
	_t(not (b.plate.find_child("Rhythm", true, false) as Control).visible, "agony: no rhythm row (it runs its own phases)")
	b.queue_free()
	await _frames(2)

	# The band component takes HUD facts too (HP / SHELL / ENRAGE with a muted tail) when a caller has them.
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

	# 1280: the text floor holds on the band and the hint.
	UI3Theme.set_scale_override(2.0 / 3.0)
	var c := await _intro("mecha")
	_min_text_ok(c.plate, 2.0 / 3.0, "1280 band")
	_min_text_ok(c.skip_hint, 2.0 / 3.0, "1280 hint")
	_t(c.plate.get_global_rect().end.x <= c.size.x + 0.5, "1280: band inside the canvas")
	c.queue_free()
	UI3Theme.set_scale_override(-1.0)
	MetaState.reduce_flash = false
	await _frames(2)

	_guard.restore()
	if _fails.is_empty():
		print("t_boss_intro_band: PASS - %d checks OK" % _checks)
		get_tree().quit(0)
	else:
		for f in _fails:
			print("t_boss_intro_band: FAIL - " + f)
		get_tree().quit(1)
