extends Node
## UI-05 b23 lane R2b: the Run rule offer against 05-run-rule-offer--offer / --picked (names, fixed card size, PriceBox vs "No Rule",
## no preselect, two different house colours, 1920 + 1280, align pairs measured, text >= 14 real px, initial focus on card 0).
const Align := preload("res://tests/ui5_align_check.gd")
var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0
var rm: Node


func _ok(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_fails.append(m)


func _frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame


func _ready() -> void:
	print("=== t_ui5_rule_offer: start ===")
	_guard.capture()
	ProjectSettings.set_setting("axie/epoch_source", "local")
	RunState.start_new_run_seeded(424242, {"team_keys": ["plant1", "beast1", "aqua1", "reptile1", "bug1"],
		"mode": "short", "ascension": 0, "ranked": false, "rules_on": true})
	await _frames(2)
	rm = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(rm)
	await _frames(8)
	_ok(RunState._rule_offer_active and RunState.pending_rewards.size() == 2, "a real rule offer with 2 cards is open")
	for sc in [1.0, 2.0 / 3.0]:
		UI3Theme.set_scale_override(sc)
		rm._show_reward_overlay("x")
		await _frames(4)
		_frame(sc, false)
	UI3Theme.set_scale_override(1.0)
	rm._show_reward_overlay("x")
	await _frames(3)
	_ok(rm._reward_cards[0].has_focus() and int(rm._reward_sel) == -1 and not bool(rm._reward_cards[0].get("selected")),
		"initial focus is card 0, nothing selected")
	rm._select_reward(0)
	await _frames(3)
	_ok(bool(rm._reward_cards[0].get("selected")) and not bool(rm._reward_cards[1].get("selected")), "picking card 0 selects only it")

	# "No Rule" next to a real rule: no PriceBox on it (frame --picked).
	var real: Dictionary = (RunState.pending_rewards[0] as Dictionary).duplicate(true)
	var none: Dictionary = (RunState.pending_rewards[0] as Dictionary).duplicate(true)
	none["key"] = CoreOffer.NO_RULE_ID
	var nd = RelicRegistry.get_def(CoreOffer.NO_RULE_ID)
	if nd != null:
		none = CoreOffer.rule_card_of(nd, 1)
	RunState.pending_rewards.assign([real, none])
	for sc in [1.0, 2.0 / 3.0]:
		UI3Theme.set_scale_override(sc)
		rm._show_reward_overlay("x")
		await _frames(4)
		_frame(sc, true)
		rm._select_reward(1)
		await _frames(3)
		_ok(bool(rm._reward_cards[1].get("selected")), "no-rule card can be picked @%.2f" % sc)
		var tk := rm._overlay_root.find_child("TakeButton", true, false) as Button
		_ok(tk != null and not tk.disabled and tk.text.begins_with("Take"), "pick turns Take on @%.2f (got '%s')" % [sc, tk.text if tk != null else "-"])
	# The longest rule text (Pack Alpha) must fit its card at the 1280 size.
	var pa = RelicRegistry.get_def("rule_pack_alpha")
	_ok(pa != null, "rule_pack_alpha exists")
	if pa != null:
		RunState._rule_offer_active = true
		RunState.pending_rewards.assign([CoreOffer.rule_card_of(pa, 0), real])
		for sc in [1.0, 2.0 / 3.0]:
			UI3Theme.set_scale_override(sc)
			rm._show_reward_overlay("x")
			await _frames(4)
			_frame(sc, false)
		# Plain reward + treasure cards: the name / text is left-aligned card text in a Body box, so no label pairs with the RewardArt icon.
	RunState._rule_offer_active = false
	RunState._core_offer_active = false
	RunState.reward_reroll_charges = 1
	for mode in ["reward", "treasure"]:
		for sc in [1.0, 2.0 / 3.0]:
			UI3Theme.set_scale_override(sc)
			var fake: Array = []
			for i in 3:
				fake.append({"t": "relic", "key": "x%d" % i, "rar": i % 3, "title": "RELIC", "desc": "Name %d" % i, "sub": "Does thing %d." % i})
			RunState.pending_rewards.assign(fake)
			if mode == "reward":
				rm._show_reward_overlay("x")
			else:
				rm.call("_build_treasure", true)
			await _frames(4)
			var rt: Node = rm._overlay_root
			var tg := "%s @%.2f" % [mode, sc]
			_ok(rm._reward_cards.size() == 3, "%s: 3 cards" % tg)
			for c in rm._reward_cards:
				_ok(c.find_child("Body", true, false) != null and c.find_child("RewardName", true, false).get_parent().name == "Body", "%s: name sits in Body" % tg)
			_ok(Align.pairs(rt) > 0, "%s: align check measured pairs" % tg)
			var al2: Array[String] = Align.check(rt, 1.5, tg)
			_ok(al2.is_empty(), "%s: aligned %s" % [tg, str(al2.slice(0, 3))])
			await _frames(3)
			_ok(rm._reward_cards[0].has_focus() and int(rm._reward_sel) == -1, "%s: initial focus is card 0, nothing selected" % tg)
			for bn in rt.find_children("*", "Button", true, false):
				if (bn as Control).is_visible_in_tree():
					_ok(float((bn as Button).get_theme_font_size("font_size")) * sc >= 13.99, "%s: button '%s' >= 14 real px" % [tg, (bn as Button).text.left(20)])
			for l in rt.find_children("*", "Label", true, false):
				var lab := l as Label
				if lab.is_visible_in_tree() and lab.text != "":
					_ok(float(lab.get_theme_font_size("font_size")) * sc >= 13.99, "%s: '%s' >= 14 real px" % [tg, lab.text.left(20)])
			for cn in rt.find_children("*", "Control", true, false):
				var ct := cn as Control
				if ct.is_visible_in_tree() and ct.size.x > 0.0:
					var rr := ct.get_global_rect()
					if rr.end.x > 1920.5 or rr.position.x < -0.5:
						_ok(false, "%s: %s outside 1920 (%s)" % [tg, ct.name, str(rr)])
			rm._select_reward(0)
			await _frames(3)
			var tb2 := rt.find_child("TakeButton", true, false) as Button
			var cap2 := tb2.get_node_or_null("KeyCap") as PanelContainer if tb2 != null else null
			_ok(cap2 != null and Ui5Keycap.text_of(cap2) == "Space" and not tb2.disabled, "%s: picked Take shows the Space keycap" % tg)
	UI3Theme.set_scale_override(-1.0)
	RunState.pending_rewards.assign([])
	rm.queue_free()
	_guard.restore()
	print("=== t_ui5_rule_offer: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("t_ui5_rule_offer: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
	else:
		for f in _fails:
			print("FAIL: " + f)
		get_tree().quit(1)


func _frame(sc: float, with_none: bool) -> void:
	var tag := "rule%s @%.2f" % [" +none" if with_none else "", sc]
	var root: Node = rm._overlay_root.find_child("RunRuleOffer", true, false)
	_ok(root != null, "%s: RunRuleOffer" % tag)
	if root == null:
		return
	for n in ["Header", "Title", "ShardPill", "CardRow", "Footer", "TakeButton"]:
		_ok(root.find_child(n, true, false) != null, "%s: node %s" % [tag, n])
	for n in ["RerollButton", "RerollCounter", "SkipButton", "TierLadder"]:
		_ok(root.find_child(n, true, false) == null, "%s: no %s" % [tag, n])
	_ok((root.find_child("Title", true, false) as Label).text == "Choose a run rule", "%s: title" % tag)
	var tk := root.find_child("TakeButton", true, false) as Button
	_ok(tk.disabled and tk.text == "Pick a rule" and tk.get_node_or_null("KeyCap") == null, "%s: Take off, 'Pick a rule', no keycap (got '%s')" % [tag, tk.text])
	var want := Vector2(UI3Theme.size_of("rule_card_w"), UI3Theme.size_of("rule_card_h"))
	_ok(rm._reward_cards.size() == 2, "%s: 2 cards" % tag)
	var tints: Array[int] = []
	for i in rm._reward_cards.size():
		var c: Control = rm._reward_cards[i]
		_ok(c.name == "RuleCard%d" % i and c.size.x == want.x and c.size.y <= want.y + 0.5 and c.size.y >= 299.0, "%s card %d: RuleCard %s, shrunk to content (got %s)" % [tag, i, want, c.size])
		for n in ["TierFrame", "RuleName", "Headline", "RuleText"]:
			_ok(c.find_child(n, true, false) != null, "%s card %d: %s" % [tag, i, n])
		_ok(absf(c.size.y - rm._reward_cards[0].size.y) < 1.0, "%s card %d: same height as card 0" % [tag, i])
		var is_none: bool = String((RunState.pending_rewards[i] as Dictionary).get("key", "")) == CoreOffer.NO_RULE_ID
		var pb := c.find_child("PriceBox", true, false)
		_ok((pb == null) == is_none, "%s card %d: PriceBox only on a real rule (none=%s)" % [tag, i, str(is_none)])
		_ok(pb == null or c.find_child("PriceLine", true, false) != null, "%s card %d: PriceLine" % [tag, i])
		_ok(not bool(c.get("selected")), "%s card %d: not preselected" % [tag, i])
		_ok(c.find_child("TierCrest", true, false) == null and c.find_child("ArtWindow", true, false) == null, "%s card %d: plaque, no tier crest / art window" % [tag, i])
		var rn := (c.find_child("RuleName", true, false) as Label).text
		var want_name := UI3.title_case(UI3.player_text(String((RunState.pending_rewards[i] as Dictionary).get("desc", ""))))
		_ok(rn == want_name and rn != "" and rn.to_lower() != "run rule", "%s card %d: name is the rule's own (%s)" % [tag, i, rn])
		_ok(not String(c.find_child("RuleText", true, false).get_meta("plain")).begins_with(rn), "%s card %d: text does not repeat the name" % [tag, i])
		tints.append(int(c.get_meta("tint_index", -1)))
		var col := c.get("column") as Control
		_ok(col.get_combined_minimum_size().y <= c.size.y - 2.0 * UI3Theme.space("20") + 0.5, "%s card %d: content fits (%.0f of %.0f)" % [tag, i,
			col.get_combined_minimum_size().y, c.size.y - 40.0])
	_ok(tints.size() == 2 and tints[0] != tints[1], "%s: two cards never share a tint index" % tag)
	_ok(Align.pairs(root) > 0, "%s: align check measured pairs" % tag)
	var al: Array[String] = Align.check(root, 1.5, tag)
	_ok(al.is_empty(), "%s: aligned %s" % [tag, str(al.slice(0, 4))])
	for bn in root.find_children("*", "Button", true, false):
		var bt := bn as Button
		if bt.is_visible_in_tree():
			_ok(float(bt.get_theme_font_size("font_size")) * sc >= 13.99, "%s: button '%s' >= 14 real px" % [tag, bt.text.left(20)])
	var vp := Vector2(1920, 1080)
	for cn in root.find_children("*", "Control", true, false):
		var ct := cn as Control
		if ct.is_visible_in_tree() and ct.size.x > 0.0:
			var rr := ct.get_global_rect()
			if rr.end.x > vp.x + 0.5 or rr.position.x < -0.5:
				_ok(false, "%s: %s outside 1920 (%s)" % [tag, ct.name, str(rr)])
	_ok(tk.get_global_rect().end.y <= 1080.0 - 13.0 + 0.5, "%s: Take bottom %.0f inside the safe area" % [tag, tk.get_global_rect().end.y])
	for l in root.find_children("*", "Label", true, false):
		var lab := l as Label
		if lab.is_visible_in_tree() and lab.text != "":
			_ok(float(lab.get_theme_font_size("font_size")) * sc >= 13.99, "%s: '%s' >= 14 real px" % [tag, lab.text.left(20)])
