extends Node
## UI-05 b23 lane S9b: Echo Box ceremony against 20-echo--opening / reveal-* / open10. Node names, one reveal per tier,
## Open 10 grid, 1920 + 1280 inside the frame, align check > 0 pairs, real text >= 14 px, initial focus (Done),
## Skip by a real Space, Equip now writes MetaState, no illustrative strings.
const Align := preload("res://tests/ui5_align_check.gd")
var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0
var _pairs := 0


func _ok(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_fails.append(m)


func _frames(n := 6) -> void:
	for _i in n:
		await get_tree().process_frame


func _ready() -> void:
	print("=== t_ui5_echo_ceremony: start ===")
	_guard.capture()
	for sc in [1.0, 2.0 / 3.0]:
		UI3Theme.set_scale_override(sc)
		await _pass(sc)
	UI3Theme.set_scale_override(1.0)
	_guard.restore()
	_ok(_pairs > 0, "align check measured > 0 pairs (%d)" % _pairs)
	print("=== t_ui5_echo_ceremony: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("t_ui5_echo_ceremony: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
	else:
		for f in _fails:
			print("FAIL: " + f)
		get_tree().quit(1)


func _screen(instant: bool) -> EchoBoxScreen:
	var s: EchoBoxScreen = load("res://scenes/echobox/EchoBoxScreen.tscn").instantiate()
	s.use_account = false
	s.remote_on = true
	s.no_scene_change = true
	s.instant = instant
	add_child(s)
	return s


func _cos(rarity: String, dup := false) -> Dictionary:
	var box: Dictionary = ((EchoBox._cfg().get("boxes", {}) as Dictionary).get("normal", {})) as Dictionary
	var best := ""
	for id in EchoBox.pool_ids(box, rarity):
		var a := Cosmetics.art_id(String(id))
		if a != "" and Cosmetics.slot_of(a) == Cosmetics.SLOT_DIE and CosmeticTile.any_name(String(id)) != "":
			best = String(id)
			break
	return {"ok": true, "kind": "cosmetic", "item": best, "rarity": rarity, "duplicate": dup, "fragments": 3 if dup else 0}


func _inside(s: Node, tag: String) -> void:
	var vp := Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size)
	for n in s.find_children("*", "Control", true, false):
		var c := n as Control
		if c.is_visible_in_tree() and c is Label and c.text != "":
			_ok(vp.encloses(c.get_global_rect().grow(-1.0)), "%s: %s inside the frame" % [tag, c.name])


func _small(root: Node, tag: String, sc: float) -> void:
	for n in root.find_children("*", "", true, false):
		if (n is Label or n is Button) and (n as Control).is_visible_in_tree() and String(n.text) != "":
			_ok(float(n.get_theme_font_size("font_size")) * sc >= 13.99, "%s: %s text >= 14 real px" % [tag, n.name])


func _pass(sc: float) -> void:
	var tag := "scale %.2f" % sc
	MetaState.tickets = {"normal": 30, "season": 0}
	MetaState.echobox_pity = {}
	# --- opening (not instant): SkipButton + KeyCap, Space skips for real
	var s := _screen(false)
	await _frames()
	var stone := {"ok": true, "kind": "stone", "amount": 500, "rarity": "", "item": "", "duplicate": false, "fragments": 0}
	s.pull_hook = func(_n: int) -> Array: return [stone]
	var done_flag := [false]
	(func() -> void:
		await s.pull(1)
		done_flag[0] = true).call()
	await _frames()
	for n in ["Scrim", "Ceremony", "Title", "ChestWord", "Footer", "SkipButton", "KeyCap"]:
		_ok(s.find_child(n, true, false) != null, "%s: opening node %s" % [tag, n])
	_ok((s.find_child("Ceremony", true, false).find_child("Title", true, false) as Label).text.begins_with("Opening"), "%s: title Opening" % tag)
	var sk := s.find_child("SkipButton", true, false) as Button
	_ok(sk != null and sk.has_focus(), "%s: SkipButton has focus" % tag)
	_inside(s, tag + " opening")
	_small(s.find_child("Ceremony", true, false), tag + " opening", sc)
	var ev := InputEventKey.new()
	ev.keycode = KEY_SPACE
	ev.physical_keycode = KEY_SPACE
	ev.pressed = true
	get_viewport().push_input(ev)
	await _frames(8)
	_ok(done_flag[0], "%s: Space skipped the opening" % tag)
	_ok(s.find_child("SkipButton", true, false) == null and s.find_child("RevealCard", true, false) != null, "%s: reveal replaced opening" % tag)
	_ok(not (s.find_child("Ceremony", true, false).find_child("Title", true, false) as Label).text.begins_with("Opening"), "%s: title Reveal" % tag)
	s.queue_free()
	await _frames(2)
	# --- reveal per tier (instant) + stone + duplicate
	var cases: Array = [["stone", stone], ["common", _cos("common")], ["rare", _cos("rare")], ["epic", _cos("epic")],
		["legendary", _cos("legendary")], ["mythic", _cos("mythic")], ["dup", _cos("rare", true)]]
	for cs in cases:
		var name_: String = cs[0]
		var res: Dictionary = cs[1]
		if String(res.get("kind")) == "cosmetic" and String(res.get("item")) == "":
			continue   # no cosmetic of that rarity in the manifest
		var sc_ := _screen(true)
		await _frames()
		sc_.pull_hook = func(_n: int) -> Array: return [res]
		await sc_.pull(1)
		await _frames()
		var t2 := "%s %s" % [tag, name_]
		for n in ["Ceremony", "Title", "RevealCard", "TierStrip", "Art", "Name", "Line", "Footer", "OpenAgainButton", "DoneButton", "KeyCap", "CostChip"]:
			_ok(sc_.find_child(n, true, false) != null, "%s: node %s" % [t2, n])
		var card := sc_.find_child("RevealCard", true, false) as Control
		var tier := Parts_tier(res)
		_ok(int(card.get_meta("tier")) == tier, "%s: card tier" % t2)
		var strip := sc_.find_child("TierStrip", true, false) as ColorRect
		_ok(strip.color.is_equal_approx(DiceSkin.tier_color(tier)), "%s: strip is the tier token colour" % t2)
		var nm := sc_.find_child("Name", true, false) as Label
		if String(res.get("kind")) == "cosmetic":
			_ok(Ui5Ellipsis.full_text(nm) == CosmeticTile.any_name(String(res["item"])), "%s: name from manifest" % t2)
			_ok(sc_.find_child("EquipButton", true, false) != null or bool(res.get("duplicate")), "%s: equip on a new cosmetic" % t2)
			_ok((sc_.find_child("NewChip", true, false) != null) != bool(res.get("duplicate")), "%s: New chip xor dup badge" % t2)
			_ok((sc_.find_child("FragmentBadge", true, false) != null) == bool(res.get("duplicate")), "%s: FragmentBadge on dup" % t2)
			_ok((sc_.find_child("RaysProposal", true, false) != null) == (tier >= 2), "%s: rays on Rare+" % t2)
			_ok(((card as PanelContainer).get_theme_stylebox("panel") as StyleBoxFlat).border_width_left == (3 if tier >= 3 else 2), "%s: epic+ 3 px border" % t2)
		else:
			_ok(sc_.find_child("StoneIcon", true, false) != null and sc_.find_child("EquipButton", true, false) == null, "%s: stone art, no equip" % t2)
		var dn := sc_.find_child("DoneButton", true, false) as Button
		_ok(dn.has_focus(), "%s: initial focus on DoneButton" % t2)
		_ok(dn.theme_type_variation == "ButtonPrimary" or dn.theme_type_variation.begins_with("ButtonPrimary"), "%s: Done is the primary" % t2)
		_inside(sc_, t2)
		_small(sc_.find_child("Ceremony", true, false), t2, sc)
		_pairs += Align.pairs(sc_.find_child("Ceremony", true, false))
		var prob := Align.check(sc_.find_child("Ceremony", true, false), 1.5, t2)
		_ok(prob.is_empty(), "%s: align %s" % [t2, str(prob)])
		if name_ == "common" or name_ == "rare":
			# equip now writes MetaState
			var eq := sc_.find_child("EquipButton", true, false) as Button
			if eq != null:
				eq.pressed.emit()
				_ok(eq.disabled and (eq.text == "Equipped" or eq.text == "Couldn't equip"), "%s: Equip now pressed" % t2)
				var art_id := Cosmetics.art_id(String(res["item"]))
				_ok((MetaState.equipped_die_skin == art_id) == (eq.text == "Equipped"), "%s: Equip now result matches MetaState" % t2)
		sc_.queue_free()
		await _frames(2)
	# --- open 10 grid
	var ten: Array = []
	for i in 10:
		ten.append(stone if i % 3 == 0 else _cos("common"))
	var s10 := _screen(true)
	await _frames()
	s10.pull_hook = func(_n: int) -> Array: return ten
	await s10.pull(10)
	await _frames()
	var t10 := tag + " open10"
	_ok(s10.find_child("RevealGrid", true, false) != null and s10.find_child("RevealGrid", true, false).get_child_count() == 10, "%s: grid of 10 cards" % t10)
	_ok((s10.find_child("Ceremony", true, false).find_child("Title", true, false) as Label).text == "Open 10", "%s: title Open 10" % t10)
	_ok(s10.find_child("EquipButton", true, false) == null, "%s: no equip in the grid" % t10)
	_inside(s10, t10)
	_small(s10.find_child("Ceremony", true, false), t10, sc)
	var g := s10.find_child("RevealGrid", true, false) as Control
	_ok(Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size).encloses(g.get_global_rect()), "%s: grid inside the frame" % t10)
	_pairs += Align.pairs(s10.find_child("Ceremony", true, false))
	_ok((s10.find_child("DoneButton", true, false) as Button).has_focus(), "%s: focus on Done" % t10)
	(s10.find_child("DoneButton", true, false) as Button).pressed.emit()
	await _frames()
	_ok(s10.find_child("Ceremony", true, false) == null, "%s: Done closes" % t10)
	s10.queue_free()
	await _frames(2)
	# no illustrative strings from the HTML
	var src := FileAccess.get_file_as_string("res://scenes/echobox/ui5/ceremony/CeremonyParts.gd") + FileAccess.get_file_as_string("res://scenes/echobox/EchoBoxCeremony.gd")
	for bad in ["Jade Sprout", "Frost Crown", "Genesis Sun", "Heart of Luna", "Reed Basket", "Coral Bloom"]:
		_ok(not src.contains(bad), "no illustrative string " + bad)


func Parts_tier(r: Dictionary) -> int:
	return 0 if String(r.get("kind")) == "stone" else maxi(EchoBox.RARITIES.find(String(r.get("rarity"))), 0)
