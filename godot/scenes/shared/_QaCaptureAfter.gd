extends Node
## THROWAWAY verification script (ui-programmer monster-sprite/nameplate task) — not part of
## the deliverable, deleted immediately after use. Needs to live under res:// (unlike a
## scratchpad path) so the autoload class cache (RunState/ContentDB) resolves — see
## godot/tests/qa_real_flow_capture.gd's own header comment on why scene-mode + res:// matters
## here. Mirrors that file's real-player-path pattern with a different output filename so the
## "before" evidence screenshot is not overwritten.

func _ready() -> void:
	var team: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	RunState.start_new_run(424242, team, "short", 0, false)
	await get_tree().process_frame

	RunState.power_level = 9
	RunState.enter_node("qa_check_node", "battle")
	await get_tree().process_frame

	var packed: PackedScene = load("res://scenes/combat/Combat.tscn")
	var scene: Node = packed.instantiate()
	get_tree().root.add_child(scene)
	for i in 120:
		await get_tree().process_frame

	var img := get_tree().root.get_texture().get_image()
	img.save_png("/Users/loc.tien.nguyen/my-game/production/qa/evidence/2026-09-18_after-monster-sprites.png")
	print("QA: saved after-sprites screenshot")
	get_tree().quit(0)
