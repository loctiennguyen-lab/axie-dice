extends Node
## UI-05 b1 lane E capture: the ten combat moments on a real fight, each shot at a fixed time t after its trigger
## (named after design/handoffs/ui-05-figma/round-1/moments/<file>.html). Not headless:
##   ADT_EVIDENCE_DIR=$PWD/production/qa/ui05-b1/e godot/tools/shot.sh res://tests/qa_ui5_moments_capture.tscn 1920x1080
## Pass `-- --reduce` to shoot with Reduce motion on (files get a "-reduced" suffix).

var _guard := SaveGuard.new()
var _out := ""
var _suffix := ""


func _ready() -> void:
	_guard.capture()
	_out = OS.get_environment("ADT_EVIDENCE_DIR")
	if _out == "":
		_out = ProjectSettings.globalize_path("res://").path_join("../production/qa/ui05-b1/e").simplify_path()
	DirAccess.make_dir_recursive_absolute(_out)
	var was_reduce := MetaState.reduce_motion
	MetaState.reduce_motion = OS.get_cmdline_user_args().has("--reduce")
	_suffix = "-reduced" if MetaState.reduce_motion else ""
	RunState.start_new_run(424242, ["plant1", "beast1", "aqua1", "reptile1", "bug1"], "short", 6, false)
	await get_tree().process_frame
	var size := get_window().size
	RunState.enter_node("r4_c0", "battle")
	var scene: CombatView = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(scene)
	for _i in 120:
		await get_tree().process_frame
	scene._land_dice_now()
	for _i in 30:
		await get_tree().process_frame
	var e: Unit = scene._combat.enemies[0]
	var a: Unit = scene._combat.party[1]
	# Hit: number at its peak (t 175 = 0.25 of 700).
	U5Moments.on_hit(scene, e.uid, "hit")
	U5Moments.float_text(scene, e.uid, "-8", "dmg", 0)
	await _at(0.175, "moment-hit", size)
	await _settle()
	U5Moments.on_hit(scene, e.uid, "crit")
	U5Moments.float_text(scene, e.uid, "CRIT -12", "dmg", 2)
	await _at(0.2, "moment-crit", size)
	await _settle()
	var big := maxi(int(ceil(e.max_hp * 0.3)), 1)
	U5Moments.on_hit(scene, e.uid, "big_hit")
	U5Moments.float_text(scene, e.uid, "-%d" % big, "dmg", 1)
	await _at(0.2, "moment-bighit", size)
	await _settle()
	U5Moments.shield_gain(scene, a.uid)
	U5Moments.float_text(scene, a.uid, "+6", "shd", 0)
	await _at(0.26, "moment-shield", size)
	await _settle()
	U5Moments.turn_banner(scene, true)
	await _at(0.5, "moment-turn-banner-player", size)
	await _settle()
	U5Moments.turn_banner(scene, false)
	await _at(0.5, "moment-turn-banner-enemy", size)
	await _settle()
	scene._reveal_intents()
	await _at(0.45, "moment-intent-reveal", size)
	await _settle()
	var hp0 := a.hp
	a.hp = 0
	U5Moments.axie_ko(scene, a.uid)
	await _at(0.6, "moment-axie-ko", size)
	await _settle()
	a.hp = hp0
	U5Moments.boss_phase(scene, e.uid)
	await _at(0.6, "moment-boss-phase", size)
	await _settle()
	U5Moments.victory(scene)
	await _at(0.6, "moment-victory-t600", size)
	await _at(0.9, "moment-victory-end", size)
	U5Moments.end_victory(scene)
	await _settle()
	scene._show_defeat_panel()
	U5Moments.defeat(scene)
	await _at(1.1, "moment-defeat", size)
	scene.queue_free()
	await get_tree().process_frame
	Engine.time_scale = 1.0
	MetaState.reduce_motion = was_reduce
	_guard.restore()
	get_tree().quit(0)


## Wait `sec` of real time after the trigger, then shoot.
func _at(sec: float, file_name: String, size: Vector2i) -> void:
	await get_tree().create_timer(sec, true, false, true).timeout
	await RenderingServer.frame_post_draw
	for sc in get_tree().root.get_children():
		var lay := sc.get_node_or_null("Ui5Moments/Root")
		if lay != null and OS.get_cmdline_user_args().has("--debug"):
			for c in lay.get_children():
				print("  node ", c.name, " pos ", c.position, " size ", c.size, " a ", c.modulate.a, " scale ", c.scale, " vis ", c.visible)
	var img := get_tree().root.get_texture().get_image()
	var path := "%s/%s%s-%dx%d.png" % [_out, file_name, _suffix, size.x, size.y]
	img.save_png(path)
	print("QA: saved %s (t %d ms)" % [path.get_file(), int(sec * 1000.0)])


func _settle() -> void:
	await get_tree().create_timer(1.6, true, false, true).timeout
