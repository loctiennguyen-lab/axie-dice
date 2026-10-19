extends Node
## Manual visual QA: Seasonal tab (mid-series state) and a season reveal.
var _EVIDENCE_DIR := QaPaths.evidence_dir()
var _guard := SaveGuard.new()


func _shot(tag: String) -> void:
	for i in 14:
		await get_tree().process_frame
	var w := DisplayServer.window_get_size()
	get_viewport().get_texture().get_image().save_png("%s/season-%s-%dx%d.png" % [_EVIDENCE_DIR, tag, w.x, w.y])


func _ready() -> void:
	_guard.capture()
	DirAccess.make_dir_recursive_absolute(_EVIDENCE_DIR)
	MetaState.tickets = {"normal": 120, "season": 0}
	MetaState.season_box = {}
	MetaState.cosmetics_owned = []
	EchoBoxScreen.season_confirmed = true
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	for i in 14:
		EchoBox.open_season(MetaState, rng, "2026-11-0%d" % (3 + i / 8))
	MetaState.tickets["normal"] = 120
	var s: EchoBoxScreen = load("res://scenes/echobox/EchoBoxScreen.tscn").instantiate()
	s.use_account = false
	s.remote_on = false
	s.no_scene_change = true
	s.instant = true
	add_child(s)
	await get_tree().process_frame
	s.select_tab("seasonal")
	await _shot("tab")
	var r := {"ok": true, "kind": "cosmetic", "tier": "legendary", "item": "die_l_relic_stone", "duplicate": false, "tickets_back": 0}
	s.pull_hook = func(_n: int) -> Array: return [s._season_result(r)]
	await s.pull(1)
	await _shot("reveal")
	s.close_modal()
	var mix: Array = []
	for it in [["epic", "fx_e_rune"], ["epic", "frame_e_firefly"], ["mythic", "frame_m_eclipse"], ["legendary", "fx_l_starfall"], ["epic", "die_e_rune"]]:
		mix.append(s._season_result({"ok": true, "kind": "cosmetic", "tier": it[0], "item": it[1], "duplicate": false, "tickets_back": 0}))
	s.pull_hook = func(_n: int) -> Array: return mix
	await s.pull(5)
	await _shot("reveal5")
	_guard.restore()
	get_tree().quit(0)
