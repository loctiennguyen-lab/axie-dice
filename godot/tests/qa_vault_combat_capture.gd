extends Node
## Manual VISUAL QA: does an imported Vault Axie's REAL body show up in combat?
##
## The report was "không hiển thị art của Vault Axie trong trận" — the Vault card drew the
## imported Axie from its genes and the battlefield drew a generic class-coloured stand-in.
## Two captures, same seed and same slot, so the only difference on screen is the body:
##   vault_off — the roster's own hero, generic descriptor (what shipped)
##   vault_on  — the same slot replaced by an imported Axie built from real genes
##
## Run: xvfb-run -a -s "-screen 0 1920x1080x24" <godot> --path godot \
##        --rendering-driver opengl3 --resolution 1920x1080 res://tests/qa_vault_combat_capture.tscn

const GENES := "0x180000000000030002018040810800000001000c080043040001000c0800800200010014084083020001000c1860430600010008100085060001000408604506"
var _EVIDENCE_DIR := QaPaths.evidence_dir()
var _guard := SaveGuard.new()


func _ready() -> void:
	var tree := get_tree()
	DirAccess.make_dir_recursive_absolute(_EVIDENCE_DIR)
	_guard.capture()

	await _shoot(tree, "vault_off", false)
	await _shoot(tree, "vault_on", true)

	_guard.restore()
	print("qa_vault_combat_capture: done")
	tree.quit(0)


func _shoot(tree: SceneTree, tag: String, use_vault: bool) -> void:
	var roster := _synthetic_roster()
	if use_vault:
		var res: Dictionary = MetaState.vault_import({
			"id": "111122", "class": "beast", "genes": GENES,
			"parts": _fake_parts(),
		}, 0)
		if not bool(res.get("ok", false)):
			push_error("vault_import failed: %s" % str(res.get("err", "")))
			return
		MetaState.ensure_vault_heroes()
		var key := MetaState.vault_key(MetaState.vault_entry("111122"))
		# Slot 0, so the imported body stands in the same place in both captures.
		roster[0] = {"persistent_id": 1, "hero_key": key, "tier": 1,
			"max_hp": 12, "muts": [], "growth": {}, "bonus_hp": 0}
		print("qa_vault_combat_capture: vault hero key=%s genes_len=%d" % [
			key, String((ContentDB.heroes.get(key, {}) as Dictionary).get("genes", "")).length()])

	RunState.pending_combat = {
		"node_id": "qa_vault", "kind": "battle", "pw": 2, "ascension": 0,
		"roster_snapshot": roster, "relic_ids": [], "combat_seed": 13371337,
	}
	var scene: Node = load("res://scenes/combat/Combat.tscn").instantiate()
	add_child(scene)
	for _i in 4:
		await tree.process_frame
	await tree.create_timer(1.2).timeout
	var img := get_viewport().get_texture().get_image()
	var path := "%s/%s_vaultart-%s.png" % [_EVIDENCE_DIR, _today(), tag]
	img.save_png(path)
	print("qa_vault_combat_capture: saved %s" % path)
	scene.queue_free()
	await tree.process_frame


func _fake_parts() -> Array:
	var out: Array = []
	for slot in ["mouth", "horn", "back", "tail", "eyes", "ears"]:
		out.append({"id": "beast-%s" % slot, "name": slot.capitalize(),
			"class": "beast", "type": slot.capitalize(), "specialGenes": null})
	return out


func _synthetic_roster() -> Array:
	var keys := ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	var out: Array = []
	for i in keys.size():
		out.append({"persistent_id": i + 1, "hero_key": keys[i], "tier": 1,
			"max_hp": ContentDB.heroes[keys[i]]["max_hp"], "muts": [], "growth": {},
			"bonus_hp": 0})
	return out


func _today() -> String:
	var d := Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [int(d["year"]), int(d["month"]), int(d["day"])]
