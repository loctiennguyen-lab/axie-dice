extends Node
## UI-06 L2 review fixes: counts on a combat strip (show_counts=true) never cover the Anchor tile / emblems, Core and
## Anchor tooltips are no taller than their content, CoreFireFX follows Reduce motion / Reduce flashing.
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


func _overlap(a: Rect2, b: Rect2) -> float:
	var i := a.intersection(b)
	return i.size.x * i.size.y if i.has_area() else 0.0


func _ready() -> void:
	_guard.capture()
	RunState.start_new_run(424242, ["plant1", "beast1", "aqua1", "reptile1", "bug1"] as Array[String], "short", 0, false)
	AnchorAdapter.test_state = {"anchor_id": "a_volley", "owned": [], "awakened": false}
	for id in ["c_bastion", "c_fissure"]:
		RunState.owned_relic_ids.append(id)
	RunState.run_rule = "rule_pack_alpha"
	var host := Control.new()
	host.theme = UI3Theme.get_theme()
	add_child(host)
	var p := CorePanel.new()
	p.slot_px = 44
	p.show_counts = true
	host.add_child(p)
	p.refresh()
	await _frames()
	# 1. counts
	var badge := p.anchor_slot.get_node("AnchorBadge") as Label
	_ok(not badge.visible, "not awakened: no text badge over the Anchor tile")
	AnchorAdapter.test_state = {"anchor_id": "a_volley", "owned": [], "awakened": true}
	p._fires["a_volley"] = 3
	p._update_anchor_badge()
	_ok(badge.visible and badge.text == "x3", "awakened: xN badge stays (%s)" % badge.text)
	var slot: Control = p._slot_by_id["c_bastion"]
	p._fires["c_bastion"] = 1
	p._update_count(slot, "c_bastion")
	await _frames()
	var cnt := slot.find_child("FireCount", true, false) as Label
	var em := slot.find_child("FamilyEmblem", true, false) as Control
	_ok(cnt != null and cnt.visible and cnt.text == "x1", "core count visible")
	if cnt != null and em != null:
		var la := cnt.get_global_rect().size.x * cnt.get_global_rect().size.y
		_ok(_overlap(cnt.get_global_rect(), em.get_global_rect()) <= la * 0.25, "xN does not sit on the emblem")
	# 2 + 3. tooltips no taller than content
	for id in ["c_bastion", "a_volley"]:
		var anchor: bool = id.begins_with("a_")
		var tgt := Control.new()
		tgt.custom_minimum_size = Vector2(40, 40)
		host.add_child(tgt)
		CoreTooltip.bind(tgt, id, false, "x")
		await _frames(2)
		CoreTooltip.show_now(tgt)
		await _frames(4)
		var plate: Control = CoreTooltip.shown(get_tree())
		_ok(plate != null, "%s tooltip shown" % id)
		if plate != null:
			var title := plate.find_child("CoreName", true, false) as Label
			_ok(title != null and (title.text == AnchorAdapter.name_of(id) if anchor else title.text != ""), "%s tooltip title" % id)
			var col := plate.get_child(0).get_child(0) as Control
			var want := col.get_combined_minimum_size().y + 2.0 * UI3Theme.space("16")
			_ok(plate.size.y <= want + 4.0, "%s tooltip height %.0f <= content %.0f" % [id, plate.size.y, want])
			if anchor:
				_ok(plate.find_children("CoreName", "Label", true, false).size() == 1, "anchor tooltip has one title")
		CoreTooltip.hide_all(get_tree())
		await _frames(2)
	# 9. FX flags
	var fxs: Array = []
	for mode in ["quiet", "full"]:
		CombatView.disable_juice_for_tests = mode == "quiet"
		var fx := CoreFireFX.new().setup(p, func(_u: int) -> Vector2: return Vector2(900, 500))
		host.add_child(fx)
		fx.fire("c_bastion", 1, 3, "shield")
		await get_tree().process_frame
		var ring := fx.find_child("FireRing", true, false) as Control
		var line := fx.find_child("FireLine", true, false)
		_ok(line == null, "%s: no FireLine any more" % mode)
		var mote := fx.find_child("FireMote", true, false)
		_ok(mote == null, "%s: no travelling particles any more" % mode)
		_ok(ring != null, "%s: ring exists" % mode)
		if mode == "quiet":
			_ok(ring != null and ring.modulate.a <= 0.121, "reduced flashing: ring alpha <= 0.12")
		else:
			_ok(ring != null and ring.modulate.a > 0.5, "full: ring bright")
		fxs.append(fx)
	CombatView.disable_juice_for_tests = false
	AnchorAdapter.test_state = {}
	_guard.restore()
	if _fails.is_empty():
		print("t_ui6_l2_review: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
	else:
		for f in _fails:
			print("FAIL: ", f)
		get_tree().quit(1)
