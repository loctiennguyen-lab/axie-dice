extends Node
## UI-06 L0 shared kit gate: UI6Assets returns a texture for every key, Chipify splits like the design regex,
## TagBadges follows Liam's tag rule, CoreHeadline covers every real Core / Run Rule within 24 characters,
## CoreVisuals is what CorePanel aliases, AwakenProgress reads the Anchor state. No network, no save access.

var _failures: Array[String] = []
var _checks := 0
var _guard := SaveGuard.new()


func _ready() -> void:
	print("=== t_ui6_kit: start ===")
	_guard.capture()
	await get_tree().process_frame
	_assets()
	_chipify()
	_badges()
	_headlines()
	_visuals()
	_awaken()
	_shells()
	AnchorAdapter.test_state = null
	_guard.restore()
	print("=== t_ui6_kit: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_ui6_kit: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_ui6_kit: FAIL — %s" % f)
	get_tree().quit(1)


func _ok(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)


func _assets() -> void:
	for px in [32, 64, 128]:
		for a in UI6Assets.FAMILIES:
			_ok(UI6Assets.family(a, px) != null, "family %s %d" % [a, px])
		for t in UI6Assets.BADGE_TAGS:
			_ok(UI6Assets.badge(t, px) != null, "badge %s %d" % [t, px])
		for h in UI6Assets.HOUSES:
			_ok(UI6Assets.house("h_" + h, px) != null and UI6Assets.house(h, px) != null, "house %s %d" % [h, px])
		for k in UI6Assets.NODE_KINDS:
			_ok(UI6Assets.node(k, px) != null, "node %s %d" % [k, px])
		for f in UI6Assets.FX:
			_ok(UI6Assets.fx(f, px) != null, "fx %s" % f)
		_ok(UI6Assets.awaken(px) != null, "awaken %d" % px)
		for t in 3:
			_ok(UI6Assets.shard(t, px) != null and UI6Assets.shards(t, px) != null and UI6Assets.slot(t, px) != null, "tier icons %d/%d" % [t, px])
		_ok(UI6Assets.slot(-1, px) != null, "slot_empty")
	for t in 3:
		_ok(UI6Assets.frame(t) != null and UI6Assets.artwin(t) != null and UI6Assets.crest(t) != null and UI6Assets.back_art(t) != null, "tier art %d" % t)
		_ok(UI6Assets.ninepatch_margins("frame_core_" + UI6Assets.tier_key(t)).x > 0, "margins frame %d" % t)
		_ok(UI6Assets.ninepatch_margins("artwin_" + UI6Assets.tier_key(t)).x > 0, "margins artwin %d" % t)
	_ok(UI6Assets.frame_run_rule() != null and UI6Assets.fx("rays_crystal") != null, "run rule frame / rays")
	for n in UI6Assets.ILLUSTRATIONS:
		_ok(UI6Assets.illustration(n) != null and UI6Assets.illustration(n, true) != null, "illustration %s" % n)
	for r in 5:
		_ok(UI6Assets.relic_rarity(r) != null and UI6Assets.relic_rarity(r, true) != null, "relic_r%d" % r)
	_ok(UI6Assets.badge("meme") == null, "meme has no badge picture")


func _join(segs: Array) -> String:
	var s := ""
	for x in segs:
		s += String(x["text"])
	return s


func _chips(text: String, kind: String) -> Array:
	var out: Array = []
	for x in Chipify.segments(text):
		if x["kind"] == kind:
			out.append(x["text"])
	return out


