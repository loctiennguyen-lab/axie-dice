extends Node
## UI-05 b1 lane A: the combat HUD shell in the real Combat scene.
## 1. Every lane A data-name from ui05-combat-screens.html exists as a node of that name.
## 2. No key cap on screen except Space (Liam 28/10): the whole combat scene has exactly one KeyCap, on End turn.
## 3. Sizes come from tokens: RunInfo / ActionDock / AidZone at scale 1.0 and after a 1920 -> 1280 -> 1920 window
##    scale change (the 1280 overrides and the 14 px text floor switch on and off again).
## 4. The shared pieces (StatusChip, WaitingPill, SkipHint) build with their token sizes.
## Run: godot --headless --path godot res://tests/t_ui5_hud_shell.tscn

const NAMES := ["RunInfo", "MenuButton", "RunPill", "FightLabel", "AscensionChip", "TurnChip", "ShardChip",
	"ActionDock", "ToolKeys", "UndoKey", "HoldKey", "WildKey", "OvercastKey", "RerollButton", "CostChip",
	"EndTurnButton", "StatusLine", "BossRhythm", "AidZone", "AidButton", "AidOffer", "AidBuyButton", "AidNotNow", "WaitingPill"]

var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0


const Align := preload("res://tests/ui5_align_check.gd")


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _roster() -> Array:
	var keys := ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	var out: Array = []
	for i in keys.size():
		out.append({"persistent_id": i + 1, "hero_key": keys[i], "tier": 1,
			"max_hp": ContentDB.heroes[keys[i]]["max_hp"], "muts": [], "growth": {}, "bonus_hp": 0})
	return out


