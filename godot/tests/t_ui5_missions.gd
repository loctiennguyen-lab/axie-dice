extends Node
## UI-05 b23 lane S5: Missions screen (round-3 frames 40-missions--*), 1920 and 1280 (scale 0.667).
## Data-names exist, nothing preselected (empty DetailPlate "Pick a tier", StakeButton disabled with its reason), the
## states (picked, locked, need shards, guest, offline, open run, loading, checking), text >= 14 real px, icon/label
## centring measured on > 0 pairs, and no illustration value of the HTML frames left in the scene or script.
## Run: AXIE_TEST_NO_NET=1 godot --headless --path godot res://tests/t_ui5_missions.tscn

const Align := preload("res://tests/ui5_align_check.gd")
const NAMES := ["Header", "BackButton", "Title", "SubLine", "Body", "Explainer", "Balance", "Table", "TierRowN1", "TierRowN2",
	"TierRowN3", "TierRowN4", "TierRowN5", "TierRowN6", "DetailPlate", "StakeButton"]
## Example values of the HTML frames: they must come from the game, not from this screen.
const ILLUSTRATION := ["4,200", "Seed 777", "1,590", "7,240", "13,680", "19,815"]

var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _ready() -> void:
	print("=== t_ui5_missions: start ===")
	_guard.capture()
	ProjectSettings.set_setting("axie/epoch_source", "local")
	ProjectSettings.set_setting("axie/gem_wallet", "local")
	MetaState.saved_run_probe = func() -> bool: return false
	for sc: float in [1.0, 2.0 / 3.0]:
		UI3Theme.set_scale_override(sc)
		await _pass(sc, "1920" if sc == 1.0 else "1280")
	UI3Theme.set_scale_override(1.0)
	_source_check()
	MetaState.saved_run_probe = Callable()
	_guard.restore()
	if _fails.is_empty():
		print("t_ui5_missions: PASS (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		for f in _fails:
			print("t_ui5_missions: FAIL - ", f)
		get_tree().quit(1)


func _make(sc: float) -> MissionsScreen:
	var host := Control.new()
	host.size = Vector2(1920, 1080)   # the canvas is logical 1920x1080 at every scale
	add_child(host)
	var s: MissionsScreen = load("res://scenes/missions/MissionsScreen.tscn").instantiate()
	s.use_account = false
	s.remote_on = true
	s.no_scene_change = true
	s.test_mode = true
	s.day_override = "2026-10-12"
	host.add_child(s)
	s.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for i in 4:
		await get_tree().process_frame
	return s


func _settle() -> void:
	for i in 3:
		await get_tree().process_frame


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


## Text >= 14 real px and icon / label centring over the whole screen in the current state.
func _audit(s: Node, sc: float, tag: String) -> void:
	_text(s, sc, tag)
	for pr in Align.check(s, 1.5, tag + ": "):
		_check(false, pr)


func _pass(sc: float, tag: String) -> void:
	MetaState.runs = 8
	MetaState.runs_with_battle = 8
	MetaState.shard_pool = 5000
	MetaState.starter_shard_locked = 0
	MetaState.mission_escrow = {}
	MetaState.set_mission_unlocks(["N1", "N2"], false)
	var s := await _make(sc)
	for n in NAMES:
		_check(s.find_child(n, true, false) != null, "%s: node %s exists" % [tag, n])
	# no preselect
	var dp := s.find_child("DetailPlate", true, false) as Ui5DetailPlate
	_check(dp.is_empty() and dp.title.text == "Pick a tier", "%s: opens with an empty DetailPlate 'Pick a tier'" % tag)
	var sb := s.find_child("StakeButton", true, false) as Button
	_check(sb.disabled and sb.text == "Pick a tier" and Ui5Keycap.all_under(sb).is_empty(), "%s: StakeButton disabled, says why, no keycap" % tag)
	_check(s.selected == "", "%s: nothing selected" % tag)
	for id in ["N1", "N2", "N3", "N4", "N5", "N6"]:
		_check((s.find_child("TierRow" + id, true, false) as Ui5ListRow).state != &"selected", "%s: %s not selected" % [tag, id])
	var rowh := (s.find_child("TierRowN1", true, false) as Control).size.y
	_check(rowh >= UI3Theme.size_of("mission_row_h") - 1.0, "%s: row height >= mission_row_h (%.0f)" % [tag, rowh])
	_audit(s, sc, tag + " open")
	# picking an open tier
	var o := s.offer("N2")
	s.select_tier("N2")
	await _settle()
	_check((s.find_child("TierRowN2", true, false) as Ui5ListRow).state == &"selected", "%s: picked row has the ring" % tag)
	for n in ["StakeRow", "LoseBox", "Warning", "ToneDisc", "ChanceLine", "RuleLine", "DetailScroll"]:
		_check(s.find_child(n, true, false) != null, "%s: picked detail has %s" % [tag, n])
	sb = s.find_child("StakeButton", true, false) as Button
	_check(not sb.disabled and sb.text == "Stake %s and play" % UI3.fmt(int(o.stake)), "%s: StakeButton '%s'" % [tag, sb.text])
	_check(not dp.is_empty() and dp.title.text.begins_with("N2"), "%s: detail title" % tag)
	_text(s, sc, tag + " picked")
	_check(Align.pairs(s) > 0, "%s: the centring check measured no icon / label pair" % tag)
	for pr in Align.check(s, 1.5, tag + ": "):
		_check(false, pr)
	# the title tier (N6, the longest detail) fits: every Label inside the plate rect, no scrolling needed
	MetaState.set_mission_unlocks(["N1", "N2", "N3", "N4", "N5", "N6"], false)
	s._refresh()
	s.select_tier("N6")
	await _settle()
	var plate := s.find_child("DetailPlate", true, false) as Control
	var pr := plate.get_global_rect()
	var spill := []
	for lb in plate.find_children("*", "Label", true, false):
		var l := lb as Label
		if l.is_visible_in_tree() and not pr.grow(1.0).encloses(l.get_global_rect()):
			spill.append(l.text.left(24))
	_check(spill.is_empty(), "%s: N6 detail Labels all inside the plate %s" % [tag, str(spill)])
	var dsc := s.find_child("DetailScroll", true, false) as ScrollContainer
	_check(dsc.get_v_scroll_bar().max_value <= dsc.get_v_scroll_bar().page + 1.0, "%s: N6 detail needs no scrolling (max %.0f page %.0f)" % [tag, dsc.get_v_scroll_bar().max_value, dsc.get_v_scroll_bar().page])
	# locked tier
	s.select_tier("N4")
	await _settle()
	sb = s.find_child("StakeButton", true, false) as Button
	_check(s.find_child("LockedTag", true, false) != null and s.find_child("LoseBox", true, false) == null and sb.disabled and sb.text == s.lock_text(s.offer("N4")), "%s: locked tier: tag, reason on the button" % tag)
	_check(s.find_child("LockNote", true, false) != null, "%s: lock note in a row" % tag)
	_audit(s, sc, tag + " locked")
	# short of Shards
	MetaState.set_mission_unlocks(["N1", "N2", "N3", "N4"], false)
	MetaState.shard_pool = int(s.offer("N4").stake) - 200
	s._refresh()
	s.select_tier("N4")
	await _settle()
	_check((s.find_child("StakeButton", true, false) as Button).text == "Need 200 more Shards", "%s: need shards reason" % tag)
	MetaState.shard_pool = 5000
	# newcomer: every row locked with the long run-count text
	MetaState.runs = 2
	MetaState.runs_with_battle = 2
	MetaState.set_mission_unlocks([], false)
	s._refresh()
	s.select_tier("N1")
	await _settle()
	_audit(s, sc, tag + " newcomer")
	MetaState.runs = 8
	MetaState.runs_with_battle = 8
	MetaState.set_mission_unlocks(["N1", "N2", "N3", "N4"], false)
	s._refresh()
	# states
	s.set_state("guest")
	await _settle()
	_check(s.find_child("Banner", true, false) != null and s.find_child("SignInButton", true, false) != null, "%s: guest banner with Sign in" % tag)
	_audit(s, sc, tag + " guest")
	_check(s.find_child("LockNote", true, false) == null, "%s: guest sees no lock lines" % tag)
	s.set_state("offline")
	await _settle()
	_check(s.find_child("Banner", true, false) != null and s.find_child("SignInButton", true, false) == null, "%s: offline banner" % tag)
	_audit(s, sc, tag + " offline")
	# Retry: offline (remote on) has it and asks the server again; a stake error banner has none
	var rb := s.find_child("RetryButton", true, false) as Button
	_check(rb != null, "%s: offline banner has RetryButton" % tag)
	if rb != null:
		var c0 := s.sync_calls
		rb.pressed.emit()
		_check(s.sync_calls == c0 + 1, "%s: Retry asks the server again (sync_server)" % tag)
	await _settle()
	s.set_state("open_run")
	await _settle()
	_check(s.find_child("Banner", true, false) != null and (s.find_child("StakeButton", true, false) as Button).disabled, "%s: open run banner, stake disabled" % tag)
	s.set_state("normal")
	s._banner("Could not take the stake", "Nothing was spent.", &"error")
	await _settle()
	_check(s.find_child("Banner", true, false).find_child("ToneDisc", true, false) != null, "%s: error banner with ToneDisc" % tag)
	_check(s.find_child("RetryButton", true, false) == null, "%s: stake error banner has no Retry" % tag)
	_audit(s, sc, tag + " error")
	s.set_state("loading")
	await _settle()
	_check(s.find_child("TierRowN1", true, false) == null and (s.find_child("StakeButton", true, false) as Button).text == "Loading…", "%s: loading: skeleton rows, button says Loading…" % tag)
	_audit(s, sc, tag + " loading")
	s.set_state("normal")
	s._syncing = true
	s._refresh()
	await _settle()
	_check((s.find_child("StakeButton", true, false) as Button).text == "Checking your last mission…", "%s: checking state" % tag)
	s._syncing = false
	s._refresh()
	# confirm dialog
	s.select_tier("N2")
	s.open_confirm("N2")
	await _settle()
	var m := s.find_child("StakeConfirm", true, false)
	_check(m != null and m.find_child("NotNowButton", true, false) != null and m.find_child("StakeButton", true, false) != null and m.find_child("Footer", true, false) != null, "%s: StakeConfirm with Footer, NotNowButton, StakeButton" % tag)
	_check((s.find_child("NotNowButton", true, false) as Button).has_focus() and not Ui5Keycap.all_under(s.find_child("NotNowButton", true, false)).is_empty(), "%s: Not now has focus and the Space keycap" % tag)
	_audit(s, sc, tag + " confirm")
	s.close_modal()
	s.get_parent().queue_free()
	await get_tree().process_frame


func _source_check() -> void:
	for p in ["res://scenes/missions/MissionsScreen.gd", "res://scenes/missions/ui5/MissionParts.gd", "res://scenes/missions/ui5/MissionTierRow.gd"]:
		var src := FileAccess.get_file_as_string(p)
		for bad in ILLUSTRATION:
			_check(not src.contains(bad), "%s has no illustration value '%s'" % [p, bad])
		_check(not src.contains("Shard\"") and not src.contains("Shard %") and not src.contains("Shard stake"), "%s: amounts say Shards" % p)
