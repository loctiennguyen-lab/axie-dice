extends Node
## Manual visual QA, UI-05 lane R3: tools/shot.sh res://tests/qa_ui5_anchor_capture.tscn 1920x1080 (and 1280x720), not headless.
var _guard := SaveGuard.new()


func _snap(name: String) -> void:
	var sz := DisplayServer.window_get_size()
	var dir := "res://../production/qa/ui05-b23/r3".replace("res://", ProjectSettings.globalize_path("res://"))
	DirAccess.make_dir_recursive_absolute(dir)
	get_viewport().get_texture().get_image().save_png("%s/%s_%dx%d.png" % [dir, name, sz.x, sz.y])


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _show(ids: Array, reasons: Dictionary, pick: int, name: String) -> void:
	AnchorAdapter.test_state = {"open": true, "offer": ids, "reasons": reasons, "picked": []}
	var host := Control.new()
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.theme = UI3Theme.get_theme()
	var bg := ColorRect.new()
	bg.color = Color("#2b3340")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.add_child(bg)
	add_child(host)
	var v := AnchorPick.new()
	host.add_child(v)
	v.setup(ids, true)
	if pick >= 0:
		v.select(pick)
	await _wait(0.6)
	_snap(name)
	host.queue_free()
	await _wait(0.1)


func _ready() -> void:
	_guard.capture()
	UI3Gacha.instant_override = 1
	var w := DisplayServer.window_get_size().x
	UI3Theme.set_scale_override(1.0 if w >= 1900 else 2.0 / 3.0)
	await _show(["a_volley", "a_gambler", "a_mana_mine"], {"a_mana_mine": "stage_locked"}, -1, "48-anchor-pick--none")
	await _show(["a_kin", "a_embers", "a_big_hand"], {}, 1, "48-anchor-pick--picked")
	await _show(["a_volley", "a_gambler", "a_mana_mine"], {"a_mana_mine": "stage_locked"}, 1, "48-anchor-pick--gambler")
	AnchorAdapter.test_state = {"anchor_id": "a_kin", "awakened": true, "owned": []}
	var host := Control.new()
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(host)
	UI3Gacha.instant_override = 0
	AnchorFx.play(host, "a_kin")
	await _wait(1.2)
	_snap("anchorfx")
	AnchorAdapter.test_state = null
	UI3Theme.set_scale_override(-1.0)
	UI3Gacha.instant_override = -1
	_guard.restore()
	get_tree().quit(0)
