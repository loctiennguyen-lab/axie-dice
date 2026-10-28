extends Node
## UI-05 b1 lane A: combat HUD shell frames (idle, player-turn, enemy-turn, waiting, aid-offer) at 1920x1080 and
## 1280x720, named after the HTML frames in design/handoffs/ui-05-figma/round-1/ui05-combat-screens.html.
## Not headless: godot/tools/shot.sh res://tests/qa_ui5_hud_capture.tscn
## Writes production/qa/ui05-b1/a/02-combat--<state>[--1280].png (or $UI5_SHOT_DIR). The UI scale is forced to 1.0 /
## 0.667 (a DPR-1 screen), so the 1280 overrides and the 14 px text floor show as they would on a 1280x720 window.

var _guard := SaveGuard.new()
var _out := ""


func _ready() -> void:
	_guard.capture()
	_out = OS.get_environment("UI5_SHOT_DIR")
	if _out == "":
		_out = ProjectSettings.globalize_path("res://").path_join("../production/qa/ui05-b1/a").simplify_path()
	DirAccess.make_dir_recursive_absolute(_out)
	RunState.start_new_run(424242, ["plant1", "beast1", "aqua1", "reptile1", "bug1"], "short", 6, false)
	RunState.ascension = 6
	await get_tree().process_frame
	for size in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		# A DPR-1 display: on a Retina Mac the window px are physical, so UI3Theme would read 0.5 / 0.333.
		UI3Theme.set_scale_override(1.0 if size.x >= 1920 else 2.0 / 3.0)
		get_window().size = size
		for _i in 5:
			await get_tree().process_frame
		await _states(size)
	UI3Theme.set_scale_override(-1.0)
	_guard.restore()
	get_tree().quit(0)


func _shot(state: String, size: Vector2i) -> void:
	for _i in 12:
		await get_tree().process_frame
	var img := get_tree().root.get_texture().get_image()
	var suffix := "" if size.x >= 1920 else "--%d" % size.x
	img.save_png("%s/02-combat--%s%s.png" % [_out, state, suffix])
	print("QA: saved 02-combat--%s%s (%dx%d image)" % [state, suffix, img.get_width(), img.get_height()])


func _states(size: Vector2i) -> void:
	MetaState.runs_with_battle = 99
	MetaState.gems_cache = 500
	RunState.power_level = 3
	RunState.enter_node("r4_c0", "battle")
	var scene: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(scene)
	for _i in 90:
		await get_tree().process_frame
	scene._land_dice_now()
	scene._rebuild_all()
	await _shot("idle", size)
	await _shot("player-turn", size)
	# BossRhythm alone (lane A part of 02-combat--boss; the boss plate itself is lane C), fed straight to the HUD.
	scene._hud_frame.update_foe({"rhythm": {"phase": "prep", "next": "hollow", "tell": "Next turn: Hollow, hit it hard"}})
	await _shot("boss-rhythm-only", size)
	scene._hud_frame.update_foe({})
	# aid-offer: free rerolls gone, no mana for a paid one -> "Reroll · need 1 MP" and the Aid offer card.
	scene._combat.rerolls = 0
	scene._combat.mana = 0
	scene._rebuild_all()
	await _shot("aid-offer", size)
	# waiting: a seed request in flight (the dock dims after 300 ms).
	scene._hud_frame.set_seed_wait(true)
	scene._aid.set_waiting(true)
	for _i in 40:
		await get_tree().process_frame
	await _shot("waiting", size)
	scene._hud_frame.set_seed_wait(false)
	scene._aid.set_waiting(false)
	# enemy-turn: the resolve phase (End turn reads "Enemy turn", disabled; tools dimmed).
	scene._combat.phase = CombatEngine.CombatPhase.END_TURN
	scene._rebuild_all()
	await _shot("enemy-turn", size)
	scene.queue_free()
	await get_tree().process_frame
