extends Node
## L6 gate (16/10, "monsters with animations are frozen"): for every glb enemy in the registry,
## CombatStage3D._make_atia_model() must pick the AnimationPlayer that holds the registry's clips
## (the wrapper's "Animations", not the FBX-embedded "Take 001" one), every registry slot must
## resolve to a real clip, idle must loop, and playing idle must put the player in motion.
##
## Run: godot --headless --path godot res://tests/t_atia_anim_play.tscn

var _failures: Array[String] = []
var _checks := 0


func _ready() -> void:
	print("=== t_atia_anim_play: start ===")
	var stage := (load("res://scenes/shared/CombatStage3D.tscn") as PackedScene).instantiate()
	add_child(stage)
	await get_tree().process_frame
	var keys: Array = MonsterArt.NORMAL_KEYS + MonsterArt.ELITE_KEYS + MonsterArt.BOSS_KEYS
	var glb := 0
	for k in keys:
		var reg := MonsterArt.resolve(String(k), MonsterArt.BOSS_KEYS.has(k))
		if String(reg.get("kind", "")) != "glb":
			continue
		glb += 1
		var atia: Dictionary = stage._make_atia_model(String(k), MonsterArt.BOSS_KEYS.has(k))
		_assert(not atia.is_empty(), "%s: model did not load" % k)
		if atia.is_empty():
			continue
		var player := atia["player"] as AnimationPlayer
		_assert(player != null, "%s: no AnimationPlayer" % k)
		if player == null:
			(atia["node"] as Node).free()
			continue
		var want: Dictionary = reg.get("anims", {})
		_assert((atia["anims"] as Dictionary).size() == want.size(),
			"%s: registry clips %s not all found in the player (%s)" % [k, want, Array(player.get_animation_list())])
		_assert((atia["anims"] as Dictionary).has("idle"), "%s: no idle clip" % k)
		if (atia["anims"] as Dictionary).has("idle"):
			var idle := player.get_animation(String(atia["anims"]["idle"]))
			_assert(idle.loop_mode == Animation.LOOP_LINEAR, "%s: idle does not loop" % k)
			_assert(stage._atia_play(atia, "idle", true) > 0.0, "%s: idle did not start" % k)
			_assert(player.is_playing(), "%s: idle is not playing" % k)
		(atia["node"] as Node).free()
	_check_no_idle_rest(stage)
	_assert(glb >= 20, "expected at least 20 glb enemies, saw %d" % glb)
	stage.queue_free()
	print("=== t_atia_anim_play: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_atia_anim_play: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_atia_anim_play: FAIL — %s" % f)
	get_tree().quit(1)


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)


## A model with no idle clip must drop back to rest after a one-shot (attack), not freeze on its last pose.
func _check_no_idle_rest(stage: Node) -> void:
	var player := AnimationPlayer.new()
	var lib := AnimationLibrary.new()
	var atk := Animation.new()
	atk.length = 0.2
	lib.add_animation("atk", atk)
	player.add_animation_library("", lib)
	var holder := Node.new()
	holder.add_child(player)
	add_child(holder)
	var atia := {"player": player, "anims": {"attack": "atk"}}
	_assert(stage._atia_play(atia, "attack") > 0.0, "no-idle: attack did not start")
	_assert(player.is_playing(), "no-idle: attack is not playing")
	player.advance(0.5)
	player.animation_finished.emit(&"atk")   # headless advance may not emit
	_assert(not player.is_playing(), "no-idle: model did not return to rest after the attack")
	holder.queue_free()
