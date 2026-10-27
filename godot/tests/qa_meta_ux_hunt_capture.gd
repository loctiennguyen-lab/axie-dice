extends Node
## Capture for the 27/10 UX hunt fixes on meta screens: Pass, Echo Box (cost + Open 10 confirm), Daily, Land tier banner.
## Run: godot/tools/shot.sh res://tests/qa_meta_ux_hunt_capture.tscn 1280x720

var _guard := SaveGuard.new()


func _ready() -> void:
	_guard.capture()
	MetaState.tutorial_seen = true
	MetaState.tickets = {"normal": 12, "season": 0}
	LandNav.dry_run = true
	var n := await _open("res://scenes/pass/Pass.tscn")
	await _shot("uxhunt_pass")
	n.queue_free()
	var e := await _open("res://scenes/echobox/EchoBoxScreen.tscn")
	await _frames(5)
	(e.find_child("OpenN", true, false) as Button).emit_signal("pressed")
	await _frames(10)
	await _shot("uxhunt_echobox_confirm")
	e.queue_free()
	var d := await _open("res://scenes/daily/DailyScreen.tscn")
	await _shot("uxhunt_daily")
	d.queue_free()
	LandHub.qa = {"guest": false, "newcomer": false, "first_launch": false}
	var l := await _open("res://scenes/land/Land.tscn")
	MetaState.land_tier_banner_seen = 1
	l.set("_tier", 2)
	l.call("_close_modal")
	l.call("_show_tier_banner")
	await _frames(10)
	await _shot("uxhunt_land_banner")
	_guard.restore()
	get_tree().quit(0)


func _open(path: String) -> Node:
	var n: Node = (load(path) as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(n)
	await _frames(40)
	return n


func _frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame


func _shot(name: String) -> void:
	var path := QaPaths.evidence_dir() + "/%s.png" % name
	get_tree().root.get_texture().get_image().save_png(path)
	print("QA: saved ", path)
