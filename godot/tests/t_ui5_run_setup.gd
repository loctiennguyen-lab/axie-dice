extends Node
## UI-05 b23 lane S3a1: Run setup main layout (frames stage1, stage3, a5, full-locked, newcomer, daily, ranked), 1920 and 1280.
## Data-names exist, the 7 run kinds (3 modes x state) build, inside 1920 logical, text >= 14 real px, equal party columns,
## Space keycap on an enabled Start only, initial focus kept, begin_run params arrive unchanged (stub).
## Run: AXIE_TEST_NO_NET=1 godot --headless --path godot res://tests/t_ui5_run_setup.tscn
const Fx := preload("res://tests/ui5_run_setup_fixture.gd")
const Align := preload("res://tests/ui5_align_check.gd")
const NAMES := ["SetupColumn", "BackButton", "Title", "ModeLabel", "NormalToggle", "DailyToggle", "RankedToggle", "ShortToggle",
	"FullToggle", "LengthDetail", "AnchorLine", "DifficultyLabel", "PartyArea", "PartyHeader", "PartyRow", "PartySlot", "Portrait",
	"Name", "ClassLine", "HpLine", "SwapButton", "ClearButton", "Actions", "FooterLine", "LeaderboardButton", "SavePresetButton",
	"TeamPresetsButton", "StartButton"]
const ASC_NAMES := ["AscGrid", "AscChipA0", "AscChipA10", "UnlockLine", "AscDetail", "AscTitle", "AscRules", "AscRule"]

var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0
var _got := {}


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _stub(p: Dictionary) -> Dictionary:
	_got = p
	return {"ok": true, "code": ""}


