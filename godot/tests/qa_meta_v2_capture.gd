extends Node
## Manual VISUAL QA capture for the v2 PASS / UNLOCKS / VAULT / GUIDES restyle.
## Not part of the automated suite — t_pass_unlocks/t_vault/t_guides_daily are the blocking gates.
##
## MUST run non-headless: the dummy rasterizer returns an empty image from `get_texture()` and
## the PNG is written blank, a failure with no other symptom.
##
## Run: /path/to/Godot --path godot res://tests/qa_meta_v2_capture.tscn

const _EVIDENCE_DIR := "/Users/loc.tien.nguyen/my-game/production/qa/evidence"

var _save_guard := SaveGuard.new()


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("qa_meta_v2_capture: running headless — the PNGs would be blank. "
			+ "Re-run WITHOUT --headless.")
		get_tree().quit(1)
		return
	DirAccess.make_dir_recursive_absolute(_EVIDENCE_DIR)
	await get_tree().process_frame
	_save_guard.capture()

	# A populated Vault reads more like the mockup than an empty one — import two fake records the
	# same way t_vault.gd does.
	MetaState.vault.clear()
	MetaState.vault_import(_payload("11778888", "aqua"))
	MetaState.vault_import(_payload("4154", "beast"))

	await _shot_scene("res://scenes/pass/Pass.tscn", "pass")
	await _shot_scene("res://scenes/unlocks/Unlocks.tscn", "unlocks")
	await _shot_scene("res://scenes/vault/Vault.tscn", "vault")
	await _shot_scene("res://scenes/guides/Guides.tscn", "guides")

	_save_guard.restore()
	print("qa_meta_v2_capture: done, save file restored byte for byte")
	get_tree().quit(0)


func _payload(id: String, cls: String) -> Dictionary:
	var parts: Array = []
	for slot in ["eyes", "ears", "back", "mouth", "horn", "tail"]:
		parts.append({"id": "%s-%s" % [cls, slot], "name": "Test %s" % slot,
			"type": slot, "class": cls})
	return {"id": id, "class": cls, "parts": parts, "genes": "0x0"}


func _shot_scene(path: String, label: String) -> void:
	var scene := (load(path) as PackedScene).instantiate()
	add_child(scene)
	for _i in 14:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var out := "%s/%s_meta-v2_%s.png" % [_EVIDENCE_DIR, _today(), label]
	get_tree().root.get_texture().get_image().save_png(out)
	print("qa_meta_v2_capture: saved ", out)
	scene.queue_free()
	await get_tree().process_frame


func _today() -> String:
	var d := Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [int(d["year"]), int(d["month"]), int(d["day"])]
