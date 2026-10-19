extends Node
## Lane U: start-of-fight skill VFX placement. Not headless:
## godot/tools/shot.sh res://tests/qa_u_vfx_capture.tscn 1920x1080 -> <ADT_EVIDENCE_DIR>/u-vfx-<tag>-<w>x<h>.png
## Logs every SkillVfxLayer clip (key, origin, scale) the first seconds of the Savannah fight.
var _guard := SaveGuard.new()


func _ready() -> void:
	_guard.capture()
	var out := OS.get_environment("ADT_EVIDENCE_DIR")
	if out == "":
		out = ProjectSettings.globalize_path("res://").path_join("../production/qa/evidence").simplify_path()
	DirAccess.make_dir_recursive_absolute(out)
	var tag := OS.get_environment("CAP_TAG") if OS.get_environment("CAP_TAG") != "" else "run"
	RunState.start_new_run(424242, ["plant1", "beast1", "aqua1", "reptile1", "bug1"], "short", 6, false)
	await get_tree().process_frame
	var graph := RunMapGraph.from_data(RunState.map_graph)
	var nid := ""
	for n in graph.get_row(3):
		if (n as RunMapNode).node_type == "battle":
			nid = (n as RunMapNode).id
	RunState.power_level = 4
	RunState.enter_node(nid, "battle")
	var scene: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(scene)
	var sz := get_window().size
	var seen := {}
	for f in 300:
		await get_tree().process_frame
		var sv = scene._skill_vfx
		if is_instance_valid(sv):
			for e in sv._active:
				var k := "%s@%s" % [e["key"], e["origin"]]
				if not seen.has(k):
					seen[k] = true
					print("VFX f=", f, " key=", e["key"], " origin=", e["origin"], " scale=", e["scale"], " rot=", snappedf(e["rot"], 0.01))
					RenderingServer.frame_post_draw
		if f % 20 == 10 and f < 200:
			await RenderingServer.frame_post_draw
			get_tree().root.get_texture().get_image().save_png("%s/u-vfx-%s-f%03d-%dx%d.png" % [out, tag, f, sz.x, sz.y])
	_guard.restore()
	get_tree().quit(0)
