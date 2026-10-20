extends Node
## QA: Result backdrop. Run non-headless via tools/shot.sh. RB_BG=<res/abs path> swaps the backdrop
## texture after the screen is built (variant compare); RB_OUT=<file stem>; RB_WON=0 for the defeat shot.
var _guard := SaveGuard.new()

func _ready() -> void:
	_guard.capture()
	var won := OS.get_environment("RB_WON") != "0"
	RunState.start_new_run(777001, ["plant1", "beast1", "aqua1", "reptile1", "bug1"], "short", 5, false)
	RunState.shards_this_run = 87
	RunState.run_stats = {"dmg": 913, "dmg_dealt_clamped": 913, "taken": 140, "turns": 41, "kills": 23, "max_hit": 31}
	RunState.set_phase(RunState.RunPhase.WON if won else RunState.RunPhase.LOST)
	var v: Node = (load("res://scenes/result/Result.tscn") as PackedScene).instantiate()
	add_child(v)
	var bgp := OS.get_environment("RB_BG")
	if bgp != "":
		var img := Image.load_from_file(bgp) if bgp.begins_with("/") else (load(bgp) as Texture2D).get_image()
		(v.get_node("PlateHost") as TextureRect).texture = ImageTexture.create_from_image(img)
	for i in 10:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var out := OS.get_environment("RB_OUT")
	get_viewport().get_texture().get_image().save_png(out + ".png")
	_guard.restore()
	get_tree().quit(0)
