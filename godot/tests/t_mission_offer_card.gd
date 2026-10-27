extends Node
## Beta Missions offer card (brainstorm section 5): rules in words, Stake -> Win back -> Net, the bot estimate
## labelled as an estimate, fixed warnings from N3 up, a disabled Stake button that says why.

var _fail: Array[String] = []
var _checks := 0
var _guard := SaveGuard.new()


func _ok(c: bool, msg: String) -> void:
	_checks += 1
	if not c:
		_fail.append(msg)


func _texts(n: Node, out: Array) -> void:
	if n is Label:
		out.append((n as Label).text)
	for c in n.get_children():
		_texts(c, out)


func _ready() -> void:
	print("=== t_mission_offer_card: start ===")
	_guard.capture()
	ProjectSettings.set_setting("axie/epoch_source", "local")
	MetaState.saved_run_probe = func() -> bool: return false
	MetaState.runs = 8
	MetaState.runs_with_battle = 8
	MetaState.shard_pool = 9000
	MetaState.starter_shard_locked = 0
	MetaState.mission_escrow = {}
	MetaState.set_mission_unlocks(["N1", "N2"], false)
	var s: MissionsScreen = load("res://scenes/missions/MissionsScreen.tscn").instantiate()
	s.use_account = false
	s.remote_on = false
	s.no_scene_change = true
	add_child(s)
	await get_tree().process_frame
	var cfg: Dictionary = MissionBoard.config()
	for id in ["N1", "N2", "N3", "N4", "N5", "N6"]:
		s.select_tier(id)
		await get_tree().process_frame
		var o := s.offer(id)
		var t: Dictionary = cfg.tiers[id]
		_ok(int(o.net) == int(o.payout) - int(o.stake), "%s net = payout - stake" % id)
		var money: Node = s.find_child("Money", true, false)
		_ok(money != null, "%s money block" % id)
		var txt: Array = []
		_texts(s.find_child("DetailBody", true, false), txt)
		var all := "\n".join(txt)
		_ok(all.find(UI3.fmt(int(o.stake))) >= 0 and all.find(UI3.fmt(int(o.payout))) >= 0 and all.find("+" + UI3.fmt(int(o.net))) >= 0,
			"%s shows stake, win back and net" % id)
		_ok(all.find("Estimate (bot)") >= 0, "%s estimate is labelled" % id)
		var rl: Node = s.find_child("RuleLines", true, false)
		_ok(rl != null and rl.get_child_count() == 1 + (t.rules as Array).size(), "%s rule lines = standard + %d" % [id, (t.rules as Array).size()])
		var w := s.find_child("Warning", true, false)
		match id:
			"N1", "N2":
				_ok(w == null, "%s has no fixed warning" % id)
			"N3", "N4":
				_ok(w != null and (w as Label).text == "Most players lose this tier.", "%s: most players lose" % id)
			"N5":
				_ok(w != null and (w as Label).text.begins_with("Challenge tier"), "N5 challenge warning")
			"N6":
				_ok(w != null and (w as Label).text.begins_with("Title tier"), "N6 title warning")
		var b := s.find_child("Stake", true, false) as Button
		if bool(o.unlocked):
			_ok(not b.disabled and b.text == "Stake %d and play" % int(o.stake), "%s button enabled" % id)
		else:
			_ok(b.disabled and b.text == s.lock_text(o) and b.text.begins_with("Win ") and b.text.ends_with(" to unlock") and b.text.contains(String(o.unlock_prev)), "%s disabled with the reason: %s" % [id, b.text])
	_ok(s.find_child("DetailScroll", true, false) != null, "detail card scrolls instead of cutting rows")
	# not enough Shard: the reason says how much
	s.select_tier("N2")
	MetaState.shard_pool = 450
	s._refresh()
	_ok((s.find_child("Stake", true, false) as Button).text == "Need 50 more Shard", "short of Shard: reason shown")
	# confirm modal: net and "no refund" in words
	MetaState.shard_pool = 9000
	s._refresh()
	s.open_confirm("N2")
	await get_tree().process_frame
	var mt: Array = []
	_texts(s.find_child("Modal", true, false), mt)
	var mall := "\n".join(mt)
	_ok(mall.find("no refund") >= 0 and mall.find("Estimate (bot)") >= 0 and mall.find("net +") >= 0, "confirm modal states net, estimate and no refund")
	s.queue_free()
	MetaState.saved_run_probe = Callable()
	_guard.restore()
	if _fail.is_empty():
		print("t_mission_offer_card: PASS (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		for f in _fail:
			print("FAIL: ", f)
		print("t_mission_offer_card: FAIL")
		get_tree().quit(1)
