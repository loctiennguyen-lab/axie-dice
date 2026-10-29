extends Node
## UI-05 b1 lane C: the EnemyColumn (EnemyColumn.place) and its plates.
## - 1 / 3 / 5 / 7 enemies and a boss with 0 / 2 / 4 summons, every intent a big hit (worst case), counter tabs on,
##   with and without the AttritionCard, at scale 1.0 (1920) and 0.667 (1280): no cluster, plate lip or AttritionCard
##   overlaps the ActionDock (real CombatHud) or the DiceDock, none overlap each other, all stay on screen.
## - Every plate is exactly its token width (enemy_card_w / boss_plate_w) and its content never asks for more,
##   the IntentBlock is enemy_intent_w and sits inside the plate, the BigHitStrip and label fit under the plate.
## - Name row: "Ravenling A" -> name + NameSuffix; tags go to their own row when the name row is full.
## - AttritionCard: enemy_card_w x attrition_h (the frame's in-column width), the three state strings, label fits,
##   right-aligned in the column it lands in.
## - EnemyColumn.stack() wraps into a second column to the left.
## - A hover / target label showing or hiding never flips the column between compact and full.
## - Node names match the HTML data-names (EnemyColumn, EnemyCluster1/2 on a real Combat scene; plate parts).

const VS := Vector2(1920, 1080)

var _fails: Array[String] = []
var _checks := 0
var _guard := SaveGuard.new()


