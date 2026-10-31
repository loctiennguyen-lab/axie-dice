extends Node
## UI-05 b23 lane R2a: no card is preselected on any of the four pick paths (reward, Core, Run rule, treasure), Take is off with a
## reason and no keycap until a pick, a pick turns it on (Space keycap), nothing before the pick is logged; plus the Core offer
## against the 47-core-offer frames (names, fixed card size, face-down state, 1920 + 1280, align check, text >= 14 real px).
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


func _take() -> Button:
	return rm._overlay_root.find_child("TakeButton", true, false) as Button


func _log_len() -> int:
	return (RunState.action_log.entries as Array).size()


func _take_count() -> int:
	var n := 0
	for e in RunState.action_log.entries:
		if String((e as Dictionary).get("fn", "")) == "take_reward":
			n += 1
	return n


## The shared no-preselect contract on whatever offer is open now. `why` = the disabled text, `label` = the text once picked.
func _contract(tag: String, why: String, label: String) -> void:
	var tb := _take()
	_ok(tb != null, "%s: TakeButton" % tag)
	if tb == null:
		return
	_ok(int(rm._reward_sel) == -1, "%s: nothing preselected" % tag)
	for c in rm._reward_cards:
		_ok(not bool(c.get("selected")), "%s: no card shows selected" % tag)
	_ok(tb.disabled and tb.text == why, "%s: Take off, says '%s' (got '%s')" % [tag, why, tb.text])
	_ok(tb.get_node_or_null("KeyCap") == null, "%s: no keycap on the disabled Take" % tag)
	var pend := RunState.pending_rewards.size()
	var ll := _log_len()
	rm._take_selected_reward()
	await _frames(2)
	_ok(RunState.pending_rewards.size() == pend and _log_len() == ll, "%s: Take with nothing picked changes nothing" % tag)
	var ev := InputEventAction.new()
	ev.action = "ui_accept"
	ev.pressed = true
	rm._reward_cards[0].gui_input.emit(ev)   # Enter / Space on a card picks it and moves focus to Take
	await _frames(3)
	_ok(int(rm._reward_sel) == 0 and not tb.disabled and tb.text == label, "%s: pick turns Take on as '%s' (got '%s')" % [tag, label, tb.text])
	_ok(tb.get_viewport().gui_get_focus_owner() == tb, "%s: ui_accept on a card moves focus to Take" % tag)
	var cap := tb.get_node_or_null("KeyCap") as PanelContainer
	_ok(cap != null and Ui5Keycap.text_of(cap) == "Space", "%s: enabled Take shows the Space keycap" % tag)
	_ok(_log_len() == ll, "%s: picking a card is not logged" % tag)
	rm._show_reward_overlay("x") if tag != "treasure" else rm.call("_build_treasure", true)   # re-opening (what a reroll does) clears the pick
	await _frames(3)
	_ok(int(rm._reward_sel) == -1 and _take().disabled, "%s: reopening resets to nothing picked" % tag)


func _fake_cards(core: bool) -> Array:
	var out: Array = []
	for i in 3:
		var d := {"t": "relic", "key": "x%d" % i, "rar": 0, "title": "CORE" if core else "RELIC", "desc": "Name %d" % i,
			"sub": "Does thing %d." % i}
		if core:
			d.merge({"core": true, "axis": ["stat", "dice", "pos"][i], "tier": i, "slot": i})
		out.append(d)
	return out


