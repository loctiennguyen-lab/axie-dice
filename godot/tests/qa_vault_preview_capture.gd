extends Node
## Manual VISUAL QA capture for AxiePreview3D.tscn — the Vault/Import Axie preview built straight
## from an Axie's gene string. Not part of the automated suite (Visual evidence is ADVISORY per
## coding-standards.md); `t_axie_gene_preview` is the blocking gate and it checks the numbers, not
## the picture.
##
## MUST run non-headless. Under --headless the dummy rasterizer hands back an empty image from
## `get_texture()`, the PNG is still written, and it is blank — a failure with no other symptom.
## The scene refuses to run in that mode rather than produce one.
##
## It lays out the vendor's pinned samples side by side ON PURPOSE. A single Axie proves the rig
## builds; a row proves the genes are actually being read, because four Axies from four genes have
## to come out looking like four different animals. The last tile is the `0x0` sample, which is
## there to show the warning badge doing its job.
##
## Run: /path/to/Godot --path godot res://tests/qa_vault_preview_capture.tscn

const _EVIDENCE_DIR := "/Users/loc.tien.nguyen/my-game/production/qa/evidence"
const _OUT := "2026-09-19_vault-preview-from-genes.png"
const GOLDEN_REL := "../third_party/godot-axie-mixer-3d-main/tests/goldens/sample_axies.json"
const PREVIEW_SCENE := "res://scenes/shared/AxiePreview3D.tscn"

## Picked to be visibly unalike: two body types (Normal + Fuzzy), four colour variants, and the
## empty gene. #4154 is the one carrying skin-3 parts, so it also exercises the resolver's fallback.
const SHOW_IDS: PackedStringArray = ["123", "4154", "1000", "777", "1"]
const TILE := Vector2(248, 300)


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("qa_vault_preview_capture: running headless — the PNG would be blank. "
			+ "Re-run WITHOUT --headless.")
		get_tree().quit(1)
		return
	DirAccess.make_dir_recursive_absolute(_EVIDENCE_DIR)
	await get_tree().process_frame

	var golden := _load_golden()
	if golden.is_empty():
		push_error("qa_vault_preview_capture: could not read the vendor golden")
		get_tree().quit(1)
		return

	var bg := ColorRect.new()
	bg.color = Color(0x13 / 255.0, 0x16 / 255.0, 0x1B / 255.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var row := HBoxContainer.new()
	row.position = Vector2(16, 16)
	row.add_theme_constant_override("separation", 10)
	add_child(row)

	for id in SHOW_IDS:
		var entry := _entry(golden, id)
		var tile := VBoxContainer.new()
		tile.custom_minimum_size = TILE
		row.add_child(tile)

		var preview: Control = (load(PREVIEW_SCENE) as PackedScene).instantiate()
		preview.custom_minimum_size = Vector2(TILE.x, TILE.y - 52)
		tile.add_child(preview)

		var report: Dictionary = preview.set_genes(str(entry.get("genes", "")))
		var caption := Label.new()
		caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		caption.add_theme_font_size_override("font_size", 12)
		caption.add_theme_color_override("font_color", Color(0.93, 0.94, 0.96))
		caption.text = "#%s — %s, colour %d\n%d/%d parts" % [
			id, report["body_name"], int(report["color_variant"]),
			int(report["resolved_count"]), int(report["part_count"])]
		tile.add_child(caption)

	# Several frames: the rig has to enter the world, the Idle pose has to apply, and the avatar
	# renderer arms its viewport for the NEXT draw each time it is called. One frame gives an
	# empty picture — the same trap tools/render_portraits.gd documents.
	for _i in 12:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw

	var img := get_tree().root.get_texture().get_image()
	if not _has_visible_pixels(img):
		push_error("qa_vault_preview_capture: the frame came back effectively empty — not writing "
			+ "a blank PNG over the previous evidence")
		get_tree().quit(1)
		return
	var path := "%s/%s" % [_EVIDENCE_DIR, _OUT]
	img.save_png(path)
	print("qa_vault_preview_capture: saved ", path)
	get_tree().quit(0)


func _load_golden() -> Dictionary:
	var path := ProjectSettings.globalize_path("res://").path_join(GOLDEN_REL)
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _entry(golden: Dictionary, id: String) -> Dictionary:
	for e in golden.get("ids", []):
		if str(e.get("id", "")) == id:
			return e
	return {}


## Guards the one failure that leaves no trace: a PNG that exists, loads, and shows nothing.
## Counts pixels that differ from the flat background rather than opaque ones, since this capture
## is of the whole window and its background is opaque by design.
func _has_visible_pixels(img: Image) -> bool:
	var bg := Color(0x13 / 255.0, 0x16 / 255.0, 0x1B / 255.0)
	var lit := 0
	for y in range(0, img.get_height(), 4):
		for x in range(0, img.get_width(), 4):
			var c := img.get_pixel(x, y)
			if absf(c.r - bg.r) + absf(c.g - bg.g) + absf(c.b - bg.b) > 0.06:
				lit += 1
	return lit > 500
