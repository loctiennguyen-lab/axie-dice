extends Node
## UI-05 b23 lane S8a1: frames a01-a12, a17-a18 at 1920x1080 and 1280x720 (scale pinned). Not headless:
## godot/tools/shot.sh res://tests/qa_ui5_account_capture.tscn [WxH]. Stub service, no network.
## Writes production/qa/ui05-b23/s8a1/<frame id>[--1280].png (or $UI5_SHOT_DIR).

class Stub extends Node:
	signal changed
	var status := 0
	var account: Dictionary = {}
	var desktop_phase := "idle"
	var desktop_error := ""
	func is_signed_in() -> bool: return not account.is_empty()
	func display_name() -> String: return String(account.get("name", ""))
	func sign_in(_sw: bool = false) -> void: pass
	func cancel_desktop_sign_in() -> void: pass
	func reopen_desktop_browser() -> void: pass
	func clear_desktop_error() -> void: pass
	func dismiss_desktop_result() -> void: pass
	func play_as_guest() -> void: pass
	func sync_now() -> void: pass
	func sign_out() -> void: pass

var _out := ""


func _ready() -> void:
	_out = OS.get_environment("UI5_SHOT_DIR")
	if _out == "":
		_out = ProjectSettings.globalize_path("res://").path_join("../production/qa/ui05-b23/s8a1").simplify_path()
	DirAccess.make_dir_recursive_absolute(_out)
	await get_tree().process_frame
	var who := {"name": "Test Player", "email": "test.player@example.test"}
	var screens := [
		["a01-account--signed-out", {}, false], ["a02-account--waiting", {"desktop_phase": "waiting"}, false],
		["a03-account--finishing", {"desktop_phase": "finishing"}, false],
		["a04-account--error-timeout", {"desktop_phase": "error", "desktop_error": "timeout"}, false],
		["a05-account--error-workspace", {"desktop_phase": "error", "desktop_error": "admin_policy_enforced"}, false],
		["a06-account--signed-in", {"status": AccountService.Status.SAVED, "account": who}, false],
		["a07-account--sign-out-armed", {"status": AccountService.Status.SAVED, "account": who}, true],
		["a08-account--expired", {"status": AccountService.Status.EXPIRED, "account": who}, false]]
	var overlays := [
		["a09-signin-overlay--waiting", "waiting", ""], ["a10-signin-overlay--finishing", "finishing", ""],
		["a11-signin-overlay--done", "signed_in", ""], ["a12-signin-overlay--error", "error", "network"]]
	var toasts := [["a17-toast--cancelled", "access_denied"], ["a18-toast--expired", "session_expired"]]
	for size in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		UI3Theme.set_scale_override(1.0 if size.x >= 1920 else 2.0 / 3.0)
		get_window().size = size
		var sfx := "" if size.x >= 1920 else "--1280"
		for sc in screens:
			var svc := Stub.new()
			add_child(svc)
			for k in (sc[1] as Dictionary):
				svc.set(k, sc[1][k])
			var s := AccountScreen.new()
			s.service = svc
			s.no_scene_change = true
			add_child(s)
			await _frames()
			if sc[2]:
				(s.find_child("SignOutButton", true, false) as Button).pressed.emit()
				await _frames()
			await _shot(sc[0] + sfx)
			s.queue_free()
			svc.queue_free()
		for o in overlays:
			var svc := Stub.new()
			svc.account = who
			svc.desktop_phase = o[1]
			svc.desktop_error = o[2]
			add_child(svc)
			var back := _backdrop()
			var layer := CanvasLayer.new()
			add_child(layer)
			AccountUI.show_desktop_flow(layer, svc, 0.0)
			await _frames()
			await _shot(o[0] + sfx)
			layer.queue_free()
			back.queue_free()
			svc.queue_free()
		for t in toasts:
			var svc := Stub.new()
			add_child(svc)
			var back := _backdrop()
			var layer := CanvasLayer.new()
			svc.add_child(layer)
			AccountUI.show_toast(layer, t[1])
			await _frames()
			await _shot(t[0] + sfx)
			back.queue_free()
			svc.queue_free()
	UI3Theme.set_scale_override(-1.0)
	get_tree().quit(0)


func _backdrop() -> Control:
	var c := ColorRect.new()
	c.color = UI3Theme.color("bg")
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(c)
	return c


func _frames() -> void:
	for _i in 10:
		await get_tree().process_frame


func _shot(id: String) -> void:
	var img := get_tree().root.get_texture().get_image()
	img.save_png("%s/%s.png" % [_out, id])
	print("QA: saved %s (%dx%d)" % [id, img.get_width(), img.get_height()])