func _chipify() -> void:
	var t := "Start of combat: front-row Axies gain 5 Shield."
	_ok(_chips(t, Chipify.KIND_NUM) == ["5 Shield"], "5 Shield chip: %s" % str(_chips(t, Chipify.KIND_NUM)))
	_ok(_join(Chipify.segments(t)) == t, "segments join back")
	_ok(_chips("+1 Mana at the start of every turn.", Chipify.KIND_NUM) == ["+1 Mana"], "+1 Mana")
	_ok(_chips("Held 2 turns: hits all", Chipify.KIND_KW) == ["Held"] and _chips("Held 2 turns: hits all", Chipify.KIND_NUM) == ["2"], "Held + bare 2")
	_ok(_chips("Dice in a SET get +2", Chipify.KIND_KW) == ["SET"] and _chips("Dice in a SET get +2", Chipify.KIND_NUM) == ["+2"], "SET kw, +2 num")
	_ok(_chips("Cheaper Wild Face and Temp Face", Chipify.KIND_KW) == ["Wild Face", "Temp Face"], "two-word keywords")
	_ok(_chips("Heal, poison +50% and 10 Max HP", Chipify.KIND_NUM) == ["+50%", "10 Max HP"], "percent and Max HP: %s" % str(_chips("Heal, poison +50% and 10 Max HP", Chipify.KIND_NUM)))
	_ok(_chips("Draw one more at the end of turn 4.", Chipify.KIND_NUM) == ["4"], "number at sentence end: turn 4.")
	_ok(_chips("Thorns scale by +0.60.", Chipify.KIND_NUM) == ["+0.60"], "+0.60. keeps the whole number: %s" % str(_chips("Thorns scale by +0.60.", Chipify.KIND_NUM)))
	_ok(_chips("Deal 3 damage, then 4.", Chipify.KIND_NUM) == ["3 damage", "4"], "3 damage, then 4.: %s" % str(_chips("Deal 3 damage, then 4.", Chipify.KIND_NUM)))
	_ok(_chips("Roll 1-2 dice", Chipify.KIND_NUM) == ["1", "2"], "1-2 is two numbers, the hyphen is not a minus: %s" % str(_chips("Roll 1-2 dice", Chipify.KIND_NUM)))
	_ok(_chips("Lose -3 HP", Chipify.KIND_NUM) == ["-3 HP"], "real minus stays")
	_ok(_chips("Holder of Settings", Chipify.KIND_KW).is_empty(), "no keyword inside a word")
	_ok(Chipify.bbcode("a [b] 3").find("[lb]") >= 0 and Chipify.bbcode("x 3 Mana").find("bgcolor") >= 0, "bbcode escapes [ and chips numbers")
	_ok(Chipify.bbcode("plain words") == "plain words", "plain text untouched")
	_ok(_join(Chipify.segments("")) == "", "empty text")


func _badges() -> void:
	_ok(TagBadges.pick(["nonattack"]) == [], "nonattack hidden")
	_ok(TagBadges.pick(["meme", "nonattack"]) == [], "meme no badge")
	_ok(TagBadges.pick(["attack", "front", "tradeoff"]) == ["tradeoff", "attack", "front"], "tradeoff first")
	_ok(TagBadges.pick(["attack", "convert_to_dmg", "front", "egg"]) == ["attack", "convert_to_dmg", "front"], "max 3, drop the last")
	_ok(TagBadges.pick(["egg", "tradeoff", "front", "attack"]) == ["tradeoff", "egg", "front"], "tradeoff + data order, capped")
	_ok(TagBadges.pick(PackedStringArray(["front"])) == ["front"], "PackedStringArray input")
	var row := TagBadges.row(["tradeoff", "attack", "nonattack"], "stat")
	_ok(row.get_child_count() == 3 and row.get_child(0).name == "FamilyChip" and row.get_child(1).get_meta("tag") == "tradeoff", "BadgeRow = family chip + badges")
	row.free()


func _headlines() -> void:
	var all := CoreHeadline.all()
	_ok(all.size() == 84, "84 headlines (67 Cores + 17 Rules), got %d" % all.size())
	for id in all:
		var h := String(all[id])
		_ok(h.length() <= CoreHeadline.MAX_LEN, "%s headline is %d chars (max 24): %s" % [id, h.length(), h])
		_ok(h.strip_edges() == h and h != "", "%s headline empty or padded" % id)
	var real := {}
	for raw in RelicRegistry.all_defs_sorted():
		var d: RelicDef = raw
		if String(d.core_axis) != "" and not d.disabled and String(d.id) != "rule_none":
			real[String(d.id)] = true
			_ok(CoreHeadline.has(String(d.id)), "%s has no headline" % d.id)
	_ok(real.size() >= 70, "only %d real Cores/Rules found" % real.size())
	for id in all:
		# Disabled (cut) Cores keep their headline for when they come back, so only resolvability is required.
		_ok(RelicRegistry.get_def(String(id)) != null, "headline %s names no Core/Rule" % id)
	var l := Label.new()
	_ok(not CoreHeadline.apply(l, "no_such_core") and not l.visible, "unknown id hides the label")
	_ok(CoreHeadline.apply(l, "c_dewdrop") and l.visible and l.text != "", "known id shows")
	l.free()