func _ready() -> void:
	print("=== t_ui5_core_offer: start ===")
	_guard.capture()
	ProjectSettings.set_setting("axie/epoch_source", "local")
	UI3Gacha.instant_override = 1
	RunState.start_new_run_seeded(424242, {"team_keys": ["plant1", "beast1", "aqua1", "reptile1", "bug1"],
		"mode": "short", "ascension": 0, "ranked": false, "rules_on": true})
	await _frames(2)
	rm = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(rm)
	await _frames(8)

	# Run rule pick (real offer): contract, then pick the second rule for real.
	await _contract("rule", "Pick a rule", "Take")
	rm._select_reward(1)
	await _frames(2)
	var takes := _take_count()
	rm._take_selected_reward()
	await _frames(8)
	_ok(_take_count() == takes + 1, "rule: exactly one take_reward logged")

	# Core offer (real): contract + frame names at both sizes.
	_ok(RunState._core_offer_active and not RunState.pending_rewards.is_empty(), "Core offer is open after the rule")
	await _contract("core", "Pick a Core", "Take")
	for sc in [1.0, 2.0 / 3.0]:
		UI3Theme.set_scale_override(sc)
		rm._show_reward_overlay("x")
		await _frames(4)
		_core_frame(sc)
	UI3Theme.set_scale_override(1.0)
	rm._show_reward_overlay("x")
	await _frames(3)
	_ok(rm._reward_cards[0].has_focus() and int(rm._reward_sel) == -1 and not bool(rm._reward_cards[0].get("selected")),
		"core: initial focus is card 0, not selected")
	# A real per-card reroll with a card picked: the pick is cleared.
	rm._select_reward(1)
	await _frames(2)
	var left0: int = RunState.core_reroll_left
	await rm._on_core_card_reroll(1)
	await _frames(6)
	_ok(RunState.core_reroll_left == left0 - 1, "core reroll: a real reroll was spent (%d -> %d)" % [left0, RunState.core_reroll_left])
	_ok(int(rm._reward_sel) == -1 and _take() != null and _take().disabled, "core reroll: pick cleared, Take off")
	takes = _take_count()
	var ll := _log_len()
	rm._select_reward(0)
	await _frames(2)
	_ok(_log_len() == ll, "core: selecting logs nothing")
	rm._take_selected_reward()
	await get_tree().create_timer(0.8).timeout
	await _frames(6)
	_ok(_take_count() == takes + 1, "core: exactly one take_reward logged")

	# Regular reward: a real reroll also clears the pick.
	RunState._core_offer_active = false
	RunState.reward_reroll_charges = 1
	RunState.pending_rewards.assign(_fake_cards(false))
	rm._show_reward_overlay("CHOOSE ONE REWARD")
	await _frames(3)
	rm._select_reward(0)
	await rm._on_reward_reroll("CHOOSE ONE REWARD")
	await _frames(4)
	_ok(int(rm._reward_sel) == -1, "reward reroll: pick cleared (sel %d)" % int(rm._reward_sel))

	# Regular reward and treasure (stand-in offers, never taken).
	RunState._core_offer_active = false
	RunState.pending_rewards.assign(_fake_cards(false))
	RunState.reward_reroll_charges = 1
	rm._show_reward_overlay("CHOOSE ONE REWARD")
	await _frames(4)
	await _contract("reward", "Pick a card", "Take")
	RunState.pending_rewards.assign(_fake_cards(false))
	rm.call("_build_treasure", true)
	await _frames(4)
	await _contract("treasure", "Pick a reward", "Take and continue")

	# AwakenChip: a house Core that takes the Anchor to 2/2 (real Anchors data, test_state).
	var hcs: Array = Anchors.get_def("a_volley").get("house_cores", []) as Array
	if hcs.size() >= Anchors.AWAKEN_NEED:
		AnchorAdapter.test_state = {"anchor_id": "a_volley", "awakened": false, "owned": hcs.slice(0, Anchors.AWAKEN_NEED - 1)}
		RunState._core_offer_active = true
		var fc := _fake_cards(true)
		fc[0]["key"] = String(hcs[Anchors.AWAKEN_NEED - 1])
		RunState.pending_rewards.assign(fc)
		rm._show_reward_overlay("x")
		await _frames(4)
		var c0: Control = rm._reward_cards[0]
		_ok(c0.find_child("AwakenChip", true, false) != null and c0.find_child("ChipRow", true, false).find_child("AwakenChip", true, false) != null,
			"awaken: AwakenChip sits in the ChipRow of the Core that awakens")
		_ok(c0.find_child("AwakenEdge", true, false) != null, "awaken: awaken edge on the card")
		_ok(rm._reward_cards[1].find_child("AwakenChip", true, false) == null, "awaken: other cards have none")
		AnchorAdapter.test_state = null
		RunState._core_offer_active = false
	else:
		_ok(false, "awaken: a_volley house_cores has too few entries")

	# Face-down Core offer: Take reads the reveal reason, counter hidden, SkipHint up; all gone after the flip.
	UI3Gacha.instant_override = 0
	RunState._core_offer_active = true
	RunState.pending_rewards.assign(_fake_cards(true))
	rm._show_reward_overlay("x")
	await _frames(3)
	_ok(_take() != null and _take().disabled and _take().text == "Reveal the cards first", "face-down: Take says 'Reveal the cards first'")
	var cnt := rm._overlay_root.find_child("RerollCounter", true, false) as Control
	_ok(cnt != null and not cnt.visible, "face-down: rerolls counter hidden")
	_ok(rm._overlay_root.find_child("SkipHint", true, false) != null, "face-down: SkipHint shown")
	_ok(rm._overlay_root.find_children("CoreCardBack", "", true, false).size() == 3, "face-down: 3 CoreCardBack")
	_ok(not rm._reward_cards[0].has_focus(), "face-down: no focus ring on the face-down cards")
	rm._reveal.skip()
	await _frames(4)
	_ok(rm._reward_cards[0].has_focus() and int(rm._reward_sel) == -1, "revealed: focus on card 0, nothing selected")
	_ok(_take().text == "Pick a Core" and cnt.visible and rm._overlay_root.find_child("SkipHint", true, false) == null, "revealed: Take says why, counter back, SkipHint gone")
	UI3Gacha.instant_override = -1
	RunState._core_offer_active = false

	UI3Theme.set_scale_override(-1.0)
	RunState.pending_rewards.assign([])
	rm.queue_free()
	_guard.restore()
	print("=== t_ui5_core_offer: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("t_ui5_core_offer: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
	else:
		for f in _fails:
			print("FAIL: " + f)
		get_tree().quit(1)


## Names, fixed card size, chips, fit, align pairs and real text size of the open Core offer.
func _core_frame(sc: float) -> void:
	var tag := "core @%.2f" % sc
	var root: Node = rm._overlay_root.find_child("CoreOffer", true, false)
	_ok(root != null, "%s: CoreOffer" % tag)
	if root == null:
		return
	for n in ["Header", "Title", "TierLadder", "ShardChip", "CardRow", "Footer", "RerollCounter", "TakeButton"]:
		_ok(root.find_child(n, true, false) != null, "%s: node %s" % [tag, n])
	_ok(root.find_child("TierLadder", true, false).find_children("TierChip", "", true, false).size() == 3, "%s: TierLadder has 3 TierChips" % tag)
	var want := Vector2(UI3Theme.size_of("core_card_w"), UI3Theme.size_of("core_card_h"))
	_ok(rm._reward_cards.size() >= 3, "%s: >= 3 cards" % tag)
	for i in rm._reward_cards.size():
		var c: Control = rm._reward_cards[i]
		_ok(c.name == "CoreCard%d" % i and c.size.is_equal_approx(want), "%s card %d: CoreCard %s (got %s)" % [tag, i, want, c.size])
		for n in ["ArtBox", "CoreName", "ChipRow", "TierChip", "CategoryChip", "RuleText", "RerollButton"]:
			_ok(c.find_child(n, true, false) != null, "%s card %d: %s" % [tag, i, n])
		var col := c.get("column") as Control
		_ok(col.get_combined_minimum_size().y <= c.size.y - 2.0 * UI3Theme.space("20") + 0.5, "%s card %d: content fits (%.0f of %.0f)" % [tag, i,
			col.get_combined_minimum_size().y, c.size.y - 40.0])
	_ok(Align.pairs(root) > 0, "%s: align check measured pairs" % tag)
	var al: Array[String] = Align.check(root, 1.5, tag)
	_ok(al.is_empty(), "%s: aligned %s" % [tag, str(al.slice(0, 4))])
	var lad := root.find_child("TierLadder", true, false)
	_ok(lad.get_child_count() == 7 and lad.find_children("Pip", "TextureRect", true, false).size() == 6, "%s: TierLadder label + 3 chips with 1/2/3 pips + arrows + (strongest)" % tag)
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
	var tk := _take()
	_ok(tk.get_global_rect().end.y * sc <= 1080.0 * (sc if sc < 1.0 else 1.0) - 13.0 * sc + 0.5, "%s: Take bottom %.0f inside the safe area" % [tag, tk.get_global_rect().end.y])
	for l in root.find_children("*", "Label", true, false):
		var lab := l as Label
		if lab.is_visible_in_tree() and lab.text != "":
			_ok(float(lab.get_theme_font_size("font_size")) * sc >= 13.99, "%s: '%s' >= 14 real px" % [tag, lab.text.left(20)])
