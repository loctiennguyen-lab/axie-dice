extends Node
## Manual VISUAL QA (run WITHOUT --headless, e.g. tools/shot.sh): screenshots of the varied combat
## clips mid-action on the real Combat screen — party Axies (part attacks, Set/Overcast, casts,
## victory cheer), an Atia monster attack and a Chimera boss Cast/Roar. Writes full frames plus a
## crop around the actor to $ADT_EVIDENCE_DIR (default production/qa/evidence).
## Run: godot/tools/shot.sh res://tests/qa_combat_anim_evidence.tscn 1920x1080

var _guard := SaveGuard.new()
var _dir := QaPaths.evidence_dir()
var _view: Node
var _stage: CombatStage3D
var _n := 0


func _ready() -> void:
	_guard.capture()
	DirAccess.make_dir_recursive_absolute(_dir)
	await _battle()
	await _boss()
	_guard.restore()
	print("qa_combat_anim_evidence: %d shot(s) in %s" % [_n, _dir])
	get_tree().quit(0)


func _roster() -> Array:
	var keys := ["beast1", "plant1", "aqua1", "reptile1", "bug1"]
	var out: Array = []
	for i in keys.size():
		out.append({"persistent_id": i + 1, "hero_key": keys[i], "tier": 1,
			"max_hp": ContentDB.heroes[keys[i]]["max_hp"], "muts": [], "growth": {}, "bonus_hp": 0})
	return out


func _open(pc: Dictionary) -> void:
	RunState.pending_combat = pc
	_view = load("res://scenes/combat/Combat.tscn").instantiate()
	add_child(_view)
	await get_tree().process_frame
	_stage = _view.get("_stage3d")
	await get_tree().create_timer(3.0).timeout   # intro band, turn banner, intent reveal settle


func _close() -> void:
	_view.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func _battle() -> void:
	await _open({"node_id": "anim_ev", "kind": "battle", "pw": 3, "ascension": 0,
		"roster_snapshot": _roster(), "relic_ids": [], "combat_seed": 4242})
	var combat: CombatEngine = _view.get("_combat")
	var p: Array = combat.party
	var e: Unit = combat.enemies[0]
	# [uid, face type, part, in Set, Overcast, seconds into the clip, tag]
	var shots := [
		[p[0].uid, "dmg", "horn", false, false, 0.30, "horn-AttackHead"],
		[p[1].uid, "dmg", "back", false, false, 0.36, "back-AttackRange"],
		[p[2].uid, "dmg", "tail", false, false, 0.30, "tail-CutTree"],
		[p[3].uid, "dmg", "mouth", true, false, 0.55, "set-AttackCombo"],
		[p[4].uid, "dmg", "horn", true, true, 0.25, "overcast-HitTree"],
		[p[0].uid, "heal", "eyes", false, false, 0.55, "heal-LootItem"],
		[p[1].uid, "buff", "ears", false, false, 0.55, "buff-MalaSkill"],
		[p[2].uid, "mana", "ears", false, false, 0.45, "mana-TalismanSkill"],
		[p[3].uid, "summon", "back", false, false, 0.55, "summon-Shoveling"],
	]
	for s in shots:
		_stage.play_action(int(s[0]), String(s[1]), e.uid, "", String(s[2]), bool(s[3]), bool(s[4]))
		await get_tree().create_timer(float(s[5])).timeout
		await _shot(String(s[6]), int(s[0]))
		await get_tree().create_timer(1.3).timeout   # back to idle before the next one
	_stage.play_action(e.uid, "dmg", p[0].uid, "")
	await get_tree().create_timer(0.35).timeout
	await _shot("enemy-attack", e.uid)
	await get_tree().create_timer(1.3).timeout
	_stage.play_hit_reaction(p[2].uid, true)
	await get_tree().create_timer(0.2).timeout
	await _shot("party-heavy-hit", p[2].uid)
	await get_tree().create_timer(1.0).timeout
	var alive: Array = []
	for u in p:
		alive.append(u.uid)
	_stage.play_victory_march(alive, 3.2, 1.1)
	await get_tree().create_timer(0.35).timeout
	await _shot("victory-FlagAttack", p[2].uid)
	await get_tree().create_timer(2.0).timeout
	await _close()


func _boss() -> void:
	await _open({"node_id": "anim_ev_boss", "kind": "boss", "pw": 8, "ascension": 0,
		"roster_snapshot": _roster(), "relic_ids": [], "combat_seed": 13579, "boss_key": "gooey_king"})
	var combat: CombatEngine = _view.get("_combat")
	var boss: Unit = null
	for e in combat.enemies:
		if (e as Unit).is_boss:
			boss = e
	if boss == null:
		push_warning("no boss")
		await _close()
		return
	_stage.play_action(boss.uid, "buff", -1, "")
	await get_tree().create_timer(0.6).timeout
	await _shot("boss-Cast", boss.uid)
	await get_tree().create_timer(1.6).timeout
	_stage.play_action(boss.uid, "dmg", combat.party[0].uid, "")
	await get_tree().create_timer(0.45).timeout
	await _shot("boss-Attack", boss.uid)
	await get_tree().create_timer(1.6).timeout
	_stage.play_charge_roar(boss.uid)
	await get_tree().create_timer(0.7).timeout
	await _shot("boss-Roar-charge", boss.uid)
	await _close()


func _shot(tag: String, uid: int) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	_n += 1
	var base := "%s/%02d-%s" % [_dir, _n, tag]
	img.save_png(base + ".png")
	var r := _stage.unit_screen_rect(uid)
	if r.size.x > 4.0:
		var xf := _stage.get_global_transform_with_canvas()
		var k := Vector2(img.get_size()) / get_viewport().get_visible_rect().size
		var gr := xf * r
		gr = Rect2(gr.position * k, gr.size * k)
		var pad := minf(maxf(gr.size.x, gr.size.y) * 0.45, 120.0)
		var c := Rect2i(gr.grow(pad)).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
		if c.size.x > 8 and c.size.y > 8:
			var crop := img.get_region(c)
			if crop.get_height() < 420:   # Axies are ~90 px tall on a 1080p frame: blow the crop up
				var f := 420.0 / float(crop.get_height())
				crop.resize(int(crop.get_width() * f), 420, Image.INTERPOLATE_LANCZOS)
			crop.save_png(base + "-crop.png")
	print("qa_combat_anim_evidence: %s" % base)
