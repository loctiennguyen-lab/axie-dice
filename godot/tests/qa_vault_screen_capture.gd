extends Node
## Manual VISUAL QA capture for the Vault screen (Import Axie, step (c)). Not part of the
## automated suite — `t_vault` is the blocking gate and it checks behaviour, not pixels.
##
## MUST run non-headless: under the dummy rasterizer `get_texture()` hands back an empty image and
## the PNG is written blank, a failure with no other symptom.
##
## It seeds the vault with fixtures and PUTS THE PLAYER'S OWN VAULT BACK afterwards. The vault is
## a real save file, not a test double.
##
## Run: /path/to/Godot --path godot res://tests/qa_vault_screen_capture.tscn

const _EVIDENCE_DIR := "/Users/loc.tien.nguyen/my-game/production/qa/evidence"
const GOLDEN_REL := "../third_party/godot-axie-mixer-3d-main/tests/goldens/sample_axies.json"

## Real genes from the vendor's pinned samples, so the previews in the shot are the same four
## Axies the step-(b) evidence shows — a reader can line the two images up.
const SEED_IDS: PackedStringArray = ["123", "4154", "1000"]

## SaveGuard, not a hand-rolled in-memory restore. The first version put `MetaState.vault` back in
## memory and stopped there — but `vault_import()` calls `save_to_disk()`, so the FILE kept the
## three fixture Axies and the player found them in their vault next time they played.
var _guard := SaveGuard.new()
var _shots := 0


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("qa_vault_screen_capture: running headless — every PNG would be blank. "
			+ "Re-run WITHOUT --headless.")
		get_tree().quit(1)
		return
	DirAccess.make_dir_recursive_absolute(_EVIDENCE_DIR)
	await get_tree().process_frame

	_guard.capture()

	MetaState.vault.clear()
	await _shot_screen("01_empty")

	for id in SEED_IDS:
		MetaState.vault_import(_payload(id, _genes_for(id)))
	# One record written under the old face rules, so the RE-SCAN state is in the evidence too.
	var stale := AxieToDie.build(_payload("321", _genes_for("777")))
	stale["axie_id"] = "321"
	stale["schema"] = 1
	MetaState.vault.append(stale)
	await _shot_screen("02_populated")

	_guard.restore()
	print("qa_vault_screen_capture: %d frame(s) written, player vault restored" % _shots)
	get_tree().quit(0)


func _shot_screen(label: String) -> void:
	var screen := (load("res://scenes/vault/Vault.tscn") as PackedScene).instantiate()
	add_child(screen)
	# Several frames: the rows build, each preview's rig enters the world, and the avatar renderer
	# arms its viewport for the NEXT draw each time it is called.
	for _i in 14:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw

	var img := get_tree().root.get_texture().get_image()
	var path := "%s/%s_vault-screen-%s.png" % [_EVIDENCE_DIR, _today(), label]
	img.save_png(path)
	_shots += 1
	print("qa_vault_screen_capture: saved ", path)
	screen.queue_free()
	await get_tree().process_frame


func _payload(id: String, genes: String) -> Dictionary:
	var parts: Array = []
	for slot in ["mouth", "horn", "back", "tail", "eyes", "ears"]:
		parts.append({"id": "p-%s-%s" % [id, slot], "name": "Sample %s" % slot,
			"class": "plant", "type": slot, "specialGenes": null})
	return {"id": id, "class": "plant", "parts": parts, "genes": genes}


func _genes_for(id: String) -> String:
	var path := ProjectSettings.globalize_path("res://").path_join(GOLDEN_REL)
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		return ""
	for e in (parsed as Dictionary).get("ids", []):
		if str((e as Dictionary).get("id", "")) == id:
			return str((e as Dictionary).get("genes", ""))
	return ""


## Today, as `YYYY-MM-DD`, for naming the files this capture writes.
##
## The date used to be typed into the filename by hand. That makes a screenshot LIE the moment
## the capture is re-run: the picture is regenerated, the name still says the day it was first
## written, and anyone reading the folder — or a report linking to it — concludes the evidence is
## stale when it is current. Stamping it at run time means a filename can only ever be right.
func _today() -> String:
	var d := Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [int(d["year"]), int(d["month"]), int(d["day"])]
