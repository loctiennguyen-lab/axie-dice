extends Node
## UI-05 b1 lane B: the SET preview on the tray uses the ENGINE's numbers (plan review item 3). For every case the card's
## "before → after" must be (int(_face_base) floored at 0) → _live_face_value, the die face must show the same "after" the engine
## deals, and the SetBanner's ×M must be bo_group_m100. Cases: plain SET of 3 / 4 / 5 (README: ×1.3 4 → 6, ×2.2 2 → 5),
## weaken, Crack (out of the SET), anti-spam chain (bonus and repeat), Core set_add (Melting Pot), Overcast (README estimate
## ×2.7 2 → 6, then the real value) and Double Beat (second Overcast on the same SET).
## Run: godot --headless --path godot res://tests/t_set_preview.tscn
var _guard := SaveGuard.new()
var _checks := 0
var _fails: Array[String] = []
var v: Node = null
var c: CombatEngine = null
var units: Array = []


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _face(ft: String, val: int, slot: int) -> Dictionary:
	return {"type": ft, "value": val, "keywords": [], "name": "t", "part": String(V4Ui.SLOT_ORDER[slot])}


## layout[i] = [slot (= part), face type, value] for party die i. Resets per-die state, then snapshots the SET and repaints.
func _setup(layout: Array) -> void:
	for i in units.size():
		var u: Unit = units[i]
		var row: Array = layout[i]
		u.die[int(row[0])] = _face(String(row[1]), int(row[2]), int(row[0]))
		u.set_roll(int(row[0]), false)
		u.cracked = false
		u.overcast = false
		u.held = false
		u.wild_slot = -1
		u.status.erase("weaken")
	c.overcast_used = 0
	c.anchor_turn["oc2"] = []
	c._snap_bo()
	v._rebuild_all()
	await get_tree().process_frame


func _card(i: int) -> DieCard:
	return (v._die_slot_content[i] as Dictionary)["card"]


## Card i shows `before → after`, both straight from the engine, and the die shows `after`.
func _expect(i: int, before: int, after: int, tag: String) -> void:
	var u: Unit = units[i]
	var fi := u.roll_face_index()
	var eb := maxi(0, int(c._face_base(u, fi)))
	var ea: int = c._face_value(u, fi)
	_check(eb == before, "%s: die %d engine before %d, expected %d" % [tag, i, eb, before])
	_check(ea == after and v._live_face_value(u, fi) == after, "%s: die %d engine after %d, expected %d" % [tag, i, ea, after])
	var card := _card(i)
	_check(card.delta_full == SetPreview.delta_text(before, after), "%s: die %d preview '%s', expected '%d → %d'" % [tag, i, card.delta_full, before, after])
	_check(card.set_delta.text != "" and card.set_delta.visible, "%s: die %d shows the preview" % [tag, i])
	_check(card.face_value.text == str(after), "%s: die %d face shows %s, deals %d" % [tag, i, card.face_value.text, after])
	_check(card.set_ring.visible and card.set_key != "", "%s: die %d wears the SET ring" % [tag, i])


func _expect_banner(n: int, m100: int, tag: String) -> void:
	var bl: BoLayer = v._bo_layer
	_check(c.bo.size() == 1 and int(c.bo[0]["size"]) == n, "%s: engine has one SET of %d (%s)" % [tag, n, str(c.bo)])
	if c.bo.is_empty():
		return
	var gm := c.bo_group_m100(c.bo[0])
	_check(gm == m100, "%s: engine group M %d, expected %d" % [tag, gm, m100])
	_check(bl.banners().size() == 1 and bl.banners()[0].key.z == gm, "%s: one SetBanner with the engine M" % tag)
	var labels := bl.group_labels()
	_check(labels.size() == 1 and labels[0] == V4Ui.set_label(n, gm), "%s: banner label %s" % [tag, str(labels)])


