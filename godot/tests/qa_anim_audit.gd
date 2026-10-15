extends Node
## One-off AUDIT (run WITHOUT --headless): for every roster monster/elite/boss spawned through the
## real CombatStage3D, report whether an AnimationPlayer exists, what clips it has, whether it is
## playing, and whether the pose actually changes over 0.6 s. `-- [key,key,...]`

func _pose(root: Node) -> float:
	var s := 0.0
	for n in CombatStage3D._descendants(root):
		if n is Skeleton3D:
			var sk := n as Skeleton3D
			for b in sk.get_bone_count():
				var p := sk.get_bone_pose(b)
				s += p.origin.length() * 3.0 + p.basis.get_euler().length()
		elif n is Node3D and n != root:
			var t := (n as Node3D).transform
			s += t.origin.length() * 3.0 + t.basis.get_euler().length() + t.basis.get_scale().length()
	return s


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var keys: Array = MonsterArt.NORMAL_KEYS + MonsterArt.ELITE_KEYS + MonsterArt.BOSS_KEYS
	if args.size() > 0:
		keys = Array(args[0].split(","))
	var stage_scene := load("res://scenes/shared/CombatStage3D.tscn") as PackedScene
	var stage: Node = stage_scene.instantiate()
	get_tree().root.add_child.call_deferred(stage)
	await get_tree().process_frame
	await get_tree().process_frame
	var uid := 1
	var rows := []
	for k in keys:
		stage.spawn_unit(uid, "bug", true, 0, 1, MonsterArt.BOSS_KEYS.has(k), k)
		var ent: Dictionary = stage._units[uid]
		var atia: Dictionary = ent.get("atia", {})
		var vis: Node3D = ent["visual"]
		var reg := MonsterArt.resolve(k, MonsterArt.BOSS_KEYS.has(k))
		var player: AnimationPlayer = atia.get("player")
		for _i in 3:
			await get_tree().process_frame
		var p0 := _pose(vis)
		var t0 := Time.get_ticks_msec()
		while Time.get_ticks_msec() - t0 < 600:
			await get_tree().process_frame
		var p1 := _pose(vis)
		var info := "kind=%s atia=%s" % [reg.get("kind", "?"), not atia.is_empty()]
		if player != null:
			info += " clips=%s cur='%s' playing=%s active=%s speed=%s proc=%d root=%s" % [
				Array(player.get_animation_list()), player.current_animation, player.is_playing(),
				player.active, player.speed_scale, player.callback_mode_process, player.root_node]
			var cfg: Dictionary = reg.get("anims", {})
			var missing := []
			for sl in cfg.keys():
				if not player.has_animation(String(cfg[sl])):
					missing.append("%s=%s" % [sl, cfg[sl]])
			info += " MISSING=%s" % [missing]
			if player.current_animation != "":
				var an := player.get_animation(player.current_animation)
				info += " len=%.2f loop=%d tracks=%d" % [an.length, an.loop_mode, an.get_track_count()]
				var bad := 0
				for ti in an.get_track_count():
					if player.get_node_or_null(NodePath(String(an.track_get_path(ti)).get_slice(":", 0))) == null and player.get_node_or_null(player.root_node).get_node_or_null(NodePath(String(an.track_get_path(ti)).get_slice(":", 0))) == null:
						bad += 1
				info += " unresolved_tracks=%d" % bad
		else:
			info += " NO_PLAYER"
		print("AUDIT ", k, " | ", info, " | pose_delta=", snappedf(absf(p1 - p0), 0.0001))
		uid += 1
	get_tree().quit(0)
