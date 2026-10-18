extends Node
## UI-03 16-boot capture: AccountScreen in signed_out / waiting / error / expired with a stub service.
## godot/tools/with_lock.sh godot/tools/shot.sh res://tests/qa_ui3_boot_capture.tscn 1280x720

class Stub extends Node:
	signal changed
	var status: int = 0
	var account: Dictionary = {}
	var desktop_phase := "idle"
	var desktop_error := ""
	func is_signed_in() -> bool: return not account.is_empty()
	func display_name() -> String: return String(account.get("name", ""))
	func sign_in(_sw: bool = false) -> void: pass
	func cancel_desktop_sign_in() -> void: pass
	func reopen_desktop_browser() -> void: pass
	func clear_desktop_error() -> void: pass
	func play_as_guest() -> void: pass
	func sign_out() -> void: pass

var _guard := SaveGuard.new()


func _ready() -> void:
	_guard.capture()
	var svc := Stub.new()
	add_child(svc)
	var s := AccountScreen.new()
	s.service = svc
	s.no_scene_change = true
	add_child(s)
	await _shot("signed-out")
	svc.desktop_phase = "waiting"
	svc.changed.emit()
	await _shot("waiting")
	svc.desktop_phase = "error"
	svc.desktop_error = "network"
	svc.changed.emit()
	await _shot("error")
	svc.desktop_phase = "idle"
	svc.desktop_error = ""
	svc.status = AccountService.Status.EXPIRED
	svc.changed.emit()
	await _shot("expired")
	_guard.restore()
	get_tree().quit(0)


func _shot(tag: String) -> void:
	for _i in 8:
		await get_tree().process_frame
	var img := get_tree().root.get_texture().get_image()
	var path := QaPaths.evidence_dir() + "/ui3-boot-%s-%dx%d.png" % [tag, img.get_width(), img.get_height()]
	img.save_png(path)
	print("QA: saved ", path)
