extends Node
## One-off capture: a real BOSS fight, reached through the real flow.
##
## Exists because the boss art rule changed (monsters and bosses come only from the Chimera
## library, never an Axie mascot) and a rule like that has to be checked with eyes, not with
## a grep — the previous boss models were removed by deleting a code branch, and what matters
## is what actually renders in its place.

## Borrows the player's real save file and puts it back byte for byte. This capture drives real
## run state — and loading `Result.tscn` alone is enough, because `ResultView._ready()` calls
## `RunState.end_run()`, which banks shards and XP into `MetaState`. See `save_guard.gd`.
var _guard := SaveGuard.new()

func _ready() -> void:
	_guard.capture()
	var team: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	RunState.start_new_run(424242, team, "short", 0, false)
	await get_tree().process_frame

	# Late enough that the boss is scaled to a real threat, not a turn-1 pushover.
	RunState.power_level = 9
	RunState.enter_node("r12_c0", "boss")
	print("QA: boss_key = ", RunState.pending_combat.get("boss_key", "<none>"))
	await get_tree().process_frame

	var scene: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(scene)
	for i in 120:
		await get_tree().process_frame

	for e in scene._combat.enemies:
		print("QA: enemy key=%s is_boss=%s hp=%d" % [e.key, e.is_boss, e.max_hp])
	get_tree().root.get_texture().get_image().save_png(
		"/Users/loc.tien.nguyen/my-game/production/qa/evidence/2026-09-18_boss-chimera.png")
	print("QA: saved boss screenshot")
	_guard.restore()
	get_tree().quit(0)
