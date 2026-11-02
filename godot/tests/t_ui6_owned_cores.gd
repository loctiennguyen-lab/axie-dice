extends Node
## UI-06 L2: owned Cores strip (data-names, 1920 + 1280, text >= 14 px, align), CoreTooltip / RunRuleTooltip, the pause
## menu rows, and CoreFireFX in a real fight: a Core fire lights its socket, an Anchor fire a gold tile, a preview
## (CoreHooks.mute) lights nothing, a burst never has more than 6 live.
const Align := preload("res://tests/ui5_align_check.gd")
var _guard := SaveGuard.new()
var _checks := 0
var _fails: Array[String] = []


func _ok(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_fails.append(m)


func _frames(n := 4) -> void:
	for _i in n:
		await get_tree().process_frame


func _small(root: Node, tag: String, sc: float) -> void:
	var bad := []
	for l in root.find_children("*", "Label", true, false):
		var lab := l as Label
		if lab.is_visible_in_tree() and lab.text != "" and float(lab.get_theme_font_size("font_size")) * sc < 13.99:
			bad.append(lab.text)
	_ok(bad.is_empty(), "%s: text >= 14 real px (%s)" % [tag, str(bad)])


func _ready() -> void:
	CombatView.disable_juice_for_tests = true
	_guard.capture()
	RunState.start_new_run(424242, ["plant1", "beast1", "aqua1", "reptile1", "bug1"] as Array[String], "short", 0, false)
	AnchorAdapter.test_state = {"anchor_id": "a_volley", "owned": [], "awakened": false}
	var cores := ["c_bastion", "c_fissure", "c_plague_spread"]
	for id in cores:
		RunState.owned_relic_ids.append(id)
	RunState.run_rule = "rule_pack_alpha"
	for sc in [1.0, 2.0 / 3.0]:
		UI3Theme.set_scale_override(sc)
		var tag := "scale %.2f" % sc
		var host := Control.new()
		host.theme = UI3Theme.get_theme()
		add_child(host)
		var p := CorePanel.new()
		p.slot_px = 40
		host.add_child(p)
		p.refresh()
		await _frames()
		for n in ["CoreStrip", "AnchorTile", "CoreSlot", "FamilyEmblem", "TierShards", "RunRuleSlot", "RunRuleEmblem", "AwakenPips"]:
			_ok(p.find_child(n + "*", true, false) != null, "%s: node %s" % [tag, n])
		_ok(p.find_children("CoreSlot*", "PanelContainer", true, false).size() == 6, "%s: 6 sockets" % tag)
		_small(host, tag, sc)
		_ok(Align.check(host).is_empty(), "%s: aligned" % tag)
		host.queue_free()
		# menu rows
		var pm := RunPauseMenu.new()
		add_child(pm)
		pm.build({"floor": 4, "total": 18, "ascension": 0, "shards": 40})
		pm.show_side("relics")
		await _frames()
		for n in ["AnchorRow", "OwnedCore", "Headline", "OwnedRule", "RunRuleSlot", "TierShards"]:
			_ok(pm.find_child(n + "*", true, false) != null, "%s: menu node %s" % [tag, n])
		_small(pm, tag + " menu", sc)
		_ok(Align.pairs(pm) > 0 and Align.check(pm).is_empty(), "%s: menu aligned (%d pairs)" % [tag, Align.pairs(pm)])
		pm.queue_free()
	UI3Theme.set_scale_override(1.0)
	# tooltips
	var tip := CoreTooltip.build("c_bastion", false)
	for n in ["CoreName", "TierLine", "Detail", "BadgeRow"]:
		_ok(tip.find_child(n, true, false) != null, "CoreTooltip %s" % n)
	_ok(CoreTooltip.build("rule_pack_alpha", true).name == "RunRuleTooltip", "RunRuleTooltip name")
	tip.free()
	# firing in a real fight
	AnchorAdapter.test_state = {}
	RunState.enter_node("r1_c0", "battle")
	var v: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(v)
	await _frames(60)
	var fx: CoreFireFX = v.core_fx
	var cp: CorePanel = v._hud_frame.core_panel
	_ok(fx != null and fx.get_parent() == v._hud_frame, "CoreFireFX in the HUD")
	var ally: int = v._combat.party[0].uid
	var foe: int = v._combat.enemies[0].uid
	var floats0 := v.core_float_log.size()
	EventBus.core_fired.emit("c_bastion", ally, 3, "shield")
	await _frames(3)
	# one number per fire: the float note (name + amount) is the only one, the FX draws none
	_ok(fx.find_children("FireNumber", "", true, false).is_empty(), "FX draws no second number")
	_ok(v.core_float_log.size() == floats0 + 1 and String((v.core_float_log.back()["lines"] as Array)[0]).contains("3"), "one float note with name + number per fire")
	_ok(fx.log.size() == 1 and not fx.log[0]["anchor"] and fx.find_child("FireRing", true, false) != null, "Core fire lights its socket")
	_ok(cp._slot_by_id.has("c_bastion"), "socket exists for the fired Core")
	# preview: muted, nothing starts
	var before := fx.log.size()
	CoreHooks.mute += 1
	CoreHooks.fire("c_bastion", ally, 5, "shield")
	CoreHooks.mute -= 1
	await _frames(3)
	_ok(fx.log.size() == before, "preview (mute) does not light a socket")
	# Anchor fire: gold tile
	AnchorAdapter.test_state = {"anchor_id": "a_volley", "owned": [], "awakened": false}
	cp._sig = ""
	cp.refresh()
	await get_tree().create_timer(0.25).timeout
	EventBus.core_fired.emit("a_volley", foe, 6, "dmg")
	await _frames(3)
	_ok(fx.log.back()["anchor"] and fx.find_child("AnchorFireFX", true, false) != null, "Anchor fire = AnchorFireFX")
	_ok(fx.find_children("FireNumber", "", true, false).is_empty(), "Anchor fire draws no FX number either")
	# burst of 10: never more than 6 live, all eventually start
	for i in 10:
		EventBus.core_fired.emit("c_fissure", foe, 1 + i, "dmg")
	await _frames(2)
	_ok(fx.queued() > 0, "burst queues (180 ms apart)")
	await get_tree().create_timer(2.4).timeout
	_ok(fx.max_seen <= CoreFireFX.MAX_LIVE and fx.queued() == 0, "burst: max live %d, queue %d" % [fx.max_seen, fx.queued()])
	v.queue_free()
	_guard.restore()
	AnchorAdapter.test_state = {}
	if _fails.is_empty():
		print("t_ui6_owned_cores: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
	else:
		for f in _fails:
			print("t_ui6_owned_cores: FAIL — %s" % f)
		get_tree().quit(1)
