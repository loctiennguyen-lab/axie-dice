extends Node
## Manual visual QA for UI-03 shop (08). Run non-headless via tools/shot.sh.
var _EVIDENCE_DIR := QaPaths.evidence_dir()
var _guard := SaveGuard.new()


func _shot(tag: String) -> void:
	for i in 12:
		await get_tree().process_frame
	var w := DisplayServer.window_get_size()
	get_viewport().get_texture().get_image().save_png("%s/ui3-shop-%s-%dx%d.png" % [_EVIDENCE_DIR, tag, w.x, w.y])


func _ready() -> void:
	_guard.capture()
	DirAccess.make_dir_recursive_absolute(_EVIDENCE_DIR)
	RunState.reset()
	var rm: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(rm)
	await get_tree().process_frame
	RunState.owned_relic_ids.assign(["r_bastionplate", "r_ember"])
	RunState.shards_this_run = 120
	RunState.shop_items.assign([
		{"kind": "relic", "key": "r_bastionplate", "title": "Bastion Plate", "desc": "Gain shield at the start of each turn. A long description to check wrapping in the narrow detail column of the shop.", "rar": 1, "cost": 75, "bought": false},
		{"kind": "relic", "key": "r_ember", "title": "Ember With A Very Long Name Indeed", "desc": "Burn.", "rar": 3, "cost": 220, "bought": false},
		{"kind": "relic", "key": "x", "title": "Old Thing", "desc": "", "rar": 0, "cost": 45, "bought": true},
		{"kind": "heal", "key": "s", "title": "Serum", "desc": "Heal the party.", "rar": 0, "cost": 30, "bought": false},
	])
	rm.call("_render_shop")
	rm.call("_select_shop", 1)
	await _shot("normal")
	RunState.shards_this_run = 5
	rm.call("_render_shop")
	await _shot("nothing-affordable")
	_guard.restore()
	get_tree().quit()
