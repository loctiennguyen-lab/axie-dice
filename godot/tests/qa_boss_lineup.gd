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

	# Roster order: 4 elites, then 6 bosses.
	var all: Array = []
	for k in MonsterArt.ELITE_KEYS:
		all.append([k, false])
	for k in BOSS_ORDER:
		all.append([k, true])
	# Half of the roster per run (user arg 0 or 1, default 0) so five units fit in frame.
	var args := OS.get_cmdline_user_args()
	var part := int(args[0]) if args.size() > 0 else 0
	for i in 5:
		var e: Array = all[part * 5 + i]
		stage.spawn_unit(100 + i, "bug", true, i, 5, e[1], String(e[0]))
	for _i in 90:
		await get_tree().process_frame
	var path := QaPaths.evidence_dir() + "/%s_boss-lineup-%d.png" % [_today(), part]
	get_tree().root.get_texture().get_image().save_png(path)
	print("QA: saved ", path)
	get_tree().quit(0)


func _today() -> String:
	var d := Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [int(d["year"]), int(d["month"]), int(d["day"])]
