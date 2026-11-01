extends Node
## UI-07 L4: every LoginScreen state at 1920x1080 and 1280x720. Not headless: godot/tools/shot.sh res://tests/qa_ui7_login_capture.tscn
## Writes production/qa/ui07/l4/<state>[--1280].png (or $UI5_SHOT_DIR). Stub service, no network.


func _ready() -> void:
	var out := OS.get_environment("UI5_SHOT_DIR")
	if out == "":
		out = ProjectSettings.globalize_path("res://").path_join("../production/qa/ui07/l4").simplify_path()
	DirAccess.make_dir_recursive_absolute(out)
	await get_tree().process_frame
	for size in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		UI3Theme.set_scale_override(1.0 if size.x >= 1920 else 2.0 / 3.0)
		get_window().size = size
		var sfx := "" if size.x >= 1920 else "--1280"
		for st in LoginScreen.STATES:
			MetaState.runs = 12 if st == "returning-guest" else 0
			var svc := AccountServiceScript.new()
			svc.account = {"id": "x"} if st == "expired" else {}
			add_child(svc)
			var scr := (load("res://scenes/login/LoginScreen.tscn") as PackedScene).instantiate() as LoginScreen
			scr.service = svc
			scr.no_scene_change = true
			scr.skip_intro = true
			add_child(scr)
			var layer := CanvasLayer.new()
			add_child(layer)
			scr.show_state(st, "Your Sky Mavis work account can't sign in to Axie Dice yet. Ask IT to allow Axie Dice for your Google Workspace, or use a personal Google account." if st == "failed" else "")
			if st.begins_with("desktop"):
				svc.desktop_phase = "waiting" if st == "desktop-waiting" else "finishing"
				AccountUI.show_desktop_flow(layer, svc)
			for _i in 12:
				await get_tree().process_frame
			get_tree().root.get_texture().get_image().save_png("%s/%s%s.png" % [out, st, sfx])
			scr.queue_free()
			layer.queue_free()
			svc.queue_free()
			await get_tree().process_frame
	UI3Theme.set_scale_override(-1.0)
	get_tree().quit(0)
