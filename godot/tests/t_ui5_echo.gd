extends Node
## UI-05 b23 lane S9a: Echo Box (20-echo*, ui05-meta2-screens.html) at 1920 and 1280 (scale 0.667): data-names, states, confirms
## (safe button first, focus, Space keycap; spending button has none), text >= 14 real px (Label + Button), inside the frame,
## Gem-free icon/label centring on > 0 pairs, no illustration strings, a box opens only after its confirm.
## Run: AXIE_TEST_NO_NET=1 godot --headless --path godot res://tests/t_ui5_echo.tscn

const Align := preload("res://tests/ui5_align_check.gd")
const SHELL := ["Header", "BackButton", "Title", "SubLine", "RegularTab", "SeasonalTab", "Body", "TicketBar", "Tickets",
	"FragmentMeter", "NextTicket", "BuyTicketButton", "Stage", "Open1Button", "Open10Button", "RatesButton", "PityPlate", "PoolPlate"]
const CEREMONY := ["Ceremony", "DoneButton", "EquipButton", "FrameArt", "Line", "MilestoneChip", "Name", "NewChip", "OpenAgainButton", "RevealCard", "TierStrip"]
const SEASON := ["ProgressPlate", "Milestones", "SeriesItems", "Open1Button", "OpenNButton", "RatesButton"]
## Example values of the HTML frames: they must come from the game, not from this screen.
const ILLUSTRATION := ["22/200", "22/1000", "Rune Ring", "Seed 777006"]