func _ready() -> void:
	print("=== t_ui5_hud_shell: start ===")
	_guard.capture()
	await get_tree().process_frame
	UI3Theme.set_scale_override(1.0)
	CombatView.disable_juice_for_tests = true
	MetaState.runs_with_battle = 99
	MetaState.gems_cache = 500
	RunState.pending_combat = {"node_id": "hud_node", "kind": "battle", "pw": 4, "ascension": 6,
		"roster_snapshot": _roster(), "relic_ids": [], "combat_seed": 77}
	var view: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	add_child(view)
	for _i in 8:
		await get_tree().process_frame
	view._combat.rerolls = 0
	view._combat.mana = 0
	view._rebuild_all()   # "Reroll · need 1 MP" and the Aid offer
	for _i in 3:
		await get_tree().process_frame

	# 1. data-names
	for n in NAMES:
		_check(view.find_child(n, true, false) != null, "node '%s' exists in the combat scene" % n)
	var hud: CombatHud = view._hud_frame
	_check(hud.find_child("ToolKeys", true, false).get_child_count() == 4, "ToolKeys holds Undo / Hold / Wild / Overcast")
	_check(view.find_child("UndoKey", true, false).find_child("UndoButton", true, false) != null, "UndoKey wraps the scene's %UndoButton")
	_check(view.get_node("%UndoButton") == hud.undo_button and view.get_node("%EndTurnButton") == hud.end_turn_button,
		"unique names still resolve after the move (tutorial + tests)")

	# 2. one key cap, Space
	var caps := Ui5Keycap.all_under(view)
	var texts: PackedStringArray = []
	for c in caps:
		var l := (c as Control).find_child("Key", true, false) as Label
		texts.append(l.text if l != null else "?")
	_check(caps.size() == 1 and texts[0] == KeyBindings.text(KeyBindings.COMBAT_END_TURN),
		"exactly one key cap in the combat scene, Space on End turn (found %d: %s)" % [caps.size(), ", ".join(texts)])
	_check(caps.size() >= 1 and (caps[0] as Control).get_parent() == hud.end_turn_button, "the Space cap sits on End turn")

	# 2b. the keys that lost their cap are named in the tooltips CombatView really builds (Hold in every state)
	var aid_btn := view.find_child("AidButton", true, false) as Control
	_check(aid_btn.tooltip_text.contains("(%s)" % KeyBindings.text(KeyBindings.COMBAT_AID)), "AidButton tooltip names the Aid key: %s" % aid_btn.tooltip_text)
	_check(hud.undo_button.tooltip_text.contains("(%s)" % KeyBindings.text(KeyBindings.COMBAT_UNDO)), "Undo tooltip names its key: %s" % hud.undo_button.tooltip_text)
	_check(hud.reroll_button.tooltip_text != "", "Reroll has a tooltip")
	view._combat.depth_stage = maxi(int(view._combat.depth_stage), 3)
	view._selected_die_uid = -1
	view._rebuild_all()
	_check(not hud.hold_button.visible or hud.hold_button.tooltip_text.contains("(%s)" % KeyBindings.text(KeyBindings.COMBAT_HOLD)),
		"Hold tooltip names its key with no die picked: %s" % hud.hold_button.tooltip_text)
	for u in view._party_dice_units():
		if u.has_rolled():
			view._selected_die_uid = u.uid
			break
	view._rebuild_all()
	_check(not hud.hold_button.visible or hud.hold_button.tooltip_text.contains("(%s)" % KeyBindings.text(KeyBindings.COMBAT_HOLD)),
		"Hold tooltip names its key with a die picked: %s" % hud.hold_button.tooltip_text)
	_check(hud.get("_hint").text == CombatHud.PICK_TEXT, "a picked die: StatusLine 'Pick a target' (%s)" % hud.get("_hint").text)
	view._selected_die_uid = -1
	view._rebuild_all()

	# 3. token sizes, then a 1920 -> 1280 -> 1920 scale change
	_sizes(view, "1920")
	UI3Theme.set_scale_override(2.0 / 3.0)
	view._rebuild_all()
	for _i in 3:
		await get_tree().process_frame
	_sizes(view, "1280")
	var dock: Control = hud.get("_dock")
	var fs := hud.get("_hint").get_theme_font_size("font_size") as int
	_check(float(fs) * (2.0 / 3.0) >= 14.0 - 0.01, "1280: StatusLine is >= 14 real px (%d logical)" % fs)
	UI3Theme.set_scale_override(1.0)
	view._rebuild_all()
	for _i in 3:
		await get_tree().process_frame
	_sizes(view, "back to 1920")
	_check(hud.get("_hint").get_theme_font_size("font_size") == UI3Theme.size_of("text_body"), "back at 1920 the StatusLine is text_body again")
	_check(absf(dock.size.x - UI3Theme.size_of("action_dock_w")) < 0.5, "ActionDock width back to action_dock_w")

	# 4. shared pieces
	var sc := Ui5StatusChip.make(StatusHeads.icon_for("poison"), 3)
	add_child(sc)
	await get_tree().process_frame
	_check(sc.name == "StatusChip" and absf(sc.size.y - UI3Theme.size_of("status_chip_h")) < 0.5, "StatusChip is status_chip_h high (%s)" % sc.size)
	var wp := Ui5WaitingPill.make()
	add_child(wp)
	await get_tree().process_frame
	_check(wp.name == "WaitingPill" and absf(wp.size.y - UI3Theme.size_of("dice_header_h")) < 0.5
		and (wp.find_child("Text", true, false) as Label).text == "Waiting for the server", "WaitingPill: dice_header_h, approved text")
	_check(view._dock_pill != null and view._dock_pill.name == "WaitingPill", "the combat scene uses the UI-05 WaitingPill")
	var sh := Ui5SkipHint.new()
	add_child(sh)
	sh.place_in(Vector2(1920, 1080))
	await get_tree().process_frame
	var shr := sh.get_global_rect()
	_check(sh.name == "SkipHint" and absf(shr.end.x - (1920.0 - UI3Theme.space("screen"))) < 0.5 and absf(shr.end.y - (1080.0 - UI3Theme.space("screen"))) < 0.5,
		"SkipHint sits bottom-right at the screen margin (%s)" % shr)
	var words := ""
	for c in sh.get_children():
		if c is Label:
			words += (c as Label).text + " "
	_check(words.strip_edges() == "Click or to skip" and Ui5Keycap.all_under(sh).size() == 1, "SkipHint reads 'Click or [Space] to skip'")

	UI3Theme.set_scale_override(-1.0)
	CombatView.disable_juice_for_tests = false
	view.queue_free()
	await get_tree().process_frame
	_guard.restore()
	if _fails.is_empty():
		print("t_ui5_hud_shell: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
	else:
		for f in _fails:
			print("t_ui5_hud_shell: FAIL — %s" % f)
		get_tree().quit(1)


func _sizes(view: Node, tag: String) -> void:
	var vs: Vector2 = view.get_viewport().get_visible_rect().size
	var edge := float(UI3Theme.space("screen"))
	var hud: CombatHud = view._hud_frame
	var ri := hud.find_child("RunInfo", true, false) as Control
	var mb := hud.find_child("MenuButton", true, false) as Control
	var rp := hud.find_child("RunPill", true, false) as Control
	_check(ri.get_global_rect().position.is_equal_approx(Vector2(edge, edge)), "%s: RunInfo at the screen margin (%s)" % [tag, ri.get_global_rect()])
	_check(absf(mb.size.x - UI3Theme.size_of("run_pill_h")) < 0.5 and absf(rp.size.y - UI3Theme.size_of("run_pill_h")) < 0.5,
		"%s: MenuButton / RunPill are run_pill_h (%s / %s)" % [tag, mb.size, rp.size])
	var dock := hud.get("_dock") as Control
	var dr := dock.get_global_rect()
	_check(absf(dr.size.x - UI3Theme.size_of("action_dock_w")) < 0.5 and absf(dr.end.x - (vs.x - edge)) < 0.5 and absf(dr.end.y - (vs.y - edge)) < 0.5,
		"%s: ActionDock action_dock_w wide at the bottom-right margin (%s in %s)" % [tag, dr, vs])
	var zone := view.find_child("AidZone", true, false) as Control
	_align(hud, "%s HUD" % tag)
	_align(zone, "%s AidZone" % tag)
	var zr := zone.get_global_rect()
	_check(absf(zr.size.x - UI3Theme.size_of("aid_w")) < 0.5 and absf(zr.position.x - edge) < 0.5 and absf(zr.end.y - (vs.y - edge)) < 0.5,
		"%s: AidZone aid_w wide at the bottom-left margin (%s, aid_w %d)" % [tag, zr, UI3Theme.size_of("aid_w")])
	_check(not zr.intersects(dr), "%s: AidZone and ActionDock do not touch" % tag)
	var end := hud.end_turn_button
	_check(absf(end.size.y - UI3Theme.size_of("btn_l")) < 0.5 and end.get_theme_font_size("font_size") == UI3Theme.size_of("text_screen_title"),
		"%s: End turn btn_l high, text_screen_title" % tag)


## Liam 29/10: text under / beside an icon is centred on the icon (<= 1.5 px), measured on the drawn text box.
func _align(root: Node, tag: String) -> void:
	var probs := Align.check(root, 1.5, tag + ": ")
	_check(Align.pairs(root) > 0, "%s: the centring check measured no icon / label pair" % tag)
	for pr in probs:
		_check(false, pr)
