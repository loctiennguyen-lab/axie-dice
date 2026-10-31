extends Node
## UI-05 b23 lane S4b: the tutorial coach against the 37-tutorial frames: data-names, Space keycaps only on live primaries,
## focus, no preselect on the reward pick (Take off and says why), spotlight hole + click-lock bands, skip confirm,
## 1920 + 1280 fit, text >= 14 real px, align check; and the step lock still refuses what the step does not name.
const Align := preload("res://tests/ui5_align_check.gd")
var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0
var _cta := 0
var _picked := -1


func _ok(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_fails.append(m)


func _frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame


func _has(root: Node, names: Array, tag: String) -> void:
	for n in names:
		_ok(root.find_child(n, true, false) != null, "%s: node %s" % [tag, n])


## Fit, text size, align on the open screen under `root`.
func _fit(root: Node, sc: float, tag: String, align := true) -> int:
	var vp := Vector2(1920, 1080)
	for cn in root.find_children("*", "Control", true, false):
		var ct := cn as Control
		if ct.is_visible_in_tree() and ct.size.x > 0.0 and ct.size.y > 0.0:
			var rr := ct.get_global_rect()
			if rr.end.x > vp.x + 0.5 or rr.position.x < -0.5 or rr.end.y > vp.y + 0.5 or rr.position.y < -0.5:
				_ok(false, "%s: %s outside the frame (%s)" % [tag, ct.name, str(rr)])
	for l in root.find_children("*", "Label", true, false):
		var lab := l as Label
		if lab.is_visible_in_tree() and lab.text != "":
			_ok(float(lab.get_theme_font_size("font_size")) * sc >= 13.99, "%s: label '%s' >= 14 real px" % [tag, lab.text.left(20)])
	for b in root.find_children("*", "Button", true, false):
		var bt := b as Button
		if bt.is_visible_in_tree():
			_ok(float(bt.get_theme_font_size("font_size")) * sc >= 13.99, "%s: button '%s' >= 14 real px" % [tag, bt.text.left(20)])
	if align:
		var al: Array[String] = Align.check(root, 1.5, tag)
		_ok(al.is_empty(), "%s: aligned %s" % [tag, str(al.slice(0, 3))])
	return Align.pairs(root)



func _caps(root: Node) -> Array:
	var out: Array = []
	for c in Ui5Keycap.all_under(root):
		if c.is_visible_in_tree():
			out.append(c)
	return out


func _coach_pass(sc: float, aligned: Array) -> void:
	var tag := "@%.2f" % sc
	UI3Theme.set_scale_override(sc)
	var coach := TutorialCoach.new()
	add_child(coach)
	coach.cta_pressed.connect(func() -> void: _cta += 1)
	coach.reward_chosen.connect(func(i: int) -> void: _picked = i)
	await _frames(3)
	# Welcome curtain.
	coach.show_curtain("Welcome", "Body text.", "Start")
	await _frames(4)
	_has(coach, ["Scrim", "Curtain", "Title", "Body", "CtaButton", "SkipTutorialButton"], "welcome " + tag)
	var cta := coach.find_child("CtaButton", true, false) as Button
	_ok(cta.get_node_or_null("KeyCap") != null and cta.has_focus(), "welcome %s: CtaButton has focus and the Space keycap" % tag)
	_ok(not (coach.find_child("SkipTutorialButton", true, false) as Button).has_focus(), "welcome %s: Skip is not the focus" % tag)
	_ok(_caps(coach).size() == 1 and Ui5Keycap.text_of(_caps(coach)[0]) == KeyBindings.text(KeyBindings.COMBAT_END_TURN), "welcome %s: exactly one cap, from KeyBindings" % tag)
	aligned.append(_fit(coach, sc, "welcome " + tag))
	# A coached step with a spotlight on a real control.
	var tgt := Control.new()
	tgt.position = Vector2(552, 800)
	tgt.size = Vector2(816, 200)
	add_child(tgt)
	coach.show_step("STEP 1 OF 6", "Title", "Body text.", "Got it →", tgt)
	await _frames(4)
	_has(coach, ["StepCard", "StepLabel", "Title", "Body", "SkipButton", "GotItButton", "Spotlight"], "step " + tag)
	var got := coach.find_child("GotItButton", true, false) as Button
	_ok(got.get_node_or_null("KeyCap") != null and got.has_focus(), "step %s: Got it has focus + Space keycap" % tag)
	var card := coach.find_child("StepCard", true, false) as Control
	_ok(is_equal_approx(card.size.x, UI3Theme.size_of("step_card_w")), "step %s: card is step_card_w wide" % tag)
	var hole := tgt.get_global_rect().grow(10.0)
	var bands: Array = coach.find_children("Dim*", "ColorRect", true, false)
	_ok(bands.size() == 4, "step %s: four dim bands" % tag)
	var leaks := 0
	for pt in [hole.get_center(), hole.position + Vector2(2, 2), hole.end - Vector2(2, 2)]:
		for b in bands:
			if (b as ColorRect).visible and (b as ColorRect).get_global_rect().has_point(pt):
				leaks += 1
	_ok(leaks == 0, "step %s: the spotlight is a real hole (no band over it)" % tag)
	var blocked := true
	for b in bands:
		blocked = blocked and (b as ColorRect).mouse_filter == Control.MOUSE_FILTER_STOP
	_ok(blocked, "step %s: every band blocks the mouse" % tag)
	aligned.append(_fit(coach, sc, "step " + tag))
	# A step with no button (the player acts in the hole).
	coach.show_step("STEP 4 OF 6", "Pick this die", "Body.", "", tgt)
	await _frames(3)
	_ok(not got.visible and got.get_node_or_null("KeyCap") == null, "step4 %s: no Got it, no keycap" % tag)
	_ok(coach.find_child("SkipButton", true, false).is_visible_in_tree(), "step4 %s: Skip still there" % tag)
	# Over to you: no dim.
	coach.show_step("", "Over to you", "Body.", "", null, Rect2(24, 70, 1, 1), false)
	await _frames(3)
	var any_dim := false
	for b in bands:
		any_dim = any_dim or (b as ColorRect).visible
	_ok(not any_dim and not coach.find_child("StepLabel", true, false).is_visible_in_tree(), "free %s: nothing dimmed, no step label" % tag)
	# Starter pack: cells come from the entries, a missing Gem has no cell.
	coach.show_starter("Ready", "Waiting.", [{"value": "7", "label": "Shards", "sub": "sub one"},
		{"value": "2", "label": "Tickets", "sub": "sub two"}], "Go to the Land")
	await _frames(4)
	_has(coach, ["StarterPackCard", "ShardCell", "TicketCell", "CtaButton"], "starter " + tag)
	_ok(coach.find_child("GemCell", true, false) == null, "starter %s: no Gem cell when no gems" % tag)
	_ok(coach.find_child("SkipTutorialButton", true, false) == null or not coach.find_child("SkipTutorialButton", true, false).is_visible_in_tree(), "starter %s: no Skip" % tag)
	aligned.append(_fit(coach, sc, "starter " + tag))
	# Reward pick: nothing chosen, Take off and says why; picking turns it on; Take emits.
	_picked = -1
	coach.show_rewards("You won.", "Pick one.", [
		{"category": "A", "rarity": "Common", "icon": "face_heal", "title": "One", "desc": "d1"},
		{"category": "B", "rarity": "Rare", "icon": "ui_mooncard", "title": "Two", "desc": "d2"},
		{"category": "C", "rarity": "Common", "icon": "cur_shard", "title": "Three", "desc": "d3"}])
	await _frames(4)
	_has(coach, ["TutorialRewardPick", "CardRow", "Footer", "TakeButton", "RewardName", "RewardBody"], "reward " + tag)
	var cards: Array = coach.find_children("RewardCard*", "PanelContainer", true, false)
	_ok(cards.size() == 3, "reward %s: three RewardCards" % tag)
	var take := coach.find_child("TakeButton", true, false) as Button
	_ok(take.disabled and take.text == "Pick a reward" and take.get_node_or_null("KeyCap") == null, "reward %s: Take off, says why, no keycap" % tag)
	var sel := 0
	for c in cards:
		sel += 1 if c.selected else 0
	_ok(sel == 0, "reward %s: nothing preselected" % tag)
	_ok(cards[0].has_focus(), "reward %s: initial focus on the first card" % tag)
	coach.call("_select_reward", 1)
	await _frames(3)
	_ok(cards[1].selected and not take.disabled and take.get_node_or_null("KeyCap") != null, "reward %s: pick turns Take on with Space cap" % tag)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	cards[2].gui_input.emit(click)
	await _frames(3)
	_ok(cards[2].selected and get_viewport().gui_get_focus_owner() == take, "reward %s: clicking a card puts focus on TakeButton" % tag)
	aligned.append(_fit(coach, sc, "reward " + tag))
	take.pressed.emit()
	_ok(_picked == 2, "reward %s: Take emits the picked index" % tag)
	# Skip confirm.
	coach.show_curtain("Done", "Body.", "Go to the Land", false)
	await _frames(3)
	_ok(not coach.find_child("SkipTutorialButton", true, false).is_visible_in_tree(), "replay-end %s: no Skip button" % tag)
	coach.show_curtain("Lost", "Body.", "Continue")
	await _frames(3)
	_ok(coach.find_child("SkipTutorialButton", true, false).is_visible_in_tree(), "lost %s: Skip button present" % tag)
	coach.call("_ask_skip")
	await _frames(4)
	_has(coach, ["SkipConfirm", "KeepGoingButton"], "confirm " + tag)
	var keep := coach.find_child("KeepGoingButton", true, false) as Button
	_ok(keep.has_focus() and keep.get_node_or_null("KeyCap") != null, "confirm %s: Keep going has focus + Space cap" % tag)
	coach.queue_free()
	tgt.queue_free()
	await _frames(2)


func _lock() -> void:
	UI3Theme.set_scale_override(1.0)
	var t := (load("res://scenes/tutorial/Tutorial.tscn") as PackedScene).instantiate()
	add_child(t)
	await _frames(12)
	for _i in 3:
		t.call("_on_cta_pressed")
		await _frames(2)
	_ok(int(t.call("_phase")) == TutorialView.Step.REROLL, "lock: three Got its reach REROLL")
	_ok(not bool(t.call("_allows", "die:0")) and not bool(t.call("_allows", "end_turn")) and not bool(t.call("_allows", "undo")), "lock: REROLL refuses die / end turn / undo")
	_ok(bool(t.call("_allows", "reroll")), "lock: REROLL allows reroll")
	var bands := t.find_children("Dim*", "ColorRect", true, false)
	_ok(bands.size() == 4, "lock: coach bands exist under the view")
	t.queue_free()
	await _frames(2)


func _ready() -> void:
	print("=== t_ui5_tutorial: start ===")
	_guard.capture()
	var aligned: Array = []
	for sc in [1.0, 2.0 / 3.0]:
		get_window().size = Vector2i(1920, 1080) if sc > 0.9 else Vector2i(1280, 720)
		await _frames(3)
		await _coach_pass(sc, aligned)
	var pairs := 0
	for a in aligned:
		pairs += int(a)
	_ok(pairs > 0, "align check measured > 0 pairs (%d)" % pairs)
	await _lock()
	UI3Theme.set_scale_override(-1.0)
	_guard.restore()
	print("=== t_ui5_tutorial: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("t_ui5_tutorial: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
	else:
		for f in _fails:
			print("FAIL: " + f)
		get_tree().quit(1)
