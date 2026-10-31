extends Node
## UI-05 b23 lane S8a2: frames a13-a16 at 1920x1080 and 1280x720. Not headless: godot/tools/shot.sh res://tests/qa_ui5_gate_capture.tscn
## Writes production/qa/ui05-b23/s8a2/<frame id>[--1280].png (or $UI5_SHOT_DIR). Stub service, fixture saves.

class Stub extends Node:
	signal changed
	func check() -> void: pass
	func sign_in(_sw: bool = false) -> void: pass
	func play_as_guest() -> void: pass

func _ready() -> void:
	var out := OS.get_environment("UI5_SHOT_DIR")
	if out == "":
		out = ProjectSettings.globalize_path("res://").path_join("../production/qa/ui05-b23/s8a2").simplify_path()
	DirAccess.make_dir_recursive_absolute(out)
	await get_tree().process_frame
	var info := {"local": {"shards": 31, "xp": 900, "vault": 2, "runs": 7, "wins": 5, "run": ""},
		"cloud": {"shards": 17, "xp": 400, "vault": 4, "runs": 9, "wins": 1, "run": "", "updated_at": int(Time.get_unix_time_from_system()) - 10800}}
	for size in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		UI3Theme.set_scale_override(1.0 if size.x >= 1920 else 2.0 / 3.0)
		get_window().size = size
		var sfx := "" if size.x >= 1920 else "--1280"
		for f in ["a13-boot-offline-gate", "a14-welcome-panel", "a15-choose-a-save", "a16-move-guest-progress"]:
			var svc := Stub.new()
			add_child(svc)
			var back := ColorRect.new()
			back.color = UI3Theme.color("bg")
			back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			add_child(back)
			var layer := CanvasLayer.new()
			svc.add_child(layer)
			match f:
				"a13-boot-offline-gate": AccountUI.show_offline_gate(layer, svc)
				"a14-welcome-panel": AccountUI.show_welcome(layer)
				"a15-choose-a-save": AccountUI.show_choice(layer, "choose", info, func(_c: String) -> void: pass)
				_: AccountUI.show_choice(layer, "move", info, func(_c: String) -> void: pass)
			for _i in 10:
				await get_tree().process_frame
			var img := get_tree().root.get_texture().get_image()
			img.save_png("%s/%s%s.png" % [out, f, sfx])
			back.queue_free()
			svc.queue_free()
			await get_tree().process_frame
	UI3Theme.set_scale_override(-1.0)
	get_tree().quit(0)
