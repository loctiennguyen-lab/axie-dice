extends Node
## Aid zone (UI-03 screen 39): hidden in Mission runs and for newcomers; never opens the confirm when the
## Gem balance is short (row / offer button stays disabled with "Need n more Gem"); opens it when it can pay.

var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _roster() -> Array:
	var keys := ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	var out: Array = []
	for i in keys.size():
		out.append({"persistent_id": i + 1, "hero_key": keys[i], "tier": 1,
			"max_hp": ContentDB.heroes[keys[i]]["max_hp"], "muts": [], "growth": {}, "bonus_hp": 0})
	return out


func _ready() -> void:
	_guard.capture()
	CombatView.disable_juice_for_tests = true
	MetaState.runs_with_battle = 99
	RunState.pending_combat = {"node_id": "aid_node", "kind": "battle", "pw": 4, "ascension": 0,
		"roster_snapshot": _roster(), "relic_ids": [], "combat_seed": 77}
	var view: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	add_child(view)
	for _i in 5:
		await get_tree().process_frame

	# Mission run: the whole zone is gone.
	view._combat.mission = false
	view._update_aid({"newcomer": false}, true)
	_check(view._aid.enabled, "normal run shows the Aid zone")
	view._combat.mission = true
	view._update_aid({"newcomer": false}, true)
	_check(not view._aid.enabled and not view._aid.visible, "Mission run hides the Aid zone")
	view._combat.mission = false
	view._update_aid({"newcomer": true}, true)
	_check(not view._aid.enabled, "newcomer hides the Aid zone")

	# Panel in isolation: short of Gem vs able to pay.
	var panel := AidPanel.new()
	add_child(panel)
	var row := {"id": "extra_reroll", "title": "Extra reroll", "price": 15, "cap_text": "Used 0 of 4 this run",
		"enabled": true, "reason": "", "gems": 5}
	panel.set_state({"enabled": true, "used": 0, "cap": 6, "rows": [row], "offer": {"id": "extra_reroll",
		"title": "Extra reroll", "what": "+1 reroll.", "price": 15, "caps": [], "gems": 5}})
	var btn := panel.find_child("AidRow_extra_reroll", true, false) as Button
	_check(btn != null and btn.disabled, "short of Gem: the row is disabled")
	var buy := panel.find_child("AidBuyButton", true, false) as Button
	_check(buy != null and buy.disabled and buy.text.find("Need 10 more Gem") != -1, "short of Gem: offer button says Need 10 more Gem")
	await get_tree().process_frame
	await get_tree().process_frame
	var card := panel.find_child("AidOffer", true, false) as Control
	var chip := buy.find_child("CostChip", true, false) as Control
	_check(chip != null and chip.visible and (chip.find_child("Amount", true, false) as Label).text == "15", "short of Gem: the real price stays on the Buy chip")
	_check(card.get_global_rect().encloses(buy.get_global_rect()), "short of Gem: Buy %s stays inside the offer card %s" % [buy.get_global_rect(), card.get_global_rect()])
	var no := panel.find_child("AidNotNow", true, false) as Control
	_check(no != null and absf(no.size.y - buy.size.y) < 0.5, "Not now is as tall as Buy (trust rule)")
	_check(Ui5Keycap.all_under(panel).is_empty(), "no key cap in the Aid zone (UI-05: only Space is shown)")
	panel._ask("extra_reroll")
	_check(not panel.modal_open(), "short of Gem: the confirm never opens")
	row["gems"] = 50
	panel.set_state({"enabled": true, "used": 0, "cap": 6, "rows": [row]})
	btn = panel.find_child("AidRow_extra_reroll", true, false) as Button
	_check(btn != null and not btn.disabled, "enough Gem: the row is enabled")
	panel._ask("extra_reroll")
	_check(panel.modal_open(), "enough Gem: the confirm opens")

	_guard.restore()
	if _fails.is_empty():
		print("t_aid_zone: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
	else:
		for f in _fails:
			print("t_aid_zone: FAIL — %s" % f)
		get_tree().quit(1)
