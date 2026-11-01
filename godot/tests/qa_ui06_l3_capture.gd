extends Node
## UI-06 L3 capture (Drop B): 48-anchor-pick none / picked / locked, 49 awaken moment (end state), ShopCoreCard.
## Not headless: UI6_PROBE_SCALE=1.0 (1920) or 0.6667 (1280) forces the scale (Retina DPR 2), UI6_SHOT_TAG names the files.
## Run: UI6_PROBE_SCALE=1 UI6_SHOT_TAG=1920 godot/tools/shot.sh res://tests/qa_ui06_l3_capture.tscn 1920x1080
var _guard := SaveGuard.new()


func _snap(name: String) -> void:
	var dir := ProjectSettings.globalize_path("res://").path_join("../production/qa/ui06/l3").simplify_path()
	DirAccess.make_dir_recursive_absolute(dir)
	get_viewport().get_texture().get_image().save_png("%s/%s--%s.png" % [dir, name, OS.get_environment("UI6_SHOT_TAG")])


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _host() -> Control:
	var host := Control.new()
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.theme = UI3Theme.get_theme()
	var bg := ColorRect.new()
	bg.color = Color("#4b3a5c")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.add_child(bg)
	add_child(host)
	return host


func _pick(ids: Array, reasons: Dictionary, pick: int, name: String) -> void:
	AnchorAdapter.test_state = {"open": true, "offer": ids, "reasons": reasons, "picked": []}
	var host := _host()
	var v := AnchorPick.new()
	host.add_child(v)
	v.setup(ids, true)
	if pick >= 0:
		v.select(pick)
	await _wait(1.5)
	_snap(name)
	host.queue_free()
	await _wait(0.1)


func _ready() -> void:
	_guard.capture()
	var want := OS.get_environment("UI6_PROBE_SCALE")
	UI3Theme.set_scale_override(float(want) if want != "" else 1.0)
	UI3Theme.sync_scale()
	UI3Gacha.instant_override = 1
	await _pick(["a_volley", "a_gambler", "a_kin"], {}, -1, "48-anchor-pick--none")
	await _pick(["a_kin", "a_embers", "a_big_hand"], {}, 0, "48-anchor-pick--picked")
	await _pick(["a_volley", "a_gambler", "a_mana_mine"], {"a_mana_mine": "stage_locked"}, -1, "48-anchor-pick--locked")
	var hc: Array = AnchorAdapter.house_cores("a_volley")
	AnchorAdapter.test_state = {"anchor_id": "a_volley", "awakened": true, "owned": [hc[1], hc[2]]}
	var host := _host()
	UI3Gacha.instant_override = 0
	var fx := AnchorFx.play(host, "a_volley")
	await _wait(1.0)
	fx._show_final()
	await _wait(0.3)
	_snap("49-anchor-awaken--moment")
	host.queue_free()
	AnchorAdapter.test_state = null
	UI3Theme.set_scale_override(-1.0)
	UI3Gacha.instant_override = -1
	_guard.restore()
	get_tree().quit(0)
