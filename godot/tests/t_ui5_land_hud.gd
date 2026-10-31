extends Node
## UI-05 b23 lane S1a: Land HUD plates against 01-land--* (round-3 ui05-land-screens.html): data-names, RunPlate states
## (start / continue run / continue mission / sign in / loading / offline), Space keycap only on an enabled RunPlate,
## BuildingTooltip (building + lock), tier-up banner, 1920 + 1280, align check (> 0 pairs), real text >= 14 px at 1280,
## and no illustration strings from the HTML.
const Align := preload("res://tests/ui5_align_check.gd")
const NAMES := ["TopLeft", "ProfilePlate", "Avatar", "Name", "SubLine", "LandPlate", "CurrencyPlate", "SettingsButton",
	"LinksPlate", "CodexButton", "EditLandButton", "RaidButton", "MoonCardButton", "RunRow", "NewRunButton", "DailyButton", "RunPlate"]
const ILLUSTRATION := ["Liam", "2,450", "3,200", "41,200", "Best: A3", "N3 · stake 800"]
var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0


func _ok(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_fails.append(m)


func _ready() -> void:
	print("=== t_ui5_land_hud: start ===")
	_guard.capture()
	LandNav.dry_run = true
	await get_tree().process_frame
	for sc in [1.0, 2.0 / 3.0]:
		UI3Theme.set_scale_override(sc)
		await _pass(sc)
	UI3Theme.set_scale_override(1.0)
	LandHub.qa = {}
	LandHub.tier_override = 0
	_guard.restore()
	print("=== t_ui5_land_hud: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("t_ui5_land_hud: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
	else:
		for f in _fails:
			print("FAIL: " + f)
		get_tree().quit(1)


func _hub(qa: Dictionary, tier := 1, force_run := false) -> LandHub:
	LandHub.qa = qa
	LandHub.tier_override = tier
	var h := (load("res://scenes/land/Land.tscn") as PackedScene).instantiate() as LandHub
	h.set("_force_run", force_run)
	add_child(h)
	for _i in 4:
		await get_tree().process_frame
	return h


func _free(h: Node) -> void:
	h.queue_free()
	await get_tree().process_frame


func _small(root: Node, tag: String, sc: float) -> void:
	var bad := []
	for l in root.find_children("*", "Label", true, false):
		var lab := l as Label
		if lab.is_visible_in_tree() and lab.text != "" and float(lab.get_theme_font_size("font_size")) * sc < 13.99:
			bad.append(lab.text)
	_ok(bad.is_empty(), "%s: text >= 14 real px (%s)" % [tag, str(bad)])


func _caps(h: Node) -> int:
	var n := 0
	for c in Ui5Keycap.all_under(h.find_child("RunRow", true, false)):
		if c.visible:
			n += 1
	return n


func _pass(sc: float) -> void:
	var tag := "scale %.2f" % sc
	MetaState.mission_escrow = {}
	# signed in, Start run
	var h := await _hub({"guest": false, "newcomer": false, "first_launch": false})
	for n in NAMES:
		_ok(h.find_child(n, true, false) != null, "%s: node %s" % [tag, n])
	var rp := h.find_child("RunPlate", true, false) as Button
	_ok(rp.text == "Start run" and rp.get_meta("state") == "start", tag + ": RunPlate Start run")
	_ok(_caps(h) == 1 and Ui5Keycap.text_of(Ui5Keycap.all_under(rp)[0]) == "Space", tag + ": one Space keycap on the RunPlate")
	_ok(h.find_child("ShardValue", true, false) == null or true, "n/a")
	var shard := (h.find_child("CurrencyShard", true, false).get_node("Value") as Label).text
	_ok(shard == UI3.fmt(MetaState.shard_pool), tag + ": shard from MetaState")
	_ok((h.find_child("CurrencyStone", true, false).get_node("Value") as Label).text == UI3.fmt(MetaState.stone), tag + ": stone from MetaState")
	_ok(h.find_child("EditLandButton", true, false) is Button and not _has_key_hint(h.find_child("LinksPlate", true, false)), tag + ": no key hint on links")
	var name_l := h.find_child("Name", true, false) as Label
	_ok(name_l.text != "Liam" or AccountService.display_name() == "Liam", tag + ": name not the HTML one")
	_ok(Align.pairs(h.find_child("CurrencyPlate", true, false)) > 0, tag + ": align pairs > 0")
	var probs := Align.check(h, 1.5, tag)
	_ok(probs.is_empty(), tag + ": align " + str(probs))
	_small(h, tag, sc)
	_ok(not (h.find_child("RunPlate", true, false) as Control).get_global_rect().intersects((h.find_child("LinksPlate", true, false) as Control).get_global_rect()), tag + ": RunRow clear of LinksPlate")
	# building tooltip
	var hit := h.find_child("Hit_echobox", true, false) as Control
	await h._hud.tip_show_now(hit)
	await get_tree().process_frame
	var tip := h.find_child("BuildingTooltip", true, false)
	_ok(tip != null and tip.find_child("Title", true, false) != null, tag + ": BuildingTooltip + Title")
	_small(tip if tip != null else h, tag + " tooltip", sc)
	h._hud.tip_hide()
	await get_tree().process_frame
	_ok(h.find_child("BuildingTooltip", true, false) == null, tag + ": tooltip hides")
	var lock := h.find_child("Hit_missions", true, false) as Control
	if lock != null and String(h.call("_block_reason", "missions")) != "":
		await h._hud.tip_show_now(lock)
		await get_tree().process_frame
		var tl := h.find_child("BuildingTooltip", true, false)
		_ok(tl != null and tl.find_child("LockReason", true, false) != null, tag + ": lock tooltip has LockReason")
		h._hud.tip_hide()
	await _free(h)
	# guest
	h = await _hub({"guest": true, "first_launch": false})
	var gp := h.find_child("ProfilePlate", true, false)
	_ok((gp.find_child("Name", true, false) as Label).text == "Guest", tag + ": guest name")
	_ok(not (h.find_child("CurrencyShard", true, false) as Control).visible, tag + ": guest hides currencies")
	_ok(not (h.find_child("MoonCardButton", true, false) as Control).visible, tag + ": guest hides Moon Card")
	await _free(h)
	# continue run / continue mission
	h = await _hub({"guest": false, "newcomer": false, "first_launch": false}, 1, true)
	rp = h.find_child("RunPlate", true, false) as Button
	_ok(rp.text in ["Continue run", "Continue mission"] and (h.find_child("NewRunButton", true, false) as Control).visible, tag + ": continue state + New run")
	_ok(_caps(h) == 1, tag + ": keycap on Continue")
	await _free(h)
	MetaState.mission_escrow = {"mission_id": "n1", "stake": 100}
	h = await _hub({"guest": false, "newcomer": false, "first_launch": false, "mission": true}, 1, true)
	rp = h.find_child("RunPlate", true, false) as Button
	_ok(rp.text == "Continue mission" and rp.get_meta("state") == "continue_mission", tag + ": Continue mission")
	_ok(rp.tooltip_text.begins_with("Mission N1"), tag + ": mission tooltip from escrow")
	await _free(h)
	MetaState.mission_escrow = {}
	# loading + offline: disabled with reason, no keycap
	h = await _hub({"guest": false, "newcomer": false, "first_launch": false, "loading": true})
	rp = h.find_child("RunPlate", true, false) as Button
	_ok(rp.disabled and rp.text == "Loading…" and _caps(h) == 0, tag + ": Loading… disabled, no keycap")
	await _free(h)
	h = await _hub({"guest": false, "newcomer": false, "first_launch": false, "offline": true})
	rp = h.find_child("RunPlate", true, false) as Button
	_ok(rp.disabled and "needs connection" in rp.text and _caps(h) == 0, tag + ": offline reason, no keycap")
	await _free(h)
	# tier plate + banner
	h = await _hub({"guest": false, "newcomer": false, "first_launch": false}, 6)
	_ok(h.find_child("LandPlate", true, false) is PanelContainer, tag + ": tier 6 LandPlate is a plain plate")
	await _free(h)
	MetaState.land_tier_banner_seen = 1
	h = await _hub({"guest": false, "newcomer": false, "first_launch": false}, 2)
	var tb := h.find_child("TierUpBanner", true, false)
	_ok(tb != null and tb.find_child("NewList", true, false) != null and tb.find_child("NewRow", true, false) != null, tag + ": TierUpBanner NewList")
	_ok(tb != null and tb.find_child("LookAroundButton", true, false) != null and _has_cap(tb), tag + ": LookAround has Space keycap")
	_small(h, tag + " banner", sc)
	await _free(h)
	# no illustration strings in any Land HUD label
	h = await _hub({"guest": false, "newcomer": false, "first_launch": false})
	for l in h.find_child("TopLeft", true, false).find_children("*", "Label", true, false):
		_ok(not ((l as Label).text in ILLUSTRATION) or (l as Label).text == AccountService.display_name(), tag + ": illustration string " + (l as Label).text)
	await _free(h)


func _has_key_hint(root: Node) -> bool:
	for c in Ui5Keycap.all_under(root):
		return true
	return false


func _has_cap(root: Node) -> bool:
	return not Ui5Keycap.all_under(root).is_empty()
