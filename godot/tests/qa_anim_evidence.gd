extends Node
## One-off evidence capture (run WITHOUT --headless). Spawns the given enemy keys on the real
## CombatStage3D, grabs 3 idle frames 0.35 s apart, then an attack frame and a hit frame, saves a
## contact sheet PNG and prints how many pixels changed between idle frames (0 = frozen).
## `-- <out prefix, e.g. /path/l6-anim-before> <key,key,...>`

const PARTY := ["plant", "beast", "aqua", "reptile", "bug"]


func _wait(sec: float) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < int(sec * 1000.0):
		await get_tree().process_frame


func _shot() -> Image:
	var img := get_tree().root.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	return img


func _diff(a: Image, b: Image) -> int:
	var n := 0
	var w := a.get_width()
	var h := a.get_height()
	for y in range(0, h, 2):
		for x in range(0, w, 2):
			if a.get_pixel(x, y).is_equal_approx(b.get_pixel(x, y)) == false:
				n += 1
	return n


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var prefix: String = args[0]
	var keys: Array = Array(args[1].split(","))
	var stage: Node = (load("res://scenes/shared/CombatStage3D.tscn") as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(stage)
	await get_tree().process_frame
	await get_tree().process_frame
	for i in 5:
		stage.spawn_unit(100 + i, PARTY[i], false, i, 5)
	for i in keys.size():
		var k: String = keys[i]
		stage.spawn_unit(1 + i, "bug", true, i, keys.size(), MonsterArt.BOSS_KEYS.has(k), k)
	await _wait(1.2)
	var frames: Array[Image] = []
	for _i in 3:
		frames.append(_shot())
		await _wait(0.35)
	print("EVIDENCE idle_diff_px 0->1=", _diff(frames[0], frames[1]), " 1->2=", _diff(frames[1], frames[2]))
	for i in keys.size():
		stage.play_action(1 + i, "dmg", 100)
	await _wait(0.25)
	frames.append(_shot())
	for i in keys.size():
		stage.play_hit_reaction(1 + i)
	await _wait(0.15)
	frames.append(_shot())
	await _wait(0.2)
	for i in keys.size():
		stage.play_death(1 + i)
	await _wait(0.4)
	frames.append(_shot())
	# contact sheet: 6 frames, 3 x 2, each half size
	var w := frames[0].get_width() / 2
	var h := frames[0].get_height() / 2
	var sheet := Image.create(w * 3, h * 2, false, Image.FORMAT_RGBA8)
	for i in frames.size():
		var f: Image = frames[i].duplicate()
		f.resize(w, h, Image.INTERPOLATE_BILINEAR)
		sheet.blit_rect(f, Rect2i(0, 0, w, h), Vector2i((i % 3) * w, (i / 3) * h))
	sheet.save_png(prefix + ".png")
	print("EVIDENCE saved ", prefix, ".png (idle,idle,idle / attack,hit,death)")
	get_tree().quit(0)