func _ready() -> void:
	_guard.capture()
	print("=== t_ui5_enemy_column: start ===")
	_test_stack()
	await _test_scene_names()
	for sc in [1.0, 2.0 / 3.0]:
		UI3Theme.set_scale_override(sc)
		await _test_plates(sc)
		await _test_attrition(sc)
		for n in [1, 3, 5, 7]:
			for attr_on in [false, true]:
				await _test_column(sc, n, false, attr_on)
		for n in [0, 2, 4]:
			await _test_column(sc, n, true, true)
		await _test_label_stability(sc)
	UI3Theme.set_scale_override(-1.0)
	_guard.restore()
	print("=== t_ui5_enemy_column: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("t_ui5_enemy_column: PASS - %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _fails:
		print("t_ui5_enemy_column: FAIL - %s" % f)
	get_tree().quit(1)


func _ok(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_fails.append(msg)


func _frames(n := 3) -> void:
	for _i in n:
		await get_tree().process_frame


func _make(host: Control, uid: int, nm: String, boss: bool, tag := "") -> UnitPortrait:
	var p := UnitPortrait.new()
	host.add_child(p)
	p.setup(uid, nm, "", true, boss, tag)
	p.set_nick("", nm)
	p.update_stats(1200 if boss else 119, 1200 if boss else 119, 0, {})
	p.set_intent({"show": true, "type": "dmg", "num": 188, "label": "ATTACK", "target": "Olek", "big_hit": true})
	if boss:
		p.set_tab({"icon": HudKit.icon("boss-clock"), "text": "ENRAGE IN 9", "right": "then +20%/turn", "pips": []})
		p.set_phase(1, 2)
		p.set_shell(42, 42)
	else:
		p.set_tab({"bg": UI3Theme.color("accent"), "ink": UI3Theme.color("accent_text"), "icon": HudKit.icon("spike"),
			"text": "BIG HIT IN 2", "right": "HITS 30", "pips": []})
	return p


func _test_stack() -> void:
	var items := [Vector2(380, 300), Vector2(380, 300), Vector2(380, 300)]
	var pos := EnemyColumn.stack(items, 24.0, 700.0, 1896.0, 12.0)
	_ok(pos[0] == Vector2(1516, 24) and pos[1] == Vector2(1516, 336), "stack: first column top-right, 12 apart: %s" % str(pos))
	_ok(pos[2] == Vector2(1516 - 12 - 380, 24), "stack: third item wraps to a second column on the left: %s" % str(pos[2]))
	_ok(EnemyColumn.column_count(pos, 24.0) == 2, "stack: two columns")
	var tall := EnemyColumn.stack([Vector2(560, 900)], 24.0, 700.0, 1896.0, 12.0)
	_ok(tall[0] == Vector2(1336, 24), "stack: first item of a column always goes in")


func _test_plates(sc: float) -> void:
	var tag := "@%.3f" % sc
	var host := Control.new()
	host.size = VS
	add_child(host)
	var a := _make(host, 1, "Ravenling A", false)
	var e := _make(host, 2, "Elite Bulwark of the Deep Marsh", false, "ELITE")
	e.set_leader(true)
	e.set_shell(12, 30)
	var b := _make(host, 3, "Frost Lord the Unending", true, "BOSS")
	await _frames()
	for p in [a, e, b]:
		var pu := p as UnitPortrait
		var want := float(UI3Theme.size_of("boss_plate_w" if pu._is_boss else "enemy_card_w"))
		_ok(is_equal_approx(pu._plate.size.x, want), "%s %s: plate width %.1f == token %.0f" % [tag, pu._name_label.text, pu._plate.size.x, want])
		_ok(pu._plate.get_combined_minimum_size().x <= want + 0.5, "%s %s: plate content asks %.1f > token %.0f" % [tag, pu._name_label.text, pu._plate.get_combined_minimum_size().x, want])
		_ok(is_equal_approx(pu._intent_panel.size.x, float(UI3Theme.size_of("enemy_intent_w"))), "%s: IntentBlock width %.1f == enemy_intent_w" % [tag, pu._intent_panel.size.x])
		var pr := pu._plate.get_global_rect()
		_ok(pr.grow(0.5).encloses(pu._intent_panel.get_global_rect()), "%s: IntentBlock inside the plate" % tag)
		_ok(pr.grow(0.5).encloses(pu._hp_label.get_global_rect()), "%s: HPValue inside the plate" % tag)
		_ok(pu._strip.visible and pu._strip.size.x <= want + 0.5 and pu._strip.get_combined_minimum_size().x <= want + 0.5, "%s: BigHitStrip fits under the plate" % tag)
		_ok(pu._bang.visible and pu.is_big_hit(), "%s: BigHitBadge shown" % tag)
		var tf := pu._intent_num.get_theme_font("font")
		var fs := pu._intent_num.get_theme_font_size("font_size")
		_ok(fs == UI3Theme.size_of("text_banner"), "%s: IntentValue at text_banner (%d)" % [tag, fs])
		_ok(tf.get_string_size(pu._intent_action.text, HORIZONTAL_ALIGNMENT_LEFT, -1, pu._intent_action.get_theme_font_size("font_size")).x <= pu._intent_panel.size.x, "%s: verb fits the intent column" % tag)
		_ok(pu._plate.size.y < 260.0, "%s: plate height sane (%.0f)" % [tag, pu._plate.size.y])
	# Name row: suffix disc + the name without " A".
	# The label shows the name cut to its width with "…" (B9, Ui5Ellipsis); the name it was given is the full one.
	_ok(Ui5Ellipsis.full_text(a._name_label) == "Ravenling" and a._suffix_chip.visible, "%s: 'Ravenling A' -> name + NameSuffix" % tag)
	_ok(a._name_label.text == "Ravenling" or (a._name_label.text.ends_with("…") and "Ravenling".begins_with(a._name_label.text.trim_suffix("…"))),
		"%s: EnemyName shows 'Ravenling' or a cut ending in '…' ('%s')" % [tag, a._name_label.text])
	_ok((a._suffix_chip.get_node("Text") as Label).text == "A", "%s: suffix letter A" % tag)
	# Long elite + LEADER: the tag moves to its own row so the name keeps room; the tooltip has the full name.
	_ok(e._plate.tags_row.visible or e._plate.tag_box.visible, "%s: LEADER tag shown somewhere" % tag)
	_ok(e._leader_badge.visible, "%s: LEADER badge visible" % tag)
	_ok(String(e._click_catcher.get_meta("ui3_tip", "")).contains("Bulwark"), "%s: cut name -> full name in the tooltip" % tag)
	_ok(e.has_shell() and e._shell_label.text == "12/30", "%s: ShellValue 12/30" % tag)
	# Lit: the TargetRing, not the edge.
	a.set_targetable(true)
	await _frames(2)
	_ok(a._ring.visible and a._ring.size == a._plate.size, "%s: TargetRing on a legal target" % tag)
	a.set_targetable(false)
	# Damage preview keeps working: label under the plate, inside the plate width.
	a.set_preview_damage(30)
	await _frames(2)
	_ok(a._chip.visible and a._chip.size.x <= a._plate.size.x + 0.5, "%s: damage preview label under the plate" % tag)
	_ok(a._chip.position.y >= a._plate.size.y, "%s: preview label below the plate" % tag)
	a.set_preview_damage(500)
	_ok(a._lethal and a._hp_label.text.contains("0"), "%s: lethal preview text %s" % [tag, a._hp_label.text])
	a.clear_preview_damage()
	await _frames(2)
	_ok(not a._chip.visible and a._hp_label.text == "119 / 119", "%s: preview cleared (%s)" % [tag, a._hp_label.text])
	# Idle and no-move intents.
	a.set_intent({"show": true, "type": "blank", "num": 0, "label": "BLANK"})
	_ok(a._intent_action.text == "IDLE" and a._intent_num.text == "–" and not a.is_big_hit(), "%s: idle intent" % tag)
	a.set_intent({"show": false})
	_ok(a._intent_action.text == "NO MOVE", "%s: no move" % tag)
	host.queue_free()
	await _frames(1)


func _test_attrition(sc: float) -> void:
	var tag := "@%.3f" % sc
	var host := Control.new()
	host.size = VS
	add_child(host)
	var c := AttritionCard.new()
	host.add_child(c)
	var cases := [
		[{"start_turn": 6, "pct": 0}, 4, &"upcoming", "ATTRITION %s TURN 6" % HudKit.dot()],
		[{"start_turn": 6, "pct": 10}, 7, &"active", "ATTRITION +10%"],
		[{"start_turn": 6, "pct": 25}, 12, &"max", "ATTRITION +25%% %s MAX" % HudKit.dot()],
	]
	for cs in cases:
		c.apply(cs[0], cs[1], false)
		await _frames(2)
		_ok(c.visible and c.state == cs[2], "%s: attrition state %s" % [tag, cs[2]])
		_ok(c.label.text == cs[3], "%s: attrition text '%s'" % [tag, c.label.text])
		_ok(is_equal_approx(c.size.x, float(UI3Theme.size_of("enemy_card_w"))) and is_equal_approx(c.size.y, float(UI3Theme.size_of("attrition_h"))),
			"%s: AttritionCard %s == enemy_card_w x attrition_h" % [tag, c.size])
		var f := c.label.get_theme_font("font")
		_ok(f.get_string_size(c.label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, c.label.get_theme_font_size("font_size")).x <= c.label.size.x + 0.5,
			"%s: attrition label fits (%s)" % [tag, c.label.text])
	_ok(c.pips.get_child_count() == 0, "%s: no pips once running" % tag)
	c.apply({"start_turn": 6, "pct": 0}, 1, false)
	_ok(not c.visible, "%s: hidden on turn 1" % tag)
	c.apply({"start_turn": 6, "pct": 0}, 4, true)
	_ok(not c.visible, "%s: hidden for newcomers" % tag)
	host.queue_free()
	await _frames(1)


func _test_column(sc: float, n: int, boss: bool, attr_on: bool) -> void:
	var tag := "@%.3f %s%d attr=%s" % [sc, "boss+" if boss else "", n, attr_on]
	var host := Control.new()
	host.size = VS
	add_child(host)
	var hud := CombatHud.new()
	host.add_child(hud)
	hud.adopt_right_zone(Button.new(), Button.new(), Button.new())
	var cards: Array[UnitPortrait] = []
	var uid := 10
	if boss:
		cards.append(_make(host, uid, "Frost Lord", true, "BOSS"))
	for i in n:
		uid += 1
		cards.append(_make(host, uid, "Ravenling %s" % char(65 + i), false, "ELITE" if i == 0 and not boss else ""))
	await _frames()
	var dock_top := TrayColumn.dock_top(VS.y)
	var limit := minf(dock_top, hud.tray_top()) - float(UI3Theme.space("12"))
	var res := EnemyColumn.place(cards, attr_on, VS, limit)
	await _frames()
	res = EnemyColumn.place(cards, attr_on, VS, limit)   # again after the compact switch settled
	var action_r := (hud.get("_dock") as Control).get_global_rect()
	var dw := float(UI3Theme.size_of("dice_dock_w"))
	var dice_r := Rect2((VS.x - dw) * 0.5, dock_top, dw, VS.y - dock_top)
	var lip := (UI3Theme.get_theme().get_stylebox("panel", "PanelPlate") as StyleBoxFlat).shadow_offset.y
	var rects: Array[Rect2] = []
	for c in cards:
		var r := Rect2(c.position, Vector2(c.size.x, c.cluster_height(bool(res["compact"]))))
		r.size.y = maxf(r.size.y, c._plate.size.y + lip)
		rects.append(r)
		_ok(c.size.x <= float(UI3Theme.size_of("boss_plate_w" if c._is_boss else "enemy_card_w")) + 0.5, "%s: cluster wider than its token" % tag)
	if attr_on:
		var ap: Vector2 = res["attr"]
		var aw := float(UI3Theme.size_of("enemy_card_w"))
		var acr := float(res["attr_col_right"])
		rects.append(Rect2(ap, Vector2(aw, UI3Theme.size_of("attrition_h") + lip)))
		_ok(is_equal_approx(ap.x + aw, acr), "%s: AttritionCard right edge %.1f == its column's right %.1f" % [tag, ap.x + aw, acr])
		# The column's right is real: the first column ends at the margin; a wrapped one ends 12 left of the widest
		# item of the column to its right, and every cluster sharing the card's column ends on the same edge.
		var shared := 0
		for c in cards:
			if is_equal_approx(c.position.x + c.size.x, acr):
				shared += 1
		if int(res["columns"]) == 1:
			_ok(is_equal_approx(acr, VS.x - UI3Theme.space("screen")), "%s: one column, AttritionCard at the right margin" % tag)
		_ok(shared > 0 or int(res["columns"]) > 1, "%s: AttritionCard shares its column edge with a cluster" % tag)
	if boss:
		_ok(cards[0].position == Vector2(VS.x - UI3Theme.space("screen") - UI3Theme.size_of("boss_plate_w"), UI3Theme.space("screen")),
			"%s: boss plate top-right at margin 24 (%s)" % [tag, cards[0].position])
	else:
		_ok(cards[0].position == Vector2(VS.x - UI3Theme.space("screen") - UI3Theme.size_of("enemy_card_w"), UI3Theme.space("screen")),
			"%s: first plate top-right at margin 24 (%s)" % [tag, cards[0].position])
	for i in rects.size():
		var r := rects[i]
		_ok(not r.intersects(action_r), "%s: item %d %s overlaps the ActionDock %s" % [tag, i, r, action_r])
		_ok(not r.intersects(dice_r), "%s: item %d %s overlaps the DiceDock %s" % [tag, i, r, dice_r])
		_ok(r.position.x >= 0.0 and r.position.y >= 0.0 and r.end.x <= VS.x - UI3Theme.space("screen") + 0.5, "%s: item %d %s off screen" % [tag, i, r])
		for j in range(i + 1, rects.size()):
			_ok(not r.grow(-0.5).intersects(rects[j].grow(-0.5)), "%s: items %d / %d overlap (%s / %s)" % [tag, i, j, r, rects[j]])
	if n <= 3 and not boss and not attr_on:   # 3 worst-case clusters (tab + strip each) + attrition just pass the limit
		_ok(not bool(res["compact"]) and int(res["columns"]) == 1, "%s: small column stays full, one column (limit %.0f, heights %s, plate %.0f)" % [tag, limit, str(cards.map(func(c): return c.cluster_height(false))), cards[0]._plate.size.y])
	host.queue_free()
	await _frames(1)


## Every HTML data-name lane C owns exists as a node of that name.
func _has(root: Node, names: Array, tag: String) -> void:
	for n in names:
		_ok(root.find_child(String(n), true, false) != null, "%s: node '%s' found" % [tag, n])


func _test_scene_names() -> void:
	CombatView.disable_juice_for_tests = true
	var keys := ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	var roster: Array = []
	for i in keys.size():
		roster.append({"persistent_id": i + 1, "hero_key": keys[i], "tier": 1,
			"max_hp": ContentDB.heroes[keys[i]]["max_hp"], "muts": [], "growth": {}, "bonus_hp": 0})
	RunState.pending_combat = {"node_id": "ui5_names", "kind": "battle", "pw": 4, "ascension": 0,
		"roster_snapshot": roster, "relic_ids": [], "combat_seed": 5150}
	var scene: Node = load("res://scenes/combat/Combat.tscn").instantiate()
	add_child(scene)
	await _frames(4)
	var col := scene.find_child("EnemyColumn", true, false)
	_ok(col != null, "scene: EnemyColumn node holds the clusters")
	var n_alive: int = scene._combat.alive_enemies().size()
	_ok(n_alive >= 1, "scene: fight has enemies (%d)" % n_alive)
	if col != null:
		_ok(col.find_child("EnemyCluster1", false, false) != null, "scene: EnemyCluster1 under EnemyColumn")
		if scene._combat.enemies.size() >= 2:
			_ok(col.find_child("EnemyCluster2", false, false) != null, "scene: EnemyCluster2 under EnemyColumn")
		var c1 := col.find_child("EnemyCluster1", false, false)
		if c1 != null:
			_has(c1, ["EnemyPlate", "EnemyMain", "EnemyName", "HPBar", "HPValue", "IntentBlock", "IntentVerb",
				"IntentValue", "BigHitBadge", "BigHitStrip"], "scene EnemyCluster1")
	scene.queue_free()
	await _frames(2)
	CombatView.disable_juice_for_tests = false
	# Plate parts that only some fights show: built directly.
	var host := Control.new()
	host.size = VS
	add_child(host)
	var a := _make(host, 1, "Ravenling A", false, "ELITE")
	var b := _make(host, 2, "Frost Lord", true, "BOSS")
	await _frames()
	_has(a, ["EnemyPlate", "EnemyMain", "EnemyName", "NameSuffix", "EnemyTag", "HPBar", "HPValue", "IntentBlock",
		"IntentVerb", "IntentValue", "BigHitBadge", "BigHitStrip", "ShellValue"], "enemy plate")
	_has(b, ["BossPlate", "EnemyName", "EnemyTag", "HPBar", "HPValue", "ShellValue", "EnrageRow", "IntentBlock",
		"IntentVerb", "IntentValue"], "boss plate")
	var card := AttritionCard.new()
	host.add_child(card)
	_ok(card.name == "AttritionCard" and card.find_child("AttritionLabel", true, false) != null, "AttritionCard + AttritionLabel")
	host.queue_free()
	await _frames(1)


## Showing / hiding the "Target · Name" label on every cluster (what a die hover does) must not change compact.
## 1..7 enemies without big hits: one of them sits exactly where the labels no longer fit the full column.
func _test_label_stability(sc: float) -> void:
	var boundary := false
	for n in range(1, 8):
		var tag := "@%.3f labels n=%d" % [sc, n]
		var host := Control.new()
		host.size = VS
		add_child(host)
		var hud := CombatHud.new()
		host.add_child(hud)
		hud.adopt_right_zone(Button.new(), Button.new(), Button.new())
		var cards: Array[UnitPortrait] = []
		for i in n:
			var p := _make(host, 100 + i, "Ravenling %s" % char(65 + i), false)
			p.set_intent({"show": true, "type": "dmg", "num": 4, "label": "ATTACK", "target": "Olek", "big_hit": false})
			cards.append(p)
		await _frames()
		var limit := minf(TrayColumn.dock_top(VS.y), hud.tray_top()) - float(UI3Theme.space("12"))
		var r0 := EnemyColumn.place(cards, true, VS, limit)
		for c in cards:
			c.set_targetable(true)
		await _frames()
		var r1 := EnemyColumn.place(cards, true, VS, limit)
		_ok(bool(r1["compact"]) == bool(r0["compact"]), "%s: labels shown flip compact %s -> %s" % [tag, r0["compact"], r1["compact"]])
		_ok(cards[0]._chip.visible, "%s: Target label shows" % tag)
		if not bool(r0["compact"]) and not bool(r1["label_room"]):
			boundary = true   # full column, but no room for the labels: they float instead of pushing to compact
		for c in cards:
			c.set_targetable(false)
		await _frames()
		var r2 := EnemyColumn.place(cards, true, VS, limit)
		_ok(bool(r2["compact"]) == bool(r0["compact"]), "%s: labels hidden flip compact" % tag)
		host.queue_free()
		await _frames(1)
	if is_equal_approx(sc, 1.0):   # at 1.0 n=4 sits on that edge; at 0.667 the larger text moves it onto the compact step
		_ok(boundary, "@%.3f: some n hits the edge where labels float instead of flipping compact" % sc)
