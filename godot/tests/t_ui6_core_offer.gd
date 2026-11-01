extends Node
## UI-06 L1: Core offer (47) + Run rule offer (05) on the new shells. Names from the frame, 1920 + 1280, text >= 14 real px,
## alignment, Liam's rules (nothing preselected, disabled Take says why, only the Space keycap).
const Align := preload("res://tests/ui5_align_check.gd")
var _guard := SaveGuard.new()
var _fails := 0
var _n := 0


func _ok(c: bool, m: String) -> void:
	_n += 1
	if not c:
		_fails += 1
		print("FAIL: ", m)


func _ready() -> void:
	_guard.capture()
	ProjectSettings.set_setting("axie/epoch_source", "local")
	for sc in [1.0, 2.0 / 3.0]:
		await _pass(sc)
	_guard.restore()
	print("=== t_ui6_core_offer: %d checks, %d failure(s) ===" % [_n, _fails])
	get_tree().quit(1 if _fails > 0 else 0)


func _pass(sc: float) -> void:
	UI3Theme.set_scale_override(sc)
	UI3Gacha.instant_override = 1
	RunState.start_new_run_seeded(424242, {"team_keys": ["plant1", "beast1", "aqua1", "reptile1", "bug1"],
		"mode": "short", "ascension": 0, "ranked": false, "rules_on": false})
	var rm: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(rm)
	for i in 8:
		await get_tree().process_frame
	var cards: Array = []
	for i in 3:
		cards.append({"t": "relic", "key": "x%d" % i, "rar": 0, "title": "CORE", "desc": "Core %d" % i,
			"sub": "Start of combat: gain 5 Shield for 2 turns.", "core": true, "axis": ["pos", "stat", "dice"][i], "tier": i, "slot": i})
	RunState._core_offer_active = true
	RunState.core_reroll_left = 2
	RunState.pending_rewards.assign(cards)
	rm._show_reward_overlay("x")
	for i in 12:
		await get_tree().process_frame
	var root: Node = rm._overlay_root
	var tag := "@%.2f" % sc
	for n in ["CoreOffer", "Header", "Title", "TierLadder", "ShardPill", "CardRow", "Footer", "RerollCounter", "TakeButton"]:
		_ok(root.find_child(n, true, false) != null, "%s: %s" % [tag, n])
	for c in rm._reward_cards:
		for n in ["TierFrame", "TierCrest", "ArtWindow", "FamilyEmblem", "CoreName", "Headline", "Detail", "BadgeRow", "RerollButton"]:
			_ok(c.find_child(n, true, false) != null, "%s: card %s" % [tag, n])
		_ok(c.find_child("TierChip", true, false) == null, "%s: no tier chip" % tag)
		_ok(not bool(c.get("selected")), "%s: not preselected" % tag)
	var tb := root.find_child("TakeButton", true, false) as Button
	_ok(tb.disabled and tb.text == "Pick a Core" and tb.get_node_or_null("KeyCap") == null, "%s: Take off, says why, no keycap" % tag)
	rm._select_reward(1)
	await get_tree().process_frame
	_ok(not tb.disabled and tb.get_node_or_null("KeyCap") != null, "%s: pick turns Take on with a keycap" % tag)
	for lab in root.find_children("*", "Label", true, false):
		if (lab as Label).is_visible_in_tree() and (lab as Label).text != "":
			_ok(float((lab as Label).get_theme_font_size("font_size")) * sc >= 13.99, "%s: '%s' >= 14 real px" % [tag, (lab as Label).text.left(20)])
	for d in root.find_children("Detail", "RichTextLabel", true, false):
		_ok(float((d as RichTextLabel).get_theme_font_size("normal_font_size")) * sc >= 13.99, "%s: Detail >= 14 real px" % tag)
	_ok(Align.pairs(root) > 0, "%s: align measured pairs" % tag)
	var al: Array[String] = Align.check(root, 1.5, tag)
	_ok(al.is_empty(), "%s: aligned %s" % [tag, str(al.slice(0, 4))])
	rm.queue_free()
	await get_tree().process_frame
	UI3Gacha.instant_override = -1
