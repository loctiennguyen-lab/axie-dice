extends Node
## One-off capture (run WITHOUT --headless): every roster monster on the real CombatStage3D,
## in batches of 3 enemies + 5 party Axies, saved as PNGs under the user-given directory.
## Also prints the average FPS of each batch. `-- <out dir> [first_batch] [facing_test]`

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "/tmp"
	var keys: Array = MonsterArt.NORMAL_KEYS + MonsterArt.ELITE_KEYS + MonsterArt.BOSS_KEYS
	if args.size() > 1:
		keys = Array(args[1].split(","))
	var stage_scene := load("res://scenes/shared/CombatStage3D.tscn") as PackedScene
	var stage: Node = null
	var classes := ["plant", "beast", "aqua", "reptile", "bug"]
	var batch := 0
	for s in range(0, keys.size(), 3):
		if stage == null:
			stage = stage_scene.instantiate()
			get_tree().root.add_child.call_deferred(stage)
			await get_tree().process_frame
			await get_tree().process_frame
		var uid := 1 + batch * 20   # unique uids so slot node names never collide between batches
		var ids := []
		var cnt: int = min(3, keys.size() - s)
		for i in 5:
			stage.spawn_unit(uid, classes[i], false, i, 5)
			ids.append(uid); uid += 1
		for i in cnt:
			var k: String = keys[s + i]
			stage.spawn_unit(uid, "bug", true, i, cnt, MonsterArt.BOSS_KEYS.has(k), k)
			ids.append(uid)
			var ent: Dictionary = stage._units[uid]
			var vis: Node3D = ent["visual"]
			print("UNIT ", k, " visual=", vis.get_class(), " ", vis.name, " pos=", vis.position, " scale=", vis.scale, " visible=", vis.visible, " atia=", not (ent.get("atia", {}) as Dictionary).is_empty())
			uid += 1
		for _i in 45:
			await get_tree().process_frame
		var t0 := Time.get_ticks_msec(); var frames := 0
		while Time.get_ticks_msec() - t0 < 1500:
			await get_tree().process_frame; frames += 1
		var fps := frames / 1.5
		var names := keys.slice(s, s + cnt)
		print("BATCH ", batch, " ", names, " fps=", snappedf(fps, 0.1))
		get_tree().root.get_texture().get_image().save_png("%s/batch%02d.png" % [out, batch])
		for id in ids:
			stage.play_action(id, "dmg", -1)
		for _i in 20:
			await get_tree().process_frame
		for id in ids:
			var slot: Node = stage._units[id]["slot"]
			slot.get_parent().remove_child(slot)
			slot.queue_free()
		stage.dispose_all()
		await get_tree().process_frame
		batch += 1
	get_tree().quit(0)