func _visuals() -> void:
	_ok(CorePanel.AXIS_ICON == CoreVisuals.AXIS_ICON and CorePanel.TIER_NAME == CoreVisuals.TIER_NAME, "CorePanel aliases")
	_ok(CorePanel.word_chip("x", "", Color.WHITE, "C").name == "C", "CorePanel.word_chip still works")
	var c := CoreVisuals.family_chip("mana")
	_ok(c.name == "FamilyChip", "family chip name")
	c.free()
	_ok(CoreVisuals.tier_color(1) == UI3Theme.color("tier_amber") and CoreVisuals.tier_name(2) == "Crystal", "tier helpers")


func _awaken() -> void:
	var cores := Anchors.get_def("a_volley").get("house_cores", []) as Array
	_ok(cores.size() >= 2, "a_volley has house cores")
	if cores.size() < 2:
		return
	AnchorAdapter.test_state = {"anchor_id": "a_volley", "owned": [cores[0]], "awakened": false}
	_ok(AwakenProgress.count() == 1 and AwakenProgress.text() == "1/2", "count 1/2")
	var tag := AwakenProgress.house_tag(String(cores[1]))
	_ok(tag != null and tag.get_meta("state") == "awakens", "second house core awakens")
	if tag != null:
		tag.free()
	AnchorAdapter.test_state = {"anchor_id": "a_volley", "owned": [], "awakened": false}
	tag = AwakenProgress.house_tag(String(cores[0]))
	_ok(tag != null and tag.get_meta("state") == "plus_one", "first house core is +1")
	if tag != null:
		tag.free()
	_ok(AwakenProgress.house_tag("c_dewdrop") == null, "non house core has no tag")
	var chip := AwakenProgress.chip()
	_ok(chip != null and int(chip.get_meta("n")) == 0 and chip.find_child("Count", true, false) != null, "chip 0/2")
	if chip != null:
		chip.free()
	AnchorAdapter.test_state = {"anchor_id": "a_volley", "owned": cores.slice(0, 2), "awakened": true}
	_ok(AwakenProgress.house_tag(String(cores[0])) == null, "no tag once awakened")
	chip = AwakenProgress.chip()
	_ok(chip != null and int(chip.get_meta("n")) == 2, "awakened chip 2/2")
	if chip != null:
		chip.free()
	AnchorAdapter.test_state = {"anchor_id": "", "owned": [], "awakened": false}
	_ok(AwakenProgress.chip() == null, "no anchor, no chip")


func _shells() -> void:
	for sc in [1.0, 2.0 / 3.0]:
		UI3Theme.set_scale_override(sc)
		var tag := "@%.2f " % sc
		for t in 3:
			var card := CoreCardShell.new().setup(t, ["stat", "dice", "pos"][t])
			add_child(card)
			card.size = card.custom_minimum_size
			for nm in ["TierFrame", "TierCrest", "Content", "Body", "ArtWindow", "ArtWindowFrame", "FamilyEmblem"]:
				_ok(card.find_child(nm, true, false) != null, "%sCoreCardShell tier %d lacks %s" % [tag, t, nm])
			_ok(card.body != null and card.art_window != null and card.crest != null and card.frame != null, tag + "shell fields set")
			_ok(card.custom_minimum_size == Vector2(UI3Theme.size_of("core_card_w"), UI3Theme.size_of("core_card_h")), tag + "shell size is the token size")
			var f := card.find_child("TierFrame", true, false) as NinePatchRect
			_ok(f != null and f.texture != null and f.patch_margin_left + f.patch_margin_right < card.size.x - 24.0, tag + "frame margins leave a centre")
			_ok(card.crest.position.y < 0.0 and absf(card.crest.position.x + card.crest.size.x * 0.5 - card.size.x * 0.5) < 1.0, tag + "crest centred on the top edge")
			var back := CardBack.new().setup(t)
			add_child(back)
			for nm in ["TierFrame", "TierCrest", "Content", "BackArt", "TierWord"]:
				_ok(back.find_child(nm, true, false) != null, "%sCardBack tier %d lacks %s" % [tag, t, nm])
			card.queue_free()
			back.queue_free()
		var rule := CoreCardShell.new().setup(0, "", true)
		_ok(rule.name == "RuleCard" and rule.crest == null and rule.art_window == null and rule.find_child("TierFrame", true, false) != null, tag + "rule shell: plaque, no crest, no art window")
		_ok(rule.custom_minimum_size.x == float(UI3Theme.size_of("rule_card_w")), tag + "rule shell uses rule_card_w")
		rule.free()
	UI3Theme.set_scale_override(-1.0)
