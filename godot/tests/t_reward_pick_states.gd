extends Node
## UI-05 b1 lane D: reward pick (31-reward--hp / core / ascend / chaos / chaos-confirm) with real offers from the
## generator. Cards are fixed reward_card_w x reward_card_h and their content fits at 1920 and at the 1280 text floor;
## rarity is a filled chip in the art-edge colour; Gain is green and Gamble/Curse red, Gain first; the selected card
## lifts 12; the chaos confirm replaces the Footer with a ConfirmBar (Back focused, Take it the one primary, Back / Esc
## restores); focus chain cards -> Reroll -> Take.
var _guard := SaveGuard.new()
var _checks := 0
var _fails: Array[String] = []
var rm: Node = null


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame


func _sets() -> Dictionary:
	var rng := Rng.new(77)
	var none: Array[Dictionary] = []
	var rost: Array = RunState.roster
	var chaos := RewardGenerator._make_chaos_reward(rng, RunState.owned_relic_ids, none)
	var curse := RewardGenerator._make_curse_reward(none)
	var lvl := RewardGenerator._make_level_reward(rng, rost, none)
	var asc := RewardGenerator._make_ascend_reward(rng, rost, none)
	var hp := RewardGenerator._make_reward("hp", [0, 1], 2, rng, [], rost, none)
	var rr := RewardGenerator._make_reward("reroll", [0, 1], 2, rng, [], rost, none)
	var relics := ["r_bastionplate", "r_ember"].map(func(id: String) -> Dictionary:
		var d = RelicRegistry.get_def(id)
		return {"t": "relic", "key": id, "rar": d.rarity, "title": "RELIC", "desc": d.name, "sub": RewardGenerator.relic_desc(d)})
	var out := {"hp": [hp, rr, lvl], "core": [relics[0], relics[1], relics[0]], "ascend": [asc, hp, rr],
		"chaos": [relics[0], chaos, curse]}
	for k in out:
		out[k] = (out[k] as Array).filter(func(x): return not (x as Dictionary).is_empty())
	return out


func _open(rewards: Array) -> void:
	RunState.pending_rewards.assign(rewards)
	rm.call("_show_reward_overlay", "CHOOSE ONE REWARD")
	await _frames(4)


func _f(n: String) -> Node:
	return rm._overlay_root.find_child(n, true, false)


func _labels_fit(card: Control, tag: String) -> void:
	# Content fits the fixed card: no clipped row, no label spilling out of the card.
	_check(card.get_combined_minimum_size().y <= float(UI3Theme.size_of("reward_card_h")) + 0.5,
		"%s: content fits the card (%.0f)" % [tag, card.get_combined_minimum_size().y])
	var cr := card.get_global_rect().grow(1.0)
	for l in card.find_children("*", "Label", true, false):
		var lab := l as Label
		if lab.is_visible_in_tree() and lab.text != "":
			_check(cr.encloses(lab.get_global_rect()), "%s: label '%s' inside the card" % [tag, lab.text.left(24)])


func _check_state(key: String, rewards: Array) -> void:
	await _open(rewards)
	var cards: Array = rm._reward_cards
	_check(cards.size() == rewards.size(), "%s: %d cards" % [key, rewards.size()])
	_check((_f("Title") as Label).text == "Choose one reward", "%s: title (sentence case)" % key)
	_check(String((_f("ShardChip").find_child("Value", true, false) as Label).text) == UI3.fmt(RunState.shards_this_run), "%s: shard chip" % key)
	for n in ["RewardPick", "CardRow", "Footer", "RerollButton", "TakeButton"]:
		_check(_f(n) != null, "%s: node %s" % [key, n])
	var want := Vector2(UI3Theme.size_of("reward_card_w"), UI3Theme.size_of("reward_card_h"))
	for i in cards.size():
		var c: Control = cards[i]
		var r: Dictionary = rewards[i]
		_check(c.size.is_equal_approx(want), "%s card %d: fixed %s (got %s)" % [key, i, want, c.size])
		var chip: PanelContainer = c.find_child("RarityChip", true, false)
		var art: Panel = c.find_child("RewardArt", true, false)
		_check(chip != null and art != null and c.find_child("Category", true, false) != null and c.find_child("RewardName", true, false) != null,
			"%s card %d: Category / RarityChip / RewardArt / RewardName" % [key, i])
		if chip == null or art == null:
			continue
		var rar: int = rm.call("_reward_rarity", r)
		var col: Color = rm.call("_rarity_color", rar)
		_check((chip.get_theme_stylebox("panel") as StyleBoxFlat).bg_color.is_equal_approx(col)
			and (art.get_theme_stylebox("panel") as StyleBoxFlat).border_color.is_equal_approx(col), "%s card %d: chip fill = art edge = rarity colour" % [key, i])
		_check((chip.find_child("Text", true, false) as Label).text == rm.call("_rarity_name", rar), "%s card %d: rarity word" % [key, i])
		if String(r.get("t", "")) == "relic":
			_check((c.find_child("Category", true, false) as Label).text == "Core", "%s card %d: a relic reads Core" % [key, i])
		_labels_fit(c, "%s card %d" % [key, i])
	# Selected card: cream ring flag + 12 px above the others.
	if cards.size() >= 2:
		rm._select_reward(1)
		await _frames(2)
		var y0: float = (cards[0] as Control).global_position.y
		var y1: float = (cards[1] as Control).global_position.y
		_check(is_equal_approx(y0 - y1, float(UI3Theme.space("12"))) and cards[1].get("selected") and not cards[0].get("selected"),
			"%s: selected card lifts 12 (dy %.1f)" % [key, y0 - y1])
		rm._select_reward(0)
		await _frames(2)
		_check(is_equal_approx((cards[1] as Control).global_position.y - (cards[0] as Control).global_position.y, float(UI3Theme.space("12"))),
			"%s: lift follows the selection" % key)


