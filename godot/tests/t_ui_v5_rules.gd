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
	await _test_new_cores()
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
	pa.set_intent({"show": true, "type": "dmg", "num": 22, "label": "ATTACK", "target": "Olek the Magnificent Warrior", "boosted": false})
	await get_tree().process_frame
	_check(pa._plate.get_combined_minimum_size().x <= UnitPortrait.WIDTH + 0.5, "Leader plate min width %.0f stays <= %.0f" % [pa._plate.get_combined_minimum_size().x, UnitPortrait.WIDTH])
	_check(pa._intent_panel.get_global_rect().end.x <= pa._plate.get_global_rect().end.x + 0.5, "intent column inside the plate")
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
	_check(String(v.alpha_notes[0]).contains(":") and String(v.alpha_notes[0]).ends_with(v._unit_name(alpha.uid)), "block note names the Leader: %s" % v.alpha_notes[0])
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
	_check(v._rr_bar.line.text.contains("Crack 20%") and v._rr_bar.line.text.contains("half value"), "bar line: Crack 20%% + half value: '%s'" % v._rr_bar.line.text)
	_check(c.reroll_mana_cost(false, 0) == 0 and v._rr_bar.gamble_button.text.contains("free"), "pick-bar Gamble price (free) matches engine")
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
	_check(txt != null and txt.text == "SHELL %d / %d" % [sh, sh], "shell label+number '%s'" % (txt.text if txt != null else "?"))
	_check(UI3Tooltip.text_of(p.find_child("ShellRow", true, false)).contains("50%"), "tooltip says outside a SET deals 50%")
	EventBus.shell_changed.emit(boss.uid, sh - 5, sh, 5)
	_check(txt.text == "SHELL %d / %d" % [sh - 5, sh], "shell_changed updates the number")
	# off-set hit: one float per turn
	var hitter: Unit = v._party_dice_units()[0]
	EventBus.face_used.emit(hitter.uid, "p", boss.uid, false, "", "", "dmg")
	EventBus.shell_changed.emit(boss.uid, sh - 8, sh, 3)
	EventBus.shell_changed.emit(boss.uid, sh - 11, sh, 3)
	_check(v.shell_notes.size() == 1 and String(v.shell_notes[0]) == "Outside a SET: 50% to Shell", "off-set Shell note once per turn: %s" % str(v.shell_notes))
	# first-sight coach
	V4Coach.reset_for_tests()
	V4Coach.enabled_in_tests = true
	v._coach_turn = -1
	v._update_coach()
	_check(v.coach_shown_id == "C8", "Shell coach shown first time, got '%s'" % v.coach_shown_id)
	_check(V4Coach.text_for("C8").contains("50%") and V4Coach.text_for("C8").contains("SET of 3"), "coach text")
	v.coach_shown_id = ""
	v._coach_turn = -1
	v._update_coach()
	_check(v.coach_shown_id != "C8", "Shell coach only once")
	V4Coach.enabled_in_tests = false
	for e in v._combat.enemies:
		if e != boss:
			v._update_portrait(e)
			_check(not (v._portraits[e.uid] as UnitPortrait).has_shell(), "escort has no Shell bar")
	v.queue_free()
	await get_tree().process_frame
	ContentDB.combat_tune = backup


const NEW_CORES := ["c_bloodline_ward", "c_smoldering", "c_cache_plate", "c_golden_thread", "c_last_testament",
	"c_melting_pot", "c_hunters_reward", "c_support_hand", "c_cracked_glass", "c_high_roller", "c_magma_seed"]


func _test_new_cores() -> void:
	var cp := CorePanel.new()
	add_child(cp)
	for id in NEW_CORES:
		var def = RelicRegistry.get_def(id)
		_check(def != null, "%s resolves" % id)
		if def == null:
			continue
		var nm := UI3.title_case(UI3.player_text(String(def.name)))
		var txt := UI3.player_text(String(def.description))
		_check(nm != "", "%s has a name" % id)
		_check(txt.length() > 20 and not txt.contains("[") and not txt.contains("RULE:") and not txt.contains("undefined"), "%s rule text clean: '%s'" % [id, txt])
		var icon_name := String(CorePanel.AXIS_ICON.get(String(def.core_axis), ""))
		_check(icon_name != "" and UI3.icon(icon_name) != null, "%s axis icon '%s' (axis '%s')" % [id, icon_name, def.core_axis])
		var slot := cp._slot(def, false, "")
		var ic := slot.get_node_or_null("AxisIcon") as TextureRect
		_check(ic != null and ic.texture != null, "%s slot shows an icon" % id)
		var tip := UI3Tooltip.text_of(slot)
		_check(tip.contains(String(def.name)) and tip.contains(txt), "%s slot tooltip carries name + rule text" % id)
		slot.free()
	cp.free()
