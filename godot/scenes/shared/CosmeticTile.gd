class_name CosmeticTile
extends RefCounted
## B12: art + display name for any cosmetic id (real art id or Echo Box placeholder id) on cards:
## Echo Box reveal, Store tiles, Pass nodes. Uses CosmeticArt's public API only.


## Art Control `px` square for `id`, or null when the id has no art (fx_*, titles, unknown).
static func art(id: String, px: float) -> Control:
	var a := Cosmetics.art_id(id)
	if a == "":
		return null
	var n := CosmeticArt.make_node(a, px)
	if n != null:
		n.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		n.name = "Art"
	return n


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
