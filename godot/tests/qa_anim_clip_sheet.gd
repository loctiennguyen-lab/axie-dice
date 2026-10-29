extends Node3D
## Manual VISUAL QA (run WITHOUT --headless): renders weapon-package / body clips on a real Axie
## and writes one contact sheet per body: one row per clip, 5 poses across the clip.
## Run: Godot --path godot res://tests/qa_anim_clip_sheet.tscn -- <out_dir> [Body,...] [clip,...] [cls]

const CELL := 240
const FRACS := [0.1, 0.25, 0.4, 0.55, 0.7, 0.85]
const DEFAULT_CLIPS := ["Idle", "WalkAttack", "RunAttack", "IdleCarryItem", "IdleGetHit", "Stun",
	"AttackHead", "AttackRange", "AttackCombo", "CutTree", "HitTree", "LootItem", "PourWater",
	"Shoveling", "StoneHarvest", "MalaSkill", "TomeSkill", "TalismanSkill", "FluteSkill",
	"StaffSkill", "LanternSkill", "HammerSkill", "FlagAttack", "GauntletSkill", "HammerRun"]

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir := args[0] if args.size() > 0 else "user://anim_sheets"
	var bodies: Array = Array(args[1].split(",")) if args.size() > 1 else ["Normal"]
	var clips: Array = Array(args[2].split(",")) if args.size() > 2 and args[2] != "-" else DEFAULT_CLIPS
	var cls := args[3] if args.size() > 3 else "Beast"
	DirAccess.make_dir_recursive_absolute(out_dir)
	get_window().size = Vector2i(720, 720)
	var cam := Camera3D.new()
	add_child(cam)
	var zoom := float(args[4]) if args.size() > 4 else 1.0
	cam.position = Vector3(2.6, 1.6, 3.4) / zoom
	cam.look_at_from_position(cam.position, Vector3(0, 0.55 if zoom <= 1.0 else 0.75, 0))
	cam.fov = 40
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.82, 0.86, 0.9)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.7, 0.7, 0.7)
	add_child(env)
	await get_tree().process_frame
	var f: AxieFactory = AxieFactory.default_factory
	for bname in bodies:
		var body := AxieTypes.BODY_NAMES.find(bname)
		var weap: Dictionary = {} if (args.size() > 5 and args[5] == "baked") else f.catalog.load_animations(str(f.catalog.body_entry(body).get("weapon_anims_glb", "")))
		var desc := AxieDescriptor.new()
		desc.body = body
		desc.color_variant = 3
		var parts: Array[AxiePartDescriptor] = []
		for pt in CombatStage3D._PART_TYPES:
			parts.append(AxiePartDescriptor.new(pt, 0, cls, CombatStage3D._PART_VARIANT, 1))
		desc.parts = parts
		var ch := AxieCharacter3D.from_descriptor(desc)
		add_child(ch.root)
		var baked := args.size() > 5 and args[5] == "baked"
		if baked:
			print("REGISTERED %d baked clips on %s" % [CombatAnim.register_extras(ch), bname])
		ch.root.rotation_degrees.y = 90.0
		var sheet := Image.create(CELL * FRACS.size(), CELL * clips.size(), false, Image.FORMAT_RGBA8)
		sheet.fill(Color.WHITE)
		var row := 0
		for clip_name in clips:
			var anim: Animation = weap.get(String(clip_name).to_lower(), null)
			if anim != null and not baked:
				ch.playable.register(clip_name, anim)
			var p := AnimPlayParams.new(clip_name, "", false, 0.0)
			var tr := ch.playable.play(p)
			if tr == null:
				print("MISSING %s %s" % [bname, clip_name])
				row += 1
				continue
			ch.playable.pause()
			for ci in FRACS.size():
				ch.playable.seek_track(tr, FRACS[ci])
				for _i in 3:
					await get_tree().process_frame
				await RenderingServer.frame_post_draw
				var img := get_viewport().get_texture().get_image()
				var s := mini(img.get_width(), img.get_height())
				img = img.get_region(Rect2i((img.get_width() - s) / 2, (img.get_height() - s) / 2, s, s))
				img.resize(CELL, CELL)
				img.convert(Image.FORMAT_RGBA8)
				sheet.blit_rect(img, Rect2i(0, 0, CELL, CELL), Vector2i(ci * CELL, row * CELL))
			print("ROW %d %s len=%.2f" % [row, clip_name, ch.playable.get_duration(clip_name)])
			ch.playable.resume()
			row += 1
		sheet.save_png(out_dir.path_join("sheet_%s.png" % bname))
		ch.root.queue_free()
	get_tree().quit(0)
