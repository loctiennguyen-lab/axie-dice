extends Node
## Combat animation variety (CombatAnim + CombatStage3D, view only).
##
## Pins: every face type / die part / Set / Overcast resolves to a clip that really loads on every
## Axie body (base GLB clip, or a baked res://assets/axie/combat_clips/<Body>/<Clip>.res whose
## tracks all hit real bones), damage parts get different signature clips, self-casts never swing,
## stunned units loop Stun, and a real stage unit plays what the table says. A clip that does not
## resolve is what leaves an Axie frozen in its bind pose, so "loads on every body" is the core.

var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0

const ATTACK_CLIPS := ["WalkAttack", "RunAttack", "AttackHead", "AttackRange", "AttackCombo",
	"HitTree", "CutTree", "StoneHarvest"]
const PARTS := ["mouth", "horn", "back", "tail", "ears", "eyes"]
const TYPES := ["dmg", "shield", "buff", "heal", "mana", "summon", "poison", "debuff", "blank", ""]


func _ready() -> void:
	var tree := get_tree()
	print("=== t_combat_anim_variety: start ===")
	_guard.capture()
	await tree.process_frame
	_test_table()
	_test_every_clip_loads_on_every_body()
	_test_real_axies_register_and_play()
	await _test_stage(tree)
	CombatView.disable_juice_for_tests = false
	_guard.restore()
	if _fails.is_empty():
		print("t_combat_anim_variety: PASS — %d checks OK" % _checks)
		tree.quit(0)
	else:
		for f in _fails:
			print("t_combat_anim_variety: FAIL — %s" % f)
		tree.quit(1)


func _test_table() -> void:
	var all := CombatAnim.all_clips()
	for t in TYPES:
		for p in PARTS + ["", "Horn", "ear", "weird"]:
			for flags in [[false, false], [true, false], [false, true], [true, true]]:
				for seed in 6:
					for reduced in [false, true]:
						var s := CombatAnim.pick_action(t, p, flags[0], flags[1], seed, reduced)
						_check(all.has(String(s["clip"])), "%s/%s -> %s is not in all_clips()" % [t, p, s["clip"]])
						_check(float(s["time_scale"]) > 0.3 and float(s["time_scale"]) < 2.5, "%s/%s time_scale %s" % [t, p, s["time_scale"]])
						_check(s == CombatAnim.pick_action(t, p, flags[0], flags[1], seed, reduced), "pick is not deterministic for %s/%s" % [t, p])
	# Damage: each part's signature differs from every other part group (ears and eyes share one).
	var sig := {}
	for p in PARTS:
		sig[p] = String(CombatAnim.pick_action("dmg", p, false, false, 1)["clip"])
	var distinct := {}
	for p in sig:
		distinct[sig[p]] = true
	_check(distinct.size() >= 5, "damage signature clips by part are not varied: %s" % str(sig))
	_check(sig["horn"] == "AttackHead", "horn signature is %s, not AttackHead" % sig["horn"])
	_check(sig["back"] == "AttackRange", "back signature is %s, not AttackRange" % sig["back"])
	_check(sig["tail"] == "CutTree", "tail signature is %s, not CutTree" % sig["tail"])
	# Each part's second clip is actually reached by some seed (a long fight does not repeat one pose).
	for p in PARTS:
		var seen := {}
		for seed in 30:
			seen[String(CombatAnim.pick_action("dmg", p, false, false, seed)["clip"])] = true
		_check(seen.size() == 2, "part %s reaches %d clip(s) over 30 seeds, want 2" % [p, seen.size()])
	_check(CombatAnim.pick_action("dmg", "mouth", true, false, 1)["clip"] == "AttackCombo", "Set damage is not AttackCombo")
	_check(CombatAnim.pick_action("dmg", "mouth", true, true, 1)["clip"] == "HitTree", "Overcast damage is not HitTree")
	_check(CombatAnim.pick_action("dmg", "tail", false, true, 1, true)["clip"] == "AttackHead",
		"Reduce motion still plays the jump/spin for an Overcast hit")
	# Self-casts never play an attack, and are all different from each other.
	var self_clips := {}
	for t in ["shield", "buff", "heal", "mana", "summon"]:
		var c := String(CombatAnim.pick_action(t, "back", true, true, 2)["clip"])
		_check(not ATTACK_CLIPS.has(c), "%s plays the attack clip %s" % [t, c])
		self_clips[c] = true
	_check(self_clips.size() == 5, "self-cast clips repeat: %s" % str(self_clips.keys()))
	_check(CombatAnim.STUN == AnimNames.Stun, "stun clip is not the body's Stun")
	_check(CombatAnim.pick_hit(true, 0)["time_scale"] < CombatAnim.pick_hit(false, 0)["time_scale"],
		"a heavy hit does not stagger longer than a normal one")


