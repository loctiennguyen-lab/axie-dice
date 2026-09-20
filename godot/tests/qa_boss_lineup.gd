extends Node
## One-off capture: all six bosses standing side by side, so the "every boss has its own
## identity" decision can be checked with eyes rather than with a grep.
##
## Four of them are .glb models and two are Chimera sprites; the whole point of the change is
## that no boss shares art with a rank-and-file monster any more, and only a picture shows
## whether they also READ as six different things.

const BOSS_ORDER := ["gooey_king", "mecha", "frost_lord", "plague_mother", "mirror", "agony"]


func _ready() -> void:
	var stage_scene := load("res://scenes/shared/CombatStage3D.tscn") as PackedScene
	var stage: Node = stage_scene.instantiate()
	# Deferred: `_ready()` runs while the root is still setting up its own children, and a plain
	# add_child() there fails with "Parent node is busy setting up children" — after which every
	# spawn_unit() call hits a null `_world` and the capture saves an empty stage while printing
	# nothing wrong. Same trap AxiePreview3D hit from the other side.
	get_tree().root.add_child.call_deferred(stage)
	await get_tree().process_frame
	await get_tree().process_frame

	for i in BOSS_ORDER.size():
		stage.spawn_unit(100 + i, "bug", true, i, BOSS_ORDER.size(), true, String(BOSS_ORDER[i]))
	for _i in 90:
		await get_tree().process_frame

	var path := QaPaths.evidence_dir() + "/%s_boss-lineup.png" % _today()
	get_tree().root.get_texture().get_image().save_png(path)
	print("QA: saved ", path)
	get_tree().quit(0)


func _today() -> String:
	var d := Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [int(d["year"]), int(d["month"]), int(d["day"])]
