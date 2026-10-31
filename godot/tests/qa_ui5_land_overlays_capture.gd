extends Node
## QA (not headless): 01-land--first-visit / toast-error / new-run-confirm / abandon-mission-confirm / offline /
## offline-retry / reconnecting / beta-reset at the window size. Files: <UI5_SHOT_DIR>/<frame id>-WxH.png
const Util := preload("res://tests/qa_ui5_util.gd")
var _guard := SaveGuard.new()


func _hub(qa: Dictionary, run := false) -> LandHub:
	LandHub.qa = qa
	LandHub.tier_override = 1
	var h := (load("res://scenes/land/Land.tscn") as PackedScene).instantiate() as LandHub
	h.set("_force_run", run)
	add_child(h)
	for _i in 30:
		await get_tree().process_frame
	return h


func _shot(id: String, h: Node) -> void:
	for _i in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	Util.save(get_viewport(), id)
	h.queue_free()
	await get_tree().process_frame


func _ready() -> void:
	_guard.capture()
	MetaState.tutorial_seen = true
	LandNav.dry_run = true
	var small := get_window().size.x < 1600
	UI3Theme.set_scale_override(2.0 / 3.0 if small else 1.0)
	var base := {"guest": false, "newcomer": false, "first_launch": false}
	var h := await _hub({"guest": false, "newcomer": true, "first_launch": true})
	h.call("_show_toast", "Welcome gift: 3 decor in your storage. Open Edit Land to place them.", 30.0)
	await _shot("01-land--first-visit", h)
	h = await _hub(base)
	h.call("_show_toast", "That run could not be loaded and was removed. You can start a new run.", 30.0, &"error")
	await _shot("01-land--toast-error", h)
	h = await _hub(base, true)
	h.call("_on_new_run_pressed")
	await _shot("01-land--new-run-confirm", h)
	MetaState.mission_escrow = {"mission_id": "n3", "stake": 800}
	h = await _hub(base.merged({"mission": true}), true)
	h.call("_on_new_run_pressed")
	await _shot("01-land--abandon-mission-confirm", h)
	MetaState.mission_escrow = {}
	h = await _hub(base.merged({"offline": true}))
	await _shot("01-land--offline", h)
	h = await _hub(base.merged({"offline": true}))
	h._hud.show_toast("Still offline", 30.0, &"error")
	await _shot("01-land--offline-retry", h)
	h = await _hub(base, true)
	h.call("_set_continue_busy", h.find_child("RunPlate", true, false), true)
	h._hud.show_toast("Still reconnecting to the server…", 30.0, &"info")
	await _shot("01-land--reconnecting", h)
	MetaState.reset_notice_id = "qa_shot"
	h = await _hub(base)
	await _shot("01-land--beta-reset", h)
	MetaState.reset_notice_id = ""
	LandHub.qa = {}
	_guard.restore()
	get_tree().quit(0)
