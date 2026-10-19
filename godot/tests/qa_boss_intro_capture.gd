extends Node
## Manual VISUAL QA capture of the boss intro at three moments (push-in, roar flash, plate). NOT in the suite:
## needs a real window (not --headless). Boss key from env AXIE_BOSS (default agony); frames go to
## $ADT_EVIDENCE_DIR. Run: AXIE_BOSS=agony godot/tools/shot.sh res://tests/qa_boss_intro_capture.tscn 1920x1080

var _dir := QaPaths.evidence_dir()


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(_dir)
	var key := OS.get_environment("AXIE_BOSS")
	if key == "":
		key = "agony"
	var intro := BossIntro.new()
	if not intro.setup(key):
		print("qa_boss_intro_capture: no data for %s" % key)
		get_tree().quit(1)
		return
	add_child(intro)
	var res := "%dx%d" % [get_window().size.x, get_window().size.y]
	for pair in [["push", 450], ["roar", 900], ["plate", 2000]]:
		while intro.elapsed_ms < int(pair[1]):
			await get_tree().process_frame
		var img := get_viewport().get_texture().get_image()
		var path := "%s/boss_intro_%s_%s_%s.png" % [_dir, key, pair[0], res]
		img.save_png(path)
		print("dbg plate pos=", intro.plate.position, " size=", intro.plate.size, " mod=", intro.plate.modulate, " vis=", intro.plate.visible, " cam=", intro._cam.position, " fps=", Engine.get_frames_per_second())
		print("qa_boss_intro_capture: %s at %d ms" % [path, intro.elapsed_ms])
	get_tree().quit(0)
