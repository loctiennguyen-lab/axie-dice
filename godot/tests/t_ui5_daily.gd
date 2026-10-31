extends Node
## UI-05 b23 lane S11a: Daily against 41-daily--* (ui05-meta2-screens.html). Names, states (unclaimed / claimed / gem-gift /
## cap / claiming / offline / guest), data-driven numbers (no illustrative strings), 1920 + 1280, align check (> 0 pairs),
## real text >= 14 px, initial focus.
const Align := preload("res://tests/ui5_align_check.gd")
var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0


func _ok(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_fails.append(m)


func _frames(n := 4) -> void:
	for _i in n:
		await get_tree().process_frame


func _ready() -> void:
	print("=== t_ui5_daily: start ===")
	_guard.capture()
	for sc in [1.0, 2.0 / 3.0]:
		UI3Theme.set_scale_override(sc)
		await _pass(sc)
	UI3Theme.set_scale_override(1.0)
	_guard.restore()
	print("=== t_ui5_daily: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("t_ui5_daily: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
	else:
		for f in _fails:
			print("FAIL: " + f)
		get_tree().quit(1)


func _screen(state: String, remote := false) -> DailyScreen:
	var d: DailyScreen = load("res://scenes/daily/DailyScreen.tscn").instantiate()
	d.use_account = false
	d.state = state
	d.remote_on = remote
	d.no_scene_change = true
	d.test_mode = true
	add_child(d)
	return d


func _btn(d: Node, n: String) -> Button:
	return d.find_child(n, true, false) as Button


func _texts(root: Node) -> String:
	var s := ""
	for n in root.find_children("*", "", true, false):
		if n is Label:
			s += (n as Label).text + "\n"
		elif n is Button:
			s += (n as Button).text + "\n"
	return s


func _small(root: Node, tag: String, sc: float) -> void:
	var bad := []
	for n in root.find_children("*", "", true, false):
		if (n is Label or n is Button) and (n as Control).is_visible_in_tree() and String(n.text) != "" \
				and float(n.get_theme_font_size("font_size")) * sc < 13.99:
			bad.append(String(n.text))
	_ok(bad.is_empty(), "%s: text >= 14 real px (%s)" % [tag, str(bad)])


func _pass(sc: float) -> void:
	var tag := "scale %.2f" % sc
	var today := MetaState.today_utc()
	MetaState.gem_gift_day = ""
	MetaState.gems_cache = 300
	MetaState.daily_date = ""
	# --- unclaimed: Daily Claim is the one primary, Gem is secondary
	var d := _screen("normal")
	d.day_override = today
	await _frames(6)
	for n in ["Header", "BackButton", "Title", "SubLine", "Body", "CardRow", "DailyCard", "DailyClaim", "WeeklyCard", "DayChip", "DayChip4",
			"WeeklyStatus", "GemGiftCard", "GemClaim"]:
		_ok(d.find_child(n, true, false) != null, "%s: node %s" % [tag, n])
	_ok(d.find_children("DayChip*", "", true, false).size() == 4, "%s: 4 day chips (weekly min_days)" % tag)
	_ok(not _btn(d, "DailyClaim").disabled and _btn(d, "DailyClaim").text == "Claim", "%s: Daily Claim live" % tag)
	_ok(_btn(d, "DailyClaim").theme_type_variation == "ButtonPrimaryL" and _btn(d, "GemClaim").theme_type_variation == "ButtonSecondary", "%s: one primary" % tag)
	_ok(_btn(d, "GemClaim").text == "Claim 300 Gem" and _btn(d, "GemClaim").find_child("GemIcon", true, false) != null, "%s: Gem claim secondary with icon, data amount" % tag)
	_ok(get_viewport().gui_get_focus_owner() == _btn(d, "DailyClaim"), "%s: initial focus on Daily Claim" % tag)
	var gb := _btn(d, "GemClaim")
	var gi := gb.find_child("GemIcon", true, false) as Control
	var gt := gb.find_child("GemText", true, false) as Control
	_ok(gi != null and gt != null and gb.icon == null, "%s: secondary Gem cluster (icon + text)" % tag)
	if gi != null and gt != null:
		var ri := Rect2(gi.global_position, gi.size)
		var rt := Rect2(gt.global_position, gt.size)
		_ok(ri.end.x <= rt.position.x + 0.5 and not ri.intersects(rt), "%s: icon left of the text, no overlap" % tag)
		var cx := (ri.position.x + rt.end.x) * 0.5
		var bx := gb.global_position.x + gb.size.x * 0.5
		_ok(absf(cx - bx) <= 2.0, "%s: cluster centred on the button (off by %.1f)" % [tag, cx - bx])
	_ok(_btn(d, "BackButton").text == "←", "%s: back arrow" % tag)
	_ok(Ui5Keycap.all_under(d).is_empty(), "%s: no keycap (frames draw none)" % tag)
	var txt := _texts(d)
	for bad in ["Liam", "2,450", "Lakebed Fishing Rod"]:
		_ok(not txt.contains(bad), "%s: no illustrative string %s" % [tag, bad])
	_small(d, tag + " unclaimed", sc)
	_ok(Align.pairs(d) > 0, "%s: align pairs (%d)" % [tag, Align.pairs(d)])
	_ok(Align.check(d).is_empty(), "%s: icon/label centred %s" % [tag, str(Align.check(d))])
	# --- claim then gem-gift primary
	d.claim_daily()
	await _frames(3)
	_ok(_btn(d, "DailyClaim").disabled and _btn(d, "DailyClaim").text == "Claim · Claimed today", "%s: claimed says why" % tag)
	var dc := _btn(d, "DailyClaim").get_global_rect()
	var dcard := d.find_child("DailyCard", true, false) as Control
	var rows_ok := true
	for rn in ["RewardShards", "RewardStone", "RewardXp"]:
		var rr := d.find_child(rn, true, false) as Control
		if rr == null or rr.get_global_rect().intersects(dc) or rr.get_global_rect().end.y > dc.position.y:
			rows_ok = false
	await get_tree().create_timer(0.6).timeout   # a claim moment (if it plays) has finished
	dc = _btn(d, "DailyClaim").get_global_rect()
	_ok(rows_ok and dcard.get_global_rect().encloses(dc) and not dc.intersects((d.find_child("RewardShards", true, false) as Control).get_global_rect()) and dc.position.y > (d.find_child("RewardXp", true, false) as Control).get_global_rect().end.y, "%s: claimed DailyClaim sits below the reward rows" % tag)
	_ok(d.find_child("ResultLine", true, false) != null and d.find_child("ToneDisc", true, false) != null, "%s: result line with ToneDisc" % tag)
	_ok(_btn(d, "GemClaim").theme_type_variation == "ButtonPrimaryL" and not _btn(d, "GemClaim").disabled, "%s: Gem claim is the primary now" % tag)
	_ok(_btn(d, "GemClaim").icon == null, "%s: primary Gem claim has no icon (text only)" % tag)
	_ok(get_viewport().gui_get_focus_owner() == _btn(d, "GemClaim"), "%s: focus moved to Gem claim" % tag)
	d.claim_gift()
	await _frames(3)
	_ok(_btn(d, "GemClaim").disabled and _btn(d, "GemClaim").text == "Claim 300 Gem · Claimed today", "%s: gift claimed says why" % tag)
	_small(d, tag + " claimed", sc)
	# --- weekly paid: 4 of 4, Daily not claimed yet
	MetaState.daily_date = ""
	d.daily_result = ""
	d.last_result = ""
	MetaState.daily_week = {"week": PassV2.week_key(MetaState.today_utc()), "n": 4, "paid": true}
	d._refresh()
	await _frames(2)
	_ok(_btn(d, "WeeklyStatus").text == "Paid this week", "%s: weekly paid says Paid this week" % tag)
	_ok(_btn(d, "DailyClaim").text == "Claim" and not _btn(d, "DailyClaim").disabled, "%s: Daily still claimable when weekly is paid" % tag)
	_ok(d.find_child("ToneDisc", true, false) == null, "%s: no ToneDisc without a result" % tag)
	MetaState.daily_week = {}
	# --- cap
	MetaState.gem_gift_day = ""
	MetaState.gems_cache = 900
	d._refresh()
	await _frames(2)
	_ok(_btn(d, "GemClaim").text == "Claim 300 Gem · At the cap", "%s: at the cap" % tag)
	# --- claiming
	MetaState.gems_cache = 0
	d._gift_pending = true
	d._refresh()
	await _frames(2)
	_ok(_btn(d, "GemClaim").disabled and _btn(d, "GemClaim").text == "Claiming…", "%s: claiming" % tag)
	d.queue_free()
	await _frames(2)
	# --- offline / guest (server wallet flag on)
	MetaState.daily_date = ""
	var o := _screen("offline", true)
	await _frames(5)
	_ok(o.find_child("Banner", true, false) != null and o.find_child("ToneDisc", true, false) != null, "%s: offline banner" % tag)
	_ok(o.find_child("SignInButton", true, false) == null, "%s: offline has no sign-in button" % tag)
	_ok(_btn(o, "DailyClaim").text == "Claim · Needs a connection" and _btn(o, "GemClaim").text == "Claim 300 Gem · Needs a connection", "%s: offline reasons" % tag)
	o.queue_free()
	await _frames(2)
	var g := _screen("guest", true)
	await _frames(5)
	_ok(g.find_child("SignInButton", true, false) != null, "%s: guest SignInButton" % tag)
	(g.find_child("SignInButton", true, false) as Button).pressed.emit()
	_ok(g.sign_in_calls == 1, "%s: Sign in calls the account hook" % tag)
	_ok(_btn(g, "DailyClaim").text == "Claim · Sign in to claim" and _btn(g, "DailyClaim").disabled, "%s: guest reasons" % tag)
	_ok(_texts(g).contains("0 of 4 days · pays on day 4"), "%s: guest weekly 0 of 4" % tag)
	_small(g, tag + " guest", sc)
	g.queue_free()
	await _frames(2)
