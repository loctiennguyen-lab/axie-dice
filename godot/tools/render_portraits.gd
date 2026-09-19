extends Node
## Renders one face portrait per hero class from the 3D rig, to `assets/portraits/<class>.png`.
##
## WHY A TOOL AND NOT A ONE-OFF
## ----------------------------
## The party Axies are 3D rigs; no 2D portrait art exists for them anywhere, and inventing one
## (borrowing a monster sprite, drawing a stand-in) would put art in the game that does not
## match the character it labels. Rendering the actual rig is the only honest source. Keeping
## it as a tool rather than a script that was run once means the portraits can be regenerated
## when the rig, the class colours or `_PART_VARIANT` change — otherwise the PNGs silently
## become a snapshot of an older character.
##
## RUN IT — WITHOUT --headless:
##   /path/to/Godot --path godot res://tools/render_portraits.tscn
##
## Under `--headless` Godot uses the dummy renderer and `SubViewport.get_texture().get_image()`
## comes back empty; the files would be written, and they would be blank. This is the same trap
## the QA capture scenes carry (see docs/godot-port-inventory.md §8).
##
## WHAT IT DELIBERATELY DOES NOT DO
## --------------------------------
## It does not render per TIER. `CombatStage3D._build_parts()` uses a fixed `_PART_VARIANT` and
## `_CLASS_COLOR_VARIANT` is keyed by class alone, so the rig has no tier appearance at all:
## asking for "6 classes x 3 tiers" would write 18 files of which 12 are duplicates pretending
## to be distinct. The die card shows the tier as a roman numeral next to the name instead —
## real information, not a fabricated visual difference.
##
## The portraits face the CAMERA, unlike the party on the battlefield. The standing rule that
## party Axies show their backs is a rule about the stage; a portrait of the back of a head
## carries no information at all, and every class would look identical. Confirmed with the user
## before this was written, not assumed.

const OUT_DIR := "res://assets/portraits/"
const SIZE := 256

## Same values CombatStage3D uses, so a portrait is the same character the player sees on the
## field. Duplicated rather than imported because CombatStage3D's copies are private to a scene
## script; if either moves, `t_assets` is what notices the portraits stopped matching.
const CLASS_COLOR_VARIANT := {
	"plant": 8, "beast": 3, "aqua": 14, "reptile": 30, "bug": 20, "bird": 26,
}
const CLASS_PART_CLASS := {
	"plant": "Plant", "beast": "Beast", "aqua": "Aquatic",
	"reptile": "Reptile", "bug": "Bug", "bird": "Bird",
}
const PART_VARIANT := 2
const PART_TYPES: Array[int] = [
	AxieTypes.Part.MOUTH, AxieTypes.Part.HORN, AxieTypes.Part.BACK,
	AxieTypes.Part.TAIL, AxieTypes.Part.EAR, AxieTypes.Part.EYE,
]

## Framing. Pulled back from the first pass, which clipped the top of Beast's ears and Bird's
## cap — checked by looking at the rendered sheet, not by computing the bounds, because the
## rig's real silhouette is taller than its nominal head height.
const CAM_POS := Vector3(0.0, 1.42, 3.05)
const CAM_LOOK_AT := Vector3(0.0, 1.12, 0.0)
const CAM_FOV := 30.0


func _ready() -> void:
	print("=== render_portraits: start ===")
	if DisplayServer.get_name() == "headless":
		push_error("render_portraits: running headless — every PNG would be blank. "
			+ "Re-run WITHOUT --headless.")
		get_tree().quit(1)
		return

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var written := 0
	for cls in CLASS_PART_CLASS.keys():
		if await _render_one(String(cls)):
			written += 1
	print("=== render_portraits: wrote %d/%d portraits to %s ===" % [
		written, CLASS_PART_CLASS.size(), OUT_DIR])
	get_tree().quit(0 if written == CLASS_PART_CLASS.size() else 1)


func _render_one(cls: String) -> bool:
	var vp := SubViewport.new()
	vp.size = Vector2i(SIZE, SIZE)
	vp.transparent_bg = true          # the card composites it over its own panel
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.own_world_3d = true            # each portrait gets its own 3D world, so two classes
		# rendered in the same run cannot light or occlude each other
	add_child(vp)

	var cam := Camera3D.new()
	cam.fov = CAM_FOV
	cam.look_at_from_position(CAM_POS, CAM_LOOK_AT, Vector3.UP)
	vp.add_child(cam)

	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-35, 25, 0)
	key_light.light_energy = 1.3
	vp.add_child(key_light)

	# Flat, generous ambient: this is an icon, not a scene. Directional light alone leaves one
	# side of the face in shadow, which at the 22px the card actually draws reads as dirt.
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 1, 1)
	env.ambient_light_energy = 0.6
	world_env.environment = env
	vp.add_child(world_env)

	var desc := AxieDescriptor.new()
	desc.body = AxieTypes.Body.NORMAL
	desc.color_variant = int(CLASS_COLOR_VARIANT.get(cls, 0))
	var parts: Array[AxiePartDescriptor] = []
	for pt in PART_TYPES:
		parts.append(AxiePartDescriptor.new(pt, 0, String(CLASS_PART_CLASS[cls]), PART_VARIANT, 1))
	desc.parts = parts

	var character = AxieCharacter3D.from_descriptor(desc)
	if character == null or character.root == null:
		push_error("render_portraits: could not build a rig for class '%s'" % cls)
		vp.queue_free()
		return false
	vp.add_child(character.root)
	character.root.position = Vector3.ZERO
	character.root.rotation_degrees.y = 0.0   # facing the camera — see the header
	if character.playable != null:
		character.playable.set_default(AnimNames.Idle)
		character.playable.play(AnimNames.Idle, "", true)

	# Two full draw cycles: the first one gets the rig into the world, the second renders it
	# with its Idle pose applied. One is not reliably enough and produces an empty image.
	await RenderingServer.frame_post_draw
	await get_tree().process_frame
	await RenderingServer.frame_post_draw

	var img := vp.get_texture().get_image()
	if not _has_visible_pixels(img):
		push_error("render_portraits: '%s' rendered completely empty — not writing it" % cls)
		vp.queue_free()
		return false
	var path := ProjectSettings.globalize_path(OUT_DIR + cls + ".png")
	var err := img.save_png(path)
	vp.queue_free()
	if err != OK:
		push_error("render_portraits: failed to write %s (error %d)" % [path, err])
		return false
	print("  %-8s -> %s" % [cls, path])
	return true


## Guards against the failure that has no other symptom: a PNG that exists, loads, and is
## entirely transparent. Sampled rather than exhaustive — a real portrait fills a large part of
## the frame, so a sparse sample separates it from blank without the cost of every pixel.
func _has_visible_pixels(img: Image) -> bool:
	var opaque := 0
	for y in range(0, img.get_height(), 4):
		for x in range(0, img.get_width(), 4):
			if img.get_pixel(x, y).a > 0.05:
				opaque += 1
	return opaque > 200
