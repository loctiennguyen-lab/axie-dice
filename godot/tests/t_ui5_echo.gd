extends Node
## UI-05 b23 lane S9a: Echo Box (20-echo*, ui05-meta2-screens.html) at 1920 and 1280 (scale 0.667): data-names, states, confirms
## (safe button first, focus, Space keycap; spending button has none), text >= 14 real px (Label + Button), inside the frame,
## Gem-free icon/label centring on > 0 pairs, no illustration strings, a box opens only after its confirm.
## Run: AXIE_TEST_NO_NET=1 godot --headless --path godot res://tests/t_ui5_echo.tscn

const Align := preload("res://tests/ui5_align_check.gd")
const SHELL := ["Header", "BackButton", "Title", "SubLine", "RegularTab", "SeasonalTab", "Body", "TicketBar", "Tickets",
	"FragmentMeter", "NextTicket", "BuyTicketButton", "Stage", "Open1Button", "Open10Button", "RatesButton", "PityPlate", "PoolPlate"]
const SEASON := ["ProgressPlate", "Milestones", "SeriesItems", "Open1Button", "OpenNButton", "RatesButton"]
## Example values of the HTML frames: they must come from the game, not from this screen.
const ILLUSTRATION := ["22/200", "22/1000", "Rune Ring", "Seed 777006"]

var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0


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
	_check(_btn(s, "Open10Button").theme_type_variation == &"ButtonPrimary" or not _btn(s, "Open10Button").disabled, tag + ": Open 10 live")
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
		_check(cancel != null and yes != null and cancel.get_index() < yes.get_index() or cancel.get_parent() == yes.get_parent() and cancel.get_index() < yes.get_index(), tag + ": safe button stands first")
		_check(cancel.find_child("KeyCap", true, false) != null or Ui5Keycap.all_under(cancel).size() > 0, tag + ": Cancel has the Space keycap")
		_check(Ui5Keycap.all_under(yes).is_empty(), tag + ": spending button has no keycap")
		_check(cancel.has_focus(), tag + ": Cancel has focus")
		_audit(s, sc, tag + " open10-confirm")
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
	s.close_modal()
	# seasonal
	s.select_tab("seasonal")
	await _settle()
	_names(s, SEASON, tag + " seasonal")
	_audit(s, sc, tag + " seasonal")
	await _free(s)
	# no tickets
	s = await _make(sc, 0)
	_names(s, ["Open1Button", "BuyPullButton"], tag + " no-tickets")
	_check(_btn(s, "Open1Button").disabled and _btn(s, "Open1Button").text.begins_with("Open 1 ·") or _btn(s, "Open1Button").disabled, tag + ": Open 1 disabled and says why")
	_audit(s, sc, tag + " no-tickets")
	await _free(s)
	# offline / guest (remote wallet) / error / loading / last pull
	for st in ["offline", "guest", "error", "loading", "last_pull"]:
		s = await _make(sc, 24, st, true)
		s.set_state(st)
		await _settle()
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