func _base_paths(cat: AxieCatalog, body: int) -> Dictionary:
	var out := {}
	var base := cat.load_animations(str(cat.body_entry(body).get("glb", "")))
	for k in base.keys():
		var a: Animation = base[k]
		for i in a.get_track_count():
			out[str(a.track_get_path(i))] = true
	return out


func _test_every_clip_loads_on_every_body() -> void:
	var cat: AxieCatalog = AxieFactory.default_factory.catalog
	for body in AxieTypes.BODY_NAMES.size():
		var paths := _base_paths(cat, body)
		for clip in CombatAnim.all_clips():
			if CombatAnim.BASE_CLIPS.has(clip) and cat.find_body_animation(body, clip) != null:
				continue   # shipped in the body GLB itself
			_check(CombatAnim.EXTRA_CLIPS.has(clip) or CombatAnim.BASE_CLIPS.has(clip), "%s is neither a base nor an extra clip" % clip)
			var path := CombatAnim.clip_path(body, clip)
			_check(ResourceLoader.exists(path), "baked clip missing: %s" % path)
			if not ResourceLoader.exists(path):
				continue
			var anim := load(path) as Animation
			_check(anim != null and anim.length > 0.2 and anim.get_track_count() > 20, "baked clip empty: %s" % path)
			if anim == null:
				continue
			var miss := 0
			for i in anim.get_track_count():
				if not paths.has(str(anim.track_get_path(i))):
					miss += 1
				_check(not str(anim.track_get_path(i)).to_lower().contains("weapon"), "%s still drives a weapon joint" % path)
			_check(miss == 0, "%s has %d track(s) for bones %s does not have" % [path, miss, AxieTypes.body_name(body)])


func _make_axie(body: int) -> AxieCharacter3D:
	var desc := AxieDescriptor.new()
	desc.body = body
	desc.color_variant = 3
	var parts: Array[AxiePartDescriptor] = []
	for pt in CombatStage3D._PART_TYPES:
		parts.append(AxiePartDescriptor.new(pt, 0, "Beast", CombatStage3D._PART_VARIANT, 1))
	desc.parts = parts
	return AxieCharacter3D.from_descriptor(desc)


func _test_real_axies_register_and_play() -> void:
	for body in [0, 4, 6]:
		var ch := _make_axie(body)
		_check(ch != null and ch.playable != null, "no Axie for body %d" % body)
		if ch == null:
			continue
		add_child(ch.root)
		_check(CombatAnim.register_extras(ch) >= CombatAnim.EXTRA_CLIPS.size(),
			"not every extra clip registered on %s" % AxieTypes.body_name(body))
		for clip in CombatAnim.all_clips():
			var tr := CombatAnim.play_spec(ch.playable, {"clip": clip, "time_scale": 1.0, "start": 0.2})
			_check(tr != null, "%s does not play on %s" % [clip, AxieTypes.body_name(body)])
		ch.root.queue_free()


func _current_clip(stage: CombatStage3D, uid: int) -> String:
	var ch: AxieCharacter3D = stage._units[uid]["character"]
	var cur = ch.playable._current
	return "" if cur == null else String((cur as AnimTrack).clip_name)


