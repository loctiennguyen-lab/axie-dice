class_name DiceThumb
extends RefCounted
## One baked 256x256 image per dice skin (dice/_shared.md section 10) for the Profile grid and the Echo Box
## 10-pull: no live 3D die per tile. Bake once (first ask), cache in memory and in user://thumbs/<id>_<hash>.png.
## The hash covers the skin's data entry and its source files' modification times, so a changed skin re-bakes.
## Rendering needs a real display: headless returns null (callers show a flat placeholder).

const VERSION := 1
const PX := 256

static var _mem: Dictionary = {}   # id -> ImageTexture
static var _busy := false


## Cache file name of a skin's thumbnail (changes when the skin data or art changes).
static func cache_name(id: String) -> String:
	var h := ("%d|%s" % [VERSION, JSON.stringify(DiceSkin.info(id))]).hash()
	for f in (DiceSkin.info(id).get("files", []) as Array):
		h = ("%d|%d" % [h, FileAccess.get_modified_time(DiceSkin.ROOT + id + "/" + String(f))]).hash()
	return "%s_%d.png" % [id, h]


static func cached_texture(id: String) -> Texture2D:
	return _mem.get(id)


## The thumbnail of `id`; bakes it under `host` when no cache exists. Await it. null = no art / headless.
static func get_thumb(host: Node, id: String) -> Texture2D:
	if not DiceSkin.has(id):
		return null
	if _mem.has(id):
		return _mem[id]
	if DisplayServer.get_name() == "headless":
		return null
	while _busy:
		await host.get_tree().process_frame
		if _mem.has(id):
			return _mem[id]
	_busy = true
	var path := "user://thumbs/" + cache_name(id)
	var tex: Texture2D = null
	if FileAccess.file_exists(path):
		var img := Image.load_from_file(path)
		if img != null and not img.is_empty():
			tex = ImageTexture.create_from_image(img)
	if tex == null:
		tex = await _bake(host, id, path)
	if tex != null:
		_mem[id] = tex
	_busy = false
	return tex


static func _bake(host: Node, id: String, path: String) -> Texture2D:
	var roller := DiceRoller3D.new()
	host.add_child(roller)
	await roller.prepare(DiceStage.THUMB_FACES, id)
	var st := DiceStage.new()
	st.setup(Vector2i(PX, PX), id, DiceStage.THUMB_FACES, false)
	st.position = Vector2(-4000, -4000)
	host.add_child(st)
	for _i in 3:
		await RenderingServer.frame_post_draw
	var img := st.vp.get_texture().get_image()
	st.queue_free()
	roller.queue_free()
	if img == null or img.is_empty():
		return null
	img.convert(Image.FORMAT_RGBA8)
	DirAccess.make_dir_recursive_absolute("user://thumbs")
	for old in DirAccess.get_files_at("user://thumbs"):
		if old.begins_with(id + "_") and old != path.get_file():
			DirAccess.remove_absolute("user://thumbs/" + old)
	img.save_png(path)
	return ImageTexture.create_from_image(img)
