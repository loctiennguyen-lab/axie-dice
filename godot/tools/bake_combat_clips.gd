extends Node
## Bakes the combat extra clips (CombatAnim.EXTRA_CLIPS) out of the Axie Mixer weapon package into
## small per-body Animation resources: assets/axie/combat_clips/<Body>/<Clip>.res.
##
## WHY. The weapon package is 8 GLBs of ~20 MB (93 clips each) and is excluded from every export
## (export_presets.cfg); the game needs 12 clips. Baking them keeps the web build small and means
## no GLB parse at combat start.
##
## Tracks that drive the weapon joints (Root_Weapon_*) are dropped: there are no weapon meshes.
## Only the Normal body ships AttackHead/AttackRange/AttackCombo/HitTree/LootItem, and Bigyak's GLB
## lacks WalkAttack/RunAttack/IdleCarryItem/IdleGetHit. Those are RETARGETED from Normal as deltas against each body's own Idle frame 0
## (pos_b = idle_b + (src - idle_n), rot_b = idle_b * idle_n^-1 * src), so attach points (where the
## parts sit) keep each body's own offsets instead of Normal's.
##
## Run (headless is fine; needs the dev-only weapon_anims GLBs on disk):
##   godot/tools/with_lock.sh "$GODOT" --headless --path godot res://tools/bake_combat_clips.tscn

const COMPRESS := true


func _ready() -> void:
	await get_tree().process_frame
	var cat: AxieCatalog = AxieFactory.default_factory.catalog
	var normal_w := cat.load_animations(str(cat.body_entry(0).get("weapon_anims_glb", "")))
	var normal_base := cat.load_animations(str(cat.body_entry(0).get("glb", "")))
	var normal_idle: Animation = normal_base.get("idle")
	var total_bytes := 0
	var fails := 0
	for body in AxieTypes.BODY_NAMES.size():
		var bname := AxieTypes.body_name(body)
		var own := cat.load_animations(str(cat.body_entry(body).get("weapon_anims_glb", "")))
		var idle: Animation = cat.load_animations(str(cat.body_entry(body).get("glb", ""))).get("idle")
		var base := cat.load_animations(str(cat.body_entry(body).get("glb", "")))
		var bones := {}
		for k in base.keys():
			var ba: Animation = base[k]
			for i in ba.get_track_count():
				bones[str(ba.track_get_path(i))] = true
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("%s/%s" % [CombatAnim.CLIP_DIR, bname]))
		# Base clips a body GLB does not ship (Bigyak has only Dead/Idle/Run/Stun/Walk) are baked
		# too, from Normal, so no combat clip lookup fails on any body.
		var wanted: Array[String] = CombatAnim.EXTRA_CLIPS.duplicate()
		for bc in CombatAnim.BASE_CLIPS:
			if not base.has(bc.to_lower()):
				wanted.append(bc)
		for clip in wanted:
			var key := clip.to_lower()
			var src: Animation = own.get(key) if CombatAnim.EXTRA_CLIPS.has(clip) else null
			var how := "own"
			var out: Animation
			var normal_src: Animation = normal_w.get(key, normal_base.get(key))
			if src != null:
				out = _strip(src, bones)
			elif normal_src != null:
				out = _retarget(normal_src, normal_idle, idle, bones)
				how = "retarget"
			else:
				push_error("bake: %s has no %s and Normal has none either" % [bname, clip])
				fails += 1
				continue
			out.resource_name = clip
			out.loop_mode = Animation.LOOP_NONE
			# Size: key reduction, then Godot's packed track compression (what the importer does
			# for imported clips). Uncompressed, 12 clips x 8 bodies were ~14 MB.
			out.optimize(0.01, 0.01, 3.0)
			if COMPRESS:
				out.compress()
			var path := CombatAnim.clip_path(body, clip)
			var err := ResourceSaver.save(out, path, ResourceSaver.FLAG_COMPRESS)
			if err != OK:
				push_error("bake: save %s failed %s" % [path, error_string(err)])
				fails += 1
				continue
			var sz := FileAccess.get_file_as_bytes(path).size()
			total_bytes += sz
			print("BAKE %s/%s %s len=%.2f tracks=%d %d KB" % [bname, clip, how, out.length, out.get_track_count(), sz / 1024])
	print("BAKE total %d KB, fails=%d" % [total_bytes / 1024, fails])
	get_tree().quit(1 if fails > 0 else 0)


static func _is_weapon(path: NodePath) -> bool:
	return str(path).to_lower().contains("weapon")


## Copy without the weapon-joint tracks and without tracks for bones this body does not have.
static func _strip(src: Animation, bones: Dictionary) -> Animation:
	var out := src.duplicate(true) as Animation
	for i in range(out.get_track_count() - 1, -1, -1):
		var p := out.track_get_path(i)
		if _is_weapon(p) or not bones.has(str(p)):
			out.remove_track(i)
	return out


static func _track(anim: Animation, path: NodePath, type: int) -> int:
	if anim == null:
		return -1
	return anim.find_track(path, type)


## Normal's clip re-based onto another body (see file header). Keys are resampled at the source's
## own key times, so timing is untouched.
static func _retarget(src: Animation, idle_n: Animation, idle_b: Animation, bones: Dictionary) -> Animation:
	var out := _strip(src, bones)
	for i in out.get_track_count():
		var path := out.track_get_path(i)
		var t := out.track_get_type(i)
		if t != Animation.TYPE_POSITION_3D and t != Animation.TYPE_ROTATION_3D:
			continue
		var ni := _track(idle_n, path, t)
		var bi := _track(idle_b, path, t)
		if ni < 0 or bi < 0:
			continue   # no baseline on one side: keep Normal's values
		for k in out.track_get_key_count(i):
			if t == Animation.TYPE_POSITION_3D:
				var v: Vector3 = out.track_get_key_value(i, k)
				var n0: Vector3 = idle_n.position_track_interpolate(ni, 0.0)
				var b0: Vector3 = idle_b.position_track_interpolate(bi, 0.0)
				out.track_set_key_value(i, k, b0 + (v - n0))
			else:
				var q: Quaternion = out.track_get_key_value(i, k)
				var qn0: Quaternion = idle_n.rotation_track_interpolate(ni, 0.0)
				var qb0: Quaternion = idle_b.rotation_track_interpolate(bi, 0.0)
				out.track_set_key_value(i, k, (qb0 * (qn0.inverse() * q)).normalized())
	return out