func _ready() -> void:
	CombatView.disable_juice_for_tests = true
	_guard.capture()
	RunState.start_new_run(424242, ["plant1", "beast1", "aqua1", "reptile1", "bug1"] as Array[String], "short", 6, false)
	await get_tree().process_frame
	RunState.enter_node("r1_c0", "battle")
	v = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(v)
	for _i in 60:
		await get_tree().process_frame
	v._land_dice_now()
	c = v._combat
	c.relic_ids.clear()
	c.anchor_id = ""
	c.anchor_awakened = false
	c.depth_stage = 3
	units = v._party_dice_units()
	_check(units.size() == 5, "five party dice")
	var others := [[3, "shield", 2], [4, "shield", 3]]

	# A. SET of 3, README ×1.3: 4 → 6 (rounded up).
	await _setup([[1, "dmg", 4], [1, "dmg", 2], [1, "dmg", 3]] + others)
	_expect_banner(3, 130, "set3")
	_expect(0, 4, 6, "set3")
	_expect(1, 2, 3, "set3")
	_expect(2, 3, 4, "set3")
	_check(not _card(3).set_ring.visible and _card(3).set_delta.text == "", "set3: a die outside the SET has no ring and no preview")

	# B. SET of 4, README ×2.2: 2 → 5 (the HTML set-4 numbers 2 → 5, 3 → 7, 4 → 9).
	await _setup([[1, "dmg", 2], [1, "dmg", 3], [1, "dmg", 2], [1, "dmg", 4], [4, "shield", 3]])
	_expect_banner(4, 220, "set4")
	_expect(0, 2, 5, "set4")
	_expect(1, 3, 7, "set4")
	_expect(3, 4, 9, "set4")

	# C. SET of 5 ×2.6.
	await _setup([[2, "dmg", 2], [2, "dmg", 2], [2, "shield", 3], [2, "dmg", 1], [2, "heal", 2]])
	_expect_banner(5, 260, "set5")
	_expect(0, 2, 6, "set5")
	_expect(2, 3, 8, "set5")
	_expect(3, 1, 3, "set5")

	# D. Weaken: the "before" is already weakened (4 - 1 = 3), the SET multiplies that: 3 → 4.
	await _setup([[1, "dmg", 4], [1, "dmg", 2], [1, "dmg", 3]] + others)
	(units[0] as Unit).status["weaken"] = 1
	v._rebuild_all()
	await get_tree().process_frame
	_expect(0, 3, 4, "weaken")

	# E. Crack: a cracked die leaves the SET (four -> three), shows no ring and no preview, keeps its 1/2 chip.
	await _setup([[1, "dmg", 2], [1, "dmg", 3], [1, "dmg", 2], [1, "dmg", 4], [4, "shield", 3]])
	(units[3] as Unit).cracked = true
	c._snap_bo()
	v._rebuild_all()
	await get_tree().process_frame
	_expect_banner(3, 130, "crack")
	var cc := _card(3)
	_check(not cc.set_ring.visible and cc.set_delta.text == "" and cc.mark(&"crack") != null and cc.mark(&"crack").visible,
		"crack: the cracked die is out of the SET (no ring, no preview, 1/2 chip)")
	_check(cc.face_value.text == str(c._face_value(units[3], 1)), "crack: the die shows the halved engine value %s" % cc.face_value.text)
	_expect(1, 3, 4, "crack")

	# F. Anti-spam chain (combat_tune chain.enabled, off by default): a new type after "shield" gets +15 in the M bag; a repeat
	#    of "dmg" gets -10 after the M bag. The preview must follow the engine both ways.
	var chain: Dictionary = ContentDB.combat_tune.get("chain", {})
	var was_on: Variant = chain.get("enabled", false)
	chain["enabled"] = true
	await _setup([[1, "dmg", 10], [1, "dmg", 10], [1, "dmg", 10]] + others)
	c.antispam_turn["chain_last"] = "shield"
	c.antispam_turn["chain_n"] = 0
	v._rebuild_all()
	await get_tree().process_frame
	_expect(0, 10, CombatEngine._mul_up(10, 145), "chain bonus")
	_check(CombatEngine._mul_up(10, 145) == 15, "chain bonus: 10 × 1.45 rounds up to 15")
	c.antispam_turn["chain_last"] = "dmg"
	v._rebuild_all()
	await get_tree().process_frame
	_expect(0, 10, CombatEngine._mul_up(CombatEngine._mul_up(10, 130), 90), "chain repeat")
	_check(CombatEngine._mul_up(CombatEngine._mul_up(10, 130), 90) == 12, "chain repeat: 13 then -10% rounds up to 12")
	chain["enabled"] = was_on
	c.antispam_turn.erase("chain_last")
	c.antispam_turn.erase("chain_n")

	# G. Core set_add (Melting Pot: five different classes, +0.25 on the SET): banner ×1.55, 4 → 7.
	c.relic_ids.append("c_melting_pot")
	await _setup([[1, "dmg", 4], [1, "dmg", 2], [1, "dmg", 3]] + others)
	_expect_banner(3, 155, "core set_add")
	_expect(0, 4, 7, "core set_add")
	c.relic_ids.erase("c_melting_pot")

	# H. Overcast. Before it is pressed the banner tooltip gives the ESTIMATE (README: SET of 4 + 0.5 = ×2.7, 2 → 6), then the
	#    pressed Overcast must land on exactly that, the cards show the mark and the banner shows ×2.7 and OVERCAST.
	await _setup([[1, "dmg", 2], [1, "dmg", 4], [1, "dmg", 2], [1, "dmg", 4], [4, "shield", 3]])
	c.mana = 20
	var g: Dictionary = c.bo[0]
	_check(c.overcast_block_reason(units[0].uid) == "", "overcast: allowed here (%s)" % c.overcast_block_reason(units[0].uid))
	_check(SetPreview.overcast_m100(c, g) == 270 and SetPreview.overcast_estimate(c, g, 2) == 6, "overcast estimate ×2.7: 2 → 6")
	var tip := String(v._bo_group_info(g)["tip"])
	_check(tip.contains("×2.7") and tip.contains(SetPreview.delta_text(2, 6)) and tip.contains("about"), "overcast: banner tooltip gives the estimate: %s" % tip)
	var est4 := SetPreview.overcast_estimate(c, g, 4)
	_check(c.overcast(units[0].uid), "overcast: engine accepts it")
	v._rebuild_all()
	await get_tree().process_frame
	_expect_banner(4, 270, "overcast")
	_expect(0, 2, 6, "overcast")
	_expect(1, 4, est4, "overcast (estimate == real)")
	_check(_card(0).mark(&"overcast") != null and _card(0).mark(&"overcast").visible and _card(2).mark(&"overcast").visible,
		"overcast: every SET member shows OVERCAST")
	_check((v._bo_layer as BoLayer).banners()[0]._oc_mark.visible, "overcast: the SetBanner shows OVERCAST")

	# I. Double Beat (Mana Mine awakened): a second Overcast stacks on the same SET; the estimate before and the real value after.
	await _setup([[1, "dmg", 2], [1, "dmg", 4], [1, "dmg", 2], [1, "dmg", 4], [4, "shield", 3]])
	c.anchor_id = "a_mana_mine"
	c.anchor_awakened = true
	c.mana = 20
	_check(c.overcast(units[0].uid), "double beat: first Overcast")
	v._rebuild_all()
	await get_tree().process_frame
	g = c.bo[0]
	_check(c.overcast_block_reason(units[1].uid) == "", "double beat: second Overcast allowed (%s)" % c.overcast_block_reason(units[1].uid))
	var cap := c.bo_cap100()
	_check(SetPreview.overcast_m100(c, g) == mini(320, cap), "double beat: estimate M %d" % SetPreview.overcast_m100(c, g))
	var est := SetPreview.overcast_estimate(c, g, 4)
	_check(c.overcast(units[1].uid), "double beat: second Overcast")
	v._rebuild_all()
	await get_tree().process_frame
	_expect_banner(4, mini(320, cap), "double beat")
	_expect(1, 4, est, "double beat (estimate == real)")
	_check(est == 12, "double beat: 4 at ×3.0 (capped) = 12, got %d" % est)
	c.anchor_id = ""
	c.anchor_awakened = false

	# One banner system: no node named SetLabel, one SetBanner per SET.
	_check(v.find_children("SetLabel*", "", true, false).is_empty(), "no old SetLabel nodes")

	print("=== t_set_preview: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	v.queue_free()
	await get_tree().process_frame
	_guard.restore()
	CombatView.disable_juice_for_tests = false
	if _fails.is_empty():
		print("t_set_preview: PASS - %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _fails:
		print("t_set_preview: FAIL - %s" % f)
	get_tree().quit(1)
