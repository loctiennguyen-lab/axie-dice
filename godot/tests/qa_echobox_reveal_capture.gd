extends Node
## Manual visual QA: Echo Box single reveal and 10-pull reveal (Stone cards carry the Stone icon).
var _EVIDENCE_DIR := QaPaths.evidence_dir()
var _guard := SaveGuard.new()


func _shot(tag: String) -> void:
	for i in 12:
		await get_tree().process_frame
	var w := DisplayServer.window_get_size()
	get_viewport().get_texture().get_image().save_png("%s/echobox-reveal-%s-%dx%d.png" % [_EVIDENCE_DIR, tag, w.x, w.y])


func _ready() -> void:
	_guard.capture()
	DirAccess.make_dir_recursive_absolute(_EVIDENCE_DIR)
	MetaState.tickets = {"normal": 12, "season": 0}
	MetaState.echobox_pity = {}
	var s: EchoBoxScreen = load("res://scenes/echobox/EchoBoxScreen.tscn").instantiate()
	s.use_account = false
	s.remote_on = true
	s.no_scene_change = true
	s.instant = true
	add_child(s)
	await get_tree().process_frame
	var stone := {"ok": true, "kind": "stone", "amount": 250, "rarity": "", "item": "", "duplicate": false, "fragments": 0}
	s.pull_hook = func(_n: int) -> Array: return [stone]
	await s.pull(1)
	await _shot("single-stone")
	s.close_modal()
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var mix: Array = [stone]
	while mix.size() < 10:
		var r := EchoBox.open_normal(MetaState, rng)
		if r.get("ok", false):
			mix.append(r)
	mix.insert(4, stone)
	mix.resize(10)
	s.pull_hook = func(_n: int) -> Array: return mix
	MetaState.tickets["normal"] = 12
	await s.pull(10)
	await _shot("ten")
	s.close_modal()
	s.results = mix
	s._refresh_all()
	await _shot("summary")
	_guard.restore()
	get_tree().quit(0)
