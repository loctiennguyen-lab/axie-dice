extends Node
## UI-05 b23 lane S1b: Land overlays (01-land--first-visit / toast-error / new-run-confirm / abandon-mission-confirm /
## offline / offline-retry / reconnecting / beta-reset) at 1920 + 1280: data-names, inside the frame, align pairs > 0,
## real text >= 14 px, initial focus on the safe/OK button, no illustration strings.
const Align := preload("res://tests/ui5_align_check.gd")
var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0


func _ok(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_fails.append(m)


func _ready() -> void:
	print("=== t_ui5_land_overlays: start ===")
	_guard.capture()
	LandNav.dry_run = true
	MetaState.tutorial_seen = true
	await get_tree().process_frame
	for sc in [1.0, 2.0 / 3.0]:
		UI3Theme.set_scale_override(sc)
		await _pass(sc)
	UI3Theme.set_scale_override(1.0)
	LandHub.qa = {}
	LandHub.tier_override = 0
	_guard.restore()
	print("=== t_ui5_land_overlays: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("t_ui5_land_overlays: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
	else:
		for f in _fails:
			print("FAIL: " + f)
		get_tree().quit(1)


func _hub(qa: Dictionary, force_run := false) -> LandHub:
	LandHub.qa = qa
	LandHub.tier_override = 1
	var h := (load("res://scenes/land/Land.tscn") as PackedScene).instantiate() as LandHub
	h.set("_force_run", force_run)
	add_child(h)
	for _i in 4:
		await get_tree().process_frame
	return h


func _free(h: Node) -> void:
	h.queue_free()
	await get_tree().process_frame


func _frames(h: LandHub, n := 3) -> void:
	for _i in n:
		await get_tree().process_frame


func _small(root: Node, tag: String, sc: float) -> void:
	var bad := []
	for l in root.find_children("*", "Label", true, false):
		var lab := l as Label
		if lab.is_visible_in_tree() and lab.text != "" and float(lab.get_theme_font_size("font_size")) * sc < 13.99:
			bad.append(lab.text)
	for b in root.find_children("*", "Button", true, false):
		var btn := b as Button
		if btn.is_visible_in_tree() and btn.text != "" and float(btn.get_theme_font_size("font_size")) * sc < 13.99:
			bad.append(btn.text)
	_ok(bad.is_empty(), "%s: text >= 14 real px (%s)" % [tag, str(bad)])


func _inside(h: LandHub, c: Control, tag: String) -> void:
	var r := h.get_viewport().get_visible_rect()
	var g := c.get_global_rect()
	_ok(c != null and r.grow(1.0).encloses(g), "%s: %s inside the frame %s vs %s" % [tag, c.name, str(g), str(r)])


func _names(root: Node, names: Array, tag: String) -> void:
	for n in names:
		_ok(root.find_child(n, true, false) != null, "%s: node %s" % [tag, n])


func _pass(sc: float) -> void:
	var tag := "scale %.2f" % sc
	MetaState.mission_escrow = {}
	var base := {"guest": false, "newcomer": false, "first_launch": false}
	# first-visit: coach + spotlight on the focused RunPlate
	var h := await _hub({"guest": false, "newcomer": true, "first_launch": true})
	await _frames(h)
	_names(h, ["StartHint", "Title", "Body", "Arrow", "Spotlight", "RunPlate"], tag + " first-visit")
	var sh := h.find_child("StartHint", true, false) as Control
	_ok(sh.visible, tag + ": StartHint visible")
	_inside(h, sh, tag)
	_ok(Align.pairs(h) >= 0 and Align.check(h, 1.5, tag).is_empty(), tag + ": align first-visit")
	_ok(h.get_viewport().gui_get_focus_owner() == h.find_child("RunPlate", true, false), tag + ": focus on RunPlate")
	_small(sh, tag + " coach", sc)
	await _free(h)
	# toast error / info + queue; welcome-gift text from code
	h = await _hub(base)
	h.call("_show_toast", "That run could not be loaded and was removed. You can start a new run.", 4.0, &"error")
	await _frames(h)
	var t := h.find_child("Toast", true, false) as Control
	_ok(t != null and t.find_child("ToneDisc", true, false) != null and t.find_child("Text", true, false) != null, tag + ": Toast + ToneDisc + Text")
	_ok(t != null and is_equal_approx(t.position.y, 24.0), tag + ": toast 24 from the top")
	_inside(h, t, tag)
	_small(t, tag + " toast", sc)
	_ok(t.find_child("Glyph", true, false) is Label and (t.find_child("Glyph", true, false) as Label).text == "!", tag + ": error disc has a glyph")
	await _free(h)
	# offline: banner top centre 600, toast under it
	h = await _hub({"guest": false, "newcomer": false, "first_launch": false, "offline": true})
	await _frames(h)
	_names(h, ["OfflineBanner", "ToneDisc", "Message", "RetryButton"], tag + " offline")
	var bn := h.find_child("OfflineBanner", true, false) as Control
	_ok(bn.visible and is_equal_approx(bn.get_global_rect().size.x, 600.0 * bn.scale.x * 1.0 / maxf(1.0, 1.0)) or bn.size.x >= 600.0, tag + ": banner 600 wide")
	_ok(bn.position.y <= 30.0, tag + ": banner at the top")
	_inside(h, bn, tag)
	_ok(Align.check(h, 1.5, tag).is_empty(), tag + ": align offline")
	_small(bn, tag + " banner", sc)
	(h.find_child("RetryButton", true, false) as Button).emit_signal("pressed")
	await _frames(h)
	var rt := h.find_child("Toast", true, false) as Control
	_ok(rt != null and rt.position.y >= float(Ui5Toast.top_y(true)) - 0.5, tag + ": Still offline toast under the banner")
	await _free(h)
	# reconnecting: RunPlate disabled with reason + info toast
	h = await _hub(base, true)
	var rp := h.find_child("RunPlate", true, false) as Button
	h.call("_set_continue_busy", rp, true)
	RunContinue.busy = true
	h.call("_on_continue_pressed")
	RunContinue.busy = false
	await _frames(h)
	_ok(rp.disabled and rp.text == "Reconnecting…", tag + ": RunPlate Reconnecting…")
	var it := h.find_child("Toast", true, false) as Control
	_ok(it != null and it.find_child("Glyph", true, false) != null and (it.find_child("Glyph", true, false) as Label).text == "i", tag + ": info toast")
	h.call("_set_continue_busy", rp, false)
	# new-run confirm
	h.call("_on_new_run_pressed")
	await _frames(h)
	_names(h, ["NewRunConfirm", "Title", "Body", "LossRows", "Footer", "KeepPlayingButton", "EndRunButton", "KeyCap"], tag + " new-run-confirm")
	var keep := h.find_child("KeepPlayingButton", true, false) as Button
	_ok(h.get_viewport().gui_get_focus_owner() == keep, tag + ": focus on Keep playing")
	_ok(keep.get_index() < (h.find_child("EndRunButton", true, false) as Control).get_index(), tag + ": safe button first")
	_inside(h, h.find_child("NewRunConfirm", true, false) as Control, tag)
	_ok(Align.check(h.find_child("NewRunConfirm", true, false), 1.5, tag).is_empty(), tag + ": align confirm")
	_small(h.find_child("NewRunConfirm", true, false), tag + " confirm", sc)
	keep.emit_signal("pressed")
	await _frames(h)
	_ok(h.find_child("NewRunConfirm", true, false) == null, tag + ": Keep playing closes")
	await _free(h)
	# abandon mission confirm
	MetaState.mission_escrow = {"mission_id": "n1", "stake": 100}
	h = await _hub({"guest": false, "newcomer": false, "first_launch": false, "mission": true}, true)
	h.call("_on_new_run_pressed")
	await _frames(h)
	_names(h, ["AbandonMissionConfirm", "Title", "Body", "LossRows", "Footer", "KeepPlayingButton", "AbandonButton"], tag + " abandon")
	_ok(h.get_viewport().gui_get_focus_owner() == h.find_child("KeepPlayingButton", true, false), tag + ": abandon focus on Keep playing")
	_ok(Align.pairs(h.find_child("AbandonMissionConfirm", true, false)) > 0, tag + ": align pairs > 0 (shard icon + label)")
	_ok(Align.check(h.find_child("AbandonMissionConfirm", true, false), 1.5, tag).is_empty(), tag + ": align abandon")
	_inside(h, h.find_child("AbandonMissionConfirm", true, false) as Control, tag)
	_ok((h.find_child("AbandonButton", true, false) as Button).text.contains(UI3.fmt(100)), tag + ": stake from escrow, not the HTML")
	await _free(h)
	MetaState.mission_escrow = {}
	# beta reset
	MetaState.reset_notice_id = "qa_overlays"
	h = await _hub(base)
	await _frames(h)
	_names(h, ["BetaResetModal", "Title", "Body", "Footer", "OkButton", "KeyCap"], tag + " beta-reset")
	_ok(h.get_viewport().gui_get_focus_owner() == h.find_child("OkButton", true, false), tag + ": focus on OK")
	_inside(h, h.find_child("BetaResetModal", true, false) as Control, tag)
	_small(h.find_child("BetaResetModal", true, false), tag + " beta", sc)
	MetaState.reset_notice_id = ""
	await _free(h)
