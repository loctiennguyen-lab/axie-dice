extends Node
## UI-05 b23 lane S8a2: a13 BootOfflineGate, a14 WelcomePanel, a15 ChooseSave, a16 MoveGuestProgress. Data-names exist, each
## button makes the right service call / callback, 1920 + 1280, inside the frame, text >= 14 real px at 1280, initial focus
## (none on ChooseSave), icon/label alignment measured, values from the save summary and no illustrative strings.
## The service is a stub (no browser, no network).
## Run: godot --headless --path godot res://tests/t_ui5_account_gate.tscn

const Parts := preload("res://scenes/account/ui5/AccountParts.gd")
const Align := preload("res://tests/ui5_align_check.gd")

class StubService extends Node:
	signal changed
	var calls: Array = []
	func check() -> void: calls.append("check")
	func sign_in(sw: bool = false) -> void: calls.append("sign_in:%s" % sw)
	func play_as_guest() -> void: calls.append("guest")

var _fails: Array[String] = []
var _checks := 0
var _pairs := 0
var _got: Array = []


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _ready() -> void:
	print("=== t_ui5_account_gate: start ===")
	await get_tree().process_frame
	for sc in [1.0, 2.0 / 3.0]:
		UI3Theme.set_scale_override(sc)
		await _gate(sc)
		await _welcome(sc)
		await _choose(sc)
		await _move(sc)
	UI3Theme.set_scale_override(1.0)
	print("=== t_ui5_account_gate: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("t_ui5_account_gate: PASS - %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _fails:
		print("t_ui5_account_gate: FAIL - " + f)
	get_tree().quit(1)


func _frames(n := 6) -> void:
	for _i in n:
		await get_tree().process_frame


func _common(root: Node, names: Array, tag: String, sc: float) -> void:
	for n in names:
		_check(root.find_child(n, true, false) != null, "[%s] node '%s' exists" % [tag, n])
	var all := ""
	for n in root.find_children("*", "", true, false):
		if n is Label and (n as Label).is_visible_in_tree():
			var l := n as Label
			all += l.text + "\n"
			if sc < 1.0:
				_check(float(l.get_theme_font_size("font_size")) * sc >= 14.0 - 0.01, "[%s] '%s' >= 14 real px" % [tag, l.text.left(24)])
		if n is BaseButton and (n as BaseButton).is_visible_in_tree() and sc < 1.0:
			_check(float(n.get_theme_font_size("font_size")) * sc >= 14.0 - 0.01, "[%s] button '%s' >= 14 real px" % [tag, n.get("text")])
	for bad in ["Liam", "4,967", "1,240", "3 hours ago", "12 · 3", "liam@gmail.com"]:
		_check(not all.contains(bad), "[%s] no illustrative value '%s'" % [tag, bad])
	_pairs += Align.pairs(root)
	var probs := Align.check(root)
	_check(probs.is_empty(), "[%s] icon/label alignment: %s" % [tag, "; ".join(probs)])


func _inside(c: Control, within: Rect2, tag: String) -> void:
	var r := c.get_global_rect()
	_check(within.grow(1.0).encloses(r), "[%s] %s inside the frame %s vs %s" % [tag, c.name, r, within])


func _focus_name() -> String:
	var fo := get_viewport().gui_get_focus_owner()
	return fo.name if fo != null else ""


func _free_overlay(o) -> void:
	if is_instance_valid(o):
		o.queue_free()
	await get_tree().process_frame


func _gate(sc: float) -> void:
	var svc := StubService.new()
	add_child(svc)
	var layer := CanvasLayer.new()
	add_child(layer)
	var ov := AccountUI.show_offline_gate(layer, svc)
	await _frames()
	var tag := "gate %.2f" % sc
	_common(ov, ["Scrim", "BootOfflineGate", "BrandRow", "Brand", "Version", "ToneDisc", "Title", "Body", "TryAgainButton"], tag, sc)
	_check(Align.pairs(ov) > 0, "[%s] gate: align_check measured > 0 ToneDisc/label pairs" % tag)
	_check(_focus_name() == "TryAgainButton", "[%s] initial focus is TryAgainButton (%s)" % [tag, _focus_name()])
	_check((ov.find_child("Version", true, false) as Label).text == Parts.version_text(), "[%s] version from the project setting" % tag)
	var disc := ov.find_child("ToneDisc", true, false)
	_check(disc != null and disc.get_meta("tone") == &"warn", "[%s] ToneDisc is warn" % tag)
	var p := ov.find_child("BootOfflineGate", true, false) as Control
	_check(absf(p.size.x - float(UI3Theme.size_of("account_w"))) < 1.0, "[%s] panel is account_w wide (%s)" % [tag, p.size.x])
	_inside(p, Rect2(Vector2.ZERO, ov.size), tag)
	var b := ov.find_child("TryAgainButton", true, false) as Button
	_check(b.theme_type_variation == &"ButtonPrimaryL", "[%s] Try again is the primary" % tag)
	_check(b.find_child("KeyCap", true, false) == null, "[%s] no keycap on Try again" % tag)
	svc.calls.clear()
	b.pressed.emit()
	_check(svc.calls == ["check"], "[%s] Try again calls check() (%s)" % [tag, svc.calls])
	_check(is_instance_valid(ov) and not ov.is_queued_for_deletion(), "[%s] the gate stays until the service says so" % tag)
	await _free_overlay(ov)
	layer.queue_free()
	svc.queue_free()
	await get_tree().process_frame


func _welcome(sc: float) -> void:
	for which in ["google", "guest"]:
		var svc := StubService.new()
		add_child(svc)
		var layer := CanvasLayer.new()
		svc.add_child(layer)
		var ov := AccountUI.show_welcome(layer)
		await _frames()
		var tag := "welcome %s %.2f" % [which, sc]
		_common(ov, ["Scrim", "WelcomePanel", "SkyMavisTag", "Title", "Body", "Points", "Point", "GoogleButton", "GuestButton"], tag, sc)
		_check(ov.find_children("Point*", "PanelContainer", true, false).size() == 3, "[%s] three Points" % tag)
		_check(_focus_name() == "GoogleButton", "[%s] initial focus is GoogleButton (%s)" % [tag, _focus_name()])
		var p := ov.find_child("WelcomePanel", true, false) as Control
		_check(absf(p.size.x - float(UI3Theme.size_of("welcome_w"))) < 1.0, "[%s] panel is welcome_w wide (%s)" % [tag, p.size.x])
		_inside(p, Rect2(Vector2.ZERO, ov.size), tag)
		var g := ov.find_child("GoogleButton", true, false) as Button
		var q := ov.find_child("GuestButton", true, false) as Button
		_check(g.theme_type_variation == &"ButtonPrimaryL" and q.theme_type_variation == &"ButtonQuiet", "[%s] one primary, guest is quiet" % tag)
		svc.calls.clear()
		(g if which == "google" else q).pressed.emit()
		await _frames(2)
		_check(svc.calls == (["sign_in:false"] if which == "google" else ["guest"]), "[%s] calls the service (%s)" % [tag, svc.calls])
		_check(not is_instance_valid(ov) or ov.is_queued_for_deletion(), "[%s] pressing frees the panel" % tag)
		await _free_overlay(ov)
		layer.queue_free()
		svc.queue_free()
		await get_tree().process_frame


func _info(local_xp: int, cloud_xp: int) -> Dictionary:
	return {"local": {"shards": 31, "xp": local_xp, "vault": 2, "runs": 7, "wins": 5, "run": ""},
		"cloud": {"shards": 17, "xp": cloud_xp, "vault": 4, "runs": 9, "wins": 1, "run": "Short · A0",
			"updated_at": int(Time.get_unix_time_from_system()) - 7200}}


func _on_done(c: String) -> void:
	_got.append(c)


func _choose(sc: float) -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	for case in [["choose", 900, 400, "KeepLocalButton", "KeepCloudButton", "local"],
			["conflict", 100, 400, "KeepCloudButton", "KeepLocalButton", "cloud"],
			["choose", 500, 500, "KeepCloudButton", "KeepLocalButton", "cloud"]]:
		var tag := "choose %s %d/%d %.2f" % [case[0], case[1], case[2], sc]
		var info := _info(case[1], case[2])
		var ov := AccountUI.show_choice(layer, case[0], info, _on_done)
		await _frames()
		_common(ov, ["Scrim", "ChooseSave", "Title", "Body", "Footer", "KeepLocalButton", "KeepCloudButton"], tag, sc)
		var cards := ov.find_children("SaveCard*", "", true, false)
		_check(cards.size() == 2 and cards[0] is Ui5SaveCard and cards[1] is Ui5SaveCard, "[%s] two Ui5SaveCards (%d)" % [tag, cards.size()])
		for c in cards:
			_check(not (c as Ui5SaveCard).picked, "[%s] no card is picked" % tag)
		_check(_focus_name() != "KeepLocalButton" and _focus_name() != "KeepCloudButton", "[%s] no Keep button has focus (%s)" % [tag, _focus_name()])
		var p := ov.find_child("ChooseSave", true, false) as Control
		_check(absf(p.size.x - float(UI3Theme.size_of("defeat_panel_w"))) < 1.0, "[%s] dialog is defeat_panel_w wide (%s)" % [tag, p.size.x])
		_inside(p, Rect2(Vector2.ZERO, ov.size), tag)
		# the numbers on the cards are the summary's, not literals
		var txt := ""
		for l in cards[0].find_children("*", "Label", true, false):
			txt += (l as Label).text + "|"
		_check(txt.contains("7 · 5"), "[%s] local card shows its own runs (%s)" % [tag, txt])
		_check(txt.contains("On this browser"), "[%s] local sub line" % tag)
		_check((cards[1].find_children("*", "Label", true, false).any(func(l: Label) -> bool: return l.text.begins_with("Saved "))), "[%s] cloud card says when it was saved" % tag)
		var pri := ov.find_child(case[3], true, false) as Button
		var sec := ov.find_child(case[4], true, false) as Button
		_check(pri.theme_type_variation == &"ButtonPrimaryM" and sec.theme_type_variation == &"ButtonSecondary",
			"[%s] primary goes to %s, the other is secondary" % [tag, case[3]])
		var foot := ov.find_child("Footer", true, false) as Control
		_check(foot.get_global_rect().position.y > (cards[0] as Control).get_global_rect().end.y - 1.0, "[%s] Footer is under the cards" % tag)
		_check(ov.find_children("KeyCap", "", true, false).is_empty(), "[%s] no keycap on a pick-a-save dialog" % tag)
		# a click on a card only moves focus, it never chooses
		_got.clear()
		(cards[0] as Ui5SaveCard).pressed.emit()
		await _frames(2)
		_check(_got.is_empty() and _focus_name() == "KeepLocalButton", "[%s] a card click focuses its button, picks nothing (%s)" % [tag, _got])
		for pair in [["KeepLocalButton", "local"], ["KeepCloudButton", "cloud"]]:
			var ov2 := AccountUI.show_choice(layer, case[0], info, _on_done)
			await _frames(2)
			_got.clear()
			(ov2.find_child(pair[0], true, false) as Button).pressed.emit()
			await _frames(2)
			_check(_got == [pair[1]], "[%s] %s calls done(%s) (%s)" % [tag, pair[0], pair[1], _got])
			_check(not is_instance_valid(ov2) or ov2.is_queued_for_deletion(), "[%s] pressing frees the dialog" % tag)
			await _free_overlay(ov2)
		await _free_overlay(ov)
	layer.queue_free()
	await get_tree().process_frame


func _move(sc: float) -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var info := _info(300, 0)
	var tag := "move %.2f" % sc
	var ov := AccountUI.show_choice(layer, "move", info, _on_done)
	await _frames()
	_common(ov, ["Scrim", "MoveGuestProgress", "Title", "Body", "SaveCard", "Footer", "StartFreshButton", "MoveButton", "KeyCap"], tag, sc)
	_check(ov.find_children("SaveCard*", "", true, false).size() == 1, "[%s] one SaveCard" % tag)
	_check(_focus_name() == "MoveButton", "[%s] initial focus is MoveButton (%s)" % [tag, _focus_name()])
	var cap := ov.find_child("KeyCap", true, false)
	_check(cap != null and cap.get_node("Key").text == "Space" and cap.get_parent().name == "MoveButton", "[%s] Move progress carries Space" % tag)
	var foot := ov.find_child("Footer", true, false) as Control
	var mv := ov.find_child("MoveButton", true, false) as Control
	_check(foot.get_global_rect().grow(1.0).encloses(mv.get_global_rect()), "[%s] MoveButton stays inside the Footer (%s vs %s)" % [tag, mv.get_global_rect(), foot.get_global_rect()])
	_check(foot.get_global_rect().grow(1.0).encloses(cap.get_global_rect()), "[%s] the Space cap stays inside the Footer" % tag)
	var p := ov.find_child("MoveGuestProgress", true, false) as Control
	_check(absf(p.size.x - float(UI3Theme.size_of("defeat_panel_w"))) < 1.0, "[%s] dialog is defeat_panel_w wide (%s)" % [tag, p.size.x])
	_inside(p, Rect2(Vector2.ZERO, ov.size), tag)
	var first := ov.find_child("StartFreshButton", true, false) as Control
	_check(first.get_global_rect().position.x < mv.get_global_rect().position.x, "[%s] the safe button stands before the primary" % tag)
	await _free_overlay(ov)
	for pair in [["StartFreshButton", "fresh"], ["MoveButton", "move"]]:
		var o := AccountUI.show_choice(layer, "move", info, _on_done)
		await _frames(2)
		_got.clear()
		(o.find_child(pair[0], true, false) as Button).pressed.emit()
		await _frames(2)
		_check(_got == [pair[1]], "[%s] %s calls done(%s) (%s)" % [tag, pair[0], pair[1], _got])
		await _free_overlay(o)
	layer.queue_free()
	await get_tree().process_frame