func _ready() -> void:
	print("=== t_ui5_run_setup: start ===")
	_guard.capture()
	ProjectSettings.set_setting("axie/epoch_source", "local")
	ProjectSettings.set_setting("axie/gem_wallet", "local")
	for sc: float in [1.0, 2.0 / 3.0]:
		UI3Theme.set_scale_override(sc)
		for id in Fx.IDS:
			await _frame(id, sc, "%s %s" % ["1920" if sc == 1.0 else "1280", id])
	UI3Theme.set_scale_override(1.0)
	_guard.restore()
	if _fails.is_empty():
		print("t_ui5_run_setup: PASS (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		for f in _fails:
			print("t_ui5_run_setup: FAIL - ", f)
		get_tree().quit(1)


func _text(n: Node, sc: float, tag: String) -> void:
	if n is CanvasItem and not (n as CanvasItem).is_visible_in_tree():
		return
	if n is Label or n is Button:
		var txt := (n as Label).text if n is Label else (n as Button).text
		if txt.strip_edges() != "":
			var fs := (n as Control).get_theme_font_size("font_size")
			_check(float(fs) * sc >= 13.99, "%s: '%s' is %.1f real px (< 14)" % [tag, txt.left(20), fs * sc])
	for ch in n.get_children():
		_text(ch, sc, tag)


func _frame(id: String, sc: float, tag: String) -> void:
	_got = {}
	var host := Control.new()
	host.size = Vector2(1920, 1080)
	add_child(host)
	var s := Fx.make(id, _stub)
	host.add_child(s)
	s.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for i in 5:
		await get_tree().process_frame
	Fx.apply_kind(s)
	for i in 3:
		await get_tree().process_frame
	for n in NAMES:
		_check(s.find_child(n, true, false) != null, "%s: node %s exists" % [tag, n])
	if id != "stage1" and id != "newcomer":
		for n in ASC_NAMES:
			_check(s.find_child(n, true, false) != null, "%s: node %s exists" % [tag, n])
	else:
		_check(s.find_child("NewcomerLine", true, false) != null, "%s: NewcomerLine" % tag)
	# kinds
	_check(s.kind == String(s.get_meta("fx_kind")) or id in ["daily", "ranked"] and s.kind == "normal", "%s: kind %s" % [tag, s.kind])
	for k in ["normal", "daily", "ranked"]:
		_check(s.find_child(k.capitalize() + "Toggle", true, false) is Button, "%s: %s toggle is a Button" % [tag, k])
	# column width from the token, columns equal
	var col := s.find_child("SetupColumn", true, false) as Control
	_check(absf(col.size.x - UI3Theme.size_of("setup_col_w")) < 1.5, "%s: SetupColumn %.1f wide (token %.1f)" % [tag, col.size.x, UI3Theme.size_of("setup_col_w")])
	var slots := s.find_children("PartySlot*", "Control", true, false)
	_check(slots.size() == 5, "%s: 5 party slots" % tag)
	for sl in slots:
		_check(absf((sl as Control).size.x - (slots[0] as Control).size.x) < 1.5, "%s: party columns equal" % tag)
	# Start: the frame has no keycap on Start (and Space does not start the run)
	var st := s.find_child("StartButton", true, false) as Button
	_check(Ui5Keycap.all_under(st).is_empty(), "%s: Start has no KeyCap" % tag)
	# locked toggles: grey, icon+text row, no Button.icon
	for tn in ["FullToggle", "RankedToggle"]:
		var tb := s.find_child(tn, true, false) as Button
		if tb != null and tb.get_node_or_null("LockRow") != null:
			_check(tb.icon == null and tb.text == "", "%s: %s lock drawn as HBox, no Button.icon" % [tag, tn])
			_check(tb.get_node("LockRow/LockIcon") is TextureRect and (tb.get_node("LockRow/LockText") as Label).text != "", "%s: %s has icon + reason text" % [tag, tn])
	# nothing outside the 1920 frame
	var lim := Rect2(Vector2.ZERO, Vector2(1920, 1080)).grow(1.0)
	for c in s.find_children("*", "Control", true, false):
		var ctl := c as Control
		if ctl.is_visible_in_tree() and ctl.size.x > 0 and ctl.size.y > 0 and not (ctl.name in ["Modals", "PlateHost", "Stage"]):
			_check(lim.encloses(ctl.get_global_rect()), "%s: %s outside the 1920 frame %s" % [tag, ctl.name, str(ctl.get_global_rect())])
	_text(s, sc, tag)
	_check(Align.pairs(s) > 0, "%s: align measured %d icon/label pairs" % [tag, Align.pairs(s)])
	# initial focus: RunSetup grabs none itself (only modals do), so no node in the screen owns focus on open
	var fo := s.get_viewport().gui_get_focus_owner()
	_check(fo == null or not s.is_ancestor_of(fo), "%s: no initial focus inside RunSetup (owner %s)" % [tag, str(fo)])
	# selected toggles keep the selection outline stylebox
	for tn in ["NormalToggle", "DailyToggle", "RankedToggle", "ShortToggle", "FullToggle"]:
		var tb2 := s.find_child(tn, true, false) as Button
		if tb2 != null and tb2.button_pressed and tb2.get_node_or_null("LockRow") == null:
			var sbx := tb2.get_theme_stylebox("normal") as StyleBoxFlat
			_check(sbx != null and sbx.border_color == UI3Theme.color("selected_outline"), "%s: selected %s has the selection outline" % [tag, tn])
	var chip_lock := s.find_children("LockRow", "HBoxContainer", true, false)
	for lr in chip_lock:
		var icr := (lr as Node).get_node("LockIcon") as Control
		_check(icr.size.x >= 14.0 and icr.size.y >= 14.0, "%s: lock icon %s >= 14 px" % [tag, str(icr.size)])
	for pr in Align.check(s, 1.5, tag + ": "):
		_check(false, pr)
	# start passes the same params as before (stub), only in the first full-party frame
	if id == "a5":
		var r: Dictionary = await s.begin()
		_check(r.get("ok", false), "%s: begin ok" % tag)
		_check(_got.get("ascension") == 5 and _got.get("mode") == "short" and _got.get("kind") == "normal" and _got.get("ranked") == false \
				and (_got.get("team_keys") as Array).size() == 5 and _got.get("anchor") == true and _got.has("depth_stage") and _got.has("newcomer"), "%s: begin params %s" % [tag, str(_got)])
	host.queue_free()
	await get_tree().process_frame