func _test_stage(tree: SceneTree) -> void:
	CombatView.disable_juice_for_tests = false
	var stage := (load("res://scenes/shared/CombatStage3D.tscn") as PackedScene).instantiate() as CombatStage3D
	add_child(stage)
	await tree.process_frame
	stage.spawn_unit(1, "beast", false, 0, 2)
	stage.spawn_unit(2, "plant", false, 1, 2)
	_check(stage._units[1]["character"] != null, "party unit has no rig")
	_check(_current_clip(stage, 1) == "Idle", "spawned Axie is not idling (%s)" % _current_clip(stage, 1))
	var cases := [["dmg", "horn", false, false, "AttackHead"], ["dmg", "back", false, false, "AttackRange"],
		["dmg", "mouth", true, false, "AttackCombo"], ["dmg", "tail", true, true, "HitTree"],
		["shield", "back", false, false, "IdleCarryItem"], ["heal", "eyes", false, false, "LootItem"],
		["buff", "ears", false, false, "MalaSkill"], ["mana", "ears", false, false, "TalismanSkill"],
		["summon", "back", false, false, "Shoveling"]]
	for c in cases:
		stage.play_action(1, c[0], 2, "", c[1], c[2], c[3])
		var last := String(stage._units[1].get("last_clip", ""))
		var cur := _current_clip(stage, 1)
		# Signature vs alternate depends on the per-unit counter: accept either clip of that part.
		var want: String = c[4]
		if c[0] == "dmg" and not c[2] and not c[3]:
			var pool: Array = CombatAnim.DMG_BY_PART[c[1]]
			_check([pool[0]["clip"], pool[1]["clip"]].has(last), "%s/%s played %s" % [c[0], c[1], last])
		else:
			_check(last == want, "%s/%s played %s, want %s" % [c[0], c[1], last, want])
		_check(cur == last, "stage says %s but the rig plays %s" % [last, cur])
	# Hit reaction goes back to Idle by itself.
	stage.play_hit_reaction(1, true)
	_check(_current_clip(stage, 1) == "IdleGetHit", "hit reaction is %s" % _current_clip(stage, 1))
	await tree.create_timer(1.4).timeout
	_check(_current_clip(stage, 1) == "Idle", "after the hit the Axie is on %s, not Idle" % _current_clip(stage, 1))
	# Stun loop while stunned, Idle after.
	stage.set_stunned(1, true)
	_check(_current_clip(stage, 1) == "Stun", "stunned Axie plays %s, not Stun" % _current_clip(stage, 1))
	stage.play_hit_reaction(1)
	await tree.create_timer(1.2).timeout
	_check(_current_clip(stage, 1) == "Stun", "stunned Axie returned to %s after a hit, not Stun" % _current_clip(stage, 1))
	stage.set_stunned(1, false)
	_check(_current_clip(stage, 1) == "Idle", "un-stunned Axie plays %s, not Idle" % _current_clip(stage, 1))
	# Turn fidget picks one Axie and only when it is idle.
	stage.play_turn_fidget([1, 2], 3)
	var f1 := _current_clip(stage, 1)
	var f2 := _current_clip(stage, 2)
	_check((f1 == "StaffSkill") != (f2 == "StaffSkill"), "turn fidget: %s / %s (want exactly one StaffSkill)" % [f1, f2])
	# Victory: cheer first, then Run.
	stage.play_victory_march([1, 2], 1.0, 1.0)
	await tree.process_frame
	var v := _current_clip(stage, 1)
	_check(v == "FlagAttack" or UI3Motion.reduced(), "victory starts with %s, not the FlagAttack cheer" % v)
	await tree.create_timer(CombatAnim.VICTORY_CHEER_SEC + 0.2).timeout
	_check(_current_clip(stage, 1) == "Run", "after the cheer the Axie plays %s, not Run" % _current_clip(stage, 1))
	stage.dispose_all()
	stage.queue_free()
	await tree.process_frame


func _check(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_fails.append(msg)
