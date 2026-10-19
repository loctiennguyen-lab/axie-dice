class_name CosmeticTile
extends RefCounted
## B12: art + display name for any cosmetic id (real art id or Echo Box placeholder id) on cards:
## Echo Box reveal, Store tiles, Pass nodes. Uses CosmeticArt's public API only.


## Art Control `px` square for `id`, or null when the id has no art (fx_*, titles, unknown).
## Dice skin: the baked thumbnail (filled in when ready). Frame: the player's initial on a disc wearing it
## (avatar = px / 1.5 x 0.86 so the node fits the box). Used by Store tiles, Pass nodes, Echo Box summary.
static func art(id: String, px: float) -> Control:
	var a := Cosmetics.art_id(id)
	if a == "":
		return null
	var n: Control = null
	if DiceSkin.has(a):
		var tr := TextureRect.new()
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.custom_minimum_size = Vector2(px, px)
		tr.size = Vector2(px, px)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_fill_thumb(tr, a)
		n = tr
	elif (CosmeticArt.manifest().get("frames", {}) as Dictionary).has(a):
		var letter := "P"
		if AccountService.is_signed_in():
			letter = AccountService.display_name()
		n = AvatarFrame.letter_preview(a, px / AvatarFrame.SCALE * 0.86, letter)
	if n != null:
		n.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		n.name = "Art"
	return n


static func _fill_thumb(tr: TextureRect, skin: String) -> void:
	var tex: Texture2D = DiceThumb.cached_texture(skin)
	if tex == null:
		var host := (Engine.get_main_loop() as SceneTree).root
		tex = await DiceThumb.get_thumb(host, skin)
	if is_instance_valid(tr) and tex != null:
		tr.texture = tex


## Manifest name ("Sunbaked Weave"), or "" when the id has no art.
static func display_name(id: String) -> String:
	var a := Cosmetics.art_id(id)
	var m := CosmeticArt.manifest()
	var e: Variant = (m.get("dice", {}) as Dictionary).get(a, (m.get("frames", {}) as Dictionary).get(a, null))
	return String((e as Dictionary).get("name", "")) if e is Dictionary else ""


## Player-facing name of any cosmetic id: dice/frame/fx manifest name, else "" (no guess, no raw id).
static func any_name(id: String) -> String:
	var n := display_name(id)
	if n != "":
		return n
	var fx: Variant = (CosmeticArt.manifest().get("fx", {}) as Dictionary).get(id, null)
	return String((fx as Dictionary).get("name", "")) if fx is Dictionary else ""
