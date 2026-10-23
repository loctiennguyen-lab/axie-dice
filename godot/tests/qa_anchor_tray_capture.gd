extends Node
## Manual visual QA: tray marks EMBER / FREE / BONUS next to HOLD / OVERCAST. tools/shot.sh res://tests/qa_anchor_tray_capture.tscn 1280x720
var _guard := SaveGuard.new()


func _snap(name: String) -> void:
	var sz := DisplayServer.window_get_size()
	var dir := QaPaths.evidence_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	get_viewport().get_texture().get_image().save_png("%s/anchor_tray_%s_%dx%d.png" % [dir, name, sz.x, sz.y])


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _ready() -> void:
	_guard.capture()
	ProjectSettings.set_setting("axie/epoch_source", "local")
	RunState.start_new_run_seeded(424242, {"team_keys": ["plant1", "beast1", "aqua1", "reptile1", "bug1"],
		"mode": "short", "ascension": 0, "ranked": false, "rules_on": true})
	RunState.enter_node("r1_c0", "battle")
	var v: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	add_child(v)
	await _wait(2.5)
	var c = v._combat
	# Embers: carried die (EMBER +0.5), one with OVERCAST too, one HOLD
	c.anchor_id = "a_embers"
	c.party[0].stash_carry = true
	c.party[1].stash_carry = true
	c.party[1].overcast = true
	c.party[2].held = true
	v._update_dice_tray()
	await _wait(0.5)
	_snap("embers")
	# Passed Flame ready: FREE · 0 mana
	c.anchor_awakened = true
	v._update_dice_tray()
	await _wait(0.5)
	_snap("embers_free")
	# Big Hand: a bonus die (phantom)
	c.anchor_id = "a_big_hand"
	c.party[0].stash_carry = false
	c.party[1].stash_carry = false
	c.call("_make_phantom", c.party[3], "6TH HAND")
	v._dice_pending.clear()
	v._rebuild_all()
	v._dice_pending.clear()
	v._update_dice_tray()
	await _wait(3.5)
	_snap("bonus")
	_guard.restore()
	get_tree().quit(0)
