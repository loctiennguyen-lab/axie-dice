extends Node
## UX hunt 27/10, meta screens: guest Land button follows the build, Echo Box cost on buttons + confirm for
## Open 10, Daily chip words, NetNotice action wording, toast queue, Profile list vs counter, Land tier banner.
## Run: godot --headless --path godot res://tests/t_meta_ux_hunt.tscn

var _fails: Array[String] = []
var _checks := 0
var _guard := SaveGuard.new()


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)
		printerr("FAIL: ", msg)


func _ready() -> void:
	print("=== t_meta_ux_hunt: start ===")
	_guard.capture()
	MetaState.tutorial_seen = true
	LandNav.dry_run = true
	await _land_guest()
	await _echo()
	_daily_net_profile()
	_header_guest()
	await _toast_queue()
	_guard.restore()
	_finish()


func _land(qa: Dictionary) -> LandHub:
	LandHub.qa = qa
	var h := (load("res://scenes/land/Land.tscn") as PackedScene).instantiate() as LandHub
	add_child(h)
	await get_tree().process_frame
	return h


func _land_guest() -> void:
	var was: Variant = ProjectSettings.get_setting("axie/epoch_source", "")
	ProjectSettings.set_setting("axie/epoch_source", "remote")
	var h := await _land({"guest": true})
	_check((h.find_child("RunPlate", true, false) as Button).text == "Sign in to play", "server build: guest button says Sign in to play")
	_check("server" in (h.find_child("RunPlate", true, false) as Button).tooltip_text, "server build: tooltip says why")
	h.queue_free()
	await get_tree().process_frame
	ProjectSettings.set_setting("axie/epoch_source", "")
	h = await _land({"guest": true})
	_check((h.find_child("RunPlate", true, false) as Button).text == "Start run", "local build: guest can start a run")
	LandNav.last_path = ""
	(h.find_child("RunPlate", true, false) as Button).emit_signal("pressed")
	_check(LandNav.last_path != "", "local build: guest press goes to Run Setup")
	h.queue_free()
	await get_tree().process_frame
	ProjectSettings.set_setting("axie/epoch_source", was)
	# Upgrade chip is a real button, tier banner names the Stone used and where the new things are.
	h = await _land({"guest": false, "newcomer": false, "first_launch": false})
	_check(h.find_child("UpgradeLand", true, false) is Button, "Upgrade Land chip is a Button")
	MetaState.land_tier_banner_seen = 1
	h.set("_tier", 2)
	h.call("_show_tier_banner")
	var texts := ""
	for l in h.find_child("TierBanner", true, false).find_children("*", "Label", true, false):
		texts += (l as Label).text + "\n"
	_check("Used " in texts and "Stone" in texts, "banner says how much Stone was used: " + texts)
	_check("preset slots: House" in texts and "Edit Land" in texts, "banner says where the new things are")
	h.queue_free()
	await get_tree().process_frame
	LandHub.qa = {}


func _echo() -> void:
	MetaState.tickets = {"normal": 12, "season": 0}
	var s: EchoBoxScreen = load("res://scenes/echobox/EchoBoxScreen.tscn").instantiate()
	s.state = "normal"
	s.use_account = false
	s.remote_on = true
	s.no_scene_change = true
	s.instant = true
	add_child(s)
	await get_tree().process_frame
	_check((s.find_child("Open1", true, false) as Button).text == "Open 1 · 1 ticket", "Open 1 shows its cost")
	_check((s.find_child("OpenN", true, false) as Button).text == "Open 10 · 10 tickets", "Open 10 shows its cost")
	_check(s.find_child("PityHelp", true, false) != null, "pity help line")
	(s.find_child("OpenN", true, false) as Button).emit_signal("pressed")
	await get_tree().process_frame
	_check(s.find_child("ConfirmOpenN", true, false) != null, "Open 10 asks first")
	_check(s.tickets() == 12, "nothing spent before the confirm")
	s.close_modal()
	await get_tree().process_frame
	_check(s.tickets() == 12, "cancel spends nothing")
	s.queue_free()
	await get_tree().process_frame


func _daily_net_profile() -> void:
	_check(DailyScreen.day_chip_text(1, true) == "Day 1 · claimed" and DailyScreen.day_chip_text(3, false) == "Day 3 · not yet", "weekly chips say claimed / not yet")
	var off := NetNotice.text_for("offline", "Could not send your turn")
	_check(off.begins_with("Could not send your turn.") and "Your run is saved" in off, "offline run action: named + run saved")
	var w := NetNotice.text_for("offline", "Could not load your wallet", false)
	_check(w.begins_with("Could not load your wallet.") and not ("run is saved" in w), "wallet action: no run-saved line")
	_check(NetNotice.text_for("offline") == "Can't reach the server. Your run is saved.", "no action: old text unchanged")
	_check(not ProfileView.empty_runs_text(14).begins_with("No runs yet"), "profile: counter 14 does not say No runs yet")
	_check(ProfileView.empty_runs_text(0).begins_with("No runs yet"), "profile: 0 runs says No runs yet")


func _header_guest() -> void:
	var was: Variant = ProjectSettings.get_setting("axie/epoch_source", "")
	ProjectSettings.set_setting("axie/epoch_source", "remote")
	var guest := not AccountService.is_signed_in()
	var p := UI3Meta.currency_plate()
	add_child(p)
	_check(p.visible == (not guest), "header wallet: hidden for a guest on the server build, shown for a signed-in player")
	ProjectSettings.set_setting("axie/epoch_source", "")
	var p2 := UI3Meta.currency_plate()
	add_child(p2)
	_check(p2.visible, "header wallet: local-econ build unchanged")
	p.queue_free()
	p2.queue_free()
	ProjectSettings.set_setting("axie/epoch_source", was)


func _toast_queue() -> void:
	var h := await _land({"guest": false, "newcomer": false, "first_launch": false})
	h.call("_show_toast", "one", 0.2)
	h.call("_show_toast", "two", 0.2)
	_check((h.get("_toasts") as Array).size() == 1 and (h.get("_toast_queue") as Array).size() == 1, "second toast waits")
	await get_tree().create_timer(1.0).timeout
	_check((h.get("_toast_queue") as Array).is_empty() and (h.get("_toasts") as Array).size() <= 1, "queued toast shown after the first")
	h.queue_free()
	await get_tree().process_frame
	LandHub.qa = {}


func _finish() -> void:
	if _fails.is_empty():
		print("PASS: t_meta_ux_hunt (%d checks)" % _checks)
	else:
		print("FAIL: t_meta_ux_hunt %d/%d" % [_fails.size(), _checks])
	get_tree().quit(0 if _fails.is_empty() else 1)
