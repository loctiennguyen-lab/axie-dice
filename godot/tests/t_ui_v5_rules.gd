extends Node
## v5 engine content must be VISIBLE: Pack Alpha LEADER badge + notes, Shell bar, High Stakes Gamble label, 11 new Cores.

var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


static func roster() -> Array:
	var keys := ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	var out: Array = []
	for i in keys.size():
		out.append({"persistent_id": i + 1, "hero_key": keys[i], "tier": 1,
			"max_hp": ContentDB.heroes[keys[i]]["max_hp"], "muts": [], "growth": {}, "bonus_hp": 0})
	return out


## Builds a Combat view with `rules` in relic_ids. Returns the view (caller frees).
func make_view(rules: Array, kind := "battle", pw := 4) -> Node:
	RunState.pending_combat = {"node_id": "v5_node", "kind": kind, "pw": pw, "ascension": 0,
		"roster_snapshot": roster(), "relic_ids": rules, "combat_seed": 77}
	var view: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	add_child(view)
	for _i in 6:
		await get_tree().process_frame
	return view


func _ready() -> void:
	_guard.capture()
	CombatView.disable_juice_for_tests = true
	MetaState.runs_with_battle = 99
	await _test_alpha()
	await _test_stakes()
	await _test_shell()
	_guard.restore()
	if _fails.is_empty():
		print("t_ui_v5_rules: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
	else:
		for f in _fails:
			print("t_ui_v5_rules: FAIL — %s" % f)
		get_tree().quit(1)


func _test_alpha() -> void:
	var v: Node = await make_view(["rule_pack_alpha"])
	var c = v._combat
	var alpha = null
	for e in c.enemies:
		if bool(e.custom_state.get("alpha", false)):
			alpha = e
	_check(alpha != null, "setup: an Alpha exists (enemies=%d)" % c.enemies.size())
	if alpha == null:
		v.queue_free()
		return
	v._update_portrait(alpha)
	var pa: UnitPortrait = v._portraits[alpha.uid]
	_check(pa.is_leader(), "Leader badge shown on the Alpha")
	var badge := pa.find_child("LeaderBadge", true, false) as Control
	_check(badge != null and (badge.find_child("Text", true, false) as Label).text == "LEADER" \
		and badge.find_child("Icon", true, false) != null, "badge has glyph + the word LEADER")
	for e in c.enemies:
		if e != alpha:
			v._update_portrait(e)
			_check(not (v._portraits[e.uid] as UnitPortrait).is_leader(), "no badge on other enemies")
	var other = null
	for e in c.enemies:
		if e != alpha:
			other = e
	EventBus.core_fired.emit("rule_pack_alpha", other.uid, 3, "block")
	EventBus.core_fired.emit("rule_pack_alpha", other.uid, 2, "block")
	_check(v.alpha_notes.size() == 1 and String(v.alpha_notes[0]).begins_with("−50%"), "block note once per turn: %s" % str(v.alpha_notes))
	EventBus.core_fired.emit("rule_pack_alpha", other.uid, 4, "dmg")
	_check(v.alpha_notes.size() == 2 and String(v.alpha_notes[1]).begins_with("Pack broken"), "Pack broken note")
	alpha.hp = 0
	v._update_portrait(alpha)
	_check(not pa.is_leader(), "badge gone when the Leader is dead")
	v.queue_free()
	await get_tree().process_frame


func _test_stakes() -> void:
	var v: Node = await make_view(["rule_high_stakes"])
	var c = v._combat
	c.rerolls = 0
	c.mana = 0
	v._rebuild_all()
	await get_tree().process_frame
	var hud: CombatHud = v._hud_frame
	_check(v._stakes_pct() == 20, "stakes pct 20, got %d" % v._stakes_pct())
	_check(hud.reroll_button.text.begins_with("Gamble") and hud.reroll_button.text.contains("Crack 20%"),
		"reroll button says Gamble · Crack 20%%: '%s'" % hud.reroll_button.text)
	_check(not hud.reroll_button.disabled, "free Gamble is usable with 0 mana")
	_check(hud.reroll_button.tooltip_text.contains("Gamble") and hud.reroll_button.tooltip_text.contains("+3 Shield"), "tooltip explains Gamble")
	v._enter_rr_mode()
	await get_tree().process_frame
	_check(v._rr_bar.gamble_button.visible and not v._rr_bar.safe_button.visible, "pick bar: only Gamble under High Stakes")
	_check(v._rr_bar.line.text.contains("Crack 20%"), "bar line mentions Crack 20%%: '%s'" % v._rr_bar.line.text)
	_check(CoreFeedback.float_line("High Stakes", 3, "shield") == "High Stakes +3 Shield", "+3 Shield float")
	_check(CoreFeedback.float_line("High Stakes", 1, "mana") == "High Stakes +1 Mana", "+1 mana float")
	v.queue_free()
	await get_tree().process_frame
	var w: Node = await make_view([])
	_check(w._stakes_pct() == 0, "no stakes without the rule")
	w.queue_free()
	await get_tree().process_frame


func _shell_tune(on: bool) -> void:
	var b: Dictionary = (ContentDB.combat_tune.get("shell", {}) as Dictionary).duplicate(true)
	b["enabled"] = on
	ContentDB.combat_tune["shell"] = b


func _test_shell() -> void:
	var backup: Dictionary = ContentDB.combat_tune.duplicate(true)
	_shell_tune(false)
	var off: Node = await make_view([], "elite", 4)
	for e in off._combat.enemies:
		off._update_portrait(e)
		_check(not (off._portraits[e.uid] as UnitPortrait).has_shell(), "shell off: no bar")
	off.queue_free()
	await get_tree().process_frame
	_shell_tune(true)
	var v: Node = await make_view([], "elite", 4)
	var boss = v._combat.enemies[0]
	var sh := int(boss.custom_state.get("shell", 0))
	_check(sh > 0, "setup: elite has a Shell (%d)" % sh)
	v._update_portrait(boss)
	var p: UnitPortrait = v._portraits[boss.uid]
	_check(p.has_shell(), "shell on: bar shown on the Elite")
	var txt := p.find_child("ShellText", true, false) as Label
	_check(txt != null and txt.text == "%d / %d" % [sh, sh], "shell number '%s'" % (txt.text if txt != null else "?"))
	_check(UI3Tooltip.text_of(p.find_child("ShellRow", true, false)).contains("50%"), "tooltip says outside a SET deals 50%")
	EventBus.shell_changed.emit(boss.uid, sh - 5, sh, 5)
	_check(txt.text == "%d / %d" % [sh - 5, sh], "shell_changed updates the number")
	for e in v._combat.enemies:
		if e != boss:
			v._update_portrait(e)
			_check(not (v._portraits[e.uid] as UnitPortrait).has_shell(), "escort has no Shell bar")
	v.queue_free()
	await get_tree().process_frame
	ContentDB.combat_tune = backup
