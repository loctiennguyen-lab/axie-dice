extends Node
## Manual visual QA (non-headless): Profile with titles, and Result on the run that earns A5 title.
var _guard := SaveGuard.new()
const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bird1"]

func _shot(name: String) -> void:
	DirAccess.make_dir_recursive_absolute(QaPaths.evidence_dir())
	var path := "%s/c7_titles_%s.png" % [QaPaths.evidence_dir(), name]
	get_tree().root.get_texture().get_image().save_png(path)
	print("saved ", path)

func _settle() -> void:
	for i in 10:
		await get_tree().process_frame

func _ready() -> void:
	_guard.capture()
	MetaState.tutorial_seen = true
	MetaState.cosmetics_owned.clear()
	RunState.start_new_run(777005, TEAM, "short", 5, false)
	RunState.power_level = 9
	RunState.set_phase(RunState.RunPhase.WON)
	var rv: Node = (load("res://scenes/result/Result.tscn") as PackedScene).instantiate()
	add_child(rv)
	await _settle()
	_shot("result")
	rv.queue_free()
	MetaState.equip_title(TitleNames.ascension_titles()[0]["id"])
	var pv: ProfileView = load("res://scenes/profile/Profile.tscn").instantiate()
	pv.no_scene_change = true
	add_child(pv)
	await _settle()
	_shot("profile")
	_guard.restore()
	get_tree().quit(0)
