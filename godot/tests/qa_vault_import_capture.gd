extends Node
## Manual VISUAL QA: the Vault screen doing a REAL import — types an ID, hits the live gateway,
## shows the preview, adds it. Proves the whole chain in one picture.
##
## Hits the network on purpose, which is exactly why it is NOT a gate (see `t_axie_api`'s header).
## MUST run non-headless or the PNGs come out blank.
##
## Run: /path/to/Godot --path godot res://tests/qa_vault_import_capture.tscn

const _EVIDENCE_DIR := "/Users/loc.tien.nguyen/my-game/production/qa/evidence"
const IDS: PackedStringArray = ["123", "11778888"]

var _guard := SaveGuard.new()


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("qa_vault_import_capture: headless — the PNGs would be blank.")
		get_tree().quit(1)
		return
	DirAccess.make_dir_recursive_absolute(_EVIDENCE_DIR)
	await get_tree().process_frame
	_guard.capture()
	MetaState.vault.clear()

	var screen := (load("res://scenes/vault/Vault.tscn") as PackedScene).instantiate()
	add_child(screen)
	await get_tree().process_frame

	if not AxieApi.is_available():
		push_error("qa_vault_import_capture: import unavailable — " + AxieApi.unavailable_reason())
		_guard.restore(); get_tree().quit(1); return

	for i in IDS.size():
		var id := IDS[i]
		screen._id_field.text = id
		screen._refresh_scan_enabled()
		screen._on_scan_pressed()
		var res: Dictionary = await screen._api.completed
		await _settle(14)
		if not bool(res.get("ok", false)):
			push_error("qa_vault_import_capture: #%s failed — %s" % [id, res.get("message", "")])
			continue
		await _shot("%02d_preview_%s" % [i + 1, id])
		screen._on_add_pressed()
		await _settle(14)

	await _shot("03_imported")
	_guard.restore()
	print("qa_vault_import_capture: done, player save restored")
	get_tree().quit(0)


func _settle(frames: int) -> void:
	for _i in frames:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw


func _shot(label: String) -> void:
	var path := "%s/2026-09-19_vault-import-%s.png" % [_EVIDENCE_DIR, label]
	get_tree().root.get_texture().get_image().save_png(path)
	print("qa_vault_import_capture: saved ", path)
