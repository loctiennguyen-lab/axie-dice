extends Node
## One-off QA capture: reproduces the REAL player path (RunState.start_new_run() ->
## RunState.enter_node() -> Combat.tscn) using DIRECT typed calls (not `.call()` reflection,
## which a throwaway diagnostic script proved can silently drop a typed Array[String] param
## and start a run with an empty roster — a scripting-harness bug, not a product bug).
## This scene-based test can call RunState/ContentDB directly by name (autoload class cache
## is available to .tscn-loaded scripts, unlike raw `--script` SceneTree overrides).

## Borrows the player's real save file and puts it back byte for byte. This capture drives real
## run state — and loading `Result.tscn` alone is enough, because `ResultView._ready()` calls
## `RunState.end_run()`, which banks shards and XP into `MetaState`. See `save_guard.gd`.
var _guard := SaveGuard.new()

func _ready() -> void:
	_guard.capture()
	var team: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	RunState.start_new_run(424242, team, "short", 0, false)
	print("QA: after start_new_run, roster.size()=", RunState.roster.size())
	await get_tree().process_frame

	# Walk to a LATER power level before entering, so the encounter generator draws from the
	# upper half of NORMAL_POOL — at pw 0 only the three starter monsters are legal, which is
	# exactly what made the old capture look like a slime-only game.
	RunState.power_level = 9
	RunState.enter_node("qa_check_node", "battle")
	print("QA: pending_combat roster_snapshot.size()=",
		(RunState.pending_combat.get("roster_snapshot", []) as Array).size())
	await get_tree().process_frame

	var packed: PackedScene = load("res://scenes/combat/Combat.tscn")
	var scene: Node = packed.instantiate()
	get_tree().root.add_child(scene)
	for i in 120:
		await get_tree().process_frame

	var combat_view = scene
	print("QA: CombatView._combat.party.size()=", combat_view._combat.party.size())
	print("QA: CombatView._combat.enemies.size()=", combat_view._combat.enemies.size())

	var img := get_tree().root.get_texture().get_image()
	img.save_png("/Users/loc.tien.nguyen/my-game/production/qa/evidence/2026-09-18_real-flow-varied-enemies.png")
	print("QA: saved real-flow screenshot")
	_guard.restore()
	get_tree().quit(0)