var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0
var _seen := {}   # every node name met in any state (for the S9a.txt data-name coverage)


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _ready() -> void:
	print("=== t_ui5_echo: start ===")
	_guard.capture()
	for sc: float in [1.0, 2.0 / 3.0]:
		UI3Theme.set_scale_override(sc)
		await _pass(sc, "1920" if sc == 1.0 else "1280")
	UI3Theme.set_scale_override(1.0)
	_guard.restore()
	var nf := FileAccess.open("res://../production/ui05-b23/names/S9a.txt", FileAccess.READ)
	_check(nf != null, "S9a.txt readable")
	var want := 0
	if nf != null:
		while not nf.eof_reached():
			var ln := nf.get_line()
			if ln.strip_edges().begins_with("#") or ln.begins_with("=") or ln.strip_edges() == "":
				continue
			var nm := ln.strip_edges().split(" ")[0]
			if CEREMONY.has(nm):
				continue   # EchoBoxCeremony.gd (lane S9b) owns these
			want += 1
			_check(_seen.has(nm), "data-name '%s' has a node" % nm)
	_check(want > 20, "S9a.txt had names (%d)" % want)
	if _fails.is_empty():
		print("t_ui5_echo: PASS (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		for f in _fails:
			print("t_ui5_echo: FAIL - ", f)
		get_tree().quit(1)


func _make(sc: float, tickets: int, state := "normal", remote := false) -> EchoBoxScreen:
	MetaState.tickets["normal"] = tickets
	var host := Control.new()
	host.name = "Frame"
	host.size = Vector2(1920, 1080) * sc
	add_child(host)
	var s: EchoBoxScreen = load("res://scenes/echobox/EchoBoxScreen.tscn").instantiate()
	s.use_account = false
	s.no_scene_change = true
	s.instant = true
	s.remote_on = remote
	s.state = state
	host.add_child(s)
	s.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await _settle()
	return s


func _settle() -> void:
	for i in 5:
		await get_tree().process_frame


func _free(s: Node) -> void:
	s.get_parent().queue_free()
	await get_tree().process_frame


func _small(root: Node, sc: float, tag: String) -> void:
	for n in root.find_children("*", "", true, false):
		if (n is Label or n is Button) and (n as Control).is_visible_in_tree() and String(n.text).strip_edges() != "":
			_check(float(n.get_theme_font_size("font_size")) * sc >= 13.99, "%s: '%s' is %.1f real px (< 14)" % [tag, String(n.text).left(20), n.get_theme_font_size("font_size") * sc])


func _inside(s: Node, frame: Rect2, tag: String) -> void:
	var bad: Array[String] = []
	for n in s.find_children("*", "Control", true, false):
		var c := n as Control
		if not c.is_visible_in_tree() or c.size.x <= 0.0 or c.size.y <= 0.0 or _in_scroll(c):
			continue
		var r := c.get_global_rect()
		if r.position.x < frame.position.x - 1.0 or r.end.x > frame.end.x + 1.0 or r.position.y < frame.position.y - 1.0 or r.end.y > frame.end.y + 1.0:
			bad.append("%s %s" % [c.name, str(r)])
	_check(bad.is_empty(), "%s: all inside the frame (%s)" % [tag, str(bad.slice(0, 4))])


func _in_scroll(c: Node) -> bool:
	var p := c.get_parent()
	while p != null:
		if p is ScrollContainer:
			return true
		p = p.get_parent()
	return false


func _names(s: Node, names: Array, tag: String) -> void:
	for n in names:
		_check(s.find_child(n, true, false) != null, "%s: node %s" % [tag, n])


func _audit(s: Node, sc: float, tag: String) -> void:
	for n in s.find_children("*", "", true, false):
		_seen[String(n.name)] = true
	_small(s, sc, tag)
	_inside(s, Rect2(Vector2.ZERO, Vector2(1920, 1080) * sc), tag)
	for pr in Align.check(s, 1.5, tag + ": "):
		_check(false, pr)


func _btn(s: Node, n: String) -> Button:
	return s.find_child(n, true, false) as Button


func _pass(sc: float, tag: String) -> void:
	# idle: 24 tickets -> Open 10 is the one primary; frame names; Open 1 not preselected
	var s := await _make(sc, 24)
	_names(s, SHELL, tag + " idle")
	_check(String(_btn(s, "Open10Button").theme_type_variation).begins_with("ButtonPrimary") and not _btn(s, "Open10Button").disabled, tag + ": Open 10 is live and the primary")
	_check(not String(_btn(s, "Open1Button").theme_type_variation).begins_with("ButtonPrimary"), tag + ": Open 1 is not a second primary")
	var fo := s.get_viewport().gui_get_focus_owner()
	_check(fo != null and fo.name == "RegularTab", tag + ": idle: first focus is the selected tab (%s)" % (fo.name if fo else "none"))
	var ch := s.find_child("Chest", true, false) as Control
	var stg0 := s.find_child("Stage", true, false) as Control
	var want := float(UI3Theme.size_of("echo_stage_chest")) * UI3Theme.layout_scale()
	_check(ch != null and ch.get_global_rect().size.x >= want - 1.0, tag + ": chest is the token size (%.0f real vs %.0f)" % [ch.get_global_rect().size.x if ch else 0.0, want])
	var cluster := ch.get_global_rect().merge(_btn(s, "Open10Button").get_global_rect()) if ch else Rect2()
	_check(stg0 != null and stg0.get_global_rect().grow(1.0).encloses(cluster), tag + ": chest + buttons sit inside the Stage")
	_check(fo == null or (fo.name != "Open1Button" and fo.name != "Open10Button"), tag + ": idle: no Open button is preselected (focus: %s)" % (fo.name if fo else "none"))
	_check(Align.pairs(s) > 0, tag + ": idle align check measures > 0 pairs (%d)" % Align.pairs(s))
	_check(s.find_child("Tickets", true, false).text == "Tickets 24 / 999", tag + ": ticket text comes from MetaState")
	_check(_btn(s, "RegularTab").button_pressed, tag + ": Regular tab on")
	_audit(s, sc, tag + " idle")
	var all := ""
	for n in s.find_children("*", "Label", true, false):
		all += (n as Label).text + "\n"
	for w in ILLUSTRATION:
		_check(all.find(w) < 0, tag + ": illustration string '%s' is not in the scene" % w)
	# Open 10 asks first; the box only opens after Confirm
	var before := int(MetaState.tickets["normal"])
	_btn(s, "Open10Button").emit_signal("pressed")
	await _settle()
	var c := s.find_child("Open10Confirm", true, false)
	_check(c != null, tag + ": Open10Confirm shown")
	_check(int(MetaState.tickets["normal"]) == before, tag + ": nothing spent before the confirm")
	if c != null:
		var cancel := c.find_child("CancelButton", true, false) as Button
		var yes := c.find_child("Open10Button", true, false) as Button
		_check(cancel != null and yes != null, tag + ": both confirm buttons exist")
		_check(cancel.get_parent() == yes.get_parent() and cancel.get_index() < yes.get_index(), tag + ": safe button stands first")
		_check(cancel.find_child("KeyCap", true, false) != null or Ui5Keycap.all_under(cancel).size() > 0, tag + ": Cancel has the Space keycap")
		_check(Ui5Keycap.all_under(yes).is_empty(), tag + ": spending button has no keycap")
		_check(cancel.has_focus(), tag + ": Cancel has focus")
		_audit(s, sc, tag + " open10-confirm")
		# Space on the focused Cancel closes the confirm and spends nothing
		var ev := InputEventKey.new()
		ev.keycode = KEY_SPACE
		ev.physical_keycode = KEY_SPACE
		ev.pressed = true
		Input.parse_input_event(ev)
		var ev2 := ev.duplicate() as InputEventKey
		ev2.pressed = false
		Input.parse_input_event(ev2)
		await _settle()
		_check(s.find_child("Open10Confirm", true, false) == null, tag + ": Space on Cancel closes the confirm")
		_check(int(MetaState.tickets["normal"]) == before, tag + ": Cancel spent nothing")
		# Confirm spends exactly 10
		_btn(s, "Open10Button").emit_signal("pressed")
		await _settle()
		(s.find_child("Open10Confirm", true, false).find_child("Open10Button", true, false) as Button).emit_signal("pressed")
		await _settle()
		var tn := int(MetaState.tickets["normal"])
		_check(tn == before - 10 or tn == before - 9, tag + ": Confirm spends 10 tickets (%d -> %d; a duplicate may refund 1)" % [before, tn])
		MetaState.tickets["normal"] = before
		s.results = []
		s._refresh_all()
		await _settle()
	s.close_modal()
	# rates
	s.open_rates()
	await _settle()
	_names(s, ["RatesModal", "CloseButton", "RatesTable"], tag + " rates")
	_check((_btn(s, "CloseButton")).has_focus(), tag + ": Close has focus")
	_audit(s, sc, tag + " rates")
	s.close_modal()
	# buy confirm
	s.open_confirm_buy()
	await _settle()
	_names(s, ["BuyTicketConfirm", "CancelButton", "BuyButton"], tag + " buy-confirm")
	_check(_btn(s, "CancelButton").has_focus(), tag + ": buy Cancel has focus")
	_audit(s, sc, tag + " buy-confirm")
	s.close_modal()
	var bb := _btn(s, "BuyTicketButton")
	_check(bb.find_child("ShardIcon", true, false) != null and bb.find_child("BuyText", true, false) != null, tag + ": Buy ticket carries the Shard icon cluster")
	# seasonal
	s.select_tab("seasonal")
	await _settle()
	_names(s, SEASON, tag + " seasonal")
	_audit(s, sc, tag + " seasonal")
	_check(String(_btn(s, "Open1Button").theme_type_variation).begins_with("ButtonPrimary"), tag + ": seasonal Open 1 is the primary")
	_check(s.find_child("CostChip", true, false) != null, tag + ": season CostChip")
	# a taken milestone reads "Done"
	var sid0 := String(EchoBox.season_cfg().get("series_id", "s1"))
	var sbm: Dictionary = (MetaState.season_box as Dictionary).duplicate(true)
	sbm[sid0] = {"opens": 12, "c_epic": 0, "c_legendary": 0, "c_mythic": 0, "owned": [], "milestones": ["m12"], "day": "", "day_pulls": 0}
	MetaState.season_box = sbm
	s.select_tab("regular")
	s.select_tab("seasonal")
	await _settle()
	var m12 := s.find_child("Milestone_12", true, false) as Label
	_check(m12 != null and m12.text.begins_with("Done 12 pulls"), tag + ": Milestone_12 reads Done ('%s')" % (m12.text if m12 else "none"))
	var m40 := s.find_child("Milestone_40", true, false) as Label
	_check(m40 != null and m40.text.begins_with("At 40 pulls"), tag + ": Milestone_40 still reads At")
	MetaState.season_box = {}
	# rates (season)
	s.open_rates()
	await _settle()
	_names(s, ["RatesModal", "CloseButton", "RatesTable"], tag + " rates-season")
	_check(_btn(s, "CloseButton").has_focus(), tag + ": season Close has focus")
	var rt := ""
	for n in s.find_child("RatesModal", true, false).find_children("*", "Label", true, false):
		rt += (n as Label).text + "\n"
	_check(rt.find("Season box") >= 0 and rt.find("Mythic: cap") >= 0 and rt.find("rises with every pull that misses it") >= 0, tag + ": season rates text")
	_audit(s, sc, tag + " rates-season")
	s.close_modal()
	# the first season pull confirms; nothing is spent before it
	MetaState.tickets["normal"] = 24
	var bt := int(MetaState.tickets["normal"])
	s.season_confirmed = false
	s._on_season_open(1)
	await _settle()
	var sconf := s.find_child("SeasonConfirm", true, false)
	_check(sconf != null, tag + ": SeasonConfirm shown")
	if sconf != null:
		_names(s, ["CancelButton", "OpenButton"], tag + " seasonal-confirm")
		_check(_btn(s, "CancelButton").has_focus(), tag + ": season Cancel has focus")
		_check(Ui5Keycap.all_under(_btn(s, "OpenButton")).is_empty(), tag + ": season Open has no keycap")
		_check(int(MetaState.tickets["normal"]) == bt, tag + ": nothing spent before the season confirm")
		_audit(s, sc, tag + " seasonal-confirm")
	s.close_modal()
	# daily cap: Open 1 says so in its own label, disabled, no keycap
	var sb0: Dictionary = (MetaState.season_box as Dictionary).duplicate(true)
	var sid := String(EchoBox.season_cfg().get("series_id", "s1"))
	var sb: Dictionary = (MetaState.season_box as Dictionary).duplicate(true)
	var ent: Dictionary = sb.get(sid, {})
	ent["day"] = s.today()
	ent["day_pulls"] = s.season_cap_day()
	sb[sid] = ent
	MetaState.season_box = sb
	s.select_tab("regular")
	s.select_tab("seasonal")
	await _settle()
	_check(s.season_pulls_left() == 0, tag + ": no season pulls left")
	_check(_btn(s, "Open1Button").disabled and _btn(s, "Open1Button").text.find("today") >= 0, tag + ": seasonal-cap text on Open 1 ('%s')" % _btn(s, "Open1Button").text)
	_check(Ui5Keycap.all_under(_btn(s, "Open1Button")).is_empty(), tag + ": no keycap on the disabled Open 1")
	_audit(s, sc, tag + " seasonal-cap")
	MetaState.season_box = sb0
	await _free(s)
	# no tickets
	s = await _make(sc, 0)
	_names(s, ["Open1Button", "BuyPullButton"], tag + " no-tickets")
	_check(_btn(s, "Open1Button").disabled, tag + ": Open 1 disabled")
	_check(_btn(s, "Open1Button").text == "Open 1 · Not enough tickets (0 of 1)", tag + ": Open 1 says why ('%s')" % _btn(s, "Open1Button").text)
	_check(s.find_child("Open10Button", true, false) == null, tag + ": no Open 10 when even one pull is blocked")
	_check(Ui5Keycap.all_under(_btn(s, "Open1Button")).is_empty(), tag + ": no keycap on the disabled Open 1")
	_audit(s, sc, tag + " no-tickets")
	await _free(s)
	# offline / guest (remote wallet) / error / loading / last pull
	for st in ["offline", "guest", "error", "loading", "last_pull"]:
		s = await _make(sc, 24, st, true)
		s.set_state(st)
		await _settle()
		if st == "last_pull":
			s.results = [{"kind": "stone", "amount": 250}, {"kind": "cosmetic", "rarity": "common", "item": "x", "duplicate": false}, {"kind": "cosmetic", "rarity": "rare", "item": "y", "duplicate": true}]
			s.set_state("last_pull")
			await _settle()
			var sm := s.find_child("Summary", true, false)
			var stg := s.find_child("Stage", true, false)
			_check(sm != null and stg != null and stg.is_ancestor_of(sm), tag + ": last-pull Summary sits inside the Stage")
			_check(s.find_child("ToneDisc", true, false) != null, tag + ": last-pull Banner has its ToneDisc")
		if st != "loading":
			_check(s.find_child("Banner", true, false) != null, "%s %s: Banner" % [tag, st])
		if st == "offline" or st == "error":
			_check(s.find_child("TryAgainButton", true, false) != null, "%s %s: TryAgainButton" % [tag, st])
		if st == "guest":
			_check(s.find_child("SignInButton", true, false) != null, "%s guest: SignInButton" % tag)
		if st == "offline" or st == "guest":
			_check(_btn(s, "Open1Button").disabled and _btn(s, "BuyTicketButton").disabled, "%s %s: pulls and buying are off, with reasons" % [tag, st])
		_audit(s, sc, "%s %s" % [tag, st])
		await _free(s)