func _ready() -> void:
	_guard.capture()
	ProjectSettings.set_setting("axie/epoch_source", "local")
	UI3Gacha.instant_override = 1
	RunState.start_new_run_seeded(424242, {"team_keys": ["plant1", "beast1", "aqua1", "reptile1", "bug1"],
		"mode": "short", "ascension": 0, "ranked": false, "rules_on": true})
	await _frames(2)
	rm = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(rm)
	await _frames(8)
	RunState.shards_this_run = 40
	RunState.reward_reroll_charges = 1
	var sets := _sets()
	for key in sets:
		await _check_state(key, sets[key])

	# Footer: "Reroll · 1 left" (icon), Take is the one primary, d_take_min_w wide. Focus chain cards -> Reroll -> Take.
	await _open(sets["hp"])
	var rb: Button = _f("RerollButton")
	var tb: Button = _f("TakeButton")
	_check(rb.text == "Reroll · 1 left" and rb.icon != null and not rb.disabled, "reroll button text + icon")
	_check(tb.theme_type_variation == "ButtonPrimaryL" and tb.size.x >= UI3Theme.size_of("d_take_min_w"), "Take primary L, min width")
	var cards: Array = rm._reward_cards
	var c0: Control = cards[0]
	_check(c0.get_node(c0.focus_next) == cards[1] and (cards[2] as Control).get_node((cards[2] as Control).focus_next) == rb
		and rb.get_node(rb.focus_next) == tb, "focus chain: cards -> Reroll -> Take")
	await _frames(2)
	_check(c0.has_focus(), "first card focused on open")

	# Gain first and green, Gamble / Curse red.
	await _open(sets["chaos"])
	var ch: Control = rm._reward_cards[1]
	var cu: Control = rm._reward_cards[2]
	var gain: Control = ch.find_child("GainBox", true, false)
	var gamble: Control = ch.find_child("GambleBox", true, false)
	var cgain: Control = cu.find_child("GainBox", true, false)
	var curse: Control = cu.find_child("CurseBox", true, false)
	_check(gain != null and gamble != null and cgain != null and curse != null, "chaos: Gain + Gamble, curse: Gain + Curse")
	if gain != null and gamble != null and cgain != null and curse != null:
		_check(gain.get_index() < gamble.get_index() and cgain.get_index() < curse.get_index(), "Gain always first")
		_check((gain.get_theme_stylebox("panel") as StyleBoxFlat).bg_color.is_equal_approx(UI3Theme.color("success_bg"))
			and (gamble.get_theme_stylebox("panel") as StyleBoxFlat).bg_color.is_equal_approx(UI3Theme.color("danger_bg"))
			and (curse.get_theme_stylebox("panel") as StyleBoxFlat).bg_color.is_equal_approx(UI3Theme.color("danger_bg")), "Gain green, Gamble / Curse red")
		_check((gain.find_child("TradeLabel", true, false) as Label).get_theme_color("font_color").is_equal_approx(UI3Theme.color("success_text"))
			and (gamble.find_child("TradeLabel", true, false) as Label).text == "Gamble" and (curse.find_child("TradeLabel", true, false) as Label).text == "Curse",
			"trade labels are words in their colour")
		_check(String((gain.find_child("TradeText", true, false) as Label).text) != "", "gain text comes from the generator")

	# Chaos confirm: the bar replaces the Footer; Back focused; Take it the one primary; Back and Esc restore.
	var reroll_before := RunState.bonus_reroll
	var n_before := RunState.pending_rewards.size()
	rm._select_reward(1)
	rm._take_selected_reward()
	await _frames(3)
	var bar: Control = _f("ConfirmBar")
	_check(bar != null and not (_f("Footer") as Control).visible, "confirm bar replaces the footer")
	if bar != null:
		var back: Button = bar.find_child("BackButton", true, false)
		var take_it: Button = bar.find_child("TakeItButton", true, false)
		_check(back.has_focus(), "Back has focus")
		_check(take_it.theme_type_variation == "ButtonPrimaryL" and back.theme_type_variation == "ButtonSecondary", "Take it is the one primary")
		_check((bar.find_child("Question", true, false) as Label).text == "This lasts the whole run. Take it?", "confirm question")
		_check(RunState.pending_rewards.size() == n_before and RunState.bonus_reroll == reroll_before, "nothing applied before confirm")
		_labels_fit(rm._reward_cards[1], "chaos-confirm")
		back.pressed.emit()
		await _frames(2)
		_check(_f("ConfirmBar") == null and (_f("Footer") as Control).visible, "Back restores the footer")
		_check((rm._reward_cards[1] as Control).has_focus(), "Back puts focus on the picked card")
		rm._take_selected_reward()
		await _frames(3)
		var esc := InputEventAction.new()
		esc.action = "ui_cancel"
		esc.pressed = true
		(_f("ConfirmBar") as Node).call("_unhandled_key_input", esc)
		await _frames(2)
		_check(_f("ConfirmBar") == null and (_f("Footer") as Control).visible, "Esc on the bar = Back")

	# A real Core offer (gacha tiers, axis / partner chips, per-card Reroll) fits the same fixed card, and the tier word
	# is the RarityChip. Checked at 1920 and at the 1280 text floor.
	for sc in [1.0, 2.0 / 3.0]:
		UI3Theme.set_scale_override(sc)
		for seed in [13, 14, 21]:
			RunState._core_offer_active = true
			await _open(CoreOffer.build_offer(Rng.new(seed), 2, RunState._core_ctx(), 3))
			for i in rm._reward_cards.size():
				var cc: Control = rm._reward_cards[i]
				var tier := clampi(int((RunState.pending_rewards[i] as Dictionary).get("tier", 0)), 0, 2)
				_check((cc.find_child("RarityChip", true, false).find_child("Text", true, false) as Label).text == ["Moss", "Amber", "Crystal"][tier],
					"core offer %d card %d: tier word in the RarityChip" % [seed, i])
				_check(cc.find_child("CardReroll%d" % i, true, false) != null, "core offer %d card %d: own Reroll" % [seed, i])
				_labels_fit(cc, "core offer %d card %d @%.2f" % [seed, i, sc])
			_check((_f("Title") as Label).text == "Choose a Core", "core offer title")
		RunState._core_offer_active = false
	UI3Theme.set_scale_override(-1.0)

	# 1280 text floor: every card state still fits its fixed card (no clipped row).
	UI3Theme.set_scale_override(2.0 / 3.0)
	for key in sets:
		await _open(sets[key])
		for i in rm._reward_cards.size():
			_labels_fit(rm._reward_cards[i], "1280 %s card %d" % [key, i])
		var body := (rm._reward_cards[0] as Node).find_child("RewardName", true, false) as Label
		_check(body.get_theme_font_size("font_size") * (2.0 / 3.0) >= 14.0 - 0.01, "1280: name text >= 14 real px")
	await _open(sets["chaos"])
	rm._select_reward(1)
	rm._take_selected_reward()
	await _frames(3)
	var bar2: Control = _f("ConfirmBar")
	_check(bar2 != null and bar2.get_global_rect().end.x <= 1920.0 and bar2.get_global_rect().position.x >= 0.0, "1280: confirm bar inside the canvas")
	UI3Theme.set_scale_override(-1.0)

	RunState.pending_rewards.assign([])
	rm.queue_free()
	UI3Gacha.instant_override = -1
	_guard.restore()
	print("=== t_reward_pick_states: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("t_reward_pick_states: PASS")
		get_tree().quit(0)
	else:
		for f in _fails:
			print("t_reward_pick_states: FAIL - " + f)
		get_tree().quit(1)
