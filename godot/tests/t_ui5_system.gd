extends Node
## UI-05 b23 lane S8b: NetNotice (frames 18-netnotice--*) and UpdateRequired (18-update--*). Every code of the frames, both
## update flavours (web / desktop / missions) + the bar, at 1920 and 1280 (scale 2/3): data-names, plate inside the
## screen, text >= 14 real px, no keycap on NetNotice, Space keycap on UpdateButton, initial focus, retry callback.
## Run: godot --headless --path godot res://tests/t_ui5_system.tscn

const Align := preload("res://tests/ui5_align_check.gd")
## [frame id, code, action, expected buttons]
const NOTICES := [
	["offline", "offline", "", ["RetryButton", "OkButton"]],
	["timeout", "timeout", "", ["RetryButton", "OkButton"]],
	["busy", "busy", "", ["RetryButton", "OkButton"]],
	["rejected", "rejected", "", ["RetryButton", "OkButton"]],
	["server-error", "server_error", "", ["RetryButton", "OkButton"]],
	["expired", "expired", "", ["SignInButton", "BackToMenuButton", "OkButton"]],
	["run-gone", "run_gone", "", ["BackToMenuButton"]],
	["action-lead", "offline", "Could not send your turn", ["RetryButton", "OkButton"]],
]
var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0
var _pairs := 0
var _sc := 1.0   ## current design scale: the frame is 1920x1080 logical * _sc


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _ready() -> void:
	print("=== t_ui5_system: start ===")
	_guard.capture()
	await get_tree().process_frame
	for sc in [1.0, 2.0 / 3.0]:
		UI3Theme.set_scale_override(sc)
		_sc = sc
		for n in NOTICES:
			await _notice(sc, n)
		await _update(sc, 0, "version")
		await _update(sc, 1, "version")
		await _update(sc, 0, "mission_needs_update")
		await _bar(sc, 0)
		await _bar(sc, 1)
	UI3Theme.set_scale_override(-1.0)
	UpdateRequired.web_override = -1
	_check(_pairs > 0, "pairs counted")
	print("t_ui5_system: icon/label pairs measured = %d" % _pairs)
	_guard.restore()
	print("=== t_ui5_system: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("t_ui5_system: PASS - %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _fails:
		print("t_ui5_system: FAIL - " + f)
	get_tree().quit(1)


func _host() -> Control:
	var host := Control.new()
	host.name = "Host"
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(host)
	var under := Button.new()   # the screen under the notice, owns the focus
	under.name = "UnderButton"
	host.add_child(under)
	under.grab_focus()
	return host


func _texts_ok(root: Node, tag: String, sc: float) -> void:
	for n in root.find_children("*", "", true, false):
		if n is Label and (n as Label).is_visible_in_tree() and sc < 1.0:
			_check(float((n as Label).get_theme_font_size("font_size")) * sc >= 14.0 - 0.01, "[%s] '%s' >= 14 real px" % [tag, (n as Label).text.left(24)])
		if n is BaseButton and (n as Control).is_visible_in_tree():
			var fs := (n as Control).get_theme_font_size("font_size")
			_check(sc >= 1.0 or float(fs) * sc >= 14.0 - 0.01, "[%s] button '%s' >= 14 real px (%d)" % [tag, n.get("text"), fs])
			var font := (n as Control).get_theme_font("font")
			var w := font.get_string_size(String(n.get("text")), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			_check((n as Control).size.x >= w, "[%s] button '%s' text not clipped" % [tag, n.get("text")])


## Sizes are design (logical) px: a 1280 screen is 1920x1080 logical at scale 2/3, so the box must fit 1920x1080 at both
## cases. Position is checked against the real viewport (the headless viewport is not 1920x1080, so not against the frame).
func _inside(c: Control, tag: String) -> void:
	var r := c.get_global_rect()
	var vp := get_viewport().get_visible_rect()
	_check(r.size.x > 0.0 and r.size.x <= 1920.0 + 0.5 and r.size.y <= 1080.0 + 0.5, "[%s] %s size %s fits 1920x1080 logical (scale %.2f)" % [tag, c.name, r.size, _sc])
	_check(vp.grow(0.5).encloses(r), "[%s] %s %s inside viewport %s" % [tag, c.name, r, vp])


func _align(root: Node, tag: String) -> void:
	_pairs += Align.pairs(root)
	var probs := Align.check(root)
	_check(probs.is_empty(), "[%s] icon/label alignment: %s" % [tag, "; ".join(probs)])


func _notice(sc: float, n: Array) -> void:
	var tag := "notice %s %.2f" % [n[0], sc]
	var host := await _host()
	var under := host.get_node("UnderButton") as Button
	var called := [0]
	var layer := NetNotice.show(host, String(n[1]), func() -> void: called[0] += 1, String(n[2]))
	for _i in 6:
		await get_tree().process_frame
	_check(layer != null and layer.name == "NetNotice", "[%s] layer named NetNotice" % tag)
	for nm in ["NetNotice", "ToneDisc", "Message", "Scrim"] + (n[3] as Array):
		_check(layer.find_child(nm, true, false) != null, "[%s] node %s exists" % [tag, nm])
	var plate := layer.find_child("NetNotice", true, false) as Control
	for b in ["RetryButton", "OkButton", "SignInButton", "BackToMenuButton"]:
		_check((layer.find_child(b, true, false) != null) == (n[3] as Array).has(b), "[%s] %s only when expected" % [tag, b])
	_check(String((layer.find_child("Message", true, false) as Label).text) == NetNotice.text_for(String(n[1]), String(n[2])), "[%s] message is the code text" % tag)
	_check(Ui5Keycap.all_under(layer).is_empty(), "[%s] no keycap anywhere" % tag)
	_check(get_viewport().gui_get_focus_owner() == under, "[%s] focus stays on the screen under" % tag)
	_check(plate != null and absf(plate.size.x - float(UI3Theme.size_of("netnotice_w"))) < 1.0, "[%s] plate is netnotice_w wide" % tag)
	if plate != null:
		_inside(plate, tag)
		_check(absf(plate.global_position.y - float(UI3Theme.space("screen")) * 1.0) < 1.5, "[%s] plate 24 px from the top (%s)" % [tag, plate.global_position.y])
	var primaries := 0
	for b in layer.find_children("*", "Button", true, false):
		if (b as Button).theme_type_variation.begins_with("ButtonPrimary"):
			primaries += 1
	_check(primaries <= 1, "[%s] at most one primary (%d)" % [tag, primaries])
	_check(primaries == 1, "[%s] exactly one live primary (%d)" % [tag, primaries])
	_texts_ok(layer, tag, sc)
	_align(layer, tag)
	var rb := layer.find_child("RetryButton", true, false) as Button
	if rb != null:
		rb.pressed.emit()
		await get_tree().process_frame
		_check(called[0] == 1, "[%s] retry callback called once" % tag)
		await get_tree().process_frame
		_check(not is_instance_valid(layer) or layer.is_queued_for_deletion(), "[%s] Retry closes the notice" % tag)
	else:
		_check(called[0] == 0, "[%s] no retry callback without Retry" % tag)
		var ok := layer.find_child("OkButton", true, false) as Button
		if ok != null:
			ok.pressed.emit()
			await get_tree().process_frame
			await get_tree().process_frame
			_check(not is_instance_valid(layer) or layer.is_queued_for_deletion(), "[%s] OK closes the notice" % tag)
	host.queue_free()
	await get_tree().process_frame


func _update(sc: float, web: int, code: String) -> void:
	UpdateRequired.web_override = web
	var tag := "update %s %s %.2f" % ["web" if web == 1 else "desktop", code, sc]
	var host := await _host()
	var closed := [0]
	var layer := UpdateRequired.show(host, code, func() -> void: closed[0] += 1)
	for _i in 8:
		await get_tree().process_frame
	var dname := "UpdateRequiredMissions" if code == "mission_needs_update" else "UpdateRequired"
	for nm in ["Scrim", dname, "Title", "Body", "Footer", "UpdateButton", "CloseButton", "KeyCap"]:
		_check(layer.find_child(nm, true, false) != null, "[%s] node %s exists" % [tag, nm])
	var dl := layer.find_child("UpdateButton", true, false) as Button
	var cl := layer.find_child("CloseButton", true, false) as Button
	var dlg := layer.find_child(dname, true, false) as Control
	_check(dl != null and dl.text == ("Reload the page" if web == 1 else "Download the new version"), "[%s] primary words" % tag)
	_check(get_viewport().gui_get_focus_owner() == dl, "[%s] initial focus is UpdateButton" % tag)
	var caps := Ui5Keycap.all_under(layer)
	_check(caps.size() == 1 and Ui5Keycap.text_of(caps[0] as PanelContainer) == "Space" and dl.is_ancestor_of(caps[0]), "[%s] one Space keycap, on UpdateButton" % tag)
	# footer in 2 rows: primary full width on top, Close under it
	var ft := layer.find_child("Footer", true, false) as Control
	_check(ft is VBoxContainer and dl.get_index() == 0 and cl.get_index() == 1, "[%s] Footer in 2 rows, primary on top" % tag)
	_check(absf(dl.size.x - cl.size.x) < 1.0 and dl.global_position.y < cl.global_position.y, "[%s] both buttons full width, stacked" % tag)
	_check(dl.size.x <= dlg.size.x, "[%s] UpdateButton does not overflow the dialog" % tag)
	if dlg != null:
		_inside(dlg, tag)
		_check(absf(dlg.size.x - float(UI3Theme.size_of("defeat_panel_w"))) < 1.0, "[%s] dialog is defeat_panel_w wide" % tag)
	_texts_ok(layer, tag, sc)
	_align(layer, tag)
	var opened: Array = []
	UpdateRequired.open_url_hook = func(u: String) -> void: opened.append(u)
	for pressed in [true, false]:   # a real Space key press on the focused UpdateButton
		var ev := InputEventKey.new()
		ev.keycode = KEY_SPACE
		ev.physical_keycode = KEY_SPACE
		ev.pressed = pressed
		Input.parse_input_event(ev)
		await get_tree().process_frame
	await get_tree().process_frame
	_check(opened == [UpdateRequired.DOWNLOAD_URL], "[%s] Space on UpdateButton opens the download (%s)" % [tag, opened])
	UpdateRequired.open_url_hook = Callable()
	# Esc = Close: on_close once, the bar stays
	(layer.find_child("Modal", true, false) as UI3.ModalRoot).cancelled.emit()
	await get_tree().process_frame
	_check(closed[0] == 1, "[%s] Esc runs on_close once (%d)" % [tag, closed[0]])
	var bar := get_tree().root.get_node_or_null(UpdateRequired.BAR_NAME)
	_check(bar != null, "[%s] Close leaves the update bar" % tag)
	if bar != null:
		bar.get_parent().remove_child(bar)
		bar.free()
	host.queue_free()
	await get_tree().process_frame


func _bar(sc: float, web: int) -> void:
	UpdateRequired.web_override = web
	var tag := "bar %s %.2f" % ["web" if web == 1 else "desktop", sc]
	var bar := UpdateRequired.show_bar(get_tree())
	for _i in 6:
		await get_tree().process_frame
	for nm in ["UpdateBar", "ToneDisc", "UpdateButton", "Message"]:
		_check(bar.find_child(nm, true, false) != null, "[%s] node %s exists" % [tag, nm])
	var b := bar.find_child("UpdateButton", true, false) as Button
	_check(b.text == ("Reload the page" if web == 1 else "Download"), "[%s] button word" % tag)
	_check(Ui5Keycap.all_under(bar).is_empty(), "[%s] no keycap" % tag)
	var panel := bar.find_child("UpdateBar", true, false) as Control
	_check(panel.size.y >= float(UI3Theme.size_of("update_bar_h")) - 0.5, "[%s] bar >= update_bar_h high" % tag)
	_inside(panel, tag)
	_texts_ok(bar, tag, sc)
	_align(bar, tag)
	bar.get_parent().remove_child(bar)
	bar.free()
	await get_tree().process_frame
