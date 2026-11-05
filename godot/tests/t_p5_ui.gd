extends Node
## p5-ui lane (4/11 polish leftovers): text floor measured on the real screens, event wording, ...
const MakeRoomSheet := preload("res://scenes/run_map/ui5/MakeRoomSheet.gd")
const ResultViewS := preload("res://scenes/result/ResultView.gd")
const Scan := preload("res://tests/p5_text_scan.gd")
var _guard := SaveGuard.new()
var _checks := 0
var _fails: Array[String] = []
var rm: Node
var _old_epoch: Variant = ""


func _ok(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_fails.append(m)


func _frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame


func _scan(root: Node, tag: String) -> void:
	var sc := UI3Theme.layout_scale()
	var bad := Scan.small(root, sc)
	for b in bad:
		print("SMALL ", tag, " ", b)
	_ok(bad.is_empty(), "%s: all text >= 14 real px (%d small, first %s)" % [tag, bad.size(), str(bad.slice(0, 2))])


func _fake_cards(core: bool) -> Array:
	var out: Array = []
	for i in 3:
		var d := {"t": "relic", "key": "x%d" % i, "rar": 0, "title": "CORE" if core else "RELIC", "desc": "Name %d" % i, "sub": "Does thing %d." % i}
		if core:
			d.merge({"core": true, "axis": ["stat", "dice", "pos"][i], "tier": i, "slot": i})
		out.append(d)
	return out


func _ready() -> void:
	print("=== t_p5_ui: start ===")
	_guard.capture()
	_old_epoch = ProjectSettings.get_setting("axie/epoch_source", "")
	ProjectSettings.set_setting("axie/epoch_source", "local")
	UI3Gacha.instant_override = 1
	CombatView.disable_juice_for_tests = true
	UI3Theme.set_scale_override(2.0 / 3.0)
	# Event wording: no "Row 0", no "relic" for the player
	_ok(RunMapEvent.event_subtitle(0) == "Event" and RunMapEvent.event_subtitle(-1) == "Event", "event: row 0 / -1 reads 'Event'")
	_ok(RunMapEvent.event_subtitle(3) == "Event · Row 3", "event: row 3 keeps its row")
	_ok(RunMapEvent.core_words("Receive a Legendary relic. Lose a random relic.") == "Receive a Legendary Core. Lose a random Core.", "event: relic -> Core")
	_ok(RunMapEvent.core_words("Relics RELIC") == "Cores CORE" and RunMapEvent.core_words("relicary") == "relicary", "event: case kept, whole words only")
	# Login
	var lg: Node = load("res://scenes/login/LoginScreen.tscn").instantiate()
	add_child(lg)
	await _frames(8)
	_scan(lg, "login")
	lg.queue_free()
	await _frames(2)
	# Core offer (real) at 1280
	RunState.start_new_run_seeded(424242, {"team_keys": ["plant1", "beast1", "aqua1", "reptile1", "bug1"], "mode": "short", "ascension": 0, "ranked": false, "rules_on": true})
	await _frames(2)
	rm = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(rm)
	await _frames(8)
	rm._select_reward(1)
	rm._take_selected_reward()
	await _frames(8)
	rm._show_reward_overlay("x")
	await _frames(4)
	_scan(rm._overlay_root, "core offer")
	rm.queue_free()
	await _frames(2)
	# Combat
	AnchorAdapter.test_state = {"anchor_id": "a_volley", "owned": ["c_bastion"], "awakened": false}
	for id in ["c_bastion", "c_fissure"]:
		RunState.owned_relic_ids.append(id)
	RunState.pending_combat = {"node_id": "p5", "kind": "battle", "pw": 4, "ascension": 0, "roster_snapshot": RunState.roster.duplicate(true), "relic_ids": [], "combat_seed": 77}
	var view: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	add_child(view)
	await _frames(10)
	_scan(view, "combat")
	view._combat.depth_stage = 2
	view._combat.mana = 0
	view._rebuild_all()
	await _frames(2)
	var hud: CombatHud = view._hud_frame
	for k in ["Undo", "Hold", "Wild"]:
		var key := hud.find_child(k + "Key", true, false) as Ui5ToolKey
		_ok(key != null and key.button.disabled and key.reason_text().length() > k.length(), "#5 %s off and says why (%s)" % [k, key.reason_text() if key != null else "missing"])
		hud._reason_show(key, true)
		_ok(hud._hint.text == key.reason_text(), "#5 %s reason on the StatusLine" % k)
		hud._reason_key = null
		hud._reason_until_ms = 0
	view._combat.party[1].roster_index = -1
	view._rebuild_all()
	await _frames(2)
	var egg_found := false
	for dc in view.find_children("*", "Control", true, false):
		if dc is DieCard and (dc as DieCard).part_word != null and (dc as DieCard).part_word.text == "Egg":
			egg_found = (dc as DieCard).part_chip.visible and (dc as DieCard).part_glyph.texture != null
	_ok(egg_found, "egg die shows an egg icon chip")
	view.queue_free()
	AnchorAdapter.test_state = {}
	_room_icons()
	await _anchor_cards()
	await _result_check()
	UI3Theme.set_scale_override(-1.0)
	UI3Gacha.instant_override = -1
	ProjectSettings.set_setting("axie/epoch_source", _old_epoch)
	_guard.restore()
	print("=== t_p5_ui: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("t_p5_ui: PASS")
		get_tree().quit(0)
	else:
		for f in _fails:
			print("FAIL: " + f)
		get_tree().quit(1)


## Defeated: "+N" counts up from +0, so the "N run payout" line stays hidden until the count has landed.
func _result_check() -> void:
	UI3Theme.set_scale_override(1.0)
	RunState.start_new_run(777001, ["plant1", "beast1", "aqua1", "reptile1", "bird1"] as Array[String], "short", 5, false)
	RunState.shards_this_run = 87
	RunState.run_stats = {"dmg": 913, "dmg_dealt_clamped": 913, "taken": 140, "turns": 41, "kills": 23, "max_hit": 31}
	RunState.mission = {}
	MetaState.mission_escrow = {}
	RunState.set_phase(RunState.RunPhase.LOST)
	ResultViewS.force_end_moment_for_tests = true
	var v: Node = (load("res://scenes/result/Result.tscn") as PackedScene).instantiate()
	add_child(v)
	await _frames(4)
	var amt := v.find_child("ShardAmount", true, false) as Label
	var bd := v.find_child("ShardBreakdown", true, false) as Control
	var tl: UI3Motion.Timeline = v.get("end_timeline")
	_ok(amt != null and bd != null and tl != null, "result: ShardAmount + ShardBreakdown + end timeline exist")
	if amt != null and bd != null and tl != null:
		_ok(not tl.done and bd.modulate.a < 0.5, "result: while counting the payout line is hidden (done=%s, a=%.1f)" % [str(tl.done), bd.modulate.a])
		if not tl.done:
			await tl.finished
		await _frames(2)
		_ok(amt.text == "+87" and bd.modulate.a > 0.99, "result: after finished: +87 and the payout line back (%s, a=%.1f)" % [amt.text, bd.modulate.a])
	v.queue_free()
	ResultViewS.force_end_moment_for_tests = false
	await _frames(2)


## Make room rows: a Core gets its socket + family emblem, a pact its pact art, an old relic its archetype glyph.
func _room_icons() -> void:
	var core := MakeRoomSheet.row_icon("c_bastion", 64)
	var relic := MakeRoomSheet.row_icon("r_claw", 64)
	_ok(core.find_child("FamilyEmblem", true, false) != null and core.find_child("RowIcon", true, false) == null, "room: a Core row keeps the Core socket + family emblem")
	_ok(relic.find_child("FamilyEmblem", true, false) == null and relic.find_child("RowIcon", true, false) != null, "room: an old relic row has no family emblem")
	var shield := MakeRoomSheet.row_icon("r_carapace", 64)
	_ok((relic.find_child("RowIcon", true, false) as TextureRect).texture != (shield.find_child("RowIcon", true, false) as TextureRect).texture, "room: relics of different archetypes get different glyphs")
	shield.free()
	var pid := ""
	for f in DirAccess.get_files_at("res://resources/relics"):
		if f.ends_with(".tres") and RelicSlots.is_pact(f.get_basename()):
			pid = f.get_basename()
			break
	_ok(pid != "", "room: found a pact id")
	if pid != "":
		var pc := MakeRoomSheet.row_icon(pid, 64)
		var ri := pc.find_child("RowIcon", true, false) as TextureRect
		_ok(ri != null and String(ri.get_meta("kind", "")) == "pact" and ri.texture == UI6Assets.pact(pid), "room: a pact row uses the pact art")
	for n in [core, relic]:
		n.free()


## Anchor pick: the cards follow their content. Dead space under the content < 15 % of the card at 1920 and 1280, nothing overflows.
func _anchor_cards() -> void:
	var ids := ["a_kin", "a_embers", "a_big_hand"]
	for sc in [1.0, 2.0 / 3.0]:
		UI3Theme.set_scale_override(sc)
		AnchorAdapter.test_state = {"open": true, "offer": ids, "reasons": {}, "picked": []}
		var host := Control.new()
		host.set_anchors_preset(Control.PRESET_FULL_RECT)
		host.theme = UI3Theme.get_theme()
		add_child(host)
		var v := AnchorPick.new()
		host.add_child(v)
		v.setup(ids, true)
		await _frames(8)
		var tallest := 0.0
		for c in v.cards:
			tallest = maxf(tallest, c.size.y)
		for c in v.cards:
			var need: float = (c.get_child(0) as Control).get_minimum_size().y + 2.0 * UI3Theme.space("20")
			var gap: float = (c.size.y - need) / c.size.y
			_ok(gap < 0.15, "anchor card %s @%.2f: dead space %.0f%% < 15%%" % [c.name, sc, gap * 100.0])
			_ok(need <= c.size.y + 1.0, "anchor card @%.2f: content fits (%.0f of %.0f)" % [sc, need, c.size.y])
		_ok(tallest <= UI3Theme.size_of("anchor_card_h") + 1.0, "anchor cards @%.2f: not above the token height" % sc)
		host.queue_free()
		await _frames(2)
	AnchorAdapter.test_state = {}
	UI3Theme.set_scale_override(2.0 / 3.0)
